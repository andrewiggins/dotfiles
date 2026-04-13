$ErrorActionPreference = "Continue"
$passed = 0
$failed = 0

$HomeDir = [Environment]::GetFolderPath("UserProfile")
$RepoPrefix = "C:\dotfiles\home\"
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
$env:VOLTA_HOME = Join-Path $HomeDir ".volta"
$env:Path = (Join-Path $HomeDir ".cargo\bin") + ";" + (Join-Path $env:VOLTA_HOME "bin") + ";" + $env:Path

function Ok {
	param([string]$Message)
	Write-Host "  ok: $Message"
	$script:passed++
}

function Fail {
	param([string]$Message)
	Write-Host "  FAIL: $Message"
	$script:failed++
}

function Check-Symlink {
	param(
		[string]$RelativePath,
		[string]$ExpectedTarget
	)

	$Path = Join-Path $HomeDir $RelativePath
	if (-not (Test-Path -LiteralPath $Path)) {
		Fail "symlink ~\$RelativePath does not exist"
		return
	}

	$Item = Get-Item -LiteralPath $Path -Force
	if ($Item.LinkType -ne "SymbolicLink") {
		Fail "path ~\$RelativePath is not a symbolic link"
		return
	}

	$Target = @($Item.Target)[0]
	if ($Target -like "$ExpectedTarget*") {
		Ok "symlink ~\$RelativePath -> $Target"
	} else {
		Fail "symlink ~\$RelativePath points to $Target, expected prefix $ExpectedTarget"
	}
}

function Check-Absent {
	param([string]$RelativePath)

	$Path = Join-Path $HomeDir $RelativePath
	if (Test-Path -LiteralPath $Path) {
		Fail "path ~\$RelativePath exists but should be absent on Windows"
	} else {
		Ok "path ~\$RelativePath is absent"
	}
}

function Check-Directory {
	param([string]$Path)

	if (Test-Path -LiteralPath $Path -PathType Container) {
		Ok "directory $Path exists"
	} else {
		Fail "directory $Path does not exist"
	}
}

function Check-Command {
	param([string]$Name)

	if (Get-Command $Name -ErrorAction SilentlyContinue) {
		Ok "command $Name found"
	} else {
		Fail "command $Name not found"
	}
}

function Check-GitConfig {
	param(
		[string]$Key,
		[string]$ExpectedValue
	)

	$ActualValue = & git config --global $Key 2>$null
	if ($LASTEXITCODE -ne 0 -or $null -eq $ActualValue) {
		$ActualValue = ""
	} else {
		$ActualValue = "$ActualValue".Trim()
	}

	if ($ActualValue -eq $ExpectedValue) {
		Ok "git config $Key = $ExpectedValue"
	} else {
		Fail "git config $Key = '$ActualValue', expected '$ExpectedValue'"
	}
}

Write-Host "==> Verifying Windows install"

Write-Host "--- Symlinks"
Check-Symlink ".bashrc" "$RepoPrefix"
Check-Symlink ".vimrc" "$RepoPrefix"
Check-Symlink ".editorconfig" "$RepoPrefix"
Check-Symlink ".config\starship.toml" "$RepoPrefix"
Check-Symlink ".claude\statusline-command.sh" "$RepoPrefix"
Check-Absent ".zshrc"
Check-Absent ".zprofile"

Write-Host "--- Directories"
Check-Directory (Join-Path $HomeDir ".vim\undodir")

Write-Host "--- Commands"
foreach ($Command in @("git", "gh", "rg", "jq", "vim", "python", "pwsh", "starship", "cargo", "rustc", "bat", "delta", "node", "pnpm", "claude")) {
	Check-Command $Command
}

Write-Host "--- Git config"
Check-GitConfig "user.name" "Andre Wiggins"
Check-GitConfig "user.email" "andrewiggins@live.com"
Check-GitConfig "init.defaultBranch" "main"
Check-GitConfig "push.autoSetupRemote" "true"
Check-GitConfig "alias.co" "checkout"
Check-GitConfig "alias.st" "status -s"
Check-GitConfig "core.pager" "delta"
Check-GitConfig "delta.side-by-side" "true"
Check-GitConfig "filter.lfs.required" "true"

Write-Host "--- Claude config"
$SettingsFile = Join-Path $HomeDir ".claude\settings.json"
if (Test-Path -LiteralPath $SettingsFile) {
	Ok "file $SettingsFile exists"
} else {
	Fail "file $SettingsFile does not exist"
}
$Settings = if (Test-Path -LiteralPath $SettingsFile) { Get-Content -LiteralPath $SettingsFile -Raw | ConvertFrom-Json } else { $null }
if ($Settings -and $Settings.statusLine.command -eq "bash ~/.claude/statusline-command.sh") {
	Ok "Claude settings.json has statusLine.command"
} else {
	$ActualCommand = if ($Settings) { $Settings.statusLine.command } else { "" }
	Fail "Claude settings.json has statusLine.command '$ActualCommand', expected 'bash ~/.claude/statusline-command.sh'"
}

Write-Host ""
Write-Host "Results: $passed passed, $failed failed"
exit $failed
