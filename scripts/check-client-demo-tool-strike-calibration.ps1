[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$requiredTextByFile = @{
    "docs/features/demo-tool-strike-calibration-v1.md" = @(
        "Demo Tool Strike Calibration V1",
        "基础多用工具",
        "基础零件",
        "工具打击校准"
    )
    "client/scripts/systems/field_outfitting_runtime.gd" = @(
        "TOOL_STRIKE_CALIBRATION_READY_FLAG",
        "TOOL_STRIKE_CALIBRATION_TRIGGERED_FLAG",
        "can_confirm_tool_strike_calibration",
        "consume_tool_strike_calibration",
        "format_tool_strike_calibration_counter_feedback"
    )
    "client/scripts/systems/gather_system.gd" = @(
        "_confirm_tool_strike_calibration",
        "tool_strike_calibration_ready",
        "工具校准已待命"
    )
    "client/scripts/map/enemy_counterattack_runtime.gd" = @(
        "consume_tool_strike_calibration",
        "TOOL_STRIKE_CALIBRATION_COUNTER_MULT",
        "format_tool_strike_calibration_counter_feedback"
    )
    "client/scripts/ui/departure_readiness_formatter.gd" = @(
        "format_tool_strike_calibration_compact_state",
        "tool_strike_state"
    )
    "client/scripts/ui/interaction_prompt_formatter.gd" = @(
        "format_tool_strike_calibration_prompt_line",
        "E 确认工具打击校准"
    )
    "client/scripts/ui/recipe_purpose_hints.gd" = @(
        "工具打击校准"
    )
    "client/scripts/checks/demo_tool_strike_calibration_check.gd" = @(
        "Demo tool strike calibration checks passed.",
        "_check_outfitting_prompt_and_confirmation",
        "_check_filter_module_equipping_keeps_priority",
        "_check_counterattack_consumes_calibration",
        "_check_triggered_calibration_requires_parts_before_reconfirm"
    )
    "scripts/check-client.sh" = @(
        "check-client-demo-tool-strike-calibration.py",
        "demo_tool_strike_calibration_check.gd"
    )
    "scripts/check-client-flow.ps1" = @(
        "demo_tool_strike_calibration_check.gd"
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
            $errors.Add("${relativePath}: missing demo tool strike calibration text '${requiredText}'")
        }
    }
}

if ($errors.Count -gt 0) {
    foreach ($errorMessage in $errors) {
        [Console]::Error.WriteLine($errorMessage)
    }
    exit 1
}

Write-Host "Client demo tool strike calibration checks passed."
