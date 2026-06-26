[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$requiredTextByFile = @{
    "docs/features/demo-quick-slot-supply-readability-v1.md" = @(
        "Demo Quick Slot Supply Readability V1",
        "快捷补给读法",
        "DemoQuickSlotSupplyReadabilityFormatter",
        "demo_quick_slot_supply_readability_check.gd",
        "不新增资源、配方、区域、任务链、完整背包或完整装备栏"
    )
    "client/scripts/systems/demo_quick_slot_supply_readability_formatter.gd" = @(
        "class_name DemoQuickSlotSupplyReadabilityFormatter",
        "format_quick_slot_summary",
        "缺:反应器",
        "缺:过滤器",
        "生命低可用",
        "防护低可用"
    )
    "client/scripts/ui/hud_status_presenter.gd" = @(
        "DemoQuickSlotSupplyReadabilityFormatter.format_quick_slot_summary",
        "format_player_quick_supply_text"
    )
    "client/scripts/ui/prototype_hud.gd" = @(
        "quick_supply_panel",
        "quick_supply_label",
        "action_summary_panel",
        "action_summary_label",
        "format_player_quick_supply_text"
    )
    "client/scenes/ui/PrototypeHud.tscn" = @(
        "QuickSupplyPanel",
        "QuickSupplyLabel",
        "ActionSummaryPanel",
        "ActionSummaryLabel"
    )
    "client/scripts/checks/demo_quick_slot_supply_readability_check.gd" = @(
        "Demo quick slot supply readability checks passed.",
        "_check_default_quick_slot_readability",
        "_check_default_hud_action_summary_surface",
        "_check_pressure_quick_slot_readability",
        "_check_supply_success_updates_readability",
        "_check_supply_failure_keeps_recovery_route"
    )
    "scripts/check-client.sh" = @(
        "check-client-demo-quick-slot-supply-readability.py",
        "demo_quick_slot_supply_readability_check.gd"
    )
    "scripts/check-client.ps1" = @(
        "check-client-demo-quick-slot-supply-readability.ps1"
    )
    "scripts/check-client-flow.ps1" = @(
        "demo_quick_slot_supply_readability_check.gd"
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
            $errors.Add("${relativePath}: missing demo quick slot supply readability text '${requiredText}'")
        }
    }
}

if ($errors.Count -gt 0) {
    foreach ($errorMessage in $errors) {
        Write-Error $errorMessage
    }
    exit 1
}

Write-Host "Client demo quick slot supply readability checks passed."
