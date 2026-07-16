#!/usr/bin/env python3
import sys
from pathlib import Path


REQUIRED_TEXT_BY_FILE = {
    "docs/archive/features-demo-v1/demo-functional-scene-gameplay-density-v1.md": [
        "Demo Functional Scene Gameplay Density V1",
        "功能 / 过渡场景玩法密度",
        "锁相框架",
        "锚定桥",
        "不新增资源、配方、区域、任务链、敌人类型、完整背包、完整装备栏或自动化物流",
    ],
    "client/scripts/systems/demo_functional_scene_gameplay_density_formatter.gd": [
        "class_name DemoFunctionalSceneGameplayDensityFormatter",
        "format_hud_summary",
        "format_object_density_line",
        "format_result_followup_line",
        "锁相框架小循环",
        "锚定桥小循环",
    ],
    "client/scripts/ui/hud_status_presenter.gd": [
        "DemoFunctionalSceneGameplayDensityFormatter.format_hud_summary",
    ],
    "client/scripts/ui/interaction_prompt_formatter.gd": [
        "DemoFunctionalSceneGameplayDensityFormatter.format_object_density_line",
        "DemoFunctionalSceneGameplayDensityFormatter.format_static_object_density_line",
    ],
    "client/scripts/systems/functional_scene_gameplay_formatter.gd": [
        "DemoFunctionalSceneGameplayDensityFormatter.format_result_followup_line",
    ],
    "client/scripts/map/phase_well_frontier_runtime.gd": [
        "DemoFunctionalSceneGameplayDensityFormatter.format_result_followup_line",
        "_with_density_followup",
    ],
    "client/scripts/checks/demo_functional_scene_gameplay_density_check.gd": [
        "Demo functional scene gameplay density checks passed.",
        "_check_hud_combines_scene_gameplay_and_density",
        "_check_interaction_prompt_shows_density_loop",
        "_check_runtime_results_advance_density_loop",
        "_check_phase_well_runtime_result_keeps_density_followup",
    ],
    "scripts/check-client.sh": [
        "check-client-demo-functional-scene-gameplay-density.py",
        "demo_functional_scene_gameplay_density_check.gd",
    ],
    "scripts/check-client.ps1": [
        "check-client-demo-functional-scene-gameplay-density.ps1",
    ],
    "scripts/check-client-flow.ps1": [
        "demo_functional_scene_gameplay_density_check.gd",
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
                errors.append(f"{relative_path}: missing demo functional scene gameplay density text '{required_text}'")

    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1

    print("Client demo functional scene gameplay density checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
