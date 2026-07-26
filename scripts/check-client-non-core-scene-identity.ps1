[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$requiredTextByFile = @{
    "docs/archive/features-demo-v1/demo-non-core-scene-identity-v1.md" = @(
        "Demo Non-Core Scene Identity V1",
        "非核心区域场景识别",
        "封锁遗迹",
        "锚定桥"
    )
    "client/scripts/systems/non_core_scene_identity_formatter.gd" = @(
        "class_name NonCoreSceneIdentityFormatter",
        "format_map_route_hint",
        "format_object_scene_line",
        "封锁遗迹旧设施区",
        "锚定桥稳定接入区"
    )
    "client/scenes/maps/VerticalSliceMap.tscn" = @(
        "NonCoreSceneIdentityLayer",
        "NonCoreRuinIdentityLabel",
        "NonCoreRidgeIdentityLabel",
        "NonCoreAnchorBridgeIdentityLabel"
    )
    "client/scripts/ui/hud_map_presenter.gd" = @(
        "NonCoreSceneIdentityFormatter.format_map_route_hint"
    )
    "client/scripts/ui/interaction_prompt_formatter.gd" = @(
        "NonCoreSceneIdentityFormatter.format_object_scene_line"
    )
    "client/scripts/checks/non_core_scene_identity_check.gd" = @(
        "Non-core scene identity checks passed.",
        "_check_scene_identity_layer",
        "_check_formatter_non_core_regions",
        "_check_hud_and_map_readouts",
        "_check_object_prompts"
    )
    "scripts/check-client.sh" = @(
        "check-client-non-core-scene-identity.py",
        "non_core_scene_identity_check.gd"
    )
    "scripts/check-client-flow.ps1" = @(
        "non_core_scene_identity_check.gd"
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
            $errors.Add("${relativePath}: missing non-core scene identity text '${requiredText}'")
        }
    }
}

if ($errors.Count -gt 0) {
    foreach ($errorMessage in $errors) {
        [Console]::Error.WriteLine($errorMessage)
    }
    exit 1
}

Write-Host "Client non-core scene identity checks passed."
