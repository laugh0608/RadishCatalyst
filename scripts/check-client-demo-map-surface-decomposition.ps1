[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$requiredTextByFile = @{
    "docs/archive/features-demo-v1/demo-map-surface-decomposition-v1.md" = @(
        "Demo Map Surface Decomposition V1",
        "地图区域 / gate 承载面",
        "区域判断、gate 回退、回投坐标和对象区域归属由窄职责 helper 承载"
    )
    "client/scripts/map/vertical_slice_map_surface.gd" = @(
        "class_name VerticalSliceMapSurface",
        "static func get_region_id_for_position",
        "static func resolve_region_gate_block",
        "static func get_phase_relay_pad_return_position",
        "static func get_phase_return_anchor_return_position",
        "static func get_interactable_region_id"
    )
    "client/scripts/map/vertical_slice_map.gd" = @(
        "VerticalSliceMapSurface.resolve_region_gate_block",
        "VerticalSliceMapSurface.get_phase_relay_pad_return_position",
        "VerticalSliceMapSurface.get_phase_return_anchor_return_position",
        "VerticalSliceMapSurface.get_interactable_region_id",
        "VerticalSliceMapSurface.get_region_id_for_position"
    )
    "client/scripts/checks/demo_map_surface_decomposition_check.gd" = @(
        "Demo map surface decomposition checks passed.",
        "_check_region_resolution",
        "_check_gate_fallbacks",
        "_check_return_positions_and_object_regions"
    )
    "scripts/check-client.sh" = @(
        "check-client-demo-map-surface-decomposition.py",
        "demo_map_surface_decomposition_check.gd"
    )
    "scripts/check-client.ps1" = @(
        "check-client-demo-map-surface-decomposition.ps1"
    )
    "scripts/check-client-flow.ps1" = @(
        "demo_map_surface_decomposition_check.gd"
    )
}

$forbiddenTextByFile = @{
    "client/scripts/map/vertical_slice_map.gd" = @(
        "晶体矿脉区尚未标记：先检查前哨核心，恢复基础导航。",
        "遗迹外圈深段仍被抖动雾幕阻断：先回基地组装稳相信标，再返回部署。",
        "func _is_outer_ring_barrier_locked",
        "func _is_deep_ruin_gate_locked",
        "map_position.x >= DEMO_STABILIZATION_CORE_REGION_X"
    )
}

$lineBudgetByFile = @{
    "client/scripts/map/vertical_slice_map.gd" = 1425
}

$surfaceConstantNames = @(
    "CRYSTAL_REGION_X",
    "CRYSTAL_GATE_RETURN_X",
    "POLLUTION_REGION_X",
    "POLLUTION_DEEP_Y",
    "POLLUTION_GATE_RETURN_X",
    "RUIN_OUTER_RING_X",
    "RUIN_GATE_RETURN_X",
    "OUTER_RING_BARRIER_X",
    "OUTER_RING_BARRIER_RETURN_X",
    "DEEP_RUIN_REGION_X",
    "INNER_PHASE_WELL_REGION_X",
    "PHASE_WELL_SINK_REGION_X",
    "PHASE_WELL_CHAMBER_REGION_X",
    "PHASE_WELL_LOOM_REGION_X",
    "PHASE_WELL_FRAME_REGION_X",
    "PHASE_WELL_TETHER_REGION_X",
    "DEMO_STABILIZATION_CORE_REGION_X",
    "DEEP_RUIN_GATE_RETURN_X",
    "INNER_PHASE_WELL_GATE_RETURN_X",
    "PHASE_WELL_SINK_GATE_RETURN_X",
    "PHASE_WELL_CHAMBER_GATE_RETURN_X",
    "PHASE_WELL_LOOM_GATE_RETURN_X",
    "PHASE_WELL_FRAME_GATE_RETURN_X",
    "PHASE_WELL_TETHER_GATE_RETURN_X",
    "DEMO_STABILIZATION_CORE_GATE_RETURN_X",
    "PHASE_RELAY_PAD_FALLBACK_POSITION",
    "PHASE_RETURN_ANCHOR_FALLBACK_POSITION"
)

$expectedRegionIds = @(
    "region.outpost_platform",
    "region.crystal_vein_field",
    "region.pollution_edge",
    "region.ruin_outer_ring",
    "region.deep_ruin_threshold",
    "region.inner_phase_well",
    "region.phase_well_sink",
    "region.phase_well_chamber",
    "region.phase_well_loom",
    "region.phase_well_frame",
    "region.phase_well_tether",
    "region.demo_stabilization_core"
)

$errors = [System.Collections.Generic.List[string]]::new()

function Read-RepoText {
    param([string]$RelativePath)

    $path = Join-Path $RepoRoot $RelativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        $errors.Add("${RelativePath}: missing file")
        return ""
    }
    return Get-Content -LiteralPath $path -Raw -Encoding UTF8
}

