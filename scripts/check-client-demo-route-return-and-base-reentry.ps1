[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$requiredTextByFile = @{
    "docs/archive/features-demo-v1/demo-route-return-and-base-reentry-readability-v1.md" = @(
        "Demo Route Return And Base Reentry Readability V1",
        "外勤返回与基地再进入读法",
        "不新增资源、配方、设备、区域、任务链、敌人类型、完整背包、完整装备栏或自动化物流"
    )
    "client/scripts/systems/demo_route_return_and_base_reentry_formatter.gd" = @(
        "class_name DemoRouteReturnAndBaseReentryFormatter",
        "format_hud_summary",
        "format_map_route_hint",
        "format_device_status_line",
        "format_result_feedback_line",
        "get_recommended_recipe_id_for_device",
        "污染沉积物已带回",
        "回波痕迹已带回"
    )
    "client/scripts/ui/hud_status_presenter.gd" = @(
        "DemoRouteReturnAndBaseReentryFormatter.format_hud_summary"
    )
    "client/scripts/ui/hud_map_presenter.gd" = @(
        "DemoRouteReturnAndBaseReentryFormatter.format_map_route_hint"
    )
    "client/scripts/ui/hud_device_panel_presenter.gd" = @(
        "DemoRouteReturnAndBaseReentryFormatter.format_device_status_line"
    )
    "client/scripts/systems/processing_system.gd" = @(
        "DemoRouteReturnAndBaseReentryFormatter.get_recommended_recipe_id_for_device",
        "base_reentry",
        "DemoRouteReturnAndBaseReentryFormatter.format_result_feedback_line"
    )
    "client/scripts/ui/hud_log_presenter.gd" = @(
        '"再进入"',
        "base_reentry"
    )
    "client/scripts/checks/demo_route_return_and_base_reentry_check.gd" = @(
        "Demo route return and base reentry checks passed.",
        "_check_residue_return_hud_map_and_device",
        "_check_signal_return_reactor_and_route",
        "_check_reentry_processing_result_feedback",
        "_check_base_reentry_state_roundtrip"
    )
    "scripts/check-client.sh" = @(
        "check-client-demo-route-return-and-base-reentry.py",
        "demo_route_return_and_base_reentry_check.gd"
    )
    "scripts/check-client.ps1" = @(
        "check-client-demo-route-return-and-base-reentry.ps1"
    )
    "scripts/check-client-flow.ps1" = @(
        "demo_route_return_and_base_reentry_check.gd"
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
            $errors.Add("${relativePath}: missing route return and base reentry text '${requiredText}'")
        }
    }
}

if ($errors.Count -gt 0) {
    foreach ($errorMessage in $errors) {
        Write-Error $errorMessage
    }
    exit 1
}

Write-Host "Client demo route return and base reentry checks passed."
