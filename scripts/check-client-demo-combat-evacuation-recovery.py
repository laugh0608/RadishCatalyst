#!/usr/bin/env python3
import sys
from pathlib import Path


REQUIRED_TEXT_BY_FILE = {
    "docs/archive/features-demo-v1/demo-combat-evacuation-recovery-v1.md": [
        "Demo Combat Evacuation Recovery V1",
        "战斗撤离恢复读法第一版",
        "不新增资源、配方、区域、任务链、敌人类型、完整背包或完整装备栏",
    ],
    "client/scripts/systems/demo_combat_evacuation_recovery_formatter.gd": [
        "class_name DemoCombatEvacuationRecoveryFormatter",
        "build_feedback",
        "format_hud_summary",
        "format_map_route_hint",
        "format_outpost_core_recovery_line",
        "format_departure_gate_status_line",
    ],
    "client/scripts/map/vertical_slice_map.gd": [
        "DemoCombatEvacuationRecoveryFormatter.build_feedback",
        "character_state.position = OUTPOST_RESPAWN_POSITION",
    ],
    "client/scripts/ui/hud_feedback_presenter.gd": [
        "DemoCombatEvacuationRecoveryFormatter.format_panel_detail_lines",
    ],
    "client/scripts/ui/hud_status_presenter.gd": [
        "DemoCombatEvacuationRecoveryFormatter.format_hud_summary",
    ],
    "client/scripts/ui/hud_map_presenter.gd": [
        "DemoCombatEvacuationRecoveryFormatter.format_map_route_hint",
    ],
    "client/scripts/ui/interaction_prompt_formatter.gd": [
        "DemoCombatEvacuationRecoveryFormatter.format_outpost_core_recovery_line",
        "DemoCombatEvacuationRecoveryFormatter.format_departure_gate_status_line",
        "DemoCombatEvacuationRecoveryFormatter.format_departure_gate_next_step",
    ],
    "client/scripts/checks/demo_combat_evacuation_recovery_check.gd": [
        "Demo combat evacuation recovery checks passed.",
        "_check_pollution_protection_evacuation_recovery",
        "_check_deep_combat_evacuation_recovery",
        "_check_core_guard_evacuation_save_roundtrip",
    ],
    "scripts/check-client.sh": [
        "check-client-demo-combat-evacuation-recovery.py",
        "demo_combat_evacuation_recovery_check.gd",
    ],
    "scripts/check-client.ps1": [
        "check-client-demo-combat-evacuation-recovery.ps1",
    ],
    "scripts/check-client-flow.ps1": [
        "demo_combat_evacuation_recovery_check.gd",
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
                errors.append(f"{relative_path}: missing demo combat evacuation recovery text '{required_text}'")

    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1

    print("Client demo combat evacuation recovery checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
