# dotfiles installer for native Windows.
#
# Symlinks files in home/ into $HOME (skipping macOS-only files), runs package
# install plus AI agent setup, then configures git and Claude Code.
#
# Symlinks require Developer Mode (Settings -> Privacy & Security -> For
# developers) or running as Administrator.
#
# Environment overrides:
#   $env:DRY_RUN = "1"        Print actions without modifying anything.
#   $env:SKIP_PACKAGES = "1"  Skip running winget install.

$ErrorActionPreference = "Stop"

$RepoDir = $PSScriptRoot
$DryRun = $env:DRY_RUN -eq "1"

function Find-GitBash {
	# Find Git Bash specifically — avoid WSL's bash.exe (C:\Windows\System32\bash.exe).
	# Strategy: use git's install location to find the co-installed bash.
	$gitCmd = Get-Command git -ErrorAction SilentlyContinue
	if ($gitCmd) {
		# git.exe is typically at <GitDir>\cmd\git.exe or <GitDir>\bin\git.exe
		# bash.exe is at <GitDir>\bin\bash.exe
		$gitDir = Split-Path -Parent (Split-Path -Parent $gitCmd.Source)
		$candidate = Join-Path $gitDir "bin\bash.exe"
		if (Test-Path $candidate) { return $candidate }
	}

	# Fallback: check common install locations
	foreach ($path in @(
		"C:\Program Files\Git\bin\bash.exe",
		"C:\Program Files (x86)\Git\bin\bash.exe"
	)) {
		if (Test-Path $path) { return $path }
	}

	Write-Error "Git Bash not found. Install Git for Windows: https://git-scm.com"
	throw
}

function Invoke-BashScript {
	param([string]$Script)

	$bashExe = Find-GitBash
	$unixScript = $Script -replace '\\', '/'

	& $bashExe $unixScript
	if ($LASTEXITCODE -ne 0) {
		Write-Error "bash script failed: $Script (exit code $LASTEXITCODE)"
		throw
	}
}

Write-Host "==> dotfiles install"
Write-Host "    repo:    $RepoDir"
Write-Host "    home:    $HOME"
Write-Host "    dry-run: $DryRun"

function Link-File {
	param([string]$Src, [string]$Dest)
	if ($DryRun) {
		Write-Host "    would link $Dest -> $Src"
		return
	}
	$parent = Split-Path -Parent $Dest
	if (-not (Test-Path $parent)) {
		New-Item -ItemType Directory -Force -Path $parent | Out-Null
	}
	if (Test-Path $Dest) {
		Remove-Item -Force $Dest
	}
	try {
		New-Item -ItemType SymbolicLink -Path $Dest -Target $Src -Force | Out-Null
		Write-Host "    linked $Dest -> $Src"
	} catch {
		Write-Error @"
Failed to create symlink $Dest -> $Src
Symlinks on Windows require either:
  - Developer Mode (Settings -> Privacy & Security -> For developers), or
  - Running this script as Administrator.
Original error: $_
"@
		throw
	}
}

# --- 1. Symlink files in home/ ----------------------------------------------
Write-Host "==> Linking dotfiles"
$skipOnWindows = @(".zshrc", ".zprofile")
Get-ChildItem -Path (Join-Path $RepoDir "home") -Recurse -File | ForEach-Object {
	$rel = $_.FullName.Substring((Join-Path $RepoDir "home").Length + 1)
	$relForward = $rel -replace '\\', '/'
	if ($skipOnWindows -contains $relForward) {
		return
	}
	$dest = Join-Path $HOME $rel
	Link-File -Src $_.FullName -Dest $dest
}

# --- 2. Ensure vim undodir --------------------------------------------------
if (-not $DryRun) {
	New-Item -ItemType Directory -Force -Path (Join-Path $HOME ".vim\undodir") | Out-Null
}

# --- 3. Install packages ----------------------------------------------------
Write-Host "==> Installing packages"
if ($DryRun) {
	Write-Host "    (dry-run, skipping package install)"
} else {
	& (Join-Path $RepoDir "scripts\install-packages-windows.ps1")
}

# --- 4. Configure git -------------------------------------------------------
Write-Host "==> Configuring git"
if ($DryRun) {
	Write-Host "    (dry-run, skipping git config)"
} else {
	Invoke-BashScript (Join-Path $RepoDir "scripts/configure-git.sh")
}

# --- 5. Install AI agents ---------------------------------------------------
Write-Host "==> Installing AI agents"
if ($DryRun) {
	Write-Host "    (dry-run, skipping AI agent install)"
} else {
	& (Join-Path $RepoDir "scripts\install-ai-agents.ps1")
}

# --- 6. Configure Claude Code -----------------------------------------------
Write-Host "==> Configuring Claude Code"
if ($DryRun) {
	Write-Host "    (dry-run, skipping Claude Code config)"
} else {
	Invoke-BashScript (Join-Path $RepoDir "scripts/configure-claude.sh")
}

Write-Host "==> Done."
