[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$requiredTextByFile = @{
    "docs/archive/features-demo-v1/demo-endpoint-readiness-v1.md" = @(
        "Demo Endpoint Readiness V1",
        "终点前综合准备读法",
        "不新增资源、配方、区域、任务链、完整背包、完整装备栏、终局菜单或发布准备流程"
    )
    "client/scripts/systems/demo_endpoint_readiness_formatter.gd" = @(
        "class_name DemoEndpointReadinessFormatter",
        "is_endpoint_readiness_context",
        "format_hud_summary",
        "format_departure_gate_next_step",
        "format_core_object_status_line"
    )
    "client/scripts/ui/hud_status_presenter.gd" = @(
        "DemoEndpointReadinessFormatter.format_hud_summary"
    )
    "client/scripts/ui/departure_readiness_formatter.gd" = @(
        "DemoEndpointReadinessFormatter.format_outpost_core_prompt_line",
        "DemoEndpointReadinessFormatter.format_departure_gate_status_line",
        "DemoEndpointReadinessFormatter.format_departure_gate_next_step"
    )
    "client/scripts/ui/interaction_prompt_formatter.gd" = @(
        "DemoEndpointReadinessFormatter.format_core_object_status_line",
        "DemoEndpointReadinessFormatter.format_core_object_next_step"
    )
    "client/scripts/checks/demo_endpoint_readiness_check.gd" = @(
        "Demo endpoint readiness checks passed.",
        "_check_hud_outpost_and_departure_gate_readiness",
        "_check_core_device_write_readiness",
        "_check_context_boundaries"
    )
    "scripts/check-client.sh" = @(
        "check-client-demo-endpoint-readiness.py",
        "demo_endpoint_readiness_check.gd"
    )
    "scripts/check-client-flow.ps1" = @(
        "demo_endpoint_readiness_check.gd"
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
            $errors.Add("${relativePath}: missing demo endpoint readiness text '${requiredText}'")
        }
    }
}

if ($errors.Count -gt 0) {
    foreach ($errorMessage in $errors) {
        Write-Error $errorMessage
    }
    exit 1
}

Write-Host "Client demo endpoint readiness checks passed."
