[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$requiredTextByFile = @{
    "client/scripts/systems/industrial_tech_spine_formatter.gd" = @(
        "class_name IndustrialTechSpineFormatter",
        "format_hud_summary",
        "format_device_status_line",
        "format_processing_prompt_line",
        "format_outfitting_station_prompt_line",
        "format_processing_log_line",
        "污染沉积物 -> 抗污染药剂 + 污染浆液",
        "基础零件 + 过滤介质 -> 基础过滤模块",
        "核心稳压缓冲包"
    )
    "client/scripts/ui/hud_status_presenter.gd" = @(
        "IndustrialTechSpineFormatter.format_hud_summary"
    )
    "client/scripts/ui/hud_device_panel_presenter.gd" = @(
        "IndustrialTechSpineFormatter.format_device_status_line"
    )
    "client/scripts/ui/processing_interaction_prompt_formatter.gd" = @(
        "IndustrialTechSpineFormatter.format_processing_prompt_line",
        "IndustrialTechSpineFormatter.format_processing_log_line"
    )
    "client/scripts/ui/interaction_prompt_formatter.gd" = @(
        "IndustrialTechSpineFormatter.format_outfitting_station_prompt_line"
    )
    "client/scripts/systems/processing_system.gd" = @(
        "industrial_spine",
        "IndustrialTechSpineFormatter.format_result_feedback_line"
    )
    "client/scripts/ui/hud_log_presenter.gd" = @(
        '"工艺"',
        "industrial_spine"
    )
    "client/scripts/checks/industrial_tech_spine_check.gd" = @(
        "Industrial tech spine checks passed.",
        "_check_hud_summary",
        "_check_device_panel_line",
        "_check_processing_prompt_and_log",
        "_check_outfitting_station_prompt",
        "_check_processing_result_feedback"
    )
    "scripts/check-client.sh" = @(
        "industrial_tech_spine_check.gd"
    )
    "scripts/check-client-flow.ps1" = @(
        "industrial_tech_spine_check.gd"
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
            $errors.Add("${relativePath}: missing industrial tech spine text '${requiredText}'")
        }
    }
}

if ($errors.Count -gt 0) {
    foreach ($errorMessage in $errors) {
        Write-Error $errorMessage
    }
    exit 1
}

Write-Host "Client industrial tech spine checks passed."
