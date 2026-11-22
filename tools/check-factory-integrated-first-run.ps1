[CmdletBinding()]
param(
    [ValidateSet('state','window','live')][string]$Mode = 'state',
    [string]$Batch = '',
    [string]$GodotExe = ''
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path $PSScriptRoot -Parent
. (Join-Path $repoRoot 'scripts/Resolve-GodotExe.ps1')
$godotBin = Resolve-GodotExe -GodotExe $GodotExe
$pythonExe = if ($env:PYTHON) { $env:PYTHON } else { 'python' }
$runnerArgs = @((Join-Path $PSScriptRoot 'check-factory-integrated-first-run.py'), '--godot', $godotBin, $Mode.ToLowerInvariant())
if ($Batch) { $runnerArgs += $Batch }
& $pythonExe @runnerArgs
exit $LASTEXITCODE
