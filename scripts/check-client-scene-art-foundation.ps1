[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$requiredTextByFile = @{
    "client/scripts/systems/scene_art_foundation_formatter.gd" = @(
        "class_name SceneArtFoundationFormatter",
        "format_hud_summary",
        "format_map_route_hint",
        "format_object_scene_line",
        "基地整备回路",
        "晶体矿脉资源线",
        "污染边界过滤线",
        "核心稳定站终点"
    )
    "client/scenes/maps/VerticalSliceMap.tscn" = @(
        "SceneArtFoundationLayer",
        "SceneArtBaseIdentityLabel",
        "SceneArtCrystalIdentityLabel",
        "SceneArtPollutionIdentityLabel",
        "SceneArtCoreIdentityLabel"
    )
    "client/scripts/ui/hud_map_presenter.gd" = @(
        "SceneArtFoundationFormatter.format_map_route_hint"
    )
    "client/scripts/ui/hud_status_presenter.gd" = @(
        "SceneArtFoundationFormatter.format_hud_summary"
    )
    "client/scripts/ui/interaction_prompt_formatter.gd" = @(
        "SceneArtFoundationFormatter.format_object_scene_line"
    )
    "client/scripts/checks/scene_art_foundation_check.gd" = @(
        "Scene art foundation checks passed.",
        "_check_scene_identity_layer",
        "_check_formatter_core_regions",
        "_check_hud_and_map_readouts",
        "_check_object_prompts"
    )
    "scripts/check-client.sh" = @(
        "check-client-scene-art-foundation.py",
        "scene_art_foundation_check.gd"
    )
    "scripts/check-client-flow.ps1" = @(
        "scene_art_foundation_check.gd"
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
            $errors.Add("${relativePath}: missing scene art foundation text '${requiredText}'")
        }
    }
}

if ($errors.Count -gt 0) {
    foreach ($errorMessage in $errors) {
        Write-Error $errorMessage
    }
    exit 1
}

Write-Host "Client scene art foundation checks passed."
