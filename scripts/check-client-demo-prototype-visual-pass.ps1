[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$requiredTextByFile = @{
    "docs/features/demo-prototype-visual-pass-v1.md" = @(
        "Demo Prototype Visual Pass V1",
        "原型视觉呈现",
        "PrototypeVisualPriorityLayer",
        "demo_prototype_visual_pass_check.gd",
        "不新增资源、配方、区域、任务链、敌人类型、完整背包或完整装备栏"
    )
    "client/scripts/systems/prototype_visual_priority_profile.gd" = @(
        "class_name PrototypeVisualPriorityProfile",
        "REGION_PROFILES",
        "STATE_PROFILES",
        "STATE_CORE_WRITE_BLOCKED",
        "make_cue_name"
    )
    "client/scripts/map/prototype_visual_priority_layer.gd" = @(
        "class_name PrototypeVisualPriorityLayer",
        "apply_profile",
        "get_generated_cue_count",
        "PrototypeVisualPriorityProfile.get_region_ids"
    )
    "client/scripts/map/current_objective_guidance_layer.gd" = @(
        "class_name CurrentObjectiveGuidanceLayer",
        "CurrentObjectiveTargetHalo",
        "CurrentObjectiveOffTargetLabel",
        "is_target_guidance_visible",
        "_resolve_current_target",
        "get_current_target_node"
    )
    "client/scenes/maps/VerticalSliceMap.tscn" = @(
        "res://scripts/map/prototype_visual_priority_layer.gd",
        "PrototypeVisualPriorityLayer",
        "res://scripts/map/current_objective_guidance_layer.gd",
        "CurrentObjectiveGuidanceLayer"
    )
    "client/scripts/interaction/prototype_interactable.gd" = @(
        "set_visual_priority_state",
        "set_missing_prerequisite_visual",
        "set_danger_active_visual",
        "set_device_busy_visual",
        "set_core_write_blocked_visual"
    )
    "client/scripts/map/interactable_visual_refresher.gd" = @(
        "_apply_visual_priority_state",
        "_is_build_prerequisite_blocked",
        "_is_processing_busy",
        "_is_danger_active",
        "_is_core_write_blocked"
    )
    "client/scripts/checks/demo_prototype_visual_pass_check.gd" = @(
        "Demo prototype visual pass checks passed.",
        "_check_visual_priority_profile_coverage",
        "_check_scene_visual_priority_layer",
        "_check_current_objective_guidance_layer",
        "post-restore storage build guidance",
        "pollution filter processing guidance",
        "_check_visual_state_methods",
        "_check_visual_refresher_state_alignment"
    )
    "scripts/check-client.sh" = @(
        "check-client-demo-prototype-visual-pass.py",
        "demo_prototype_visual_pass_check.gd"
    )
    "scripts/check-client.ps1" = @(
        "check-client-demo-prototype-visual-pass.ps1"
    )
    "scripts/check-client-flow.ps1" = @(
        "demo_prototype_visual_pass_check.gd"
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
            $errors.Add("${relativePath}: missing prototype visual pass text '${requiredText}'")
        }
    }
}

if ($errors.Count -gt 0) {
    foreach ($errorMessage in $errors) {
        Write-Error $errorMessage
    }
    exit 1
}

Write-Host "Client demo prototype visual pass checks passed."
