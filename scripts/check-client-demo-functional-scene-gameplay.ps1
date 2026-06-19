[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$requiredTextByFile = @{
    "docs/features/demo-functional-scene-gameplay-v1.md" = @(
        "Demo Functional Scene Gameplay V1",
        "功能场景玩法",
        "封锁遗迹",
        "锚定桥",
        "不新增资源、配方、区域、任务链、完整背包、完整装备栏或自动化物流"
    )
    "client/scripts/systems/functional_scene_gameplay_formatter.gd" = @(
        "class_name FunctionalSceneGameplayFormatter",
        "format_hud_summary",
        "format_object_gameplay_line",
        "format_result_followup_line",
        "碎晶沟谷现场玩法",
        "锚定桥现场玩法"
    )
    "client/scripts/ui/hud_status_presenter.gd" = @(
        "FunctionalSceneGameplayFormatter.format_hud_summary"
    )
    "client/scripts/ui/interaction_prompt_formatter.gd" = @(
        "FunctionalSceneGameplayFormatter.format_object_gameplay_line",
        "FunctionalSceneGameplayFormatter.format_static_object_gameplay_line"
    )
    "client/scripts/systems/gather_system.gd" = @(
        "FunctionalSceneGameplayFormatter.format_result_followup_line",
        "_with_functional_scene_gameplay_followup"
    )
    "client/scripts/checks/functional_scene_gameplay_check.gd" = @(
        "Functional scene gameplay checks passed.",
        "_check_hud_summary_uses_scene_gameplay",
        "_check_interaction_prompts_show_scene_gameplay",
        "_check_runtime_interaction_results_show_scene_gameplay"
    )
    "scripts/check-client.sh" = @(
        "check-client-demo-functional-scene-gameplay.py",
        "functional_scene_gameplay_check.gd"
    )
    "scripts/check-client.ps1" = @(
        "check-client-demo-functional-scene-gameplay.ps1"
    )
    "scripts/check-client-flow.ps1" = @(
        "functional_scene_gameplay_check.gd"
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
            $errors.Add("${relativePath}: missing demo functional scene gameplay text '${requiredText}'")
        }
    }
}

if ($errors.Count -gt 0) {
    foreach ($errorMessage in $errors) {
        Write-Error $errorMessage
    }
    exit 1
}

Write-Host "Client demo functional scene gameplay checks passed."
