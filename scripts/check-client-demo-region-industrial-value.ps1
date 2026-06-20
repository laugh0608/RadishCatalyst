[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$requiredTextByFile = @{
    "client/scripts/map/demo_region_industrial_value_layer.gd" = @(
        "class_name DemoRegionIndustrialValueLayer",
        "REGION_VALUE_PROFILES",
        "ROLE_RESOURCE",
        "ROLE_RISK",
        "ROLE_UNLOCK",
        "ROLE_STABILITY",
        "ROLE_LOGISTICS",
        "get_value_node_count",
        "is_region_value_route_visible",
        "industrial_value_role",
        "region.demo_stabilization_core"
    )
    "client/scenes/maps/VerticalSliceMap.tscn" = @(
        "DemoRegionIndustrialValueLayer",
        "demo_region_industrial_value_layer.gd"
    )
    "client/scripts/checks/demo_region_industrial_value_check.gd" = @(
        "Demo region industrial value checks passed.",
        "_check_region_industrial_value_layer_exists",
        "_check_region_value_roles_cover_twelve_regions",
        "_check_region_value_routes_stay_local",
        "_check_region_backgrounds_are_tagged",
        "_check_no_thirteenth_region_is_added"
    )
    "docs/devlogs/2026-W25.md" = @(
        "12 区工业职责",
        "DemoRegionIndustrialValueLayer"
    )
    "scripts/check-client.sh" = @(
        "check-client-demo-region-industrial-value.py",
        "demo_region_industrial_value_check.gd"
    )
    "scripts/check-client.ps1" = @(
        "check-client-demo-region-industrial-value.ps1"
    )
    "scripts/check-client-flow.ps1" = @(
        "demo_region_industrial_value_check.gd"
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
            $errors.Add("${relativePath}: missing demo region industrial value text '${requiredText}'")
        }
    }
}

if ($errors.Count -gt 0) {
    foreach ($errorMessage in $errors) {
        Write-Error $errorMessage
    }
    exit 1
}

Write-Host "Client demo region industrial value checks passed."
