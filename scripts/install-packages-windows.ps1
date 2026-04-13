# Windows package install via winget + Podman Desktop + Volta + Rustup.
# Honors $env:SKIP_PACKAGES = "1" for CI dry-runs.

$ErrorActionPreference = "Stop"
$IsWindowsContainer = $env:DOTFILES_WINDOWS_CONTAINER -eq "1"

if ($env:SKIP_PACKAGES -eq "1") {
	Write-Host "SKIP_PACKAGES=1, skipping windows package install"
	exit 0
}

function Ensure-Winget {
	if (Get-Command winget -ErrorAction SilentlyContinue) {
		return
	}

	try {
		Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe | Out-Null
	} catch {
		Write-Host "WinGet registration attempt failed: $_"
	}

	if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
		throw "winget not found. Install App Installer or ensure DesktopAppInstaller is registered before running install.ps1."
	}
}

function Install-WingetPackage {
	param(
		[string]$Id,
		[string]$Source
	)

	$args = @(
		"install",
		"-e",
		"--id", $Id,
		"--accept-package-agreements",
		"--accept-source-agreements",
		"--disable-interactivity"
	)

	if ($Source) {
		$args += @("--source", $Source)
	}

	& winget @args
}

function Install-WingetPackageIfAllowed {
	param(
		[string]$Id,
		[string]$ReasonToSkipInContainer,
		[string]$Source
	)

	if ($IsWindowsContainer -and $ReasonToSkipInContainer) {
		Write-Host "Skipping $Id in Windows container mode: $ReasonToSkipInContainer"
		return
	}

	Install-WingetPackage -Id $Id -Source $Source
}

Write-Host "Installing packages via winget..."
Ensure-Winget

Install-WingetPackageIfAllowed -Id "GitHub.cli"
Install-WingetPackageIfAllowed -Id "BurntSushi.ripgrep.MSVC"
Install-WingetPackageIfAllowed -Id "dandavison.delta"
Install-WingetPackageIfAllowed -Id "jqlang.jq"
Install-WingetPackageIfAllowed -Id "Microsoft.VisualStudioCode" -ReasonToSkipInContainer "GUI editors are not needed for container verification."
Install-WingetPackageIfAllowed -Id "Microsoft.PowerShell"
Install-WingetPackageIfAllowed -Id "RedHat.Podman-Desktop" -ReasonToSkipInContainer "The container runtime already exists outside the guest."
Install-WingetPackageIfAllowed -Id "sharkdp.bat"
Install-WingetPackageIfAllowed -Id "vim.vim"
Install-WingetPackageIfAllowed -Id "7zip.7zip"
Install-WingetPackageIfAllowed -Id "Python.Python"
Install-WingetPackageIfAllowed -Id "Volta.Volta"
Install-WingetPackageIfAllowed -Id "9P7KNL5RWT25" -Source "msstore" -ReasonToSkipInContainer "Microsoft Store packages are not available in Windows container tests."
Install-WingetPackageIfAllowed -Id "Rustlang.Rustup"
Install-WingetPackageIfAllowed -Id "Starship.Starship"

if (-not $IsWindowsContainer) {
	Write-Host ""
	Write-Host "Podman Desktop needs one manual first run to finish setup."
	Write-Host "Open Podman Desktop, complete onboarding, and create the default Podman machine before using the CLI."
	Write-Host ""
}

# Reload environment so newly installed tools like Volta are available.
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

# Install Node toolchain
volta install node
volta install pnpm

if ($IsWindowsContainer) {
	Write-Host "Skipping Fira Code Nerd Font install in Windows container mode."
} else {
	# Install Fira Code Nerd Font
	Write-Host "Installing Fira Code Nerd Font..."
	$tempDir = Join-Path $env:TEMP "nerd-fonts"
	if (Test-Path $tempDir) { Remove-Item -Recurse -Force $tempDir }
	git clone --depth=1 https://github.com/ryanoasis/nerd-fonts/ $tempDir
	Push-Location $tempDir
	& .\install.ps1 FiraCode
	Pop-Location
	Remove-Item -Recurse -Force $tempDir
}

# Install npm globals
npm install -g @anthropic-ai/claude-code
