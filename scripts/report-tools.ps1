# Optional PATH inventory. Does not execute discovered tools or modify anything.
# Usage: ./scripts/report-tools.ps1 [-Tools node,pnpm,pi]
param(
	[string[]]$Tools = @(
		"git", "gh", "bash", "vim", "jq", "rg", "bat", "delta", "starship",
		"podman", "curl", "volta", "node", "npm", "pnpm", "cargo", "rustc",
		"python", "ffmpeg", "magick", "claude", "codex", "pi", "winget", "pwsh"
	)
)

$ErrorActionPreference = "Stop"
Write-Output "Executable paths on the current PATH (not package provenance or versions):"
foreach ($tool in $Tools) {
	# Exclude aliases/functions; include scripts such as npm.ps1 on Windows.
	$command = Get-Command -Name $tool -CommandType Application,ExternalScript -ErrorAction SilentlyContinue |
		Select-Object -First 1
	if ($command) {
		Write-Output "$tool`t$($command.Source)"
	} else {
		Write-Output "$tool`tnot found"
	}
}
