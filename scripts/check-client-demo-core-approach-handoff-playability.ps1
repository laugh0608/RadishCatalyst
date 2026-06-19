[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$requiredTextByFile = @{
    "docs/features/demo-core-approach-handoff-playability-v1.md" = @(
        "Demo Core Approach Handoff Playability V1",
        "核心稳定站入口承接可玩路径",
        "锁相框架 -> 锚定桥 -> 核心稳定站入口",
        "不新增第 13 区域，不新增资源、配方、设备、敌人、任务链、存档字段或 UI 面板"
    )
    "client/scripts/systems/demo_core_approach_handoff_formatter.gd" = @(
        "class_name DemoCoreApproachHandoffFormatter",
        "format_hud_summary",
        "format_map_route_hint",
        "format_object_handoff_line",
        "format_static_object_handoff_line",
        "format_result_followup_line",
        "核心入口承接",
        "锚定桥 -> 核心稳定站入口"
    )
    "client/scenes/maps/VerticalSliceMap.tscn" = @(
        "CoreApproachHandoffLayer",
        "FrameExitHandoff",
        "TetherBridgeHandoff",
        "AnchorFieldHandoff",
        "CoreEntryThreshold",
        "CoreDeviceHandoff"
    )
    "client/scripts/ui/hud_map_presenter.gd" = @(
        "DemoCoreApproachHandoffFormatter.format_map_route_hint"
    )
    "client/scripts/ui/hud_status_presenter.gd" = @(
        "DemoCoreApproachHandoffFormatter.format_hud_summary"
    )
    "client/scripts/ui/interaction_prompt_formatter.gd" = @(
        "DemoCoreApproachHandoffFormatter.format_object_handoff_line",
        "DemoCoreApproachHandoffFormatter.format_static_object_handoff_line"
    )
    "client/scripts/systems/functional_scene_gameplay_formatter.gd" = @(
        "DemoCoreApproachHandoffFormatter.format_result_followup_line"
    )
    "client/scripts/map/phase_well_frontier_runtime.gd" = @(
        "DemoCoreApproachHandoffFormatter.format_result_followup_line",
        "_with_core_approach_followup"
    )
    "client/scripts/checks/demo_core_approach_handoff_playability_check.gd" = @(
        "Demo core approach handoff playability checks passed.",
        "_check_scene_layer_marks_core_approach_handoff",
        "_check_hud_and_map_core_approach_readouts",
        "_check_object_prompts_show_core_approach_handoff",
        "_check_runtime_results_keep_core_approach_followup"
    )
    "scripts/check-client.sh" = @(
        "check-client-demo-core-approach-handoff-playability.py",
        "demo_core_approach_handoff_playability_check.gd"
    )
    "scripts/check-client.ps1" = @(
        "check-client-demo-core-approach-handoff-playability.ps1"
    )
    "scripts/check-client-flow.ps1" = @(
        "demo_core_approach_handoff_playability_check.gd"
    )
}

$lineBudgetByFile = @{
    "client/scripts/map/vertical_slice_map.gd" = 1500
    "client/scripts/ui/interaction_prompt_formatter.gd" = 1500
    "client/scripts/map/phase_well_frontier_runtime.gd" = 1500
    "client/scripts/systems/gather_system.gd" = 1500
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
            $errors.Add("${relativePath}: missing core approach handoff text '${requiredText}'")
        }
    }
}

foreach ($relativePath in $lineBudgetByFile.Keys) {
    $path = Join-Path $RepoRoot $relativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        $errors.Add("${relativePath}: missing file")
        continue
    }

    $lineCount = ((Get-Content -LiteralPath $path -Encoding UTF8) | Measure-Object -Line).Lines
    $maxLines = $lineBudgetByFile[$relativePath]
    if ($lineCount -ge $maxLines) {
        $errors.Add("${relativePath}: expected fewer than ${maxLines} lines, got ${lineCount}")
    }
}

if ($errors.Count -gt 0) {
    $errors | ForEach-Object { [Console]::Error.WriteLine($_) }
    exit 1
}

Write-Host "Client demo core approach handoff playability checks passed."
