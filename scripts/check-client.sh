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

python_exe="${PYTHON:-python3}"
if ! command -v "${python_exe}" >/dev/null 2>&1; then
  echo "python3 is required to run macOS/Linux client checks." >&2
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
"${python_exe}" "${repo_root}/scripts/check-client-scene-art-foundation.py" "${repo_root}"
"${python_exe}" "${repo_root}/scripts/check-client-demo-mainline-completion.py" "${repo_root}"
"${python_exe}" "${repo_root}/scripts/check-client-demo-protective-response.py" "${repo_root}"

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
run_godot_checked "industrial-tech-spine" --script "${client_root}/scripts/checks/industrial_tech_spine_check.gd" --no-header
run_godot_checked "scene-art-foundation" --script "${client_root}/scripts/checks/scene_art_foundation_check.gd" --no-header
run_godot_checked "demo-mainline-completion" --script "${client_root}/scripts/checks/demo_mainline_completion_check.gd" --no-header
run_godot_checked "demo-protective-response" --script "${client_root}/scripts/checks/demo_protective_response_check.gd" --no-header

echo "Client checks passed."
