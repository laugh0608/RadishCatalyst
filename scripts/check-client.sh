#!/bin/sh
set -eu

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
repo_root="$(CDPATH= cd -- "${script_dir}/.." && pwd)"
client_root="${repo_root}/client"

usage() {
  cat <<'USAGE'
Usage: sh ./scripts/check-client.sh [--with-godot] [--godot-exe PATH]

Runs portable client checks by default:
  - static client data
  - scene references

Godot import and project runtime checks are opt-in because they start the
Godot process and depend on the local desktop/runtime environment.
USAGE
}

case "${CHECK_CLIENT_WITH_GODOT:-0}" in
  1|true|TRUE|yes|YES)
    with_godot=1
    ;;
  *)
    with_godot=0
    ;;
esac

while [ "$#" -gt 0 ]; do
  case "$1" in
    --with-godot)
      with_godot=1
      ;;
    --godot-exe)
      shift
      if [ "$#" -eq 0 ]; then
        echo "--godot-exe requires a path." >&2
        exit 2
      fi
      GODOT_EXE="$1"
      export GODOT_EXE
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

python_exe="${PYTHON:-python}"
if ! command -v "${python_exe}" >/dev/null 2>&1; then
  echo "python is required to run macOS/Linux client checks." >&2
  exit 1
fi

find_godot() {
  if [ -n "${GODOT_EXE:-}" ] && [ -x "${GODOT_EXE}" ]; then
    printf '%s\n' "${GODOT_EXE}"
    return 0
  fi
  if command -v godot >/dev/null 2>&1; then
    command -v godot
    return 0
  fi
  if command -v godot4 >/dev/null 2>&1; then
    command -v godot4
    return 0
  fi
  if [ -x "/Applications/Godot.app/Contents/MacOS/Godot" ]; then
    printf '%s\n' "/Applications/Godot.app/Contents/MacOS/Godot"
    return 0
  fi
  return 1
}

run_godot_checked() {
  check_name="$1"
  shift
  log_file="${godot_home}/${check_name}.log"
  echo "Running ${check_name}..."
  set +e
  HOME="${godot_fake_home}" \
  XDG_CONFIG_HOME="${godot_config_home}" \
  XDG_DATA_HOME="${godot_data_home}" \
  XDG_CACHE_HOME="${godot_cache_home}" \
  APPDATA="${godot_app_data}" \
  LOCALAPPDATA="${godot_local_app_data}" \
  "${godot_exe}" --headless --path "${client_root}" "$@" >"${log_file}" 2>&1
  exit_code=$?
  set -e
  grep -v 'Condition "ret != noErr"' "${log_file}" \
    | grep -v "Failed to read the root certificate store" \
    | grep -v "get_system_ca_certificates (platform/macos/os_macos.mm" \
    || true
  if [ "${exit_code}" -gt 128 ]; then
    signal_number=$((exit_code - 128))
    echo "${check_name} stopped because Godot was terminated by signal ${signal_number}." >&2
    echo "Godot runtime checks require a local Godot process that can start cleanly; rerun without --with-godot for portable checks." >&2
    exit 1
  fi
  if [ "${exit_code}" -ne 0 ]; then
    echo "${check_name} failed with exit code ${exit_code}." >&2
    exit "${exit_code}"
  fi
  if grep -E "^(SCRIPT ERROR|ERROR:)" "${log_file}" | grep -v 'Condition "ret != noErr"' | grep -v "Failed to read the root certificate store" >/dev/null 2>&1; then
    echo "${check_name} reported unexpected Godot errors." >&2
    exit 1
  fi
}

echo "Running macOS/Linux client checks."
echo "Coverage: static data and scene references."

