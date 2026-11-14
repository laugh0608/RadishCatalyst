[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][ValidateSet('prepare','preflight','feasibility','fault-prepare-v4','fault-preflight-v2','fault-preflight-v3','fault-preflight-v4','fault-fd-cycle','fault-fd-diagnostic','fault-prepare-v5','fault-v5-cycle','fault-v5-recheck','fault-preflight-v5')][string]$Mode,
    [Parameter(Mandatory=$true)][string]$Batch,
    [string]$ParentBatch = '',
    [string]$GodotExe = '',
    [string]$PreflightParentBatch = '',
    [string]$CycleParentBatch = '',
    [string]$ReferenceBatch = '',
    [string]$RecheckParentBatch = ''
)
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path $PSScriptRoot -Parent
. (Join-Path $repoRoot 'scripts/Resolve-GodotExe.ps1')
$godotBin = Resolve-GodotExe -GodotExe $GodotExe
$pythonExe = if ($env:PYTHON) { $env:PYTHON } else { 'python' }
$runnerArgs = @((Join-Path $PSScriptRoot 'check-factory-d2-comparison.py'),$Mode,$Batch,'--godot',$godotBin)
if ($ParentBatch) { $runnerArgs += @('--parent',$ParentBatch) }
if ($PreflightParentBatch) { $runnerArgs += @('--preflight-parent',$PreflightParentBatch) }
if ($CycleParentBatch) { $runnerArgs += @('--cycle-parent',$CycleParentBatch) }
if ($RecheckParentBatch) { $runnerArgs += @('--recheck-parent',$RecheckParentBatch) }
if ($ReferenceBatch) { $runnerArgs += @('--reference',$ReferenceBatch) }
& $pythonExe @runnerArgs
exit $LASTEXITCODE
