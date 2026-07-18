[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$requiredTextByFile = @{
    "docs/archive/features-demo-v1/demo-supply-pressure-pacing-v1.md" = @(
        "Demo Supply Pressure Pacing V1",
        "补给节奏与承压价值",
        "demo_supply_pressure_pacing_check.gd",
        "不新增资源、配方、区域、任务链、UI 面板、目标箭头或同类 HUD 提示"
    )
    "client/scripts/checks/demo_supply_pressure_pacing_check.gd" = @(
        "Demo supply pressure pacing checks passed.",
        "_check_repair_gel_craft_and_treatment_pressure_value",
        "_check_resistance_vial_craft_and_gate_pressure_value",
        "_check_outpost_core_restocks_pressure_vial",
        "_check_core_write_pressure_uses_vial"
    )
    "scripts/check-client.sh" = @(
        "check-client-demo-supply-pressure-pacing.py",
        "demo_supply_pressure_pacing_check.gd"
    )
    "scripts/check-client.ps1" = @(
        "check-client-demo-supply-pressure-pacing.ps1"
    )
    "scripts/check-client-flow.ps1" = @(
        "demo_supply_pressure_pacing_check.gd"
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
            $errors.Add("${relativePath}: missing demo supply pressure pacing text '${requiredText}'")
        }
    }
}

if ($errors.Count -gt 0) {
    foreach ($errorMessage in $errors) {
        Write-Error $errorMessage
    }
    exit 1
}

Write-Host "Client demo supply pressure pacing checks passed."
