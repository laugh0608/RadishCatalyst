[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$requiredTextByFile = @{
    "docs/features/demo-wind-corridor-transition-playability-v1.md" = @(
        "Demo Wind Corridor Transition Playability V1",
        "风蚀管廊过渡可玩路径",
        "碎晶沟谷 -> 风蚀管廊 -> 锁相框架入口",
        "不新增第 13 区域，不新增资源、配方、设备、敌人、任务链、存档字段或 UI 面板"
    )
    "client/scripts/systems/demo_wind_corridor_transition_playability_formatter.gd" = @(
        "class_name DemoWindCorridorTransitionPlayabilityFormatter",
        "format_hud_summary",
        "format_map_route_hint",
        "format_object_route_line",
        "format_static_object_route_line",
        "format_result_followup_line",
        "风蚀管廊过渡路径",
        "锁相入口承接"
    )
    "client/scenes/maps/VerticalSliceMap.tscn" = @(
        "WindCorridorTransitionPlayabilityLayer",
        "WindEntryLane",
        "WindTensionBoundary",
        "WindWeftResourcePocket",
        "WindLoomFacilityPocket",
        "FrameEntryBoundary"
    )
    "client/scripts/ui/hud_map_presenter.gd" = @(
        "DemoWindCorridorTransitionPlayabilityFormatter.format_map_route_hint"
    )
    "client/scripts/ui/hud_status_presenter.gd" = @(
        "DemoWindCorridorTransitionPlayabilityFormatter.format_hud_summary"
    )
    "client/scripts/ui/interaction_prompt_formatter.gd" = @(
        "DemoWindCorridorTransitionPlayabilityFormatter.format_object_route_line",
        "DemoWindCorridorTransitionPlayabilityFormatter.format_static_object_route_line"
    )
    "client/scripts/systems/functional_scene_gameplay_formatter.gd" = @(
        "DemoWindCorridorTransitionPlayabilityFormatter.format_result_followup_line"
    )
    "client/scripts/checks/demo_wind_corridor_transition_playability_check.gd" = @(
        "Demo wind corridor transition playability checks passed.",
        "_check_scene_layer_marks_wind_corridor_transition",
        "_check_hud_and_map_wind_readouts",
        "_check_object_prompts_show_wind_transition",
        "_check_runtime_results_keep_wind_followup"
    )
    "scripts/check-client.sh" = @(
        "check-client-demo-wind-corridor-transition-playability.py",
        "demo_wind_corridor_transition_playability_check.gd"
    )
    "scripts/check-client.ps1" = @(
        "check-client-demo-wind-corridor-transition-playability.ps1"
    )
    "scripts/check-client-flow.ps1" = @(
        "demo_wind_corridor_transition_playability_check.gd"
    )
}

$lineBudgetByFile = @{
    "client/scripts/map/vertical_slice_map.gd" = 1500
    "client/scripts/ui/interaction_prompt_formatter.gd" = 1500
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
            $errors.Add("${relativePath}: missing wind corridor transition playability text '${requiredText}'")
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

Write-Host "Client demo wind corridor transition playability checks passed."
