[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$python = "python"
if ($env:PYTHON) {
    $python = $env:PYTHON
}

& $python (Join-Path $PSScriptRoot "check-client-demo-device-panel-operation-readability.py") $RepoRoot
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
