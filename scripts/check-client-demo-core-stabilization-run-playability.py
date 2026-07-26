#!/usr/bin/env python3
import sys
from pathlib import Path


REQUIRED_TEXT_BY_FILE = {
    "docs/archive/features-demo-v1/demo-core-stabilization-run-playability-v1.md": [
        "Demo Core Stabilization Run Playability V1",
        "核心稳定站内可玩路径",
        "入口确认 -> 侧边补给 -> 稳压缓冲包 -> 阶段守卫 -> 回写缓存 -> 核心写入",
        "不新增第 13 区域，不新增资源、配方、设备、敌人、任务链、存档字段或 UI 面板",
    ],
    "client/scripts/systems/demo_core_stabilization_run_formatter.gd": [
        "class_name DemoCoreStabilizationRunFormatter",
        "format_hud_summary",
        "format_map_route_hint",
        "format_object_run_line",
        "format_result_followup_line",
        "format_guard_defeat_followup",
        "入口确认 -> 侧边补给 -> 稳压缓冲包 -> 阶段守卫 -> 回写缓存 -> 核心写入",
    ],
    "client/scenes/maps/VerticalSliceMap.tscn": [
        "CoreStabilizationRunLayer",
        "CoreRunEntryCheck",
        "CoreRunSideSupply",
        "CoreRunBufferReturn",
        "CoreRunGuardField",
        "CoreRunGuardCache",
        "CoreRunWritePad",
    ],
    "client/scripts/ui/hud_status_presenter.gd": [
        "DemoCoreStabilizationRunFormatter.format_hud_summary",
    ],
    "client/scripts/ui/hud_map_presenter.gd": [
        "DemoCoreStabilizationRunFormatter.format_map_route_hint",
    ],
    "client/scripts/ui/interaction_prompt_formatter.gd": [
        "DemoCoreStabilizationRunFormatter.format_object_run_line",
    ],
    "client/scripts/systems/gather_system.gd": [
        "DemoCoreStabilizationRunFormatter.format_result_followup_line",
    ],
    "client/scripts/map/vertical_slice_map.gd": [
        "DemoCoreStabilizationRunFormatter.format_guard_defeat_followup",
    ],
    "client/scripts/checks/demo_core_stabilization_run_playability_check.gd": [
        "Demo core stabilization run playability checks passed.",
        "_check_scene_layer_marks_core_station_run",
        "_check_hud_and_map_show_core_station_run",
        "_check_object_prompts_show_core_station_run",
        "_check_results_show_core_station_run_followup",
    ],
    "scripts/check-client.sh": [
        "check-client-demo-core-stabilization-run-playability.py",
        "demo_core_stabilization_run_playability_check.gd",
    ],
    "scripts/check-client.ps1": [
        "check-client-demo-core-stabilization-run-playability.ps1",
    ],
    "scripts/check-client-flow.ps1": [
        "demo_core_stabilization_run_playability_check.gd",
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
                errors.append(f"{relative_path}: missing core stabilization run text '{required_text}'")

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

    print("Client demo core stabilization run playability checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
