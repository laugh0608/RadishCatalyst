#!/usr/bin/env python3
import sys
from pathlib import Path


REQUIRED_TEXT_BY_FILE = {
    "docs/archive/features-demo-v1/demo-playable-content-substance-v1.md": [
        "角色 / 怪物 UI 第一包",
        "DemoCombatReadabilityFormatter",
        "demo_combat_readability_check.gd",
        "战斗现场",
        "不新增第 13 区域",
    ],
    "client/scripts/systems/demo_combat_readability_formatter.gd": [
        "class_name DemoCombatReadabilityFormatter",
        "format_panel_text",
        "format_hit_feedback",
        "format_enemy_threat_label",
        "生命 / 防护承压",
    ],
    "client/scripts/ui/prototype_hud.gd": [
        "update_combat_readability",
        "show_combat_feedback",
        "CombatPanel",
        "DemoCombatReadabilityFormatter.format_panel_text",
    ],
    "client/scripts/map/vertical_slice_map.gd": [
        "get_current_combat_target",
        "combat_feedback",
        "DemoCombatReadabilityFormatter.format_hit_feedback",
    ],
    "client/scripts/actors/prototype_enemy.gd": [
        "configure_readability_tags",
        "get_combat_status_label",
        "readability_threat_label",
    ],
    "client/scripts/checks/demo_combat_readability_check.gd": [
        "Demo combat readability checks passed.",
        "_check_formatter_exposes_player_enemy_and_supply_state",
        "_check_attack_result_carries_combat_feedback",
        "_check_hud_panel_uses_current_target_and_recent_feedback",
    ],
    "scripts/check-client.sh": [
        "check-client-demo-combat-readability.py",
        "demo_combat_readability_check.gd",
    ],
    "scripts/check-client.ps1": [
        "check-client-demo-combat-readability.ps1",
    ],
    "scripts/check-client-flow.ps1": [
        "demo_combat_readability_check.gd",
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
                errors.append(f"{relative_path}: missing demo combat readability text '{required_text}'")

    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1

    print("Client demo combat readability checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
