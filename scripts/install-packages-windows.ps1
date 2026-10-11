# Windows package install via winget + Podman Desktop + Volta + Rustup.
# Honors $env:SKIP_PACKAGES = "1" for CI dry-runs.

$ErrorActionPreference = "Stop"

if ($env:SKIP_PACKAGES -eq "1") {
	Write-Host "SKIP_PACKAGES=1, skipping windows package install"
	exit 0
}

Write-Host "Installing packages via winget..."

# winget install otherwise attempts to upgrade existing packages.
winget install --no-upgrade -e --id GitHub.cli
winget install --no-upgrade -e --id BurntSushi.ripgrep.MSVC
winget install --no-upgrade -e --id dandavison.delta
winget install --no-upgrade -e --id Gyan.FFmpeg
winget install --no-upgrade -e --id ImageMagick.ImageMagick
winget install --no-upgrade -e --id jqlang.jq
winget install --no-upgrade -e --id Microsoft.VisualStudioCode
winget install --no-upgrade -e --id Microsoft.PowerShell
winget install --no-upgrade -e --id RedHat.Podman-Desktop
winget install --no-upgrade -e --id sharkdp.bat
winget install --no-upgrade -e --id vim.vim
winget install --no-upgrade -e --id 7zip.7zip
winget install --no-upgrade -e --id Python.Python
winget install --no-upgrade -e --id Volta.Volta
winget install --no-upgrade --id 9P7KNL5RWT25 --source msstore # Sysinternals Suite
winget install --no-upgrade -e --id Rustlang.Rustup
winget install --no-upgrade -e --id Starship.Starship

Write-Host ""
Write-Host "Podman Desktop needs one manual first run to finish setup."
Write-Host "Open Podman Desktop, complete onboarding, and create the default Podman machine before using the CLI."
Write-Host ""

# Reload environment so newly installed tools like Volta are available.
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

# Always configure Volta-managed tools, regardless of other tools on PATH.
volta install node
volta install pnpm

# Install Fira Code Nerd Font
Write-Host "Installing Fira Code Nerd Font..."
$tempDir = Join-Path $env:TEMP "nerd-fonts"
if (Test-Path $tempDir) { Remove-Item -Recurse -Force $tempDir }
git clone --depth=1 https://github.com/ryanoasis/nerd-fonts/ $tempDir
Push-Location $tempDir
& .\install.ps1 FiraCode
Pop-Location
Remove-Item -Recurse -Force $tempDir
