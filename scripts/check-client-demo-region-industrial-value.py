#!/usr/bin/env python3
import sys
from pathlib import Path


REQUIRED_TEXT_BY_FILE = {
    "client/scripts/map/demo_region_industrial_value_layer.gd": [
        "class_name DemoRegionIndustrialValueLayer",
        "REGION_VALUE_PROFILES",
        "ROLE_RESOURCE",
        "ROLE_RISK",
        "ROLE_UNLOCK",
        "ROLE_STABILITY",
        "ROLE_LOGISTICS",
        "get_value_node_count",
        "is_region_value_route_visible",
        "industrial_value_role",
        "region.demo_stabilization_core",
    ],
    "client/scenes/maps/VerticalSliceMap.tscn": [
        "DemoRegionIndustrialValueLayer",
        "demo_region_industrial_value_layer.gd",
    ],
    "client/scripts/checks/demo_region_industrial_value_check.gd": [
        "Demo region industrial value checks passed.",
        "_check_region_industrial_value_layer_exists",
        "_check_region_value_roles_cover_twelve_regions",
        "_check_region_value_routes_stay_local",
        "_check_region_backgrounds_are_tagged",
        "_check_no_thirteenth_region_is_added",
    ],
    "docs/devlogs/2026-W25.md": [
        "12 区工业职责",
        "DemoRegionIndustrialValueLayer",
    ],
    "scripts/check-client.sh": [
        "check-client-demo-region-industrial-value.py",
        "demo_region_industrial_value_check.gd",
    ],
    "scripts/check-client.ps1": [
        "check-client-demo-region-industrial-value.ps1",
    ],
    "scripts/check-client-flow.ps1": [
        "demo_region_industrial_value_check.gd",
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
                errors.append(f"{relative_path}: missing demo region industrial value text '{required_text}'")

    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1

    print("Client demo region industrial value checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
