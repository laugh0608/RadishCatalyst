[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [string]$ReviewRoot = "",
    [string]$GodotExe = ""
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "Resolve-GodotExe.ps1")
$GodotExe = Resolve-GodotExe -GodotExe $GodotExe
if ([string]::IsNullOrWhiteSpace($ReviewRoot)) {
    $ReviewRoot = Join-Path $RepoRoot "tools/runtime-intake/review-worlds/current"
}

if (-not (Test-Path -LiteralPath $GodotExe -PathType Leaf)) {
    Write-Error "Godot executable not found: ${GodotExe}"
    exit 1
}
if (
    -not (Test-Path -LiteralPath (Join-Path $ReviewRoot "worlds") -PathType Container) -and
    -not (Test-Path -LiteralPath (Join-Path $ReviewRoot "trash") -PathType Container)
) {
    Write-Error "Review root does not exist or has not been generated: ${ReviewRoot}"
    exit 1
}

$clientRoot = Join-Path $RepoRoot "client"
$launcher = Join-Path $clientRoot "scripts/tools/slice_save_review_launcher.gd"
& $GodotExe `
    --path $clientRoot `
    --script $launcher `
    -- `
    "--review-root=${ReviewRoot}"
exit $LASTEXITCODE
