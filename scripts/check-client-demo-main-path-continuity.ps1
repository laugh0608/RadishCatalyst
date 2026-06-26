[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$requiredTextByFile = @{
    "docs/features/demo-main-path-continuity-v1.md" = @(
        "Demo Main Path Continuity V1",
        "主路径连续性",
        "S0",
        "S21",
        "quest.write_demo_stabilization_core",
        "不新增资源、配方、区域、任务链、完整背包、完整装备栏或自动化物流"
    )
    "client/scripts/checks/demo_main_path_continuity_check.gd" = @(
        "Demo main path continuity checks passed.",
        "DevelopmentBaselineBuilder",
        "GatherSystem",
        "ProcessingSystem",
        "EnemyCounterattackRuntime",
        "_check_baseline_main_path_milestones",
        "_check_first_playable_core_loop_rhythm",
        "_check_s21_to_demo_completion_path",
        "DemoCoreLoopRhythmFormatter"
    )
    "client/scripts/systems/demo_core_loop_rhythm_formatter.gd" = @(
        "class_name DemoCoreLoopRhythmFormatter",
        "format_hud_summary",
        "get_stage_id",
        "format_result_feedback_line",
        "核心循环",
        "循环接力"
    )
    "client/scripts/ui/hud_status_presenter.gd" = @(
        "DemoCoreLoopRhythmFormatter.format_hud_summary"
    )
    "client/scripts/systems/processing_system.gd" = @(
        "core_loop",
        "show_core_loop",
        "DemoCoreLoopRhythmFormatter.format_result_feedback_line"
    )
    "scripts/check-client.sh" = @(
        "check-client-demo-main-path-continuity.py",
        "demo_main_path_continuity_check.gd"
    )
    "scripts/check-client.ps1" = @(
        "check-client-demo-main-path-continuity.ps1"
    )
    "scripts/check-client-flow.ps1" = @(
        "demo_main_path_continuity_check.gd"
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
            $errors.Add("${relativePath}: missing demo main path continuity text '${requiredText}'")
        }
    }
}

if ($errors.Count -gt 0) {
    foreach ($errorMessage in $errors) {
        Write-Error $errorMessage
    }
    exit 1
}

Write-Host "Client demo main path continuity checks passed."
