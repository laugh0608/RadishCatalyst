[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$Mode,
    [Parameter(Mandatory=$true)][string]$Batch,
    [string]$Source = "",
    [string]$GodotExe = "",
    [string]$Fault = ""
)
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "../scripts/Resolve-GodotExe.ps1")
$resolvedGodot = Resolve-GodotExe -GodotExe $GodotExe
$previousGodot = $env:GODOT_EXE
try {
    $env:GODOT_EXE = $resolvedGodot
    $pythonExe = if ($env:PYTHON) { $env:PYTHON } else { "python" }
    $arguments = @((Join-Path $PSScriptRoot "check-factory-combination.py"), $Mode, $Batch)
    if ($Source) { $arguments += $Source }
    if ($Fault) { $arguments += @("--fault", $Fault) }
    & $pythonExe @arguments
    if ($LASTEXITCODE -ne 0) { throw "C $Mode check failed with exit code $LASTEXITCODE." }
}
finally { $env:GODOT_EXE = $previousGodot }
