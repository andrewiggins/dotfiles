# Windows package install via winget + cargo + volta.
# Honors $env:SKIP_PACKAGES = "1" for CI dry-runs.

$ErrorActionPreference = "Stop"

if ($env:SKIP_PACKAGES -eq "1") {
	Write-Host "SKIP_PACKAGES=1, skipping windows package install"
	exit 0
}

Write-Host "Installing packages via winget..."

winget install -e --id GitHub.cli
winget install -e --id BurntSushi.ripgrep.MSVC
winget install -e --id jqlang.jq
winget install -e --id Microsoft.VisualStudioCode
winget install -e --id Microsoft.PowerShell
winget install -e --id vim.vim
winget install -e --id 7zip.7zip
winget install -e --id Python.Python
winget install -e --id Volta.Volta
winget install --id 9P7KNL5RWT25 --source msstore # Sysinternals Suite
winget install -e --id Rustlang.Rustup
winget install -e --id Starship.Starship

# Reload environment so cargo/volta are available
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

# Install Rust packages
cargo install bat
cargo install git-delta

# Install Node toolchain
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

# Install npm globals
npm install -g @anthropic-ai/claude-code
