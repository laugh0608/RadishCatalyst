#!/usr/bin/env python3
import sys
from pathlib import Path


REQUIRED_TEXT_BY_FILE = {
    "client/scripts/map/demo_core_stabilization_visual_layer.gd": [
        "class_name DemoCoreStabilizationVisualLayer",
        "station.guard_pressure_field",
        "station.writeback_device",
        "station.retest_readout",
        "flow.core_return_to_base",
        "PollutionToCoreHandoffArtPass",
        "operation_relation.core.guard_cache_to_write_device",
        "operation_relation.core.logistics_return",
        "refresh_focus_visibility",
        "_deemphasize_legacy_core_blocks",
        "map_object.demo_stabilization_core",
    ],
    "client/scenes/maps/VerticalSliceMap.tscn": [
        "DemoCoreStabilizationVisualLayer",
        "demo_core_stabilization_visual_layer.gd",
    ],
    "client/scripts/map/demo_pollution_to_core_handoff_art_pass.gd": [
        "class_name DemoPollutionToCoreHandoffArtPass",
        "get_core_shape_ids",
        "core_handoff.write_energy",
        "core_handoff.demo_hook",
    ],
    "client/scripts/checks/demo_core_stabilization_visual_check.gd": [
        "Demo core stabilization visual checks passed.",
        "_check_core_visual_layer_exists_and_registers_station_shapes",
        "_check_core_visual_operation_relation_shapes",
        "_check_core_visual_focus_visibility",
        "core relation links guard cache to write device",
        "_check_core_visual_layer_replaces_old_terminal_blocks",
        "_check_core_visual_runtime_anchors_are_tagged",
        "core handoff marks demo hook after write",
    ],
    "docs/devlogs/2026-W25.md": [
        "核心稳定站终点视觉第一轮",
        "DemoCoreStabilizationVisualLayer",
    ],
    "scripts/check-client.sh": [
        "check-client-demo-core-stabilization-visual.py",
        "demo_core_stabilization_visual_check.gd",
    ],
    "scripts/check-client.ps1": [
        "check-client-demo-core-stabilization-visual.ps1",
    ],
    "scripts/check-client-flow.ps1": [
        "demo_core_stabilization_visual_check.gd",
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
                errors.append(f"{relative_path}: missing core stabilization visual text '{required_text}'")

    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1

    print("Client demo core stabilization visual checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
