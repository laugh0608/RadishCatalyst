[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$requiredTextByFile = @{
    "docs/features/demo-field-loop-payoff-v1.md" = @(
        "Demo Field Loop Payoff V1",
        "外勤回基地收益兑现",
        "不新增资源、配方、区域、任务链、完整背包、完整装备栏或自动化物流"
    )
    "client/scripts/systems/demo_field_loop_payoff_formatter.gd" = @(
        "class_name DemoFieldLoopPayoffFormatter",
        "FIELD_LOOP_PAYOFF_CONFIRMED_FLAG",
        "format_hud_summary",
        "format_outfitting_prompt_line",
        "format_pressure_feedback"
    )
    "client/scripts/systems/field_outfitting_runtime.gd" = @(
        "should_confirm_field_loop_payoff",
        "mark_field_loop_payoff_confirmed",
        "has_active_field_loop_payoff",
        "FIELD_LOOP_PAYOFF_PRESSURE_MULT"
    )
    "client/scripts/systems/gather_system.gd" = @(
        "_confirm_field_loop_payoff",
        "field_loop_payoff_confirmed",
        "外勤收益兑现完成"
    )
    "client/scripts/ui/departure_readiness_formatter.gd" = @(
        "DemoFieldLoopPayoffFormatter.format_hud_summary",
        "format_departure_next_step",
        "DemoFieldLoopPayoffFormatter.format_compact_state"
    )
    "client/scripts/ui/interaction_prompt_formatter.gd" = @(
        "DemoFieldLoopPayoffFormatter.format_outfitting_prompt_line",
        "E 确认外勤收益整备"
    )
    "client/scripts/save/save_content_validator.gd" = @(
        "field_loop_payoff_confirmed"
    )
    "client/scripts/checks/demo_field_loop_payoff_check.gd" = @(
        "Demo field loop payoff checks passed.",
        "_check_outfitting_prompt_and_confirmation",
        "_check_pressure_payoff_runtime",
        "_check_payoff_state_roundtrip"
    )
    "scripts/check-client.sh" = @(
        "check-client-demo-field-loop-payoff.py",
        "demo_field_loop_payoff_check.gd"
    )
    "scripts/check-client-flow.ps1" = @(
        "demo_field_loop_payoff_check.gd"
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
            $errors.Add("${relativePath}: missing demo field loop payoff text '${requiredText}'")
        }
    }
}

if ($errors.Count -gt 0) {
    foreach ($errorMessage in $errors) {
        Write-Error $errorMessage
    }
    exit 1
}

Write-Host "Client demo field loop payoff checks passed."
