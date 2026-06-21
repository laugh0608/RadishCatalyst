[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$requiredTextByFile = @{
    "docs/features/demo-resource-chain-state-v1.md" = @(
        "Demo Resource Chain State V1",
        "资源 / 生产链",
        "状态序列化"
    )
    "client/scripts/systems/demo_resource_chain_state_formatter.gd" = @(
        "class_name DemoResourceChainStateFormatter",
        "get_core_resource_ids",
        "format_hud_summary",
        "format_device_status_line",
        "format_result_feedback_line",
        "核心稳压缓冲包"
    )
    "client/scripts/ui/hud_status_presenter.gd" = @(
        "DemoResourceChainStateFormatter.format_hud_summary"
    )
    "client/scripts/ui/hud_device_panel_presenter.gd" = @(
        "DemoResourceChainStateFormatter.format_device_status_line"
    )
    "client/scripts/systems/processing_system.gd" = @(
        "resource_chain",
        "show_resource_chain",
        "DemoResourceChainStateFormatter.format_result_feedback_line"
    )
    "client/scripts/map/demo_crystal_resource_visual_layer.gd" = @(
        "class_name DemoCrystalResourceVisualLayer",
        "crystal.main_vein",
        "crystal.rich_vein",
        "get_terrain_material_shape_count",
        "terrain.crystal.harvest_face",
        "terrain.crystal.scrap_recovery_yard",
        "terrain.crystal.base_loading_mouth",
        "_deemphasize_legacy_crystal_blocks",
        "map_object.rich_crystal_vein"
    )
    "client/scripts/map/demo_industrial_base_visual_layer.gd" = @(
        "class_name DemoIndustrialBaseVisualLayer",
        "refresh_pollution_chain_state",
        "pollution_chain.residue_input_slot",
        "pollution_chain.filter_process_window",
        "pollution_chain.vial_output_slot",
        "pollution_chain.slurry_byproduct_slot",
        "pollution_chain.core_prep_route"
    )
    "client/scripts/map/demo_first_industrial_path_visual_layer.gd" = @(
        "class_name DemoFirstIndustrialPathVisualLayer",
        "first_path.primary_player_lane",
        "first_path.base_receiving_bay",
        "first_path.reactor_work_window",
        "first_path.outfitting_handoff",
        "_quiet_global_planning_layers"
    )
    "client/scenes/maps/VerticalSliceMap.tscn" = @(
        "DemoCrystalResourceVisualLayer",
        "demo_crystal_resource_visual_layer.gd",
        "DemoFirstIndustrialPathVisualLayer",
        "demo_first_industrial_path_visual_layer.gd"
    )
    "client/scripts/ui/hud_log_presenter.gd" = @(
        '"资源链"',
        "resource_chain"
    )
    "client/scripts/checks/demo_resource_chain_state_check.gd" = @(
        "Demo resource chain state checks passed.",
        "_check_core_resource_scope",
        "_check_hud_resource_chain_state",
        "_check_device_panel_resource_chain_state",
        "_check_processing_result_resource_chain",
        "_check_crystal_resource_visual_layer",
        "first industrial path layer registers the playable path slice",
        "crystal visual layer registers mining terrain materials",
        "terrain.crystal.return_cart_lane",
        "_check_pollution_chain_hud_and_visual_state",
        "pollution_chain.core_prep_route.ready",
        "_check_resource_chain_state_roundtrip"
    )
    "scripts/check-client.sh" = @(
        "check-client-demo-resource-chain-state.py",
        "demo_resource_chain_state_check.gd"
    )
    "scripts/check-client-flow.ps1" = @(
        "demo_resource_chain_state_check.gd"
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
            $errors.Add("${relativePath}: missing demo resource chain state text '${requiredText}'")
        }
    }
}

if ($errors.Count -gt 0) {
    foreach ($errorMessage in $errors) {
        Write-Error $errorMessage
    }
    exit 1
}

Write-Host "Client demo resource chain state checks passed."
