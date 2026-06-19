[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$requiredTextByFile = @{
    "docs/features/demo-action-blocker-recovery-v1.md" = @(
        "Demo Action Blocker Recovery V1",
        "第一包实施范围",
        "DemoActionBlockerRecoveryFormatter",
        "不新增 UI 面板、存档 schema、资源、配方、区域、任务链、敌人类型、完整背包或完整装备栏"
    )
    "client/scripts/systems/demo_action_blocker_recovery_formatter.gd" = @(
        "class_name DemoActionBlockerRecoveryFormatter",
        "format_interaction_prerequisite_failure",
        "format_already_processed_failure",
        "format_build_prerequisite_failure",
        "format_build_material_failure",
        "format_processing_missing_input_failure",
        "format_processing_busy_failure",
        "format_supply_failure",
        "format_core_write_failure"
    )
    "client/scripts/systems/gather_system.gd" = @(
        "DemoActionBlockerRecoveryFormatter.format_already_processed_failure",
        "DemoActionBlockerRecoveryFormatter.format_core_write_failure",
        "DemoActionBlockerRecoveryFormatter.format_interaction_prerequisite_failure"
    )
    "client/scripts/systems/build_system.gd" = @(
        "DemoActionBlockerRecoveryFormatter.format_build_prerequisite_failure",
        "DemoActionBlockerRecoveryFormatter.format_build_material_failure"
    )
    "client/scripts/systems/processing_system.gd" = @(
        "DemoActionBlockerRecoveryFormatter.format_processing_missing_input_failure",
        "DemoActionBlockerRecoveryFormatter.format_processing_busy_failure"
    )
    "client/scripts/state/character_state.gd" = @(
        "DemoActionBlockerRecoveryFormatter.format_supply_failure",
        '"failure_feedback": failure_feedback'
    )
    "client/scripts/game/game_root.gd" = @(
        "hud_log_presenter.format_result_log(result)"
    )
    "client/scripts/checks/demo_action_blocker_recovery_check.gd" = @(
        "Demo action blocker recovery checks passed.",
        "_check_gather_and_sample_prerequisite_blockers",
        "_check_already_processed_object_blocker",
        "_check_build_blockers",
        "_check_processing_blockers",
        "_check_supply_blockers",
        "_check_core_write_blockers"
    )
    "scripts/check-client.sh" = @(
        "check-client-demo-action-blocker-recovery.py",
        "demo_action_blocker_recovery_check.gd"
    )
    "scripts/check-client.ps1" = @(
        "check-client-demo-action-blocker-recovery.ps1"
    )
    "scripts/check-client-flow.ps1" = @(
        "demo_action_blocker_recovery_check.gd"
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
            $errors.Add("${relativePath}: missing demo action blocker recovery text '${requiredText}'")
        }
    }
}

if ($errors.Count -gt 0) {
    foreach ($errorMessage in $errors) {
        Write-Error $errorMessage
    }
    exit 1
}

Write-Host "Client demo action blocker recovery checks passed."
