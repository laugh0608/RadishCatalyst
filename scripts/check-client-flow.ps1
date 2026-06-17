[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [string]$GodotExe = ""
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "Resolve-GodotExe.ps1")
$GodotExe = Resolve-GodotExe -GodotExe $GodotExe

if (-not (Test-Path -LiteralPath $GodotExe -PathType Leaf)) {
    Write-Error "Godot executable not found: ${GodotExe}"
    exit 1
}

$clientRoot = Join-Path $RepoRoot "client"
if (-not (Test-Path -LiteralPath (Join-Path $clientRoot "project.godot") -PathType Leaf)) {
    Write-Error "Godot project not found: ${clientRoot}"
    exit 1
}

$checkScript = Join-Path $clientRoot "scripts/checks/vertical_slice_flow_check.gd"
if (-not (Test-Path -LiteralPath $checkScript -PathType Leaf)) {
    Write-Error "Vertical slice flow check script not found: ${checkScript}"
    exit 1
}
$onboardingHintRuntimeCheckScript = Join-Path $clientRoot "scripts/checks/onboarding_hint_runtime_check.gd"
if (-not (Test-Path -LiteralPath $onboardingHintRuntimeCheckScript -PathType Leaf)) {
    Write-Error "Onboarding hint runtime check script not found: ${onboardingHintRuntimeCheckScript}"
    exit 1
}
$functionalSceneGameplayCheckScript = Join-Path $clientRoot "scripts/checks/functional_scene_gameplay_check.gd"
if (-not (Test-Path -LiteralPath $functionalSceneGameplayCheckScript -PathType Leaf)) {
    Write-Error "Functional scene gameplay check script not found: ${functionalSceneGameplayCheckScript}"
    exit 1
}
$demoFieldLoopPayoffCheckScript = Join-Path $clientRoot "scripts/checks/demo_field_loop_payoff_check.gd"
if (-not (Test-Path -LiteralPath $demoFieldLoopPayoffCheckScript -PathType Leaf)) {
    Write-Error "Demo field loop payoff check script not found: ${demoFieldLoopPayoffCheckScript}"
    exit 1
}
$industrialTechSpineCheckScript = Join-Path $clientRoot "scripts/checks/industrial_tech_spine_check.gd"
if (-not (Test-Path -LiteralPath $industrialTechSpineCheckScript -PathType Leaf)) {
    Write-Error "Industrial tech spine check script not found: ${industrialTechSpineCheckScript}"
    exit 1
}
$demoResourceChainStateCheckScript = Join-Path $clientRoot "scripts/checks/demo_resource_chain_state_check.gd"
if (-not (Test-Path -LiteralPath $demoResourceChainStateCheckScript -PathType Leaf)) {
    Write-Error "Demo resource chain state check script not found: ${demoResourceChainStateCheckScript}"
    exit 1
}
$demoSaveStateContractCheckScript = Join-Path $clientRoot "scripts/checks/demo_save_state_contract_check.gd"
if (-not (Test-Path -LiteralPath $demoSaveStateContractCheckScript -PathType Leaf)) {
    Write-Error "Demo save state contract check script not found: ${demoSaveStateContractCheckScript}"
    exit 1
}
$demoMainPathContinuityCheckScript = Join-Path $clientRoot "scripts/checks/demo_main_path_continuity_check.gd"
if (-not (Test-Path -LiteralPath $demoMainPathContinuityCheckScript -PathType Leaf)) {
    Write-Error "Demo main path continuity check script not found: ${demoMainPathContinuityCheckScript}"
    exit 1
}
$sceneArtFoundationCheckScript = Join-Path $clientRoot "scripts/checks/scene_art_foundation_check.gd"
if (-not (Test-Path -LiteralPath $sceneArtFoundationCheckScript -PathType Leaf)) {
    Write-Error "Scene art foundation check script not found: ${sceneArtFoundationCheckScript}"
    exit 1
}
$nonCoreSceneIdentityCheckScript = Join-Path $clientRoot "scripts/checks/non_core_scene_identity_check.gd"
if (-not (Test-Path -LiteralPath $nonCoreSceneIdentityCheckScript -PathType Leaf)) {
    Write-Error "Non-core scene identity check script not found: ${nonCoreSceneIdentityCheckScript}"
    exit 1
}
$functionalTransitionRouteSupportCheckScript = Join-Path $clientRoot "scripts/checks/functional_transition_route_support_check.gd"
if (-not (Test-Path -LiteralPath $functionalTransitionRouteSupportCheckScript -PathType Leaf)) {
    Write-Error "Functional transition route support check script not found: ${functionalTransitionRouteSupportCheckScript}"
    exit 1
}
$demoMainlineCompletionCheckScript = Join-Path $clientRoot "scripts/checks/demo_mainline_completion_check.gd"
if (-not (Test-Path -LiteralPath $demoMainlineCompletionCheckScript -PathType Leaf)) {
    Write-Error "Demo mainline completion check script not found: ${demoMainlineCompletionCheckScript}"
    exit 1
}
$demoProtectiveResponseCheckScript = Join-Path $clientRoot "scripts/checks/demo_protective_response_check.gd"
if (-not (Test-Path -LiteralPath $demoProtectiveResponseCheckScript -PathType Leaf)) {
    Write-Error "Demo protective response check script not found: ${demoProtectiveResponseCheckScript}"
    exit 1
}
$demoToolStrikeCalibrationCheckScript = Join-Path $clientRoot "scripts/checks/demo_tool_strike_calibration_check.gd"
if (-not (Test-Path -LiteralPath $demoToolStrikeCalibrationCheckScript -PathType Leaf)) {
    Write-Error "Demo tool strike calibration check script not found: ${demoToolStrikeCalibrationCheckScript}"
    exit 1
}

