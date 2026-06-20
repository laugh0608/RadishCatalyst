[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$requiredTextByFile = @{
    "client/scripts/map/demo_pollution_boundary_visual_layer.gd" = @(
        "class_name DemoPollutionBoundaryVisualLayer",
        "refresh_pollution_chain_state",
        "boundary.filter_build_site",
        "boundary.pressure_gate",
        "residue.entry_patch",
        "flow.filter_to_base_return",
        "pollution_chain.boundary_residue_queue",
        "pollution_chain.boundary_core_prep_route",
        "_deemphasize_legacy_pollution_blocks",
        "map_object.pollution_residue_patch"
    )
    "client/scenes/maps/VerticalSliceMap.tscn" = @(
        "DemoPollutionBoundaryVisualLayer",
        "demo_pollution_boundary_visual_layer.gd"
    )
    "client/scripts/checks/demo_pollution_boundary_visual_check.gd" = @(
        "Demo pollution boundary visual checks passed.",
        "_check_pollution_boundary_layer_exists_and_registers_visuals",
        "_check_pollution_boundary_chain_state_visuals",
        "_check_pollution_boundary_visual_priority_replaces_old_blocks",
        "_check_pollution_boundary_runtime_anchors_are_tagged"
    )
    "docs/devlogs/2026-W25.md" = @(
        "污染处理边界视觉第一轮",
        "DemoPollutionBoundaryVisualLayer"
    )
    "scripts/check-client.sh" = @(
        "check-client-demo-pollution-boundary-visual.py",
        "demo_pollution_boundary_visual_check.gd"
    )
    "scripts/check-client.ps1" = @(
        "check-client-demo-pollution-boundary-visual.ps1"
    )
    "scripts/check-client-flow.ps1" = @(
        "demo_pollution_boundary_visual_check.gd"
    )
}

$errors = [System.Collections.Generic.List[string]]::new()

foreach ($relativePath in $requiredTextByFile.Keys) {
    $path = Join-Path $RepoRoot $relativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        $errors.Add("${relativePath}: missing file")
        continue
    }

    $content = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    foreach ($requiredText in $requiredTextByFile[$relativePath]) {
        if (-not $content.Contains($requiredText)) {
            $errors.Add("${relativePath}: missing pollution boundary visual text '${requiredText}'")
        }
    }
}

if ($errors.Count -gt 0) {
    foreach ($errorMessage in $errors) {
        Write-Error $errorMessage
    }
    exit 1
}

Write-Host "Client demo pollution boundary visual checks passed."
