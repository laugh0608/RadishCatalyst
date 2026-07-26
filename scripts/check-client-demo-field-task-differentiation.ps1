[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$requiredTextByFile = @{
    "docs/archive/features-demo-v1/demo-field-task-differentiation-v1.md" = @(
        "Demo Field Task Differentiation V1",
        "资源处理与外勤任务差异第一包",
        "DemoFieldTaskDifferentiationFormatter",
        "demo_field_task_differentiation_check.gd"
    )
    "docs/archive/features-demo-v1/demo-playable-content-substance-v1.md" = @(
        "资源处理与外勤任务差异第一包",
        "DemoFieldTaskDifferentiationFormatter",
        "不新增第 13 区域"
    )
    "client/scripts/systems/demo_field_task_differentiation_formatter.gd" = @(
        "class_name DemoFieldTaskDifferentiationFormatter",
        "FIELD_TASK_CONFIRMED_FLAG",
        "format_gather_result_line",
        "format_device_status_line",
        "format_outfitting_prompt_line"
    )
    "client/scripts/systems/field_outfitting_runtime.gd" = @(
        "can_confirm_field_task_differentiation",
        "mark_field_task_differentiation_confirmed",
        "is_field_task_differentiation_confirmed"
    )
    "client/scripts/systems/gather_system.gd" = @(
        "DemoFieldTaskDifferentiationFormatter.format_gather_result_line",
        "DemoFieldTaskDifferentiationFormatter.format_sample_result_line",
        "field_task_differentiation_confirmed"
    )
    "client/scripts/systems/processing_system.gd" = @(
        "DemoFieldTaskDifferentiationFormatter.format_result_feedback_line",
        "DemoFieldTaskDifferentiationFormatter.should_show_result_line",
        "`"field_task`""
    )
    "client/scripts/ui/hud_status_presenter.gd" = @(
        "DemoFieldTaskDifferentiationFormatter.format_hud_summary"
    )
    "client/scripts/ui/hud_device_panel_presenter.gd" = @(
        "DemoFieldTaskDifferentiationFormatter.format_device_status_line"
    )
    "client/scripts/ui/interaction_prompt_formatter.gd" = @(
        "DemoFieldTaskDifferentiationFormatter.format_object_task_line",
        "DemoFieldTaskDifferentiationFormatter.format_outfitting_prompt_line",
        "FieldOutfittingRuntime.can_confirm_field_task_differentiation"
    )
    "client/scripts/ui/processing_interaction_prompt_formatter.gd" = @(
        "DemoFieldTaskDifferentiationFormatter.format_processing_prompt_line",
        "DemoFieldTaskDifferentiationFormatter.format_processing_log_line"
    )
    "client/scripts/ui/hud_log_presenter.gd" = @(
        "`"任务差异`"",
        "`"show_field_task`""
    )
    "client/scripts/checks/demo_field_task_differentiation_check.gd" = @(
        "Demo field task differentiation checks passed.",
        "_check_gather_feedback_and_object_prompt",
        "_check_device_panel_and_processing_feedback",
        "_check_outfitting_confirmation_and_roundtrip"
    )
    "scripts/check-client.sh" = @(
        "check-client-demo-field-task-differentiation.py",
        "demo_field_task_differentiation_check.gd"
    )
    "scripts/check-client.ps1" = @(
        "check-client-demo-field-task-differentiation.ps1"
    )
    "scripts/check-client-flow.ps1" = @(
        "demo_field_task_differentiation_check.gd"
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
            $errors.Add("${relativePath}: missing demo field task differentiation text '${requiredText}'")
        }
    }
}

if ($errors.Count -gt 0) {
    $errors | ForEach-Object { [Console]::Error.WriteLine($_) }
    exit 1
}

Write-Host "Client demo field task differentiation checks passed."