function Get-GdscriptConstantValue {
    param(
        [string]$Content,
        [string]$ConstantName
    )

    $pattern = '(?m)^const\s+' + [regex]::Escape($ConstantName) + '\s*:=\s*(?<value>Vector2\([^)]+\)|-?\d+(?:\.\d+)?)$'
    $match = [regex]::Match($Content, $pattern)
    if (-not $match.Success) {
        return ""
    }
    return $match.Groups["value"].Value
}

foreach ($relativePath in $requiredTextByFile.Keys) {
    $content = Read-RepoText $relativePath
    if ($content.Length -eq 0) {
        continue
    }
    foreach ($requiredText in $requiredTextByFile[$relativePath]) {
        if (-not $content.Contains($requiredText)) {
            $errors.Add("${relativePath}: missing map surface decomposition text '${requiredText}'")
        }
    }
}

foreach ($relativePath in $forbiddenTextByFile.Keys) {
    $content = Read-RepoText $relativePath
    if ($content.Length -eq 0) {
        continue
    }
    foreach ($forbiddenText in $forbiddenTextByFile[$relativePath]) {
        if ($content.Contains($forbiddenText)) {
            $errors.Add("${relativePath}: should not contain '${forbiddenText}' after map surface decomposition")
        }
    }
}

foreach ($relativePath in $lineBudgetByFile.Keys) {
    $content = Read-RepoText $relativePath
    if ($content.Length -eq 0) {
        continue
    }
    $lineCount = ($content -split "`n").Count
    if ($content.EndsWith("`n")) {
        $lineCount -= 1
    }
    if ($lineCount -ge $lineBudgetByFile[$relativePath]) {
        $errors.Add("${relativePath}: expected fewer than $($lineBudgetByFile[$relativePath]) lines, got ${lineCount}")
    }
}

$mapContent = Read-RepoText "client/scripts/map/vertical_slice_map.gd"
$surfaceContent = Read-RepoText "client/scripts/map/vertical_slice_map_surface.gd"
if ($mapContent.Length -gt 0 -and $surfaceContent.Length -gt 0) {
    foreach ($constantName in $surfaceConstantNames) {
        $mapValue = Get-GdscriptConstantValue $mapContent $constantName
        $surfaceValue = Get-GdscriptConstantValue $surfaceContent $constantName
        if ($mapValue.Length -eq 0) {
            $errors.Add("client/scripts/map/vertical_slice_map.gd: missing public constant ${constantName}")
            continue
        }
        if ($surfaceValue.Length -eq 0) {
            $errors.Add("client/scripts/map/vertical_slice_map_surface.gd: missing helper constant ${constantName}")
            continue
        }
        if ($mapValue -ne $surfaceValue) {
            $errors.Add("${constantName}: map value ${mapValue} should match helper value ${surfaceValue}")
        }
    }

    $helperRegionIds = [regex]::Matches($surfaceContent, 'return "(region\.[^"]+)"') |
        ForEach-Object { $_.Groups[1].Value } |
        Sort-Object -Unique
    $expectedSorted = $expectedRegionIds | Sort-Object
    if (($helperRegionIds -join "|") -ne ($expectedSorted -join "|")) {
        $errors.Add("client/scripts/map/vertical_slice_map_surface.gd: expected 12 demo regions, got $($helperRegionIds -join ', ')")
    }
}

if ($errors.Count -gt 0) {
    foreach ($errorMessage in $errors) {
        Write-Error $errorMessage
    }
    exit 1
}

Write-Host "Client demo map surface decomposition checks passed."
