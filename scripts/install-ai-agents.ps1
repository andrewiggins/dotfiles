# Install AI coding agents for Windows.
# Honors $env:SKIP_PACKAGES = "1" for CI dry-runs.

$ErrorActionPreference = "Stop"

if ($env:SKIP_PACKAGES -eq "1") {
	Write-Host "SKIP_PACKAGES=1, skipping AI agent install"
	exit 0
}

$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

function Install-NpmCli {
	param(
		[string]$CommandName,
		[string]$PackageName
	)

	if (Get-Command $CommandName -ErrorAction SilentlyContinue) {
		Write-Host "$CommandName already installed"
		return
	}

	if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
		throw "npm is required to install $PackageName"
	}

	Write-Host "Installing $PackageName..."
	npm install -g $PackageName
}

if (Get-Command claude -ErrorAction SilentlyContinue) {
	Write-Host "claude already installed"
} else {
	Write-Host "Installing Claude Code via native installer..."
	& ([scriptblock]::Create((Invoke-RestMethod -Uri "https://claude.ai/install.ps1")))
	$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}

Install-NpmCli -CommandName "codex" -PackageName "@openai/codex"
Install-NpmCli -CommandName "pi" -PackageName "@mariozechner/pi-coding-agent"
