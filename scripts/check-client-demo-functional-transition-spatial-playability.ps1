[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$requiredTextByFile = @{
    "docs/features/demo-functional-transition-spatial-playability-v1.md" = @(
        "Demo Functional Transition Spatial Playability V1",
        "功能 / 过渡场景可达空间",
        "封锁遗迹到裂相脊",
        "不新增资源、配方、任务链、敌人类型、完整背包、完整装备栏或自动化物流"
    )
    "client/scripts/systems/demo_functional_transition_spatial_playability_formatter.gd" = @(
        "class_name DemoFunctionalTransitionSpatialPlayabilityFormatter",
        "format_hud_summary",
        "format_map_route_hint",
        "format_static_object_spatial_line",
        "format_result_followup_line",
        "封锁遗迹可达空间",
        "裂相脊可达空间"
    )
    "client/scenes/maps/VerticalSliceMap.tscn" = @(
        "FunctionalTransitionSpatialPlayabilityLayer",
        "RuinEntranceLane",
        "RuinBarrierBoundary",
        "RuinHazardReturnPocket",
        "RidgeEntranceLane",
        "RidgeLatchBoundary",
        "RidgeReturnAnchorPocket"
    )
    "client/scripts/ui/hud_map_presenter.gd" = @(
        "DemoFunctionalTransitionSpatialPlayabilityFormatter.format_map_route_hint"
    )
    "client/scripts/ui/hud_status_presenter.gd" = @(
        "DemoFunctionalTransitionSpatialPlayabilityFormatter.format_hud_summary"
    )
    "client/scripts/systems/functional_transition_route_support_formatter.gd" = @(
        "DemoFunctionalTransitionSpatialPlayabilityFormatter.format_static_object_spatial_line"
    )
    "client/scripts/systems/functional_scene_gameplay_formatter.gd" = @(
        "DemoFunctionalTransitionSpatialPlayabilityFormatter.format_result_followup_line"
    )
    "client/scripts/checks/demo_functional_transition_spatial_playability_check.gd" = @(
        "Demo functional transition spatial playability checks passed.",
        "_check_scene_layer_marks_representative_path",
        "_check_hud_and_map_spatial_readouts",
        "_check_object_prompts_show_spatial_playability",
        "_check_runtime_results_keep_spatial_followup"
    )
    "scripts/check-client.sh" = @(
        "check-client-demo-functional-transition-spatial-playability.py",
        "demo_functional_transition_spatial_playability_check.gd"
    )
    "scripts/check-client.ps1" = @(
        "check-client-demo-functional-transition-spatial-playability.ps1"
    )
    "scripts/check-client-flow.ps1" = @(
        "demo_functional_transition_spatial_playability_check.gd"
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
            $errors.Add("${relativePath}: missing functional transition spatial playability text '${requiredText}'")
        }
    }
}

if ($errors.Count -gt 0) {
    foreach ($errorMessage in $errors) {
        Write-Error $errorMessage
    }
    exit 1
}

Write-Host "Client demo functional transition spatial playability checks passed."
