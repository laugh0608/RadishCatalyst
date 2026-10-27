param(
    [Parameter(Mandatory = $true)][string]$Mode,
    [Parameter(Mandatory = $true)][string]$Batch,
    [string]$Source,
    [switch]$LegacySource
)
$ErrorActionPreference = 'Stop'
$runner = Join-Path $PSScriptRoot 'check-factory-expansion.py'
$argsList = @($runner, '--energy', '--standby', $Mode, $Batch)
if ($Source) { $argsList += $Source }
if ($LegacySource) { $argsList += '--legacy-source' }
python @argsList
exit $LASTEXITCODE
