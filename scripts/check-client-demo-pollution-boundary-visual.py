#!/usr/bin/env python3
import sys
from pathlib import Path


REQUIRED_TEXT_BY_FILE = {
    "client/scripts/map/demo_pollution_boundary_visual_layer.gd": [
        "class_name DemoPollutionBoundaryVisualLayer",
        "boundary.filter_build_site",
        "boundary.pressure_gate",
        "residue.entry_patch",
        "flow.filter_to_base_return",
        "refresh_focus_visibility",
        "_deemphasize_legacy_pollution_blocks",
        "map_object.pollution_residue_patch",
    ],
    "client/scenes/maps/VerticalSliceMap.tscn": [
        "DemoPollutionBoundaryVisualLayer",
        "demo_pollution_boundary_visual_layer.gd",
    ],
    "client/scripts/checks/demo_pollution_boundary_visual_check.gd": [
        "Demo pollution boundary visual checks passed.",
        "_check_pollution_boundary_layer_exists_and_registers_visuals",
        "_check_pollution_boundary_focus_visibility",
        "_check_pollution_boundary_visual_priority_replaces_old_blocks",
        "_check_pollution_boundary_runtime_anchors_are_tagged",
    ],
    "docs/devlogs/2026-W25.md": [
        "污染处理边界视觉第一轮",
        "DemoPollutionBoundaryVisualLayer",
    ],
    "scripts/check-client.sh": [
        "check-client-demo-pollution-boundary-visual.py",
        "demo_pollution_boundary_visual_check.gd",
    ],
    "scripts/check-client.ps1": [
        "check-client-demo-pollution-boundary-visual.ps1",
    ],
    "scripts/check-client-flow.ps1": [
        "demo_pollution_boundary_visual_check.gd",
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
                errors.append(f"{relative_path}: missing pollution boundary visual text '{required_text}'")

    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1

    print("Client demo pollution boundary visual checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