"${python_exe}" "${repo_root}/scripts/check-client-data.py" "${repo_root}"
"${python_exe}" "${repo_root}/scripts/check-client-scenes.py" "${repo_root}"
"${python_exe}" "${repo_root}/scripts/check-client-industrial-tech-spine.py" "${repo_root}"
"${python_exe}" "${repo_root}/scripts/check-client-demo-resource-chain-state.py" "${repo_root}"
"${python_exe}" "${repo_root}/scripts/check-client-demo-pollution-boundary-visual.py" "${repo_root}"
"${python_exe}" "${repo_root}/scripts/check-client-demo-core-stabilization-visual.py" "${repo_root}"
"${python_exe}" "${repo_root}/scripts/check-client-demo-region-industrial-value.py" "${repo_root}"
"${python_exe}" "${repo_root}/scripts/check-client-demo-save-state-contract.py" "${repo_root}"
"${python_exe}" "${repo_root}/scripts/check-client-demo-main-path-continuity.py" "${repo_root}"
"${python_exe}" "${repo_root}/scripts/check-client-demo-runtime-surface-decomposition.py" "${repo_root}"
"${python_exe}" "${repo_root}/scripts/check-client-demo-functional-scene-gameplay.py" "${repo_root}"
"${python_exe}" "${repo_root}/scripts/check-client-demo-functional-scene-gameplay-density.py" "${repo_root}"
"${python_exe}" "${repo_root}/scripts/check-client-demo-functional-transition-spatial-playability.py" "${repo_root}"
"${python_exe}" "${repo_root}/scripts/check-client-demo-midfield-route-playability.py" "${repo_root}"
"${python_exe}" "${repo_root}/scripts/check-client-demo-wind-corridor-transition-playability.py" "${repo_root}"
"${python_exe}" "${repo_root}/scripts/check-client-demo-core-approach-handoff-playability.py" "${repo_root}"
"${python_exe}" "${repo_root}/scripts/check-client-demo-core-stabilization-run-playability.py" "${repo_root}"
"${python_exe}" "${repo_root}/scripts/check-client-demo-device-panel-operation-readability.py" "${repo_root}"
"${python_exe}" "${repo_root}/scripts/check-client-demo-field-loop-payoff.py" "${repo_root}"
"${python_exe}" "${repo_root}/scripts/check-client-demo-route-return-and-base-reentry.py" "${repo_root}"
"${python_exe}" "${repo_root}/scripts/check-client-demo-endpoint-readiness.py" "${repo_root}"
"${python_exe}" "${repo_root}/scripts/check-client-demo-completion-outcome-readout.py" "${repo_root}"
"${python_exe}" "${repo_root}/scripts/check-client-demo-playable-experience-coherence.py" "${repo_root}"
"${python_exe}" "${repo_root}/scripts/check-client-demo-playable-scene-composition.py" "${repo_root}"
"${python_exe}" "${repo_root}/scripts/check-client-demo-startup-shell.py" "${repo_root}"
"${python_exe}" "${repo_root}/scripts/check-client-demo-combat-evacuation-recovery.py" "${repo_root}"
"${python_exe}" "${repo_root}/scripts/check-client-demo-interaction-affordance.py" "${repo_root}"
"${python_exe}" "${repo_root}/scripts/check-client-demo-interaction-prompt-surface-decomposition.py" "${repo_root}"
"${python_exe}" "${repo_root}/scripts/check-client-demo-map-surface-decomposition.py" "${repo_root}"
"${python_exe}" "${repo_root}/scripts/check-client-scene-art-foundation.py" "${repo_root}"
"${python_exe}" "${repo_root}/scripts/check-client-non-core-scene-identity.py" "${repo_root}"
"${python_exe}" "${repo_root}/scripts/check-client-functional-transition-route-support.py" "${repo_root}"
"${python_exe}" "${repo_root}/scripts/check-client-demo-mainline-completion.py" "${repo_root}"
"${python_exe}" "${repo_root}/scripts/check-client-demo-protective-response.py" "${repo_root}"
"${python_exe}" "${repo_root}/scripts/check-client-demo-tool-strike-calibration.py" "${repo_root}"
"${python_exe}" "${repo_root}/scripts/check-client-demo-action-feedback-readability.py" "${repo_root}"
"${python_exe}" "${repo_root}/scripts/check-client-demo-action-blocker-recovery.py" "${repo_root}"
"${python_exe}" "${repo_root}/scripts/check-client-demo-prototype-visual-pass.py" "${repo_root}"
"${python_exe}" "${repo_root}/scripts/check-client-demo-quick-slot-supply-readability.py" "${repo_root}"
"${python_exe}" "${repo_root}/scripts/check-client-demo-supply-pressure-pacing.py" "${repo_root}"
"${python_exe}" "${repo_root}/scripts/check-client-demo-combat-readability.py" "${repo_root}"
"${python_exe}" "${repo_root}/scripts/check-client-demo-core-scene-playable-space.py" "${repo_root}"
"${python_exe}" "${repo_root}/scripts/check-client-demo-industrial-module-task-rhythm.py" "${repo_root}"
"${python_exe}" "${repo_root}/scripts/check-client-demo-initial-art-identity.py" "${repo_root}"
"${python_exe}" "${repo_root}/scripts/check-client-demo-field-task-differentiation.py" "${repo_root}"

