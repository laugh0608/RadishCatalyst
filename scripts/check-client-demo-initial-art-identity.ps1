[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$requiredTextByFile = @{
    "docs/features/demo-initial-art-identity-v1.md" = @(
        "Demo Initial Art Identity V1",
        "初步美术识别与设备现场表现第一包",
        "DemoInitialArtIdentityLayer",
        "demo_initial_art_identity_check.gd"
    )
    "docs/features/demo-playable-content-substance-v1.md" = @(
        "初步美术识别与设备现场表现第一包",
        "DemoInitialArtIdentityLayer",
        "不新增第 13 区域"
    )
    "client/scripts/systems/demo_initial_art_identity_profile.gd" = @(
        "class_name DemoInitialArtIdentityProfile",
        "ROLE_DEVICE",
        "MATERIAL_REACTOR_HEAT",
        "identity.demo_stabilization_core"
    )
    "client/scripts/map/demo_initial_art_identity_layer.gd" = @(
        "class_name DemoInitialArtIdentityLayer",
        "GENERATED_IDENTITY_PREFIX",
        "apply_profile",
        "get_generated_shape_count"
    )
    "client/scenes/maps/VerticalSliceMap.tscn" = @(
        "DemoInitialArtIdentityLayer",
        "demo_initial_art_identity_layer.gd"
    )
    "client/scripts/checks/demo_initial_art_identity_check.gd" = @(
        "Demo initial art identity checks passed.",
        "_check_profile_scope_and_boundaries",
        "_check_scene_layer_applies_identity_shapes",
        "_check_representative_scene_nodes_are_tagged"
    )
    "scripts/check-client.sh" = @(
        "check-client-demo-initial-art-identity.py",
        "demo_initial_art_identity_check.gd"
    )
    "scripts/check-client.ps1" = @(
        "check-client-demo-initial-art-identity.ps1"
    )
    "scripts/check-client-flow.ps1" = @(
        "demo_initial_art_identity_check.gd"
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
            $errors.Add("${relativePath}: missing demo initial art identity text '${requiredText}'")
        }
    }
}

if ($errors.Count -gt 0) {
    foreach ($errorMessage in $errors) {
        Write-Error $errorMessage
    }
    exit 1
}

Write-Host "Client demo initial art identity checks passed."
