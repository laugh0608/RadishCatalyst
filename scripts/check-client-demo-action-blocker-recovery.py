#!/usr/bin/env python3
import sys
from pathlib import Path


REQUIRED_TEXT_BY_FILE = {
    "docs/features/demo-action-blocker-recovery-v1.md": [
        "Demo Action Blocker Recovery V1",
        "第一包实施范围",
        "DemoActionBlockerRecoveryFormatter",
        "不新增 UI 面板、存档 schema、资源、配方、区域、任务链、敌人类型、完整背包或完整装备栏",
    ],
    "client/scripts/systems/demo_action_blocker_recovery_formatter.gd": [
        "class_name DemoActionBlockerRecoveryFormatter",
        "format_interaction_prerequisite_failure",
        "format_already_processed_failure",
        "format_build_prerequisite_failure",
        "format_build_material_failure",
        "format_processing_missing_input_failure",
        "format_processing_busy_failure",
        "format_supply_failure",
        "format_core_write_failure",
    ],
    "client/scripts/systems/gather_system.gd": [
        "DemoActionBlockerRecoveryFormatter.format_already_processed_failure",
        "DemoActionBlockerRecoveryFormatter.format_core_write_failure",
        "DemoActionBlockerRecoveryFormatter.format_interaction_prerequisite_failure",
    ],
    "client/scripts/systems/build_system.gd": [
        "DemoActionBlockerRecoveryFormatter.format_build_prerequisite_failure",
        "DemoActionBlockerRecoveryFormatter.format_build_material_failure",
    ],
    "client/scripts/systems/processing_system.gd": [
        "DemoActionBlockerRecoveryFormatter.format_processing_missing_input_failure",
        "DemoActionBlockerRecoveryFormatter.format_processing_busy_failure",
    ],
    "client/scripts/state/character_state.gd": [
        "DemoActionBlockerRecoveryFormatter.format_supply_failure",
        "\"failure_feedback\": failure_feedback",
    ],
    "client/scripts/game/game_root.gd": [
        "hud_log_presenter.format_result_log(result)",
    ],
    "client/scripts/checks/demo_action_blocker_recovery_check.gd": [
        "Demo action blocker recovery checks passed.",
        "_check_gather_and_sample_prerequisite_blockers",
        "_check_already_processed_object_blocker",
        "_check_build_blockers",
        "_check_processing_blockers",
        "_check_supply_blockers",
        "_check_core_write_blockers",
    ],
    "scripts/check-client.sh": [
        "check-client-demo-action-blocker-recovery.py",
        "demo_action_blocker_recovery_check.gd",
    ],
    "scripts/check-client.ps1": [
        "check-client-demo-action-blocker-recovery.ps1",
    ],
    "scripts/check-client-flow.ps1": [
        "demo_action_blocker_recovery_check.gd",
    ],
}


def main() -> int:
    repo_root = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path(__file__).resolve().parents[1]
    errors: list[str] = []

    for relative_path, required_texts in REQUIRED_TEXT_BY_FILE.items():
        path = repo_root / relative_path
        if not path.is_file():
            errors.append(f"{relative_path}: missing file")
            continue
        content = path.read_text(encoding="utf-8")
        for required_text in required_texts:
            if required_text not in content:
                errors.append(f"{relative_path}: missing demo action blocker recovery text '{required_text}'")

    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1

    print("Client demo action blocker recovery checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
