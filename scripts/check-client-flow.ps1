[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [string]$GodotExe = "D:\Program Files\Godot\Godot_v4.6.2-stable_win64_console.exe"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $GodotExe -PathType Leaf)) {
    Write-Error "Godot executable not found: ${GodotExe}"
    exit 1
}

$clientRoot = Join-Path $RepoRoot "client"
if (-not (Test-Path -LiteralPath (Join-Path $clientRoot "project.godot") -PathType Leaf)) {
    Write-Error "Godot project not found: ${clientRoot}"
    exit 1
}

$checkScript = Join-Path $clientRoot "scripts/checks/vertical_slice_flow_check.gd"
if (-not (Test-Path -LiteralPath $checkScript -PathType Leaf)) {
    Write-Error "Vertical slice flow check script not found: ${checkScript}"
    exit 1
}

$godotHome = Join-Path $RepoRoot ".godot-check-home/vertical-slice-flow"
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
        Write-Error "Godot import before vertical slice flow check failed with exit code ${LASTEXITCODE}."
        exit $LASTEXITCODE
    }

    $checkOutput = & $GodotExe --headless --path $clientRoot --script $checkScript --no-header 2>&1
    if ($LASTEXITCODE -ne 0) {
        $checkOutput | ForEach-Object { [Console]::Error.WriteLine($_) }
        Write-Error "Vertical slice flow check failed with exit code ${LASTEXITCODE}."
        exit $LASTEXITCODE
    }

    $unexpectedErrors = @(
        $importOutput + $checkOutput |
            Where-Object { $_ -match "^ERROR:" -and $_ -notmatch "Failed to read the root certificate store" }
    )
    if ($unexpectedErrors.Count -gt 0) {
        $unexpectedErrors | ForEach-Object { [Console]::Error.WriteLine($_) }
        Write-Error "Vertical slice flow check reported unexpected errors."
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

Write-Host "Vertical slice flow checks passed."
