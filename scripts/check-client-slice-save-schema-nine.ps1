[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [string]$GodotExe = ""
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "Resolve-GodotExe.ps1")
$GodotExe = Resolve-GodotExe -GodotExe $GodotExe

if (-not (Test-Path -LiteralPath $GodotExe -PathType Leaf)) {
    Write-Error "Godot executable not found: ${GodotExe}"
    exit 1
}

$clientRoot = Join-Path $RepoRoot "client"
$checkScript = Join-Path $clientRoot "scripts/checks/slice_save_schema_nine_check.gd"
if (-not (Test-Path -LiteralPath $checkScript -PathType Leaf)) {
    Write-Error "Slice save schema 9 check script not found: ${checkScript}"
    exit 1
}

$runId = "slice-save-schema-nine-{0}-{1}" -f $PID, [DateTime]::UtcNow.ToString("yyyyMMddHHmmssfff")
$godotHome = Join-Path (Join-Path $RepoRoot ".godot-check-runs") $runId
$godotConfigHome = Join-Path $godotHome "config"
$godotDataHome = Join-Path $godotHome "data"
$godotCacheHome = Join-Path $godotHome "cache"
$godotAppData = Join-Path $godotDataHome "Roaming"
$godotLocalAppData = Join-Path $godotCacheHome "Local"
New-Item -ItemType Directory -Force -Path $godotConfigHome, $godotDataHome, $godotCacheHome | Out-Null
New-Item -ItemType Directory -Force -Path $godotAppData, $godotLocalAppData | Out-Null

Push-Location $clientRoot
try {
    $previousXdgConfigHome = $env:XDG_CONFIG_HOME
    $previousXdgDataHome = $env:XDG_DATA_HOME
    $previousXdgCacheHome = $env:XDG_CACHE_HOME
    $previousAppData = $env:APPDATA
    $previousLocalAppData = $env:LOCALAPPDATA

    $env:XDG_CONFIG_HOME = $godotConfigHome
    $env:XDG_DATA_HOME = $godotDataHome
    $env:XDG_CACHE_HOME = $godotCacheHome
    $env:APPDATA = $godotAppData
    $env:LOCALAPPDATA = $godotLocalAppData

    $importOutput = & $GodotExe --headless --path $clientRoot --import --quit --no-header 2>&1
    if ($LASTEXITCODE -ne 0) {
        $importOutput | ForEach-Object { [Console]::Error.WriteLine($_) }
        Write-Error "Godot import before slice save schema 9 check failed with exit code ${LASTEXITCODE}."
        exit $LASTEXITCODE
    }

    $checkOutput = & $GodotExe --headless --path $clientRoot --script $checkScript --no-header 2>&1
    if ($LASTEXITCODE -ne 0) {
        $checkOutput | ForEach-Object { [Console]::Error.WriteLine($_) }
        Write-Error "Slice save schema 9 check failed with exit code ${LASTEXITCODE}."
        exit $LASTEXITCODE
    }

    $unexpectedErrors = @(
        $importOutput + $checkOutput |
            Where-Object { $_ -match "^ERROR:" -and $_ -notmatch "Failed to read the root certificate store" }
    )
    if ($unexpectedErrors.Count -gt 0) {
        $unexpectedErrors | ForEach-Object { [Console]::Error.WriteLine($_) }
        Write-Error "Slice save schema 9 check reported unexpected errors."
        exit 1
    }
}
finally {
    $env:XDG_CONFIG_HOME = $previousXdgConfigHome
    $env:XDG_DATA_HOME = $previousXdgDataHome
    $env:XDG_CACHE_HOME = $previousXdgCacheHome
    $env:APPDATA = $previousAppData
    $env:LOCALAPPDATA = $previousLocalAppData
    Pop-Location
}

Write-Host "Slice save schema 9 checks passed."
