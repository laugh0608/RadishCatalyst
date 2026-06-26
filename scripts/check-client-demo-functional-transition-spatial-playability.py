#!/usr/bin/env python3
import sys
from pathlib import Path


REQUIRED_TEXT_BY_FILE = {
    "docs/features/demo-functional-transition-spatial-playability-v1.md": [
        "Demo Functional Transition Spatial Playability V1",
        "功能 / 过渡场景可达空间",
        "封锁遗迹到裂相脊",
        "不新增资源、配方、任务链、敌人类型、完整背包、完整装备栏或自动化物流",
    ],
    "client/scripts/systems/demo_functional_transition_spatial_playability_formatter.gd": [
        "class_name DemoFunctionalTransitionSpatialPlayabilityFormatter",
        "format_hud_summary",
        "format_map_route_hint",
        "format_static_object_spatial_line",
        "format_result_followup_line",
        "封锁遗迹可达空间",
        "裂相脊可达空间",
    ],
    "client/scenes/maps/VerticalSliceMap.tscn": [
        "FunctionalTransitionSpatialPlayabilityLayer",
        "RuinEntranceLane",
        "RuinBarrierBoundary",
        "RuinHazardReturnPocket",
        "RidgeEntranceLane",
        "RidgeLatchBoundary",
        "RidgeReturnAnchorPocket",
    ],
    "client/scripts/ui/hud_map_presenter.gd": [
        "DemoFunctionalTransitionSpatialPlayabilityFormatter.format_map_route_hint",
    ],
    "client/scripts/ui/hud_status_presenter.gd": [
        "DemoFunctionalTransitionSpatialPlayabilityFormatter.format_hud_summary",
    ],
    "client/scripts/systems/functional_transition_route_support_formatter.gd": [
        "DemoFunctionalTransitionSpatialPlayabilityFormatter.format_static_object_spatial_line",
    ],
    "client/scripts/systems/functional_scene_gameplay_formatter.gd": [
        "DemoFunctionalTransitionSpatialPlayabilityFormatter.format_result_followup_line",
    ],
    "client/scripts/checks/demo_functional_transition_spatial_playability_check.gd": [
        "Demo functional transition spatial playability checks passed.",
        "_check_scene_layer_marks_representative_path",
        "_check_hud_and_map_spatial_readouts",
        "_check_object_prompts_show_spatial_playability",
        "_check_runtime_results_keep_spatial_followup",
    ],
    "scripts/check-client.sh": [
        "check-client-demo-functional-transition-spatial-playability.py",
        "demo_functional_transition_spatial_playability_check.gd",
    ],
    "scripts/check-client.ps1": [
        "check-client-demo-functional-transition-spatial-playability.ps1",
    ],
    "scripts/check-client-flow.ps1": [
        "demo_functional_transition_spatial_playability_check.gd",
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
                errors.append(f"{relative_path}: missing functional transition spatial playability text '{required_text}'")

    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1

    print("Client demo functional transition spatial playability checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
