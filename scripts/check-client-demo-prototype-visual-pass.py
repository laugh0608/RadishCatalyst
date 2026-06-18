#!/usr/bin/env python3
import sys
from pathlib import Path


REQUIRED_TEXT_BY_FILE = {
    "docs/features/demo-prototype-visual-pass-v1.md": [
        "Demo Prototype Visual Pass V1",
        "原型视觉呈现",
        "PrototypeVisualPriorityLayer",
        "demo_prototype_visual_pass_check.gd",
        "不新增资源、配方、区域、任务链、敌人类型、完整背包或完整装备栏",
    ],
    "client/scripts/systems/prototype_visual_priority_profile.gd": [
        "class_name PrototypeVisualPriorityProfile",
        "REGION_PROFILES",
        "STATE_PROFILES",
        "STATE_CORE_WRITE_BLOCKED",
        "make_cue_name",
    ],
    "client/scripts/map/prototype_visual_priority_layer.gd": [
        "class_name PrototypeVisualPriorityLayer",
        "apply_profile",
        "get_generated_cue_count",
        "PrototypeVisualPriorityProfile.get_region_ids",
    ],
    "client/scripts/map/current_objective_guidance_layer.gd": [
        "class_name CurrentObjectiveGuidanceLayer",
        "CurrentObjectiveTargetHalo",
        "CurrentObjectiveOffTargetLabel",
        "is_target_guidance_visible",
    ],
    "client/scenes/maps/VerticalSliceMap.tscn": [
        "res://scripts/map/prototype_visual_priority_layer.gd",
        "PrototypeVisualPriorityLayer",
        "res://scripts/map/current_objective_guidance_layer.gd",
        "CurrentObjectiveGuidanceLayer",
    ],
    "client/scripts/interaction/prototype_interactable.gd": [
        "set_visual_priority_state",
        "set_missing_prerequisite_visual",
        "set_danger_active_visual",
        "set_device_busy_visual",
        "set_core_write_blocked_visual",
    ],
    "client/scripts/map/interactable_visual_refresher.gd": [
        "_apply_visual_priority_state",
        "_is_build_prerequisite_blocked",
        "_is_processing_busy",
        "_is_danger_active",
        "_is_core_write_blocked",
    ],
    "client/scripts/checks/demo_prototype_visual_pass_check.gd": [
        "Demo prototype visual pass checks passed.",
        "_check_visual_priority_profile_coverage",
        "_check_scene_visual_priority_layer",
        "_check_current_objective_guidance_layer",
        "_check_visual_state_methods",
        "_check_visual_refresher_state_alignment",
    ],
    "scripts/check-client.sh": [
        "check-client-demo-prototype-visual-pass.py",
        "demo_prototype_visual_pass_check.gd",
    ],
    "scripts/check-client.ps1": [
        "check-client-demo-prototype-visual-pass.ps1",
    ],
    "scripts/check-client-flow.ps1": [
        "demo_prototype_visual_pass_check.gd",
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
                errors.append(f"{relative_path}: missing prototype visual pass text '{required_text}'")

    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1

    print("Client demo prototype visual pass checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