if [ "${with_godot}" -ne 1 ]; then
  echo "Skipping Godot runtime checks. Use --with-godot after confirming Godot can start in this environment."
  echo "Client checks passed."
  exit 0
fi

godot_exe="$(find_godot || true)"
if [ -z "${godot_exe}" ]; then
  echo "Godot executable not found. Set GODOT_EXE or install Godot.app / godot / godot4." >&2
  exit 1
fi

run_id="godot-shell-$$-$(date -u +%Y%m%d%H%M%S)"
godot_home="${repo_root}/.godot-check-runs/${run_id}"
godot_config_home="${godot_home}/config"
godot_data_home="${godot_home}/data"
godot_cache_home="${godot_home}/cache"
godot_app_data="${godot_data_home}/Roaming"
godot_local_app_data="${godot_cache_home}/Local"
godot_fake_home="${godot_home}/home"
mkdir -p "${godot_config_home}" "${godot_data_home}" "${godot_cache_home}" "${godot_app_data}" "${godot_local_app_data}"
mkdir -p "${godot_fake_home}/Library/Application Support/Godot/app_userdata/RadishCatalyst/logs"

echo "Running Godot import and project runtime checks."
echo "Using Godot: ${godot_exe}"
run_godot_checked "godot-import" --import --quit --no-header
run_godot_checked "save-service" --script "${client_root}/scripts/checks/save_service_check.gd" --no-header
run_godot_checked "quest-rules" --script "${client_root}/scripts/checks/quest_rules_check.gd" --no-header
run_godot_checked "vertical-slice-flow" --script "${client_root}/scripts/checks/vertical_slice_flow_check.gd" --no-header
run_godot_checked "slice-building-placement" --script "${client_root}/scripts/checks/slice_building_placement_check.gd" --no-header
run_godot_checked "slice-building-operations" --script "${client_root}/scripts/checks/slice_building_operations_check.gd" --no-header
run_godot_checked "slice-inventory-model" --script "${client_root}/scripts/checks/slice_inventory_model_check.gd" --no-header
run_godot_checked "slice-powered-storage" --script "${client_root}/scripts/checks/slice_powered_storage_check.gd" --no-header
run_godot_checked "slice-power-grid" --script "${client_root}/scripts/checks/slice_power_grid_check.gd" --no-header
run_godot_checked "slice-reactor" --script "${client_root}/scripts/checks/slice_reactor_check.gd" --no-header
run_godot_checked "slice-combat-package1" --script "${client_root}/scripts/checks/slice_combat_package1_check.gd" --no-header
run_godot_checked "slice-combat-package2" --script "${client_root}/scripts/checks/slice_combat_package2_check.gd" --no-header
run_godot_checked "slice-combat-package3" --script "${client_root}/scripts/checks/slice_combat_package3_check.gd" --no-header
run_godot_checked "slice-ranged-weapon-p3" --script "${client_root}/scripts/checks/slice_ranged_weapon_p3_check.gd" --no-header
run_godot_checked "slice-first-playable-journey" --script "${client_root}/scripts/checks/slice_first_playable_journey_check.gd" --no-header
run_godot_checked "slice-logistics" --script "${client_root}/scripts/checks/slice_logistics_check.gd" --no-header
run_godot_checked "slice-core-logistics" --script "${client_root}/scripts/checks/slice_core_logistics_check.gd" --no-header
run_godot_checked "slice-playtest-remediation-package0" --script "${client_root}/scripts/checks/slice_playtest_remediation_package0_check.gd" --no-header
run_godot_checked "slice-playtest-remediation-package1" --script "${client_root}/scripts/checks/slice_playtest_remediation_package1_check.gd" --no-header
run_godot_checked "slice-playtest-remediation-package2" --script "${client_root}/scripts/checks/slice_playtest_remediation_package2_check.gd" --no-header
run_godot_checked "slice-save-schema" --script "${client_root}/scripts/checks/slice_save_schema_check.gd" --no-header
run_godot_checked "slice-save-schema-nine" --script "${client_root}/scripts/checks/slice_save_schema_nine_check.gd" --no-header
run_godot_checked "slice-save-catalog" --script "${client_root}/scripts/checks/slice_save_catalog_check.gd" --no-header
run_godot_checked "onboarding-hint-runtime" --script "${client_root}/scripts/checks/onboarding_hint_runtime_check.gd" --no-header
run_godot_checked "functional-scene-gameplay" --script "${client_root}/scripts/checks/functional_scene_gameplay_check.gd" --no-header
run_godot_checked "demo-functional-scene-gameplay-density" --script "${client_root}/scripts/checks/demo_functional_scene_gameplay_density_check.gd" --no-header
run_godot_checked "demo-functional-transition-spatial-playability" --script "${client_root}/scripts/checks/demo_functional_transition_spatial_playability_check.gd" --no-header
run_godot_checked "demo-midfield-route-playability" --script "${client_root}/scripts/checks/demo_midfield_route_playability_check.gd" --no-header
run_godot_checked "demo-wind-corridor-transition-playability" --script "${client_root}/scripts/checks/demo_wind_corridor_transition_playability_check.gd" --no-header
run_godot_checked "demo-core-approach-handoff-playability" --script "${client_root}/scripts/checks/demo_core_approach_handoff_playability_check.gd" --no-header
run_godot_checked "demo-core-stabilization-run-playability" --script "${client_root}/scripts/checks/demo_core_stabilization_run_playability_check.gd" --no-header
run_godot_checked "demo-device-panel-operation-readability" --script "${client_root}/scripts/checks/demo_device_panel_operation_readability_check.gd" --no-header
run_godot_checked "demo-field-loop-payoff" --script "${client_root}/scripts/checks/demo_field_loop_payoff_check.gd" --no-header
run_godot_checked "demo-route-return-and-base-reentry" --script "${client_root}/scripts/checks/demo_route_return_and_base_reentry_check.gd" --no-header
run_godot_checked "demo-endpoint-readiness" --script "${client_root}/scripts/checks/demo_endpoint_readiness_check.gd" --no-header
run_godot_checked "demo-completion-outcome-readout" --script "${client_root}/scripts/checks/demo_completion_outcome_readout_check.gd" --no-header
run_godot_checked "demo-playable-experience-coherence" --script "${client_root}/scripts/checks/demo_playable_experience_coherence_check.gd" --no-header
run_godot_checked "playable-scene-composition" --script "${client_root}/scripts/checks/playable_scene_composition_check.gd" --no-header
run_godot_checked "demo-startup-shell" --script "${client_root}/scripts/checks/demo_startup_shell_check.gd" --no-header
run_godot_checked "demo-combat-evacuation-recovery" --script "${client_root}/scripts/checks/demo_combat_evacuation_recovery_check.gd" --no-header
run_godot_checked "demo-interaction-affordance" --script "${client_root}/scripts/checks/demo_interaction_affordance_check.gd" --no-header
run_godot_checked "demo-interaction-prompt-surface-decomposition" --script "${client_root}/scripts/checks/demo_interaction_prompt_surface_decomposition_check.gd" --no-header
run_godot_checked "demo-map-surface-decomposition" --script "${client_root}/scripts/checks/demo_map_surface_decomposition_check.gd" --no-header
run_godot_checked "industrial-tech-spine" --script "${client_root}/scripts/checks/industrial_tech_spine_check.gd" --no-header
run_godot_checked "demo-resource-chain-state" --script "${client_root}/scripts/checks/demo_resource_chain_state_check.gd" --no-header
run_godot_checked "demo-pollution-boundary-visual" --script "${client_root}/scripts/checks/demo_pollution_boundary_visual_check.gd" --no-header
run_godot_checked "demo-core-stabilization-visual" --script "${client_root}/scripts/checks/demo_core_stabilization_visual_check.gd" --no-header
run_godot_checked "demo-region-industrial-value" --script "${client_root}/scripts/checks/demo_region_industrial_value_check.gd" --no-header
run_godot_checked "demo-save-state-contract" --script "${client_root}/scripts/checks/demo_save_state_contract_check.gd" --no-header
run_godot_checked "demo-main-path-continuity" --script "${client_root}/scripts/checks/demo_main_path_continuity_check.gd" --no-header
run_godot_checked "scene-art-foundation" --script "${client_root}/scripts/checks/scene_art_foundation_check.gd" --no-header
run_godot_checked "non-core-scene-identity" --script "${client_root}/scripts/checks/non_core_scene_identity_check.gd" --no-header
run_godot_checked "functional-transition-route-support" --script "${client_root}/scripts/checks/functional_transition_route_support_check.gd" --no-header
run_godot_checked "demo-mainline-completion" --script "${client_root}/scripts/checks/demo_mainline_completion_check.gd" --no-header
run_godot_checked "demo-protective-response" --script "${client_root}/scripts/checks/demo_protective_response_check.gd" --no-header
run_godot_checked "demo-tool-strike-calibration" --script "${client_root}/scripts/checks/demo_tool_strike_calibration_check.gd" --no-header
run_godot_checked "demo-action-feedback-readability" --script "${client_root}/scripts/checks/demo_action_feedback_readability_check.gd" --no-header
run_godot_checked "demo-action-blocker-recovery" --script "${client_root}/scripts/checks/demo_action_blocker_recovery_check.gd" --no-header
run_godot_checked "demo-prototype-visual-pass" --script "${client_root}/scripts/checks/demo_prototype_visual_pass_check.gd" --no-header
run_godot_checked "demo-quick-slot-supply-readability" --script "${client_root}/scripts/checks/demo_quick_slot_supply_readability_check.gd" --no-header
run_godot_checked "demo-supply-pressure-pacing" --script "${client_root}/scripts/checks/demo_supply_pressure_pacing_check.gd" --no-header
run_godot_checked "demo-combat-readability" --script "${client_root}/scripts/checks/demo_combat_readability_check.gd" --no-header
run_godot_checked "demo-core-scene-playable-space" --script "${client_root}/scripts/checks/demo_core_scene_playable_space_check.gd" --no-header
run_godot_checked "demo-industrial-module-task-rhythm" --script "${client_root}/scripts/checks/demo_industrial_module_task_rhythm_check.gd" --no-header
run_godot_checked "demo-initial-art-identity" --script "${client_root}/scripts/checks/demo_initial_art_identity_check.gd" --no-header
run_godot_checked "demo-field-task-differentiation" --script "${client_root}/scripts/checks/demo_field_task_differentiation_check.gd" --no-header

echo "Client checks passed."
