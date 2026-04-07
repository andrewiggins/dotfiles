# dotfiles installer for native Windows.
#
# Symlinks files in home/ into $HOME (skipping macOS-only files), runs winget
# package install, and configures git.
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
	& (Join-Path $RepoDir "scripts\configure-git.ps1")
}

Write-Host "==> Done."
