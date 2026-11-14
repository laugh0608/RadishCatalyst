param(
    [Parameter(Mandatory = $true)][string]$Mode,
    [Parameter(Mandatory = $true)][string]$Batch,
    [string]$Source
)
$ErrorActionPreference = 'Stop'
$runner = Join-Path $PSScriptRoot 'check-factory-expansion.py'
$argsList = @($runner, $Mode, $Batch)
if ($Source) { $argsList += $Source }
python @argsList
exit $LASTEXITCODE
