[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$requiredTextByFile = @{
    "docs/features/demo-runtime-surface-decomposition-v1.md" = @(
        "Demo Runtime Surface Decomposition V1",
        "运行时承载面拆分",
        "vertical_slice_flow_check.gd",
        "onboarding_hint_runtime_check.gd",
        "不新增资源、配方、区域、任务链、完整背包、完整装备栏或自动化物流"
    )
    "client/scripts/checks/onboarding_hint_runtime_check.gd" = @(
        "Onboarding hint runtime checks passed.",
        "HudHintPresenter",
        "VerticalSliceMapScene",
        "_expect_hint_contains"
    )
    "scripts/check-client.sh" = @(
        "check-client-demo-runtime-surface-decomposition.py",
        "onboarding_hint_runtime_check.gd"
    )
    "scripts/check-client.ps1" = @(
        "check-client-demo-runtime-surface-decomposition.ps1"
    )
    "scripts/check-client-flow.ps1" = @(
        "onboarding_hint_runtime_check.gd"
    )
}

$forbiddenTextByFile = @{
    "client/scripts/checks/vertical_slice_flow_check.gd" = @(
        "_check_onboarding_hints",
        "VerticalSliceMapScene"
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
            $errors.Add("${relativePath}: missing demo runtime surface decomposition text '${requiredText}'")
        }
    }
}

foreach ($relativePath in $forbiddenTextByFile.Keys) {
    $path = Join-Path $RepoRoot $relativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        $errors.Add("${relativePath}: missing file")
        continue
    }

    $content = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    foreach ($forbiddenText in $forbiddenTextByFile[$relativePath]) {
        if ($content.Contains($forbiddenText)) {
            $errors.Add("${relativePath}: should not contain '${forbiddenText}' after runtime surface decomposition")
        }
    }
}

if ($errors.Count -gt 0) {
    foreach ($errorMessage in $errors) {
        Write-Error $errorMessage
    }
    exit 1
}

Write-Host "Client demo runtime surface decomposition checks passed."
