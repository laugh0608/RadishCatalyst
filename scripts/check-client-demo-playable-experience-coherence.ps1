[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$requiredTextByFile = @{
    "docs/features/demo-playable-experience-coherence-v1.md" = @(
        "Demo Playable Experience Coherence V1",
        "整段体验连贯性",
        "不新增资源、配方、区域、任务链、完整背包或完整装备栏"
    )
    "client/scripts/save/development_baseline_catalog.gd" = @(
        "baseline.s22_demo_completion_outpost_review",
        "S22 Demo 完成后前哨整理"
    )
    "client/scripts/save/development_baseline_builder.gd" = @(
        "baseline.s22_demo_completion_outpost_review",
        "DevelopmentBaselineDemoCompletionState.apply"
    )
    "client/scripts/save/development_baseline_demo_completion_state.gd" = @(
        "class_name DevelopmentBaselineDemoCompletionState",
        "_apply_demo_quest_state",
        "DemoFieldLoopPayoffFormatter.mark_payoff_confirmed"
    )
    "client/scripts/checks/demo_playable_experience_coherence_check.gd" = @(
        "Demo playable experience coherence checks passed.",
        "_check_new_game_checkpoint",
        "_check_outer_ring_checkpoint",
        "_check_core_entry_checkpoint",
        "_check_completed_outpost_review_checkpoint",
        "_check_completed_review_save_roundtrip"
    )
    "scripts/check-client.sh" = @(
        "check-client-demo-playable-experience-coherence.py",
        "demo_playable_experience_coherence_check.gd"
    )
    "scripts/check-client.ps1" = @(
        "check-client-demo-playable-experience-coherence.ps1"
    )
    "scripts/check-client-flow.ps1" = @(
        "demo_playable_experience_coherence_check.gd"
    )
}

$errors = New-Object System.Collections.Generic.List[string]
foreach ($relativePath in $requiredTextByFile.Keys) {
    $path = Join-Path $RepoRoot $relativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        $errors.Add("${relativePath}: missing file")
        continue
    }
    $content = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    foreach ($requiredText in $requiredTextByFile[$relativePath]) {
        if (-not $content.Contains($requiredText)) {
            $errors.Add("${relativePath}: missing demo playable experience coherence text '${requiredText}'")
        }
    }
}

if ($errors.Count -gt 0) {
    $errors | ForEach-Object { [Console]::Error.WriteLine($_) }
    exit 1
}

Write-Host "Client demo playable experience coherence checks passed."
