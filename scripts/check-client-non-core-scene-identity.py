#!/usr/bin/env python3
import sys
from pathlib import Path


REQUIRED_TEXT_BY_FILE = {
    "docs/features/demo-non-core-scene-identity-v1.md": [
        "Demo Non-Core Scene Identity V1",
        "非核心区域场景识别",
        "封锁遗迹",
        "锚定桥",
    ],
    "client/scripts/systems/non_core_scene_identity_formatter.gd": [
        "class_name NonCoreSceneIdentityFormatter",
        "format_map_route_hint",
        "format_object_scene_line",
        "封锁遗迹旧设施区",
        "锚定桥稳定接入区",
    ],
    "client/scenes/maps/VerticalSliceMap.tscn": [
        "NonCoreSceneIdentityLayer",
        "NonCoreRuinIdentityLabel",
        "NonCoreRidgeIdentityLabel",
        "NonCoreAnchorBridgeIdentityLabel",
    ],
    "client/scripts/ui/hud_map_presenter.gd": [
        "NonCoreSceneIdentityFormatter.format_map_route_hint",
    ],
    "client/scripts/ui/interaction_prompt_formatter.gd": [
        "NonCoreSceneIdentityFormatter.format_object_scene_line",
    ],
    "client/scripts/checks/non_core_scene_identity_check.gd": [
        "Non-core scene identity checks passed.",
        "_check_scene_identity_layer",
        "_check_formatter_non_core_regions",
        "_check_hud_and_map_readouts",
        "_check_object_prompts",
    ],
    "scripts/check-client.sh": [
        "check-client-non-core-scene-identity.py",
        "non_core_scene_identity_check.gd",
    ],
    "scripts/check-client-flow.ps1": [
        "non_core_scene_identity_check.gd",
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
                errors.append(f"{relative_path}: missing non-core scene identity text '{required_text}'")

    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1

    print("Client non-core scene identity checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
