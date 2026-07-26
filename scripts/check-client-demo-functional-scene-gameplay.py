#!/usr/bin/env python3
import sys
from pathlib import Path


REQUIRED_TEXT_BY_FILE = {
    "docs/archive/features-demo-v1/demo-functional-scene-gameplay-v1.md": [
        "Demo Functional Scene Gameplay V1",
        "功能场景玩法",
        "封锁遗迹",
        "锚定桥",
        "不新增资源、配方、区域、任务链、完整背包、完整装备栏或自动化物流",
    ],
    "client/scripts/systems/functional_scene_gameplay_formatter.gd": [
        "class_name FunctionalSceneGameplayFormatter",
        "format_hud_summary",
        "format_object_gameplay_line",
        "format_result_followup_line",
        "碎晶沟谷现场玩法",
        "锚定桥现场玩法",
    ],
    "client/scripts/ui/hud_status_presenter.gd": [
        "FunctionalSceneGameplayFormatter.format_hud_summary",
    ],
    "client/scripts/ui/interaction_prompt_formatter.gd": [
        "FunctionalSceneGameplayFormatter.format_object_gameplay_line",
        "FunctionalSceneGameplayFormatter.format_static_object_gameplay_line",
    ],
    "client/scripts/systems/gather_system.gd": [
        "FunctionalSceneGameplayFormatter.format_result_followup_line",
        "_with_functional_scene_gameplay_followup",
    ],
    "client/scripts/checks/functional_scene_gameplay_check.gd": [
        "Functional scene gameplay checks passed.",
        "_check_hud_summary_uses_scene_gameplay",
        "_check_interaction_prompts_show_scene_gameplay",
        "_check_runtime_interaction_results_show_scene_gameplay",
    ],
    "scripts/check-client.sh": [
        "check-client-demo-functional-scene-gameplay.py",
        "functional_scene_gameplay_check.gd",
    ],
    "scripts/check-client.ps1": [
        "check-client-demo-functional-scene-gameplay.ps1",
    ],
    "scripts/check-client-flow.ps1": [
        "functional_scene_gameplay_check.gd",
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
                errors.append(f"{relative_path}: missing demo functional scene gameplay text '{required_text}'")

    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1

    print("Client demo functional scene gameplay checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
