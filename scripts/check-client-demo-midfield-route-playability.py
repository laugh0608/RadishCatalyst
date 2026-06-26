#!/usr/bin/env python3
import sys
from pathlib import Path


REQUIRED_TEXT_BY_FILE = {
    "docs/features/demo-midfield-route-playability-v1.md": [
        "Demo Midfield Route Playability V1",
        "中段异常地貌可玩路径",
        "回声台地 -> 盐壳浅滩 -> 碎晶沟谷",
        "不新增第 13 区域，不新增资源、配方、设备、敌人、任务链、存档字段或 UI 面板",
    ],
    "client/scripts/systems/demo_midfield_route_playability_formatter.gd": [
        "class_name DemoMidfieldRoutePlayabilityFormatter",
        "format_hud_summary",
        "format_map_route_hint",
        "format_object_route_line",
        "format_static_object_route_line",
        "format_result_followup_line",
        "回声台地中段路径",
        "盐壳浅滩中段路径",
        "碎晶沟谷中段路径",
    ],
    "client/scenes/maps/VerticalSliceMap.tscn": [
        "MidfieldRoutePlayabilityLayer",
        "EchoEntryLane",
        "EchoVentBoundary",
        "SaltCrustBoundary",
        "SaltSinkFacilityPocket",
        "CrystalShuntBoundary",
        "CrystalChamberFacilityPocket",
    ],
    "client/scripts/ui/hud_map_presenter.gd": [
        "DemoMidfieldRoutePlayabilityFormatter.format_map_route_hint",
    ],
    "client/scripts/ui/hud_status_presenter.gd": [
        "DemoMidfieldRoutePlayabilityFormatter.format_hud_summary",
    ],
    "client/scripts/ui/interaction_prompt_formatter.gd": [
        "DemoMidfieldRoutePlayabilityFormatter.format_object_route_line",
        "DemoMidfieldRoutePlayabilityFormatter.format_static_object_route_line",
    ],
    "client/scripts/systems/functional_scene_gameplay_formatter.gd": [
        "DemoMidfieldRoutePlayabilityFormatter.format_result_followup_line",
    ],
    "client/scripts/checks/demo_midfield_route_playability_check.gd": [
        "Demo midfield route playability checks passed.",
        "_check_scene_layer_marks_midfield_route",
        "_check_hud_and_map_midfield_readouts",
        "_check_object_prompts_show_midfield_route",
        "_check_runtime_results_keep_midfield_followup",
    ],
    "scripts/check-client.sh": [
        "check-client-demo-midfield-route-playability.py",
        "demo_midfield_route_playability_check.gd",
    ],
    "scripts/check-client.ps1": [
        "check-client-demo-midfield-route-playability.ps1",
    ],
    "scripts/check-client-flow.ps1": [
        "demo_midfield_route_playability_check.gd",
    ],
}

LINE_BUDGET_BY_FILE = {
    "client/scripts/map/vertical_slice_map.gd": 1500,
    "client/scripts/ui/interaction_prompt_formatter.gd": 1500,
    "client/scripts/systems/gather_system.gd": 1500,
}


def read_text(repo_root: Path, relative_path: str, errors: list[str]) -> str:
    path = repo_root / relative_path
    if not path.is_file():
        errors.append(f"{relative_path}: missing file")
        return ""
    return path.read_text(encoding="utf-8")


def main() -> int:
    repo_root = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path(__file__).resolve().parents[1]
    errors: list[str] = []

    for relative_path, required_texts in REQUIRED_TEXT_BY_FILE.items():
        content = read_text(repo_root, relative_path, errors)
        if not content:
            continue
        for required_text in required_texts:
            if required_text not in content:
                errors.append(f"{relative_path}: missing midfield route playability text '{required_text}'")

    for relative_path, max_lines in LINE_BUDGET_BY_FILE.items():
        content = read_text(repo_root, relative_path, errors)
        if not content:
            continue
        line_count = len(content.splitlines())
        if line_count >= max_lines:
            errors.append(f"{relative_path}: expected fewer than {max_lines} lines, got {line_count}")

    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1

    print("Client demo midfield route playability checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
