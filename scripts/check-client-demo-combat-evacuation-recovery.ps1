[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$requiredTextByFile = @{
    "docs/archive/features-demo-v1/demo-combat-evacuation-recovery-v1.md" = @(
        "Demo Combat Evacuation Recovery V1",
        "战斗撤离恢复读法第一版",
        "不新增资源、配方、区域、任务链、敌人类型、完整背包或完整装备栏"
    )
    "client/scripts/systems/demo_combat_evacuation_recovery_formatter.gd" = @(
        "class_name DemoCombatEvacuationRecoveryFormatter",
        "build_feedback",
        "format_hud_summary",
        "format_map_route_hint",
        "format_outpost_core_recovery_line",
        "format_departure_gate_status_line"
    )
    "client/scripts/map/vertical_slice_map.gd" = @(
        "DemoCombatEvacuationRecoveryFormatter.build_feedback",
        "character_state.position = OUTPOST_RESPAWN_POSITION"
    )
    "client/scripts/ui/hud_feedback_presenter.gd" = @(
        "DemoCombatEvacuationRecoveryFormatter.format_panel_detail_lines"
    )
    "client/scripts/ui/hud_status_presenter.gd" = @(
        "DemoCombatEvacuationRecoveryFormatter.format_hud_summary"
    )
    "client/scripts/ui/hud_map_presenter.gd" = @(
        "DemoCombatEvacuationRecoveryFormatter.format_map_route_hint"
    )
    "client/scripts/ui/interaction_prompt_formatter.gd" = @(
        "DemoCombatEvacuationRecoveryFormatter.format_outpost_core_recovery_line",
        "DemoCombatEvacuationRecoveryFormatter.format_departure_gate_status_line",
        "DemoCombatEvacuationRecoveryFormatter.format_departure_gate_next_step"
    )
    "client/scripts/checks/demo_combat_evacuation_recovery_check.gd" = @(
        "Demo combat evacuation recovery checks passed.",
        "_check_pollution_protection_evacuation_recovery",
        "_check_deep_combat_evacuation_recovery",
        "_check_core_guard_evacuation_save_roundtrip"
    )
    "scripts/check-client.sh" = @(
        "check-client-demo-combat-evacuation-recovery.py",
        "demo_combat_evacuation_recovery_check.gd"
    )
    "scripts/check-client.ps1" = @(
        "check-client-demo-combat-evacuation-recovery.ps1"
    )
    "scripts/check-client-flow.ps1" = @(
        "demo_combat_evacuation_recovery_check.gd"
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
            $errors.Add("${relativePath}: missing demo combat evacuation recovery text '${requiredText}'")
        }
    }
}

if ($errors.Count -gt 0) {
    foreach ($errorMessage in $errors) {
        Write-Error $errorMessage
    }
    exit 1
}

Write-Host "Client demo combat evacuation recovery checks passed."
