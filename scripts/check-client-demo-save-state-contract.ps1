[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$requiredTextByFile = @{
    "docs/features/demo-save-state-contract-v1.md" = @(
        "Demo Save State Contract V1",
        "存档 / 状态",
        "世界、角色、库存、建筑、任务、区域、敌人",
        "不新增资源、配方、区域、任务链、完整背包、完整装备栏或自动化物流"
    )
    "client/scripts/checks/demo_save_state_contract_check.gd" = @(
        "Demo save state contract checks passed.",
        "_check_demo_main_path_roundtrip",
        "_check_contract_validation_rejects_display_name_region",
        "_check_contract_validation_rejects_enemy_source_mismatch",
        "SaveService",
        "DevelopmentBaselineBuilder",
        "DemoResourceChainStateFormatter"
    )
    "scripts/check-client.sh" = @(
        "check-client-demo-save-state-contract.py",
        "demo_save_state_contract_check.gd"
    )
    "scripts/check-client.ps1" = @(
        "check-client-demo-save-state-contract.ps1"
    )
    "scripts/check-client-flow.ps1" = @(
        "demo_save_state_contract_check.gd"
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
            $errors.Add("${relativePath}: missing demo save state contract text '${requiredText}'")
        }
    }
}

if ($errors.Count -gt 0) {
    foreach ($errorMessage in $errors) {
        Write-Error $errorMessage
    }
    exit 1
}

Write-Host "Client demo save state contract checks passed."