$godotRunId = "vertical-slice-flow-{0}-{1}" -f $PID, [DateTime]::UtcNow.ToString("yyyyMMddHHmmssfff")
$godotHome = Join-Path (Join-Path $RepoRoot ".godot-check-runs") $godotRunId
$godotConfigHome = Join-Path $godotHome "config"
$godotDataHome = Join-Path $godotHome "data"
$godotCacheHome = Join-Path $godotHome "cache"
$godotAppData = Join-Path $godotDataHome "Roaming"
$godotLocalAppData = Join-Path $godotCacheHome "Local"
New-Item -ItemType Directory -Force -Path $godotConfigHome, $godotDataHome, $godotCacheHome | Out-Null
New-Item -ItemType Directory -Force -Path $godotAppData, $godotLocalAppData | Out-Null

Push-Location $clientRoot
try {
    $previousXdgConfigHome = $env:XDG_CONFIG_HOME
    $previousXdgDataHome = $env:XDG_DATA_HOME
    $previousXdgCacheHome = $env:XDG_CACHE_HOME
    $previousAppData = $env:APPDATA
    $previousLocalAppData = $env:LOCALAPPDATA

    $env:XDG_CONFIG_HOME = $godotConfigHome
    $env:XDG_DATA_HOME = $godotDataHome
    $env:XDG_CACHE_HOME = $godotCacheHome
    $env:APPDATA = $godotAppData
    $env:LOCALAPPDATA = $godotLocalAppData

    $importOutput = & $GodotExe --headless --path $clientRoot --import --quit --no-header 2>&1
    if ($LASTEXITCODE -ne 0) {
        $importOutput | ForEach-Object { [Console]::Error.WriteLine($_) }
        Write-Error "Godot import before vertical slice flow check failed with exit code ${LASTEXITCODE}."
        exit $LASTEXITCODE
    }

    $checkOutput = & $GodotExe --headless --path $clientRoot --script $checkScript --no-header 2>&1
    if ($LASTEXITCODE -ne 0) {
        $checkOutput | ForEach-Object { [Console]::Error.WriteLine($_) }
        Write-Error "Vertical slice flow check failed with exit code ${LASTEXITCODE}."
        exit $LASTEXITCODE
    }

    $onboardingHintOutput = & $GodotExe --headless --path $clientRoot --script $onboardingHintRuntimeCheckScript --no-header 2>&1
    if ($LASTEXITCODE -ne 0) {
        $onboardingHintOutput | ForEach-Object { [Console]::Error.WriteLine($_) }
        Write-Error "Onboarding hint runtime check failed with exit code ${LASTEXITCODE}."
        exit $LASTEXITCODE
    }

    $functionalSceneGameplayOutput = & $GodotExe --headless --path $clientRoot --script $functionalSceneGameplayCheckScript --no-header 2>&1
    if ($LASTEXITCODE -ne 0) {
        $functionalSceneGameplayOutput | ForEach-Object { [Console]::Error.WriteLine($_) }
        Write-Error "Functional scene gameplay check failed with exit code ${LASTEXITCODE}."
        exit $LASTEXITCODE
    }

    $demoFieldLoopPayoffOutput = & $GodotExe --headless --path $clientRoot --script $demoFieldLoopPayoffCheckScript --no-header 2>&1
    if ($LASTEXITCODE -ne 0) {
        $demoFieldLoopPayoffOutput | ForEach-Object { [Console]::Error.WriteLine($_) }
        Write-Error "Demo field loop payoff check failed with exit code ${LASTEXITCODE}."
        exit $LASTEXITCODE
    }

    $industrialCheckOutput = & $GodotExe --headless --path $clientRoot --script $industrialTechSpineCheckScript --no-header 2>&1
    if ($LASTEXITCODE -ne 0) {
        $industrialCheckOutput | ForEach-Object { [Console]::Error.WriteLine($_) }
        Write-Error "Industrial tech spine check failed with exit code ${LASTEXITCODE}."
        exit $LASTEXITCODE
    }

    $resourceChainOutput = & $GodotExe --headless --path $clientRoot --script $demoResourceChainStateCheckScript --no-header 2>&1
    if ($LASTEXITCODE -ne 0) {
        $resourceChainOutput | ForEach-Object { [Console]::Error.WriteLine($_) }
        Write-Error "Demo resource chain state check failed with exit code ${LASTEXITCODE}."
        exit $LASTEXITCODE
    }

    $saveContractOutput = & $GodotExe --headless --path $clientRoot --script $demoSaveStateContractCheckScript --no-header 2>&1
    if ($LASTEXITCODE -ne 0) {
        $saveContractOutput | ForEach-Object { [Console]::Error.WriteLine($_) }
        Write-Error "Demo save state contract check failed with exit code ${LASTEXITCODE}."
        exit $LASTEXITCODE
    }

    $mainPathContinuityOutput = & $GodotExe --headless --path $clientRoot --script $demoMainPathContinuityCheckScript --no-header 2>&1
    if ($LASTEXITCODE -ne 0) {
        $mainPathContinuityOutput | ForEach-Object { [Console]::Error.WriteLine($_) }
        Write-Error "Demo main path continuity check failed with exit code ${LASTEXITCODE}."
        exit $LASTEXITCODE
    }

    $sceneArtOutput = & $GodotExe --headless --path $clientRoot --script $sceneArtFoundationCheckScript --no-header 2>&1
    if ($LASTEXITCODE -ne 0) {
        $sceneArtOutput | ForEach-Object { [Console]::Error.WriteLine($_) }
        Write-Error "Scene art foundation check failed with exit code ${LASTEXITCODE}."
        exit $LASTEXITCODE
    }

    $nonCoreSceneOutput = & $GodotExe --headless --path $clientRoot --script $nonCoreSceneIdentityCheckScript --no-header 2>&1
    if ($LASTEXITCODE -ne 0) {
        $nonCoreSceneOutput | ForEach-Object { [Console]::Error.WriteLine($_) }
        Write-Error "Non-core scene identity check failed with exit code ${LASTEXITCODE}."
        exit $LASTEXITCODE
    }

    $functionalTransitionOutput = & $GodotExe --headless --path $clientRoot --script $functionalTransitionRouteSupportCheckScript --no-header 2>&1
    if ($LASTEXITCODE -ne 0) {
        $functionalTransitionOutput | ForEach-Object { [Console]::Error.WriteLine($_) }
        Write-Error "Functional transition route support check failed with exit code ${LASTEXITCODE}."
        exit $LASTEXITCODE
    }

    $demoCompletionOutput = & $GodotExe --headless --path $clientRoot --script $demoMainlineCompletionCheckScript --no-header 2>&1
    if ($LASTEXITCODE -ne 0) {
        $demoCompletionOutput | ForEach-Object { [Console]::Error.WriteLine($_) }
        Write-Error "Demo mainline completion check failed with exit code ${LASTEXITCODE}."
        exit $LASTEXITCODE
    }

    $protectiveResponseOutput = & $GodotExe --headless --path $clientRoot --script $demoProtectiveResponseCheckScript --no-header 2>&1
    if ($LASTEXITCODE -ne 0) {
        $protectiveResponseOutput | ForEach-Object { [Console]::Error.WriteLine($_) }
        Write-Error "Demo protective response check failed with exit code ${LASTEXITCODE}."
        exit $LASTEXITCODE
    }

    $toolStrikeOutput = & $GodotExe --headless --path $clientRoot --script $demoToolStrikeCalibrationCheckScript --no-header 2>&1
    if ($LASTEXITCODE -ne 0) {
        $toolStrikeOutput | ForEach-Object { [Console]::Error.WriteLine($_) }
        Write-Error "Demo tool strike calibration check failed with exit code ${LASTEXITCODE}."
        exit $LASTEXITCODE
    }

    $unexpectedErrors = @(
        $importOutput + $checkOutput + $onboardingHintOutput + $functionalSceneGameplayOutput + $demoFieldLoopPayoffOutput + $industrialCheckOutput + $resourceChainOutput + $saveContractOutput + $mainPathContinuityOutput + $sceneArtOutput + $nonCoreSceneOutput + $functionalTransitionOutput + $demoCompletionOutput + $protectiveResponseOutput + $toolStrikeOutput |
            Where-Object { $_ -match "^ERROR:" -and $_ -notmatch "Failed to read the root certificate store" }
    )
    if ($unexpectedErrors.Count -gt 0) {
        $unexpectedErrors | ForEach-Object { [Console]::Error.WriteLine($_) }
        Write-Error "Vertical slice flow check reported unexpected errors."
        exit 1
    }
}
finally {
    $env:XDG_CONFIG_HOME = $previousXdgConfigHome
    $env:XDG_DATA_HOME = $previousXdgDataHome
    $env:XDG_CACHE_HOME = $previousXdgCacheHome
    $env:APPDATA = $previousAppData
    $env:LOCALAPPDATA = $previousLocalAppData
    Pop-Location
}

Write-Host "Vertical slice flow checks passed."
