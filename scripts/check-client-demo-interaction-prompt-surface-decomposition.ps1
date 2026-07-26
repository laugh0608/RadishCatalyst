[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$requiredTextByFile = @{
    "docs/archive/features-demo-v1/demo-interaction-prompt-surface-decomposition-v1.md" = @(
        "Demo Interaction Prompt Surface Decomposition V1",
        "交互提示承载面拆分",
        "加工设备交互提示"
    )
    "client/scripts/ui/processing_interaction_prompt_formatter.gd" = @(
        "class_name ProcessingInteractionPromptFormatter",
        "format_processing_prompt",
        "format_processing_log",
        "DemoRouteReturnAndBaseReentryFormatter.format_device_status_line"
    )
    "client/scripts/ui/interaction_prompt_formatter.gd" = @(
        "processing_prompt_formatter",
        "ProcessingInteractionPromptFormatter.new",
        "processing_prompt_formatter.format_processing_prompt",
        "processing_prompt_formatter.format_processing_log"
    )
    "client/scripts/checks/demo_interaction_prompt_surface_decomposition_check.gd" = @(
        "Demo interaction prompt surface decomposition checks passed.",
        "_check_processing_prompt_delegation",
        "_check_processing_prompt_keeps_base_reentry_line",
        "_check_processing_log_delegation"
    )
    "scripts/check-client.sh" = @(
        "check-client-demo-interaction-prompt-surface-decomposition.py",
        "demo_interaction_prompt_surface_decomposition_check.gd"
    )
    "scripts/check-client.ps1" = @(
        "check-client-demo-interaction-prompt-surface-decomposition.ps1"
    )
    "scripts/check-client-flow.ps1" = @(
        "demo_interaction_prompt_surface_decomposition_check.gd"
    )
}

$lineBudgetByFile = @{
    "client/scripts/ui/interaction_prompt_formatter.gd" = 1450
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
            $errors.Add("${relativePath}: missing interaction prompt surface text '${requiredText}'")
        }
    }
}

foreach ($relativePath in $lineBudgetByFile.Keys) {
    $path = Join-Path $RepoRoot $relativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        $errors.Add("${relativePath}: missing file")
        continue
    }
    $lineCount = (Get-Content -LiteralPath $path -Encoding UTF8).Count
    if ($lineCount -ge $lineBudgetByFile[$relativePath]) {
        $errors.Add("${relativePath}: expected fewer than $($lineBudgetByFile[$relativePath]) lines, got ${lineCount}")
    }
}

if ($errors.Count -gt 0) {
    foreach ($errorMessage in $errors) {
        Write-Error $errorMessage
    }
    exit 1
}

Write-Host "Client demo interaction prompt surface decomposition checks passed."
