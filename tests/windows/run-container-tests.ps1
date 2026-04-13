[CmdletBinding()]
param(
	[switch]$NoCleanup,
	[Parameter(ValueFromRemainingArguments = $true)]
	[string[]]$Tests
)

$ErrorActionPreference = "Stop"

$RepoDir = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$Containers = [System.Collections.Generic.List[string]]::new()
$Failures = 0
$Total = 0

if (-not $Tests -or $Tests.Count -eq 0) {
	$Tests = @("full")
}

$ValidTests = @("full")
foreach ($Test in $Tests) {
	if ($ValidTests -notcontains $Test) {
		throw "Unknown test '$Test'. Valid tests: $($ValidTests -join ', ')"
	}
}

function Get-PodmanServerOs {
	try {
		$info = & podman info --format json 2>$null | ConvertFrom-Json
		return $info.host.os
	} catch {
		return $null
	}
}

function Get-DockerServerOs {
	try {
		return (& docker version --format '{{.Server.Os}}' 2>$null).Trim()
	} catch {
		return $null
	}
}

function Get-ContainerRuntime {
	$podman = Get-Command podman -ErrorAction SilentlyContinue
	if ($podman) {
		$podmanOs = Get-PodmanServerOs
		if ($podmanOs -eq "windows") {
			return "podman"
		}
		if ($podmanOs) {
			Write-Host "Skipping podman: connected engine reports os=$podmanOs. Windows container tests require a Windows-capable engine."
		}
	}

	$docker = Get-Command docker -ErrorAction SilentlyContinue
	if ($docker) {
		$dockerOs = Get-DockerServerOs
		if ($dockerOs -eq "windows") {
			return "docker"
		}
		if ($dockerOs) {
			Write-Host "Skipping docker: connected engine reports os=$dockerOs. Windows container tests require a Windows-capable engine."
		}
	}

	throw "No Windows-capable container runtime found. Podman on Windows usually connects to a Linux podman machine, so use Docker with Windows containers or a remote Windows-capable runtime."
}

$Runtime = Get-ContainerRuntime
$Image = "dotfiles-test:windows-ltsc2025"

function Invoke-ContainerRuntime {
	param(
		[string[]]$Arguments,
		[switch]$AllowFailure
	)

	& $Runtime @Arguments
	$exitCode = $LASTEXITCODE
	if (-not $AllowFailure -and $exitCode -ne 0) {
		throw "$Runtime $($Arguments -join ' ') failed with exit code $exitCode"
	}

	return $exitCode
}

function Invoke-Test {
	param(
		[string]$Name,
		[string[]]$ExtraArgs = @()
	)

	$script:Total++
	$Containers.Add($Name)

	Write-Host ""
	Write-Host "==> Running test: $Name"
	$exitCode = Invoke-ContainerRuntime -Arguments (@("run", "--name", $Name) + $ExtraArgs + @($Image)) -AllowFailure
	if ($exitCode -eq 0) {
		Write-Host "--- PASSED: $Name"
	} else {
		Write-Host "--- FAILED: $Name"
		$script:Failures++
	}
}

try {
	Write-Host "==> Building image: $Image (using $Runtime)"
		Invoke-ContainerRuntime -Arguments @(
		"build",
		"-f", (Join-Path $RepoDir "tests\windows\Containerfile.windows"),
		"-t", $Image,
		$RepoDir
	)

	$Timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()

	foreach ($Test in $Tests) {
		switch ($Test) {
			"full" {
				Invoke-Test -Name "dotfiles-test-windows-full-$Timestamp"
			}
		}
	}

	Write-Host ""
	Write-Host "========================================="
	Write-Host "  Results: $($Total - $Failures)/$Total passed"
	Write-Host "========================================="

	exit $Failures
} finally {
	if (-not $NoCleanup) {
		Write-Host ""
		Write-Host "==> Cleaning up containers"
		foreach ($Name in $Containers) {
			$exitCode = Invoke-ContainerRuntime -Arguments @("rm", "-f", $Name) -AllowFailure 2>$null
			if ($exitCode -eq 0) {
				Write-Host "    removed $Name"
			}
		}
	} else {
		Write-Host ""
		Write-Host "==> Containers kept (--no-cleanup). To debug or clean up:"
		foreach ($Name in $Containers) {
			Write-Host "    $Runtime exec -it $Name powershell"
			Write-Host "    $Runtime rm -f $Name"
		}
	}
}
