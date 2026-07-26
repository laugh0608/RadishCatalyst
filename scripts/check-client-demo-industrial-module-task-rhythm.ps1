[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$requiredTextByFile = @{
    "docs/archive/features-demo-v1/demo-industrial-module-task-rhythm-v1.md" = @(
        "Demo Industrial Module Task Rhythm V1",
        "工业模块职责与任务节奏第一包",
        "DemoIndustrialModuleTaskRhythmFormatter",
        "demo_industrial_module_task_rhythm_check.gd"
    )
    "docs/archive/features-demo-v1/demo-playable-content-substance-v1.md" = @(
        "工业模块职责与任务节奏第一包",
        "DemoIndustrialModuleTaskRhythmFormatter",
        "不新增第 13 区域"
    )
    "client/scripts/systems/demo_industrial_module_task_rhythm_formatter.gd" = @(
        "class_name DemoIndustrialModuleTaskRhythmFormatter",
        "BASIC_STORAGE_ID",
        "FIELD_OUTFITTING_STATION_ID",
        "format_hud_summary",
        "format_build_prompt_line"
    )
    "client/scripts/ui/hud_status_presenter.gd" = @(
        "DemoIndustrialModuleTaskRhythmFormatter.format_hud_summary",
        "DemoIndustrialModuleTaskRhythmFormatter.format_recipe_task_hint",
        "DemoIndustrialModuleTaskRhythmFormatter.format_build_task_hint"
    )
    "client/scripts/ui/hud_device_panel_presenter.gd" = @(
        "DemoIndustrialModuleTaskRhythmFormatter.format_device_status_line"
    )
    "client/scripts/ui/interaction_prompt_formatter.gd" = @(
        "DemoIndustrialModuleTaskRhythmFormatter.format_build_prompt_line",
        "DemoIndustrialModuleTaskRhythmFormatter.format_outpost_core_prompt_line",
        "DemoIndustrialModuleTaskRhythmFormatter.format_outfitting_station_prompt_line"
    )
    "client/scripts/ui/processing_interaction_prompt_formatter.gd" = @(
        "DemoIndustrialModuleTaskRhythmFormatter.format_processing_prompt_line",
        "DemoIndustrialModuleTaskRhythmFormatter.format_processing_log_line"
    )
    "client/scripts/ui/hud_log_presenter.gd" = @(
        "`"任务节奏`"",
        "`"module_task`""
    )
    "client/scripts/systems/build_system.gd" = @(
        "DemoIndustrialModuleTaskRhythmFormatter.format_build_result_line",
        "`"module_task`""
    )
    "client/scripts/systems/processing_system.gd" = @(
        "DemoIndustrialModuleTaskRhythmFormatter.format_result_feedback_line",
        "`"module_task`""
    )
    "client/scripts/checks/demo_industrial_module_task_rhythm_check.gd" = @(
        "Demo industrial module task rhythm checks passed.",
        "_check_hud_and_build_prompt_task_rhythm",
        "_check_device_panel_and_processing_prompt_task_rhythm",
        "_check_processing_and_build_result_logs"
    )
    "scripts/check-client.sh" = @(
        "check-client-demo-industrial-module-task-rhythm.py",
        "demo_industrial_module_task_rhythm_check.gd"
    )
    "scripts/check-client.ps1" = @(
        "check-client-demo-industrial-module-task-rhythm.ps1"
    )
    "scripts/check-client-flow.ps1" = @(
        "demo_industrial_module_task_rhythm_check.gd"
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
            $errors.Add("${relativePath}: missing demo industrial module task rhythm text '${requiredText}'")
        }
    }
}

if ($errors.Count -gt 0) {
    foreach ($errorMessage in $errors) {
        Write-Error $errorMessage
    }
    exit 1
}

Write-Host "Client demo industrial module task rhythm checks passed."
