[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [string]$GodotExe = ""
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "Resolve-GodotExe.ps1")
$GodotExe = Resolve-GodotExe -GodotExe $GodotExe
$clientRoot = Join-Path $RepoRoot "client"
$recordRoot = Join-Path $RepoRoot "tools/runtime-intake/check-runs/factory-foundation-v1"
New-Item -ItemType Directory -Force -Path $recordRoot | Out-Null

foreach ($name in @("state", "save")) {
    $scriptPath = Join-Path $clientRoot "scripts/checks/factory_${name}_check.gd"
    $logPath = Join-Path $recordRoot "powershell-${name}.log"
    & $GodotExe --headless --path $clientRoot --script $scriptPath --no-header --log-file $logPath
    if ($LASTEXITCODE -ne 0) {
        throw "Factory $name check exited with $LASTEXITCODE."
    }
    $errors = @(Get-Content -LiteralPath $logPath | Where-Object {
        $_ -match "^(SCRIPT ERROR|ERROR:)" -and $_ -notmatch 'Condition "ret != noErr"'
    })
    if ($errors.Count -gt 0) {
        throw ("Factory $name check reported errors: " + ($errors -join [Environment]::NewLine))
    }
}
Write-Host "Factory state and save checks passed."
