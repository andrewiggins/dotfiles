# Idempotent Claude Code configuration. Ensures ~/.claude/settings.json has the
# statusLine command pointing to the dotfiles-managed script. Re-running is safe
# — existing settings are preserved.

$ErrorActionPreference = "Stop"

Write-Host "Configuring Claude Code..."

$settingsFile = Join-Path $HOME ".claude\settings.json"
$statusLineCmd = "bash ~/.claude/statusline-command.sh"

$claudeDir = Join-Path $HOME ".claude"
if (-not (Test-Path $claudeDir)) {
    New-Item -ItemType Directory -Force -Path $claudeDir | Out-Null
}

if (-not (Test-Path $settingsFile)) {
    # Create a minimal settings file with just the statusLine
    $settings = [ordered]@{
        statusLine = [ordered]@{
            type    = "command"
            command = $statusLineCmd
        }
    }
    $settings | ConvertTo-Json -Depth 5 | Set-Content -Path $settingsFile -Encoding utf8
    Write-Host "    created $settingsFile with statusLine"
} else {
    $existing = Get-Content -Path $settingsFile -Raw | ConvertFrom-Json
    $currentCmd = $null
    if ($existing.PSObject.Properties['statusLine'] -and $existing.statusLine.PSObject.Properties['command']) {
        $currentCmd = $existing.statusLine.command
    }
    if ($currentCmd -eq $statusLineCmd) {
        Write-Host "    statusLine already configured"
    } else {
        $existing | Add-Member -NotePropertyName 'statusLine' -NotePropertyValue ([ordered]@{
            type    = "command"
            command = $statusLineCmd
        }) -Force
        $existing | ConvertTo-Json -Depth 5 | Set-Content -Path $settingsFile -Encoding utf8
        Write-Host "    updated $settingsFile with statusLine"
    }
}

Write-Host "Claude Code configured."
