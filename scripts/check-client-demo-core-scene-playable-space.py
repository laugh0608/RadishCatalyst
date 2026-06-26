#!/usr/bin/env python3
import sys
from pathlib import Path


REQUIRED_TEXT_BY_FILE = {
    "docs/features/demo-core-scene-playable-space-v1.md": [
        "Demo Core Scene Playable Space V1",
        "核心场景空间第一包",
        "DemoCoreSceneSpaceLayer",
        "demo_core_scene_playable_space_check.gd",
    ],
    "docs/features/demo-playable-content-substance-v1.md": [
        "核心场景空间第一包",
        "DemoCoreSceneSpaceProfile",
        "DemoCoreSceneSpaceLayer",
        "不新增第 13 区域",
    ],
    "client/scripts/systems/demo_core_scene_space_profile.gd": [
        "class_name DemoCoreSceneSpaceProfile",
        "ROLE_GROUND",
        "ROLE_OBJECT_ANCHOR",
        "region.demo_stabilization_core",
    ],
    "client/scripts/map/demo_core_scene_space_layer.gd": [
        "class_name DemoCoreSceneSpaceLayer",
        "GENERATED_FRAME_PREFIX",
        "apply_profile",
        "get_tagged_node_count",
    ],
    "client/scenes/maps/VerticalSliceMap.tscn": [
        "DemoCoreSceneSpaceLayer",
        "demo_core_scene_space_layer.gd",
    ],
    "client/scripts/checks/demo_core_scene_playable_space_check.gd": [
        "Demo core scene playable space checks passed.",
        "_check_profile_covers_core_regions_without_expansion",
        "_check_scene_space_layer_applies_roles",
        "_check_representative_objects_and_enemies_sit_on_space_surfaces",
    ],
    "scripts/check-client.sh": [
        "check-client-demo-core-scene-playable-space.py",
        "demo_core_scene_playable_space_check.gd",
    ],
    "scripts/check-client.ps1": [
        "check-client-demo-core-scene-playable-space.ps1",
    ],
    "scripts/check-client-flow.ps1": [
        "demo_core_scene_playable_space_check.gd",
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
                errors.append(f"{relative_path}: missing demo core scene playable space text '{required_text}'")

    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1

    print("Client demo core scene playable space checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
