[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$Mode,
    [Parameter(Mandatory=$true)][string]$Batch,
    [Parameter(Mandatory=$true)][string]$Source,
    [string]$GodotExe = "",
    [ValidateSet("", "before", "sampling", "close")][string]$InterruptAt = ""
)
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "../scripts/Resolve-GodotExe.ps1")
$resolvedGodot = Resolve-GodotExe -GodotExe $GodotExe
$previousGodot = $env:GODOT_EXE
try {
    $env:GODOT_EXE = $resolvedGodot
    $pythonExe = if ($env:PYTHON) { $env:PYTHON } else { "python" }
    $arguments = @((Join-Path $PSScriptRoot "check-factory-statistics-performance.py"), $Mode, $Batch, $Source)
    if ($InterruptAt) { $arguments += @("--interrupt-at", $InterruptAt) }
    & $pythonExe @arguments
    if ($LASTEXITCODE -ne 0) { throw "Statistics $Mode check failed with exit code $LASTEXITCODE." }
}
finally { $env:GODOT_EXE = $previousGodot }
