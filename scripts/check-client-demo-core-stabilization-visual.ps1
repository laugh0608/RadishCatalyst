[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$requiredTextByFile = @{
    "client/scripts/map/demo_core_stabilization_visual_layer.gd" = @(
        "class_name DemoCoreStabilizationVisualLayer",
        "demo_default_path_asset_language_art_pass.gd",
        "station.guard_pressure_field",
        "station.writeback_device",
        "station.retest_readout",
        "flow.core_return_to_base",
        "PollutionToCoreHandoffArtPass",
        "operation_relation.core.guard_cache_to_write_device",
        "operation_relation.core.logistics_return",
        "_deemphasize_legacy_core_blocks",
        "core_station.feedback.stability_window.open",
        "core_station.flow.core_write_to_stability_window.ready",
        "map_object.demo_stabilization_core"
    )
    "client/scripts/map/demo_default_path_asset_language_art_pass.gd" = @(
        "class_name DemoDefaultPathAssetLanguageArtPass",
        "station.assetized_write_device_machine",
        "station.assetized_core_pipe_bundle",
        "draw_core_language"
    )
    "client/scenes/maps/VerticalSliceMap.tscn" = @(
        "DemoCoreStabilizationVisualLayer",
        "demo_core_stabilization_visual_layer.gd"
    )
    "client/scripts/map/demo_pollution_to_core_handoff_art_pass.gd" = @(
        "class_name DemoPollutionToCoreHandoffArtPass",
        "get_core_shape_ids",
        "core_handoff.write_energy",
        "core_handoff.demo_hook"
    )
    "client/scripts/checks/demo_core_stabilization_visual_check.gd" = @(
        "Demo core stabilization visual checks passed.",
        "_check_core_visual_layer_exists_and_registers_station_shapes",
        "_check_core_visual_operation_relation_shapes",
        "core relation links guard cache to write device",
        "_check_core_visual_layer_replaces_old_terminal_blocks",
        "_check_core_visual_runtime_anchors_are_tagged",
        "core visual marks opened stability window",
        "core visual layer uses an assetized write device body",
        "core handoff marks demo hook after write"
    )
    "docs/devlogs/2026-W25.md" = @(
        "核心稳定站终点视觉第一轮",
        "DemoCoreStabilizationVisualLayer"
    )
    "scripts/check-client.sh" = @(
        "check-client-demo-core-stabilization-visual.py",
        "demo_core_stabilization_visual_check.gd"
    )
    "scripts/check-client.ps1" = @(
        "check-client-demo-core-stabilization-visual.ps1"
    )
    "scripts/check-client-flow.ps1" = @(
        "demo_core_stabilization_visual_check.gd"
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
            $errors.Add("${relativePath}: missing core stabilization visual text '${requiredText}'")
        }
    }
}

if ($errors.Count -gt 0) {
    foreach ($errorMessage in $errors) {
        Write-Error $errorMessage
    }
    exit 1
}

Write-Host "Client demo core stabilization visual checks passed."
