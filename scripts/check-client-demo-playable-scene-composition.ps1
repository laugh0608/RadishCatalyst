[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$requiredTextByFile = @{
    "docs/features/demo-playable-scene-composition-v1.md" = @(
        "Demo Playable Scene Composition V1",
        "可玩场景构成",
        "不新增资源、配方、区域、任务链、完整背包或完整装备栏"
    )
    "client/scripts/systems/playable_scene_composition_formatter.gd" = @(
        "class_name PlayableSceneCompositionFormatter",
        "format_map_route_hint",
        "format_object_composition_line",
        "前哨平台构成",
        "锚定桥构成",
        "核心稳定站构成"
    )
    "client/scripts/ui/hud_map_presenter.gd" = @(
        "PlayableSceneCompositionFormatter.format_map_route_hint"
    )
    "client/scripts/ui/interaction_prompt_formatter.gd" = @(
        "PlayableSceneCompositionFormatter.format_object_composition_line"
    )
    "client/scripts/checks/playable_scene_composition_check.gd" = @(
        "Playable scene composition checks passed.",
        "_check_formatter_region_coverage",
        "_check_map_route_composition",
        "_check_object_prompt_composition",
        "_check_scene_object_region_placement"
    )
    "scripts/check-client.sh" = @(
        "check-client-demo-playable-scene-composition.py",
        "playable_scene_composition_check.gd"
    )
    "scripts/check-client.ps1" = @(
        "check-client-demo-playable-scene-composition.ps1"
    )
    "scripts/check-client-flow.ps1" = @(
        "playable_scene_composition_check.gd"
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
            $errors.Add("${relativePath}: missing playable scene composition text '${requiredText}'")
        }
    }
}

if ($errors.Count -gt 0) {
    foreach ($errorMessage in $errors) {
        Write-Error $errorMessage
    }
    exit 1
}

Write-Host "Client demo playable scene composition checks passed."
