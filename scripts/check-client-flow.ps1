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
$demoFunctionalSceneGameplayDensityCheckScript = Join-Path $clientRoot "scripts/checks/demo_functional_scene_gameplay_density_check.gd"
if (-not (Test-Path -LiteralPath $demoFunctionalSceneGameplayDensityCheckScript -PathType Leaf)) {
    Write-Error "Demo functional scene gameplay density check script not found: ${demoFunctionalSceneGameplayDensityCheckScript}"
    exit 1
}
$demoFunctionalTransitionSpatialPlayabilityCheckScript = Join-Path $clientRoot "scripts/checks/demo_functional_transition_spatial_playability_check.gd"
if (-not (Test-Path -LiteralPath $demoFunctionalTransitionSpatialPlayabilityCheckScript -PathType Leaf)) {
    Write-Error "Demo functional transition spatial playability check script not found: ${demoFunctionalTransitionSpatialPlayabilityCheckScript}"
    exit 1
}
$demoMidfieldRoutePlayabilityCheckScript = Join-Path $clientRoot "scripts/checks/demo_midfield_route_playability_check.gd"
if (-not (Test-Path -LiteralPath $demoMidfieldRoutePlayabilityCheckScript -PathType Leaf)) {
    Write-Error "Demo midfield route playability check script not found: ${demoMidfieldRoutePlayabilityCheckScript}"
    exit 1
}
$demoWindCorridorTransitionPlayabilityCheckScript = Join-Path $clientRoot "scripts/checks/demo_wind_corridor_transition_playability_check.gd"
if (-not (Test-Path -LiteralPath $demoWindCorridorTransitionPlayabilityCheckScript -PathType Leaf)) {
    Write-Error "Demo wind corridor transition playability check script not found: ${demoWindCorridorTransitionPlayabilityCheckScript}"
    exit 1
}
$demoCoreApproachHandoffPlayabilityCheckScript = Join-Path $clientRoot "scripts/checks/demo_core_approach_handoff_playability_check.gd"
if (-not (Test-Path -LiteralPath $demoCoreApproachHandoffPlayabilityCheckScript -PathType Leaf)) {
    Write-Error "Demo core approach handoff playability check script not found: ${demoCoreApproachHandoffPlayabilityCheckScript}"
    exit 1
}
$demoFieldLoopPayoffCheckScript = Join-Path $clientRoot "scripts/checks/demo_field_loop_payoff_check.gd"
if (-not (Test-Path -LiteralPath $demoFieldLoopPayoffCheckScript -PathType Leaf)) {
    Write-Error "Demo field loop payoff check script not found: ${demoFieldLoopPayoffCheckScript}"
    exit 1
}
$demoRouteReturnAndBaseReentryCheckScript = Join-Path $clientRoot "scripts/checks/demo_route_return_and_base_reentry_check.gd"
if (-not (Test-Path -LiteralPath $demoRouteReturnAndBaseReentryCheckScript -PathType Leaf)) {
    Write-Error "Demo route return and base reentry check script not found: ${demoRouteReturnAndBaseReentryCheckScript}"
    exit 1
}
$demoEndpointReadinessCheckScript = Join-Path $clientRoot "scripts/checks/demo_endpoint_readiness_check.gd"
if (-not (Test-Path -LiteralPath $demoEndpointReadinessCheckScript -PathType Leaf)) {
    Write-Error "Demo endpoint readiness check script not found: ${demoEndpointReadinessCheckScript}"
    exit 1
}
$demoCompletionOutcomeReadoutCheckScript = Join-Path $clientRoot "scripts/checks/demo_completion_outcome_readout_check.gd"
if (-not (Test-Path -LiteralPath $demoCompletionOutcomeReadoutCheckScript -PathType Leaf)) {
    Write-Error "Demo completion outcome readout check script not found: ${demoCompletionOutcomeReadoutCheckScript}"
    exit 1
}
$demoPlayableExperienceCoherenceCheckScript = Join-Path $clientRoot "scripts/checks/demo_playable_experience_coherence_check.gd"
if (-not (Test-Path -LiteralPath $demoPlayableExperienceCoherenceCheckScript -PathType Leaf)) {
    Write-Error "Demo playable experience coherence check script not found: ${demoPlayableExperienceCoherenceCheckScript}"
    exit 1
}
$playableSceneCompositionCheckScript = Join-Path $clientRoot "scripts/checks/playable_scene_composition_check.gd"
if (-not (Test-Path -LiteralPath $playableSceneCompositionCheckScript -PathType Leaf)) {
    Write-Error "Playable scene composition check script not found: ${playableSceneCompositionCheckScript}"
    exit 1
}
$demoCombatEvacuationRecoveryCheckScript = Join-Path $clientRoot "scripts/checks/demo_combat_evacuation_recovery_check.gd"
if (-not (Test-Path -LiteralPath $demoCombatEvacuationRecoveryCheckScript -PathType Leaf)) {
    Write-Error "Demo combat evacuation recovery check script not found: ${demoCombatEvacuationRecoveryCheckScript}"
    exit 1
}
$demoInteractionAffordanceCheckScript = Join-Path $clientRoot "scripts/checks/demo_interaction_affordance_check.gd"
if (-not (Test-Path -LiteralPath $demoInteractionAffordanceCheckScript -PathType Leaf)) {
    Write-Error "Demo interaction affordance check script not found: ${demoInteractionAffordanceCheckScript}"
    exit 1
}
$demoInteractionPromptSurfaceDecompositionCheckScript = Join-Path $clientRoot "scripts/checks/demo_interaction_prompt_surface_decomposition_check.gd"
if (-not (Test-Path -LiteralPath $demoInteractionPromptSurfaceDecompositionCheckScript -PathType Leaf)) {
    Write-Error "Demo interaction prompt surface decomposition check script not found: ${demoInteractionPromptSurfaceDecompositionCheckScript}"
    exit 1
}
$demoMapSurfaceDecompositionCheckScript = Join-Path $clientRoot "scripts/checks/demo_map_surface_decomposition_check.gd"
if (-not (Test-Path -LiteralPath $demoMapSurfaceDecompositionCheckScript -PathType Leaf)) {
    Write-Error "Demo map surface decomposition check script not found: ${demoMapSurfaceDecompositionCheckScript}"
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
$demoActionFeedbackReadabilityCheckScript = Join-Path $clientRoot "scripts/checks/demo_action_feedback_readability_check.gd"
if (-not (Test-Path -LiteralPath $demoActionFeedbackReadabilityCheckScript -PathType Leaf)) {
    Write-Error "Demo action feedback readability check script not found: ${demoActionFeedbackReadabilityCheckScript}"
    exit 1
}
$demoActionBlockerRecoveryCheckScript = Join-Path $clientRoot "scripts/checks/demo_action_blocker_recovery_check.gd"
if (-not (Test-Path -LiteralPath $demoActionBlockerRecoveryCheckScript -PathType Leaf)) {
    Write-Error "Demo action blocker recovery check script not found: ${demoActionBlockerRecoveryCheckScript}"
    exit 1
}
$demoPrototypeVisualPassCheckScript = Join-Path $clientRoot "scripts/checks/demo_prototype_visual_pass_check.gd"
if (-not (Test-Path -LiteralPath $demoPrototypeVisualPassCheckScript -PathType Leaf)) {
    Write-Error "Demo prototype visual pass check script not found: ${demoPrototypeVisualPassCheckScript}"
    exit 1
}
$demoQuickSlotSupplyReadabilityCheckScript = Join-Path $clientRoot "scripts/checks/demo_quick_slot_supply_readability_check.gd"
if (-not (Test-Path -LiteralPath $demoQuickSlotSupplyReadabilityCheckScript -PathType Leaf)) {
    Write-Error "Demo quick slot supply readability check script not found: ${demoQuickSlotSupplyReadabilityCheckScript}"
    exit 1
}
$demoSupplyPressurePacingCheckScript = Join-Path $clientRoot "scripts/checks/demo_supply_pressure_pacing_check.gd"
if (-not (Test-Path -LiteralPath $demoSupplyPressurePacingCheckScript -PathType Leaf)) {
    Write-Error "Demo supply pressure pacing check script not found: ${demoSupplyPressurePacingCheckScript}"
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

    $demoFunctionalSceneGameplayDensityOutput = & $GodotExe --headless --path $clientRoot --script $demoFunctionalSceneGameplayDensityCheckScript --no-header 2>&1
    if ($LASTEXITCODE -ne 0) {
        $demoFunctionalSceneGameplayDensityOutput | ForEach-Object { [Console]::Error.WriteLine($_) }
        Write-Error "Demo functional scene gameplay density check failed with exit code ${LASTEXITCODE}."
        exit $LASTEXITCODE
    }

    $demoFunctionalTransitionSpatialPlayabilityOutput = & $GodotExe --headless --path $clientRoot --script $demoFunctionalTransitionSpatialPlayabilityCheckScript --no-header 2>&1
    if ($LASTEXITCODE -ne 0) {
        $demoFunctionalTransitionSpatialPlayabilityOutput | ForEach-Object { [Console]::Error.WriteLine($_) }
        Write-Error "Demo functional transition spatial playability check failed with exit code ${LASTEXITCODE}."
        exit $LASTEXITCODE
    }

    $demoMidfieldRoutePlayabilityOutput = & $GodotExe --headless --path $clientRoot --script $demoMidfieldRoutePlayabilityCheckScript --no-header 2>&1
    if ($LASTEXITCODE -ne 0) {
        $demoMidfieldRoutePlayabilityOutput | ForEach-Object { [Console]::Error.WriteLine($_) }
        Write-Error "Demo midfield route playability check failed with exit code ${LASTEXITCODE}."
        exit $LASTEXITCODE
    }

    $demoWindCorridorTransitionPlayabilityOutput = & $GodotExe --headless --path $clientRoot --script $demoWindCorridorTransitionPlayabilityCheckScript --no-header 2>&1
    if ($LASTEXITCODE -ne 0) {
        $demoWindCorridorTransitionPlayabilityOutput | ForEach-Object { [Console]::Error.WriteLine($_) }
        Write-Error "Demo wind corridor transition playability check failed with exit code ${LASTEXITCODE}."
        exit $LASTEXITCODE
    }

    $demoCoreApproachHandoffPlayabilityOutput = & $GodotExe --headless --path $clientRoot --script $demoCoreApproachHandoffPlayabilityCheckScript --no-header 2>&1
    if ($LASTEXITCODE -ne 0) {
        $demoCoreApproachHandoffPlayabilityOutput | ForEach-Object { [Console]::Error.WriteLine($_) }
        Write-Error "Demo core approach handoff playability check failed with exit code ${LASTEXITCODE}."
        exit $LASTEXITCODE
    }

    $demoFieldLoopPayoffOutput = & $GodotExe --headless --path $clientRoot --script $demoFieldLoopPayoffCheckScript --no-header 2>&1
    if ($LASTEXITCODE -ne 0) {
        $demoFieldLoopPayoffOutput | ForEach-Object { [Console]::Error.WriteLine($_) }
        Write-Error "Demo field loop payoff check failed with exit code ${LASTEXITCODE}."
        exit $LASTEXITCODE
    }

    $demoRouteReturnAndBaseReentryOutput = & $GodotExe --headless --path $clientRoot --script $demoRouteReturnAndBaseReentryCheckScript --no-header 2>&1
    if ($LASTEXITCODE -ne 0) {
        $demoRouteReturnAndBaseReentryOutput | ForEach-Object { [Console]::Error.WriteLine($_) }
        Write-Error "Demo route return and base reentry check failed with exit code ${LASTEXITCODE}."
        exit $LASTEXITCODE
    }

    $demoEndpointReadinessOutput = & $GodotExe --headless --path $clientRoot --script $demoEndpointReadinessCheckScript --no-header 2>&1
    if ($LASTEXITCODE -ne 0) {
        $demoEndpointReadinessOutput | ForEach-Object { [Console]::Error.WriteLine($_) }
        Write-Error "Demo endpoint readiness check failed with exit code ${LASTEXITCODE}."
        exit $LASTEXITCODE
    }

    $demoCompletionOutcomeOutput = & $GodotExe --headless --path $clientRoot --script $demoCompletionOutcomeReadoutCheckScript --no-header 2>&1
    if ($LASTEXITCODE -ne 0) {
        $demoCompletionOutcomeOutput | ForEach-Object { [Console]::Error.WriteLine($_) }
        Write-Error "Demo completion outcome readout check failed with exit code ${LASTEXITCODE}."
        exit $LASTEXITCODE
    }

    $demoCoherenceOutput = & $GodotExe --headless --path $clientRoot --script $demoPlayableExperienceCoherenceCheckScript --no-header 2>&1
    if ($LASTEXITCODE -ne 0) {
        $demoCoherenceOutput | ForEach-Object { [Console]::Error.WriteLine($_) }
        Write-Error "Demo playable experience coherence check failed with exit code ${LASTEXITCODE}."
        exit $LASTEXITCODE
    }

    $playableSceneCompositionOutput = & $GodotExe --headless --path $clientRoot --script $playableSceneCompositionCheckScript --no-header 2>&1
    if ($LASTEXITCODE -ne 0) {
        $playableSceneCompositionOutput | ForEach-Object { [Console]::Error.WriteLine($_) }
        Write-Error "Playable scene composition check failed with exit code ${LASTEXITCODE}."
        exit $LASTEXITCODE
    }

    $demoCombatEvacuationRecoveryOutput = & $GodotExe --headless --path $clientRoot --script $demoCombatEvacuationRecoveryCheckScript --no-header 2>&1
    if ($LASTEXITCODE -ne 0) {
        $demoCombatEvacuationRecoveryOutput | ForEach-Object { [Console]::Error.WriteLine($_) }
        Write-Error "Demo combat evacuation recovery check failed with exit code ${LASTEXITCODE}."
        exit $LASTEXITCODE
    }

    $demoInteractionAffordanceOutput = & $GodotExe --headless --path $clientRoot --script $demoInteractionAffordanceCheckScript --no-header 2>&1
    if ($LASTEXITCODE -ne 0) {
        $demoInteractionAffordanceOutput | ForEach-Object { [Console]::Error.WriteLine($_) }
        Write-Error "Demo interaction affordance check failed with exit code ${LASTEXITCODE}."
        exit $LASTEXITCODE
    }

    $demoInteractionPromptSurfaceDecompositionOutput = & $GodotExe --headless --path $clientRoot --script $demoInteractionPromptSurfaceDecompositionCheckScript --no-header 2>&1
    if ($LASTEXITCODE -ne 0) {
        $demoInteractionPromptSurfaceDecompositionOutput | ForEach-Object { [Console]::Error.WriteLine($_) }
        Write-Error "Demo interaction prompt surface decomposition check failed with exit code ${LASTEXITCODE}."
        exit $LASTEXITCODE
    }

    $demoMapSurfaceDecompositionOutput = & $GodotExe --headless --path $clientRoot --script $demoMapSurfaceDecompositionCheckScript --no-header 2>&1
    if ($LASTEXITCODE -ne 0) {
        $demoMapSurfaceDecompositionOutput | ForEach-Object { [Console]::Error.WriteLine($_) }
        Write-Error "Demo map surface decomposition check failed with exit code ${LASTEXITCODE}."
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

    $actionFeedbackOutput = & $GodotExe --headless --path $clientRoot --script $demoActionFeedbackReadabilityCheckScript --no-header 2>&1
    if ($LASTEXITCODE -ne 0) {
        $actionFeedbackOutput | ForEach-Object { [Console]::Error.WriteLine($_) }
        Write-Error "Demo action feedback readability check failed with exit code ${LASTEXITCODE}."
        exit $LASTEXITCODE
    }

    $actionBlockerOutput = & $GodotExe --headless --path $clientRoot --script $demoActionBlockerRecoveryCheckScript --no-header 2>&1
    if ($LASTEXITCODE -ne 0) {
        $actionBlockerOutput | ForEach-Object { [Console]::Error.WriteLine($_) }
        Write-Error "Demo action blocker recovery check failed with exit code ${LASTEXITCODE}."
        exit $LASTEXITCODE
    }

    $prototypeVisualPassOutput = & $GodotExe --headless --path $clientRoot --script $demoPrototypeVisualPassCheckScript --no-header 2>&1
    if ($LASTEXITCODE -ne 0) {
        $prototypeVisualPassOutput | ForEach-Object { [Console]::Error.WriteLine($_) }
        Write-Error "Demo prototype visual pass check failed with exit code ${LASTEXITCODE}."
        exit $LASTEXITCODE
    }

    $quickSlotSupplyReadabilityOutput = & $GodotExe --headless --path $clientRoot --script $demoQuickSlotSupplyReadabilityCheckScript --no-header 2>&1
    if ($LASTEXITCODE -ne 0) {
        $quickSlotSupplyReadabilityOutput | ForEach-Object { [Console]::Error.WriteLine($_) }
        Write-Error "Demo quick slot supply readability check failed with exit code ${LASTEXITCODE}."
        exit $LASTEXITCODE
    }

    $supplyPressurePacingOutput = & $GodotExe --headless --path $clientRoot --script $demoSupplyPressurePacingCheckScript --no-header 2>&1
    if ($LASTEXITCODE -ne 0) {
        $supplyPressurePacingOutput | ForEach-Object { [Console]::Error.WriteLine($_) }
        Write-Error "Demo supply pressure pacing check failed with exit code ${LASTEXITCODE}."
        exit $LASTEXITCODE
    }

    $unexpectedErrors = @(
        $importOutput + $checkOutput + $onboardingHintOutput + $functionalSceneGameplayOutput + $demoMidfieldRoutePlayabilityOutput + $demoWindCorridorTransitionPlayabilityOutput + $demoCoreApproachHandoffPlayabilityOutput + $demoFieldLoopPayoffOutput + $demoRouteReturnAndBaseReentryOutput + $demoEndpointReadinessOutput + $demoCompletionOutcomeOutput + $demoCoherenceOutput + $playableSceneCompositionOutput + $demoCombatEvacuationRecoveryOutput + $demoInteractionAffordanceOutput + $demoInteractionPromptSurfaceDecompositionOutput + $industrialCheckOutput + $resourceChainOutput + $saveContractOutput + $mainPathContinuityOutput + $sceneArtOutput + $nonCoreSceneOutput + $functionalTransitionOutput + $demoCompletionOutput + $protectiveResponseOutput + $toolStrikeOutput + $actionFeedbackOutput + $actionBlockerOutput + $prototypeVisualPassOutput + $quickSlotSupplyReadabilityOutput + $supplyPressurePacingOutput |
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
