#!/usr/bin/env python3
import sys
from pathlib import Path


REQUIRED_TEXT_BY_FILE = {
    "docs/features/demo-interaction-affordance-v1.md": [
        "Demo Interaction Affordance V1",
        "第一包实施范围",
        "DemoInteractionAffordanceFormatter",
        "不新增资源、配方、区域、任务链、敌人类型、完整背包或完整装备栏",
    ],
    "client/scripts/systems/demo_interaction_affordance_formatter.gd": [
        "class_name DemoInteractionAffordanceFormatter",
        "format_general_affordance_line",
        "format_build_affordance_line",
        "format_clear_affordance_line",
        "format_outpost_core_affordance_line",
        "format_outfitting_station_affordance_line",
    ],
    "client/scripts/ui/interaction_prompt_formatter.gd": [
        "DemoInteractionAffordanceFormatter.format_general_affordance_line",
        "DemoInteractionAffordanceFormatter.format_build_affordance_line",
        "DemoInteractionAffordanceFormatter.format_clear_affordance_line",
        "DemoInteractionAffordanceFormatter.format_outpost_core_affordance_line",
        "DemoInteractionAffordanceFormatter.format_outfitting_station_affordance_line",
        "DemoInteractionAffordanceFormatter.format_definition_affordance_line",
    ],
    "client/scripts/checks/demo_interaction_affordance_check.gd": [
        "Demo interaction affordance checks passed.",
        "_check_general_prompt_affordance_states",
        "_check_signal_echo_and_core_guard_affordance",
        "_check_hud_map_route_alignment",
        "_check_scene_visual_affordance_labels",
        "_check_enemy_focus_affordance_labels",
    ],
    "scripts/check-client.sh": [
        "check-client-demo-interaction-affordance.py",
        "demo_interaction_affordance_check.gd",
    ],
    "scripts/check-client.ps1": [
        "check-client-demo-interaction-affordance.ps1",
    ],
    "scripts/check-client-flow.ps1": [
        "demo_interaction_affordance_check.gd",
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
                errors.append(f"{relative_path}: missing demo interaction affordance text '{required_text}'")

    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1

    print("Client demo interaction affordance checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
