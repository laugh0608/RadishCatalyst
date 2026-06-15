#!/usr/bin/env python3
import sys
from pathlib import Path


REQUIRED_TEXT_BY_FILE = {
    "client/scripts/systems/scene_art_foundation_formatter.gd": [
        "class_name SceneArtFoundationFormatter",
        "format_hud_summary",
        "format_map_route_hint",
        "format_object_scene_line",
        "基地整备回路",
        "晶体矿脉资源线",
        "污染边界过滤线",
        "核心稳定站终点",
    ],
    "client/scenes/maps/VerticalSliceMap.tscn": [
        "SceneArtFoundationLayer",
        "SceneArtBaseIdentityLabel",
        "SceneArtCrystalIdentityLabel",
        "SceneArtPollutionIdentityLabel",
        "SceneArtCoreIdentityLabel",
    ],
    "client/scripts/ui/hud_map_presenter.gd": [
        "SceneArtFoundationFormatter.format_map_route_hint",
    ],
    "client/scripts/ui/hud_status_presenter.gd": [
        "SceneArtFoundationFormatter.format_hud_summary",
    ],
    "client/scripts/ui/interaction_prompt_formatter.gd": [
        "SceneArtFoundationFormatter.format_object_scene_line",
    ],
    "client/scripts/checks/scene_art_foundation_check.gd": [
        "Scene art foundation checks passed.",
        "_check_scene_identity_layer",
        "_check_formatter_core_regions",
        "_check_hud_and_map_readouts",
        "_check_object_prompts",
    ],
    "scripts/check-client.sh": [
        "check-client-scene-art-foundation.py",
        "scene_art_foundation_check.gd",
    ],
    "scripts/check-client-flow.ps1": [
        "scene_art_foundation_check.gd",
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
                errors.append(f"{relative_path}: missing scene art foundation text '{required_text}'")

    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1

    print("Client scene art foundation checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
