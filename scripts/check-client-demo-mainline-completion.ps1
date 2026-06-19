[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$requiredTextByFile = @{
    "client/scripts/systems/demo_mainline_completion_formatter.gd" = @(
        "class_name DemoMainlineCompletionFormatter",
        "is_demo_complete",
        "format_goal_name",
        "format_hud_summary",
        "format_map_route_hint",
        "format_core_object_status",
        "format_outpost_core_prompt_line",
        "format_completion_note",
        "首版 Demo 主线已完成",
        "Demo 终点已完成"
    )
    "client/scripts/ui/hud_status_presenter.gd" = @(
        "DemoMainlineCompletionFormatter.format_goal_name",
        "DemoMainlineCompletionFormatter.format_progress_line",
        "DemoMainlineCompletionFormatter.is_demo_complete"
    )
    "client/scripts/ui/hud_map_presenter.gd" = @(
        "DemoMainlineCompletionFormatter.format_map_route_hint"
    )
    "client/scripts/ui/interaction_prompt_formatter.gd" = @(
        "DemoMainlineCompletionFormatter.format_core_object_status",
        "DemoMainlineCompletionFormatter.format_core_object_next_step",
        "DemoMainlineCompletionFormatter.format_outpost_core_prompt_line"
    )
    "client/scripts/quests/quest_completion_applier.gd" = @(
        "DemoMainlineCompletionFormatter.format_completion_note"
    )
    "client/scripts/checks/demo_mainline_completion_check.gd" = @(
        "Demo mainline completion checks passed.",
        "_check_hud_and_map_completion_readout",
        "_check_core_object_and_outpost_prompts",
        "_check_completion_log_reuses_mainline_note"
    )
    "scripts/check-client.sh" = @(
        "check-client-demo-mainline-completion.py",
        "demo_mainline_completion_check.gd"
    )
    "scripts/check-client-flow.ps1" = @(
        "demo_mainline_completion_check.gd"
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
            $errors.Add("${relativePath}: missing demo mainline completion text '${requiredText}'")
        }
    }
}

if ($errors.Count -gt 0) {
    foreach ($errorMessage in $errors) {
        Write-Error $errorMessage
    }
    exit 1
}

Write-Host "Client demo mainline completion checks passed."
