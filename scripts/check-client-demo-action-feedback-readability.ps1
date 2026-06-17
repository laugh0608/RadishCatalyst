[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$requiredTextByFile = @{
    "docs/features/demo-action-feedback-readability-v1.md" = @(
        "Demo Action Feedback Readability V1",
        "第一包实施范围",
        "DemoActionFeedbackFormatter",
        "不新增资源、配方、区域、任务链、敌人类型、完整背包或完整装备栏"
    )
    "client/scripts/systems/demo_action_feedback_formatter.gd" = @(
        "class_name DemoActionFeedbackFormatter",
        "format_gather_success_feedback",
        "format_sample_success_feedback",
        "format_clear_success_feedback",
        "format_core_write_success_feedback",
        "format_enemy_defeat_success_feedback",
        "format_outpost_core_success_feedback"
    )
    "client/scripts/systems/gather_system.gd" = @(
        "DemoActionFeedbackFormatter.format_gather_success_feedback",
        "DemoActionFeedbackFormatter.format_sample_success_feedback",
        "DemoActionFeedbackFormatter.format_clear_success_feedback",
        "DemoActionFeedbackFormatter.format_core_write_success_feedback",
        "DemoActionFeedbackFormatter.format_outpost_core_success_feedback"
    )
    "client/scripts/map/vertical_slice_map.gd" = @(
        "DemoActionFeedbackFormatter.format_enemy_defeat_success_feedback"
    )
    "client/scripts/checks/demo_action_feedback_readability_check.gd" = @(
        "Demo action feedback readability checks passed.",
        "_check_gather_sample_and_clear_feedback",
        "_check_build_and_processing_feedback",
        "_check_enemy_defeat_feedback",
        "_check_core_write_and_outpost_feedback"
    )
    "scripts/check-client.sh" = @(
        "check-client-demo-action-feedback-readability.py",
        "demo_action_feedback_readability_check.gd"
    )
    "scripts/check-client.ps1" = @(
        "check-client-demo-action-feedback-readability.ps1"
    )
    "scripts/check-client-flow.ps1" = @(
        "demo_action_feedback_readability_check.gd"
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
            $errors.Add("${relativePath}: missing demo action feedback readability text '${requiredText}'")
        }
    }
}

if ($errors.Count -gt 0) {
    foreach ($errorMessage in $errors) {
        Write-Error $errorMessage
    }
    exit 1
}

Write-Host "Client demo action feedback readability checks passed."
