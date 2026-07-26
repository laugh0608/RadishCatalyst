[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$requiredTextByFile = @{
    "docs/archive/features-demo-v1/demo-core-scene-playable-space-v1.md" = @(
        "Demo Core Scene Playable Space V1",
        "核心场景空间第一包",
        "DemoCoreSceneSpaceLayer",
        "demo_core_scene_playable_space_check.gd"
    )
    "docs/archive/features-demo-v1/demo-playable-content-substance-v1.md" = @(
        "核心场景空间第一包",
        "DemoCoreSceneSpaceProfile",
        "DemoCoreSceneSpaceLayer",
        "不新增第 13 区域"
    )
    "client/scripts/systems/demo_core_scene_space_profile.gd" = @(
        "class_name DemoCoreSceneSpaceProfile",
        "ROLE_GROUND",
        "ROLE_OBJECT_ANCHOR",
        "region.demo_stabilization_core"
    )
    "client/scripts/map/demo_core_scene_space_layer.gd" = @(
        "class_name DemoCoreSceneSpaceLayer",
        "GENERATED_FRAME_PREFIX",
        "FOCUSED_FRAME_ALPHA",
        "apply_profile",
        "refresh_frame_focus",
        "get_muted_frame_count",
        "get_tagged_node_count"
    )
    "client/scenes/maps/VerticalSliceMap.tscn" = @(
        "DemoCoreSceneSpaceLayer",
        "demo_core_scene_space_layer.gd"
    )
    "client/scripts/checks/demo_core_scene_playable_space_check.gd" = @(
        "Demo core scene playable space checks passed.",
        "_check_profile_covers_core_regions_without_expansion",
        "_check_scene_space_layer_applies_roles",
        "_check_scene_space_frames_step_back_in_workfaces",
        "_check_representative_objects_and_enemies_sit_on_space_surfaces"
    )
    "scripts/check-client.sh" = @(
        "check-client-demo-core-scene-playable-space.py",
        "demo_core_scene_playable_space_check.gd"
    )
    "scripts/check-client.ps1" = @(
        "check-client-demo-core-scene-playable-space.ps1"
    )
    "scripts/check-client-flow.ps1" = @(
        "demo_core_scene_playable_space_check.gd"
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
            $errors.Add("${relativePath}: missing demo core scene playable space text '${requiredText}'")
        }
    }
}

if ($errors.Count -gt 0) {
    foreach ($errorMessage in $errors) {
        Write-Error $errorMessage
    }
    exit 1
}

Write-Host "Client demo core scene playable space checks passed."
