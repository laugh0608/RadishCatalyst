#!/bin/sh
set -eu

repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
godot_bin="${GODOT_EXE:-/Applications/Godot.app/Contents/MacOS/Godot}"
log_root="$repo_root/tools/runtime-intake/check-runs/factory-foundation-v1"
mkdir -p "$log_root"
mode="${1:-state}"

run_check() {
  check_name="$1"
  script_name="$2"
  shift 2
  log_file="$log_root/$check_name.log"
  "$godot_bin" --path "$repo_root/client" --script "res://scripts/checks/$script_name.gd" \
    --no-header --log-file "$log_file" "$@"
  if rg '^(SCRIPT ERROR|ERROR:)' "$log_file" | rg -v 'Condition "ret != noErr"' >/dev/null; then
    echo "Factory check reported an error: $log_file" >&2
    return 1
  fi
}

case "$mode" in
  import)
    "$godot_bin" --headless --path "$repo_root/client" --import --quit --no-header --log-file "$log_root/import.log"
    ;;
  state)
    node "$repo_root/tools/visual-studies/topdown-3d/production/verify-parity.mjs"
    run_check parity factory_web_parity_check --headless --quit-after 600
    run_check state factory_state_check --headless --quit-after 600
    run_check save factory_save_check --headless --quit-after 600
    ;;
  process)
    batch="process-$(date +%s)-$$"
    run_check process-write factory_process_check --headless --quit-after 600 -- --phase=write "--batch=$batch"
    run_check process-read factory_process_check --headless --quit-after 600 -- --phase=read "--batch=$batch"
    run_check process-hold factory_process_check --headless -- --phase=hold "--batch=$batch" &
    holder_pid=$!
    attempts=0
    while [ ! -f "$log_root/$batch/lock-owner.json" ]; do
      attempts=$((attempts + 1))
      if [ "$attempts" -ge 100 ]; then
        echo "Lock owner did not become ready." >&2
        wait "$holder_pid" || true
        exit 1
      fi
      sleep 0.1
    done
    run_check process-probe factory_process_check --headless --quit-after 600 -- --phase=probe "--batch=$batch"
    wait "$holder_pid"
    run_check process-recover factory_process_check --headless --quit-after 600 -- --phase=recover "--batch=$batch"
    ;;
  legacy)
    run_check legacy-startup demo_startup_shell_check --headless --quit-after 1200
    run_check legacy-catalog slice_save_catalog_check --headless --quit-after 1200
    run_check legacy-schema slice_save_schema_check --headless --quit-after 1200
    ;;
  scale) run_check scale-state factory_scale_state_check --headless --quit-after 600 ;;
  boot) run_check boot factory_boot_check ;;
  operation-write) run_check operation-write factory_operation_check -- "--batch=${2:?supply a unique batch name}" ;;
  operation-read) run_check operation-read factory_operation_check -- --read "--batch=${2:?supply the written batch name}" ;;
  performance) run_check performance-short factory_performance_check ;;
  sustained) run_check performance-sustained factory_performance_check -- --active --phase-seconds=450 ;;
  *) echo "Usage: sh tools/check-factory-foundation.sh [import|state|process|scale|boot|operation-write|operation-read|performance] [batch]" >&2; exit 2 ;;
esac
echo "Factory $mode check completed."
