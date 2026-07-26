#!/usr/bin/env python3
import sys
from pathlib import Path


REQUIRED_TEXT_BY_FILE = {
    "docs/archive/features-demo-v1/demo-initial-art-identity-v1.md": [
        "Demo Initial Art Identity V1",
        "初步美术识别与设备现场表现第一包",
        "DemoInitialArtIdentityLayer",
        "demo_initial_art_identity_check.gd",
    ],
    "docs/archive/features-demo-v1/demo-playable-content-substance-v1.md": [
        "初步美术识别与设备现场表现第一包",
        "DemoInitialArtIdentityLayer",
        "不新增第 13 区域",
    ],
    "client/scripts/systems/demo_initial_art_identity_profile.gd": [
        "class_name DemoInitialArtIdentityProfile",
        "ROLE_DEVICE",
        "MATERIAL_REACTOR_HEAT",
        "identity.demo_stabilization_core",
    ],
    "client/scripts/map/demo_initial_art_identity_layer.gd": [
        "class_name DemoInitialArtIdentityLayer",
        "GENERATED_IDENTITY_PREFIX",
        "apply_profile",
        "get_generated_shape_count",
    ],
    "client/scenes/maps/VerticalSliceMap.tscn": [
        "DemoInitialArtIdentityLayer",
        "demo_initial_art_identity_layer.gd",
    ],
    "client/scripts/checks/demo_initial_art_identity_check.gd": [
        "Demo initial art identity checks passed.",
        "_check_profile_scope_and_boundaries",
        "_check_scene_layer_applies_identity_shapes",
        "_check_representative_scene_nodes_are_tagged",
    ],
    "scripts/check-client.sh": [
        "check-client-demo-initial-art-identity.py",
        "demo_initial_art_identity_check.gd",
    ],
    "scripts/check-client.ps1": [
        "check-client-demo-initial-art-identity.ps1",
    ],
    "scripts/check-client-flow.ps1": [
        "demo_initial_art_identity_check.gd",
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
                errors.append(f"{relative_path}: missing demo initial art identity text '{required_text}'")

    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1

    print("Client demo initial art identity checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
