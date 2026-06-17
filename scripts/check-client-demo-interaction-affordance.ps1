[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$requiredTextByFile = @{
    "docs/features/demo-interaction-affordance-v1.md" = @(
        "Demo Interaction Affordance V1",
        "第一包实施范围",
        "DemoInteractionAffordanceFormatter",
        "不新增资源、配方、区域、任务链、敌人类型、完整背包或完整装备栏"
    )
    "client/scripts/systems/demo_interaction_affordance_formatter.gd" = @(
        "class_name DemoInteractionAffordanceFormatter",
        "format_general_affordance_line",
        "format_build_affordance_line",
        "format_clear_affordance_line",
        "format_outpost_core_affordance_line",
        "format_outfitting_station_affordance_line"
    )
    "client/scripts/ui/interaction_prompt_formatter.gd" = @(
        "DemoInteractionAffordanceFormatter.format_general_affordance_line",
        "DemoInteractionAffordanceFormatter.format_build_affordance_line",
        "DemoInteractionAffordanceFormatter.format_clear_affordance_line",
        "DemoInteractionAffordanceFormatter.format_outpost_core_affordance_line",
        "DemoInteractionAffordanceFormatter.format_outfitting_station_affordance_line",
        "DemoInteractionAffordanceFormatter.format_definition_affordance_line"
    )
    "client/scripts/checks/demo_interaction_affordance_check.gd" = @(
        "Demo interaction affordance checks passed.",
        "_check_general_prompt_affordance_states",
        "_check_signal_echo_and_core_guard_affordance",
        "_check_hud_map_route_alignment",
        "_check_scene_visual_affordance_labels",
        "_check_enemy_focus_affordance_labels"
    )
    "scripts/check-client.sh" = @(
        "check-client-demo-interaction-affordance.py",
        "demo_interaction_affordance_check.gd"
    )
    "scripts/check-client.ps1" = @(
        "check-client-demo-interaction-affordance.ps1"
    )
    "scripts/check-client-flow.ps1" = @(
        "demo_interaction_affordance_check.gd"
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
            $errors.Add("${relativePath}: missing demo interaction affordance text '${requiredText}'")
        }
    }
}

if ($errors.Count -gt 0) {
    foreach ($errorMessage in $errors) {
        Write-Error $errorMessage
    }
    exit 1
}

Write-Host "Client demo interaction affordance checks passed."
