[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$requiredTextByFile = @{
    "docs/archive/features-demo-v1/demo-protective-response-v1.md" = @(
        "Demo Protective Response V1",
        "基础防护服",
        "基础过滤模块",
        "防护响应"
    )
    "client/scripts/systems/field_outfitting_runtime.gd" = @(
        "PROTECTIVE_RESPONSE_READY_FLAG",
        "PROTECTIVE_RESPONSE_TRIGGERED_FLAG",
        "can_confirm_protective_response",
        "consume_protective_response",
        "format_protective_response_counter_feedback"
    )
    "client/scripts/systems/gather_system.gd" = @(
        "_confirm_protective_response",
        "protective_response_ready",
        "防护响应已待命"
    )
    "client/scripts/map/enemy_counterattack_runtime.gd" = @(
        "consume_protective_response",
        "PROTECTIVE_RESPONSE_COUNTER_MULT",
        "format_protective_response_counter_feedback"
    )
    "client/scripts/ui/departure_readiness_formatter.gd" = @(
        "format_protective_response_compact_state",
        "防护响应待命"
    )
    "client/scripts/ui/interaction_prompt_formatter.gd" = @(
        "format_protective_response_prompt_line",
        "E 确认防护响应"
    )
    "client/scripts/checks/demo_protective_response_check.gd" = @(
        "Demo protective response checks passed.",
        "_check_outfitting_prompt_and_confirmation",
        "_check_calibration_keeps_priority",
        "_check_counterattack_consumes_response",
        "_check_triggered_response_requires_refit_before_reconfirm"
    )
    "scripts/check-client.sh" = @(
        "check-client-demo-protective-response.py",
        "demo_protective_response_check.gd"
    )
    "scripts/check-client-flow.ps1" = @(
        "demo_protective_response_check.gd"
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
            $errors.Add("${relativePath}: missing demo protective response text '${requiredText}'")
        }
    }
}

if ($errors.Count -gt 0) {
    foreach ($errorMessage in $errors) {
        Write-Error $errorMessage
    }
    exit 1
}

Write-Host "Client demo protective response checks passed."
