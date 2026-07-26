#!/usr/bin/env python3
import sys
from pathlib import Path


REQUIRED_TEXT_BY_FILE = {
    "docs/archive/features-demo-v1/demo-playable-scene-composition-v1.md": [
        "Demo Playable Scene Composition V1",
        "可玩场景构成",
        "不新增资源、配方、区域、任务链、完整背包或完整装备栏",
    ],
    "client/scripts/systems/playable_scene_composition_formatter.gd": [
        "class_name PlayableSceneCompositionFormatter",
        "format_map_route_hint",
        "format_object_composition_line",
        "前哨平台构成",
        "锚定桥构成",
        "核心稳定站构成",
    ],
    "client/scripts/ui/hud_map_presenter.gd": [
        "PlayableSceneCompositionFormatter.format_map_route_hint",
    ],
    "client/scripts/ui/interaction_prompt_formatter.gd": [
        "PlayableSceneCompositionFormatter.format_object_composition_line",
    ],
    "client/scripts/checks/playable_scene_composition_check.gd": [
        "Playable scene composition checks passed.",
        "_check_formatter_region_coverage",
        "_check_map_route_composition",
        "_check_object_prompt_composition",
        "_check_scene_object_region_placement",
    ],
    "scripts/check-client.sh": [
        "check-client-demo-playable-scene-composition.py",
        "playable_scene_composition_check.gd",
    ],
    "scripts/check-client.ps1": [
        "check-client-demo-playable-scene-composition.ps1",
    ],
    "scripts/check-client-flow.ps1": [
        "playable_scene_composition_check.gd",
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
                errors.append(f"{relative_path}: missing playable scene composition text '{required_text}'")

    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1

    print("Client demo playable scene composition checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
