# Run in Windows PowerShell or pwsh, both normally and as Administrator.
# Uses dry-run only: no symlinks, downloads, or machine configuration changes.
$ErrorActionPreference = "Stop"
$installer = Join-Path $PSScriptRoot "..\install.ps1"
$previousDryRun = $env:DRY_RUN
$identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
try {
	$principal = [System.Security.Principal.WindowsPrincipal]::new($identity)
	$elevated = $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
	$env:DRY_RUN = "1"
	$failure = $null
	try {
		& $installer
	} catch {
		$failure = $_
	}
	if ($elevated) {
		if (-not $failure -or $failure.Exception.Message -notlike "*Do not run the dotfiles installer as Administrator*") {
			throw "FAIL: elevated installer did not produce the expected rejection. Error: $failure"
		}
		Write-Host "ok: Administrator dry-run rejected"
	} else {
		if ($failure) { throw $failure }
		Write-Host "ok: non-elevated dry-run allowed"
	}
} finally {
	$env:DRY_RUN = $previousDryRun
	$identity.Dispose()
}
