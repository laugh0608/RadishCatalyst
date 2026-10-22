$ErrorActionPreference = 'Stop'
$runner = Join-Path $PSScriptRoot 'check-factory-engineering.py'
& python $runner @args
exit $LASTEXITCODE
