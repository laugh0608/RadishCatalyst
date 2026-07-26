#!/usr/bin/env python3
import re
import sys
from pathlib import Path


REQUIRED_TEXT_BY_FILE = {
    "docs/archive/features-demo-v1/demo-map-surface-decomposition-v1.md": [
        "Demo Map Surface Decomposition V1",
        "地图区域 / gate 承载面",
        "区域判断、gate 回退、回投坐标和对象区域归属由窄职责 helper 承载",
    ],
    "client/scripts/map/vertical_slice_map_surface.gd": [
        "class_name VerticalSliceMapSurface",
        "static func get_region_id_for_position",
        "static func resolve_region_gate_block",
        "static func get_phase_relay_pad_return_position",
        "static func get_phase_return_anchor_return_position",
        "static func get_interactable_region_id",
    ],
    "client/scripts/map/vertical_slice_map.gd": [
        "VerticalSliceMapSurface.resolve_region_gate_block",
        "VerticalSliceMapSurface.get_phase_relay_pad_return_position",
        "VerticalSliceMapSurface.get_phase_return_anchor_return_position",
        "VerticalSliceMapSurface.get_interactable_region_id",
        "VerticalSliceMapSurface.get_region_id_for_position",
    ],
    "client/scripts/checks/demo_map_surface_decomposition_check.gd": [
        "Demo map surface decomposition checks passed.",
        "_check_region_resolution",
        "_check_gate_fallbacks",
        "_check_return_positions_and_object_regions",
    ],
    "scripts/check-client.sh": [
        "check-client-demo-map-surface-decomposition.py",
        "demo_map_surface_decomposition_check.gd",
    ],
    "scripts/check-client.ps1": [
        "check-client-demo-map-surface-decomposition.ps1",
    ],
    "scripts/check-client-flow.ps1": [
        "demo_map_surface_decomposition_check.gd",
    ],
}

FORBIDDEN_TEXT_BY_FILE = {
    "client/scripts/map/vertical_slice_map.gd": [
        "晶体矿脉区尚未标记：先检查前哨核心，恢复基础导航。",
        "遗迹外圈深段仍被抖动雾幕阻断：先回基地组装稳相信标，再返回部署。",
        "func _is_outer_ring_barrier_locked",
        "func _is_deep_ruin_gate_locked",
        "map_position.x >= DEMO_STABILIZATION_CORE_REGION_X",
    ],
}

LINE_BUDGET_BY_FILE = {
    "client/scripts/map/vertical_slice_map.gd": 1425,
}

SURFACE_CONSTANT_NAMES = [
    "CRYSTAL_REGION_X",
    "CRYSTAL_GATE_RETURN_X",
    "POLLUTION_REGION_X",
    "POLLUTION_DEEP_Y",
    "POLLUTION_GATE_RETURN_X",
    "RUIN_OUTER_RING_X",
    "RUIN_GATE_RETURN_X",
    "OUTER_RING_BARRIER_X",
    "OUTER_RING_BARRIER_RETURN_X",
    "DEEP_RUIN_REGION_X",
    "INNER_PHASE_WELL_REGION_X",
    "PHASE_WELL_SINK_REGION_X",
    "PHASE_WELL_CHAMBER_REGION_X",
    "PHASE_WELL_LOOM_REGION_X",
    "PHASE_WELL_FRAME_REGION_X",
    "PHASE_WELL_TETHER_REGION_X",
    "DEMO_STABILIZATION_CORE_REGION_X",
    "DEEP_RUIN_GATE_RETURN_X",
    "INNER_PHASE_WELL_GATE_RETURN_X",
    "PHASE_WELL_SINK_GATE_RETURN_X",
    "PHASE_WELL_CHAMBER_GATE_RETURN_X",
    "PHASE_WELL_LOOM_GATE_RETURN_X",
    "PHASE_WELL_FRAME_GATE_RETURN_X",
    "PHASE_WELL_TETHER_GATE_RETURN_X",
    "DEMO_STABILIZATION_CORE_GATE_RETURN_X",
    "PHASE_RELAY_PAD_FALLBACK_POSITION",
    "PHASE_RETURN_ANCHOR_FALLBACK_POSITION",
]

EXPECTED_REGION_IDS = {
    "region.outpost_platform",
    "region.crystal_vein_field",
    "region.pollution_edge",
    "region.ruin_outer_ring",
    "region.deep_ruin_threshold",
    "region.inner_phase_well",
    "region.phase_well_sink",
    "region.phase_well_chamber",
    "region.phase_well_loom",
    "region.phase_well_frame",
    "region.phase_well_tether",
    "region.demo_stabilization_core",
}


def read_text(repo_root: Path, relative_path: str, errors: list[str]) -> str:
    path = repo_root / relative_path
    if not path.is_file():
        errors.append(f"{relative_path}: missing file")
        return ""
    return path.read_text(encoding="utf-8")


def get_constant_value(content: str, constant_name: str) -> str:
    match = re.search(
        rf"^const {re.escape(constant_name)} := (?P<value>Vector2\([^)]+\)|-?\d+(\.\d+)?)$",
        content,
        re.MULTILINE,
    )
    return match.group("value") if match else ""


def main() -> int:
    repo_root = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path(__file__).resolve().parents[1]
    errors: list[str] = []

    for relative_path, required_texts in REQUIRED_TEXT_BY_FILE.items():
        content = read_text(repo_root, relative_path, errors)
        if not content:
            continue
        for required_text in required_texts:
            if required_text not in content:
                errors.append(f"{relative_path}: missing map surface decomposition text '{required_text}'")

    for relative_path, forbidden_texts in FORBIDDEN_TEXT_BY_FILE.items():
        content = read_text(repo_root, relative_path, errors)
        if not content:
            continue
        for forbidden_text in forbidden_texts:
            if forbidden_text in content:
                errors.append(f"{relative_path}: should not contain '{forbidden_text}' after map surface decomposition")

    for relative_path, max_lines in LINE_BUDGET_BY_FILE.items():
        content = read_text(repo_root, relative_path, errors)
        if not content:
            continue
        line_count = len(content.splitlines())
        if line_count >= max_lines:
            errors.append(f"{relative_path}: expected fewer than {max_lines} lines, got {line_count}")

    map_content = read_text(repo_root, "client/scripts/map/vertical_slice_map.gd", errors)
    surface_content = read_text(repo_root, "client/scripts/map/vertical_slice_map_surface.gd", errors)
    if map_content and surface_content:
        for constant_name in SURFACE_CONSTANT_NAMES:
            map_value = get_constant_value(map_content, constant_name)
            surface_value = get_constant_value(surface_content, constant_name)
            if not map_value:
                errors.append(f"client/scripts/map/vertical_slice_map.gd: missing public constant {constant_name}")
                continue
            if not surface_value:
                errors.append(f"client/scripts/map/vertical_slice_map_surface.gd: missing helper constant {constant_name}")
                continue
            if map_value != surface_value:
                errors.append(f"{constant_name}: map value {map_value} should match helper value {surface_value}")

        helper_region_ids = set(re.findall(r'return "(region\.[^"]+)"', surface_content))
        if helper_region_ids != EXPECTED_REGION_IDS:
            errors.append(
                "client/scripts/map/vertical_slice_map_surface.gd: expected 12 demo regions, got "
                + ", ".join(sorted(helper_region_ids))
            )

    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1

    print("Client demo map surface decomposition checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
