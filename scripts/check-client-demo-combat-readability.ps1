[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$requiredTextByFile = @{
    "docs/features/demo-playable-content-substance-v1.md" = @(
        "角色 / 怪物 UI 第一包",
        "DemoCombatReadabilityFormatter",
        "demo_combat_readability_check.gd",
        "战斗现场",
        "不新增第 13 区域"
    )
    "client/scripts/systems/demo_combat_readability_formatter.gd" = @(
        "class_name DemoCombatReadabilityFormatter",
        "format_panel_text",
        "format_hit_feedback",
        "format_enemy_threat_label",
        "生命 / 防护承压"
    )
    "client/scripts/ui/prototype_hud.gd" = @(
        "update_combat_readability",
        "show_combat_feedback",
        "CombatPanel",
        "DemoCombatReadabilityFormatter.format_panel_text"
    )
    "client/scripts/map/vertical_slice_map.gd" = @(
        "get_current_combat_target",
        "combat_feedback",
        "DemoCombatReadabilityFormatter.format_hit_feedback"
    )
    "client/scripts/actors/prototype_enemy.gd" = @(
        "configure_readability_tags",
        "get_combat_status_label",
        "readability_threat_label"
    )
    "client/scripts/checks/demo_combat_readability_check.gd" = @(
        "Demo combat readability checks passed.",
        "_check_formatter_exposes_player_enemy_and_supply_state",
        "_check_attack_result_carries_combat_feedback",
        "_check_hud_panel_uses_current_target_and_recent_feedback"
    )
    "scripts/check-client.sh" = @(
        "check-client-demo-combat-readability.py",
        "demo_combat_readability_check.gd"
    )
    "scripts/check-client.ps1" = @(
        "check-client-demo-combat-readability.ps1"
    )
    "scripts/check-client-flow.ps1" = @(
        "demo_combat_readability_check.gd"
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
            $errors.Add("${relativePath}: missing demo combat readability text '${requiredText}'")
        }
    }
}

if ($errors.Count -gt 0) {
    foreach ($errorMessage in $errors) {
        Write-Error $errorMessage
    }
    exit 1
}

Write-Host "Client demo combat readability checks passed."
