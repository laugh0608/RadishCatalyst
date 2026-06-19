[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$requiredTextByFile = @{
    "docs/features/demo-midfield-route-playability-v1.md" = @(
        "Demo Midfield Route Playability V1",
        "中段异常地貌可玩路径",
        "回声台地 -> 盐壳浅滩 -> 碎晶沟谷",
        "不新增第 13 区域，不新增资源、配方、设备、敌人、任务链、存档字段或 UI 面板"
    )
    "client/scripts/systems/demo_midfield_route_playability_formatter.gd" = @(
        "class_name DemoMidfieldRoutePlayabilityFormatter",
        "format_hud_summary",
        "format_map_route_hint",
        "format_object_route_line",
        "format_static_object_route_line",
        "format_result_followup_line",
        "回声台地中段路径",
        "盐壳浅滩中段路径",
        "碎晶沟谷中段路径"
    )
    "client/scenes/maps/VerticalSliceMap.tscn" = @(
        "MidfieldRoutePlayabilityLayer",
        "EchoEntryLane",
        "EchoVentBoundary",
        "SaltCrustBoundary",
        "SaltSinkFacilityPocket",
        "CrystalShuntBoundary",
        "CrystalChamberFacilityPocket"
    )
    "client/scripts/ui/hud_map_presenter.gd" = @(
        "DemoMidfieldRoutePlayabilityFormatter.format_map_route_hint"
    )
    "client/scripts/ui/hud_status_presenter.gd" = @(
        "DemoMidfieldRoutePlayabilityFormatter.format_hud_summary"
    )
    "client/scripts/ui/interaction_prompt_formatter.gd" = @(
        "DemoMidfieldRoutePlayabilityFormatter.format_object_route_line",
        "DemoMidfieldRoutePlayabilityFormatter.format_static_object_route_line"
    )
    "client/scripts/systems/functional_scene_gameplay_formatter.gd" = @(
        "DemoMidfieldRoutePlayabilityFormatter.format_result_followup_line"
    )
    "client/scripts/checks/demo_midfield_route_playability_check.gd" = @(
        "Demo midfield route playability checks passed.",
        "_check_scene_layer_marks_midfield_route",
        "_check_hud_and_map_midfield_readouts",
        "_check_object_prompts_show_midfield_route",
        "_check_runtime_results_keep_midfield_followup"
    )
    "scripts/check-client.sh" = @(
        "check-client-demo-midfield-route-playability.py",
        "demo_midfield_route_playability_check.gd"
    )
    "scripts/check-client.ps1" = @(
        "check-client-demo-midfield-route-playability.ps1"
    )
    "scripts/check-client-flow.ps1" = @(
        "demo_midfield_route_playability_check.gd"
    )
}

$lineBudgetByFile = @{
    "client/scripts/map/vertical_slice_map.gd" = 1500
    "client/scripts/ui/interaction_prompt_formatter.gd" = 1500
    "client/scripts/systems/gather_system.gd" = 1500
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
            $errors.Add("${relativePath}: missing midfield route playability text '${requiredText}'")
        }
    }
}

foreach ($relativePath in $lineBudgetByFile.Keys) {
    $path = Join-Path $RepoRoot $relativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        $errors.Add("${relativePath}: missing file")
        continue
    }

    $lineCount = ((Get-Content -LiteralPath $path -Encoding UTF8) | Measure-Object -Line).Lines
    $maxLines = $lineBudgetByFile[$relativePath]
    if ($lineCount -ge $maxLines) {
        $errors.Add("${relativePath}: expected fewer than ${maxLines} lines, got ${lineCount}")
    }
}

if ($errors.Count -gt 0) {
    $errors | ForEach-Object { [Console]::Error.WriteLine($_) }
    exit 1
}

Write-Host "Client demo midfield route playability checks passed."
