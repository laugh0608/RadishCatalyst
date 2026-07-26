[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$requiredTextByFile = @{
    "docs/archive/features-demo-v1/demo-functional-transition-route-support-v1.md" = @(
        "Demo Functional Transition Route Support V1",
        "功能 / 过渡路线支撑",
        "封锁遗迹",
        "锚定桥"
    )
    "client/scripts/systems/functional_transition_route_support_formatter.gd" = @(
        "class_name FunctionalTransitionRouteSupportFormatter",
        "format_hud_summary",
        "format_map_route_hint",
        "format_object_route_line",
        "封锁遗迹机制展示线",
        "锚定桥稳定工程接入线"
    )
    "client/scripts/ui/hud_map_presenter.gd" = @(
        "FunctionalTransitionRouteSupportFormatter.format_map_route_hint"
    )
    "client/scripts/ui/hud_status_presenter.gd" = @(
        "FunctionalTransitionRouteSupportFormatter.format_hud_summary"
    )
    "client/scripts/ui/interaction_prompt_formatter.gd" = @(
        "FunctionalTransitionRouteSupportFormatter.format_object_route_line",
        "_with_functional_transition_line"
    )
    "client/scripts/checks/functional_transition_route_support_check.gd" = @(
        "Functional transition route support checks passed.",
        "_check_formatter_covers_functional_and_transition_regions",
        "_check_hud_and_map_readouts",
        "_check_object_prompts",
        "_check_region_count_boundary"
    )
    "scripts/check-client.sh" = @(
        "check-client-functional-transition-route-support.py",
        "functional_transition_route_support_check.gd"
    )
    "scripts/check-client-flow.ps1" = @(
        "functional_transition_route_support_check.gd"
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
            $errors.Add("${relativePath}: missing functional transition route support text '${requiredText}'")
        }
    }
}

if ($errors.Count -gt 0) {
    foreach ($errorMessage in $errors) {
        [Console]::Error.WriteLine($errorMessage)
    }
    exit 1
}

Write-Host "Client functional transition route support checks passed."
