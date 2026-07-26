[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$requiredTextByFile = @{
    "docs/archive/features-demo-v1/demo-completion-outcome-readout-v1.md" = @(
        "Demo Completion Outcome Readout V1",
        "终点完成后的玩家可见成果整理",
        "不新增终局菜单、结算页、制作人员名单、试玩准备、发布准备或大规模 polish"
    )
    "client/scripts/systems/demo_completion_outcome_formatter.gd" = @(
        "class_name DemoCompletionOutcomeFormatter",
        "is_completion_outcome_context",
        "format_hud_summary",
        "format_map_route_hint",
        "format_completion_note",
        "前哨稳定窗口已打开"
    )
    "client/scripts/map/demo_industrial_base_visual_layer.gd" = @(
        "CompletionOutcomeArtPass",
        "get_completion_outcome_shape_count"
    )
    "client/scripts/map/demo_base_completion_outcome_art_pass.gd" = @(
        "class_name DemoBaseCompletionOutcomeArtPass",
        "completion_outcome.outpost.stability_window.ready",
        "completion_outcome.flow.core_archive_to_outpost.ready"
    )
    "client/scripts/systems/demo_mainline_completion_formatter.gd" = @(
        "CompletionOutcomeFormatter := preload",
        "CompletionOutcomeFormatter.format_goal_name",
        "CompletionOutcomeFormatter.format_hud_summary",
        "CompletionOutcomeFormatter.format_completion_note"
    )
    "client/scripts/ui/hud_status_presenter.gd" = @(
        "CompletionOutcomeFormatter := preload",
        "CompletionOutcomeFormatter.format_hud_summary"
    )
    "client/scripts/quests/quest_completion_applier.gd" = @(
        "DemoMainlineCompletionFormatter.format_completion_note_for_state"
    )
    "client/scripts/checks/demo_completion_outcome_readout_check.gd" = @(
        "Demo completion outcome readout checks passed.",
        "_check_hud_map_and_outpost_outcome",
        "_check_core_device_and_completion_log_outcome",
        "_check_outpost_completion_visual_outcome",
        "_check_completion_outcome_boundaries"
    )
    "scripts/check-client.sh" = @(
        "check-client-demo-completion-outcome-readout.py",
        "demo_completion_outcome_readout_check.gd"
    )
    "scripts/check-client-flow.ps1" = @(
        "demo_completion_outcome_readout_check.gd"
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
            $errors.Add("${relativePath}: missing demo completion outcome text '${requiredText}'")
        }
    }
}

if ($errors.Count -gt 0) {
    foreach ($errorMessage in $errors) {
        Write-Error $errorMessage
    }
    exit 1
}

Write-Host "Client demo completion outcome readout checks passed."
