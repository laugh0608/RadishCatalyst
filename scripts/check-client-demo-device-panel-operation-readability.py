#!/usr/bin/env python3
import sys
from pathlib import Path


REQUIRED_TEXT_BY_FILE = {
    "docs/features/demo-device-panel-operation-readability-v1.md": [
        "Demo Device Panel Operation Readability V1",
        "设备面板操作读法",
        "前哨核心",
        "基础反应器",
        "污染过滤器",
        "出发整备台",
    ],
    "client/scripts/systems/demo_device_panel_operation_formatter.gd": [
        "class_name DemoDevicePanelOperationFormatter",
        "format_device_status_line",
        "format_processing_prompt_line",
        "format_processing_log_line",
        "format_result_feedback_line",
        "format_outpost_core_panel_line",
        "format_outfitting_station_panel_line",
        "操作读法",
        "缺料读法",
    ],
    "client/scripts/ui/hud_device_panel_presenter.gd": [
        "DemoDevicePanelOperationFormatter.format_device_status_line",
    ],
    "client/scripts/ui/processing_interaction_prompt_formatter.gd": [
        "DemoDevicePanelOperationFormatter.format_processing_prompt_line",
        "DemoDevicePanelOperationFormatter.format_processing_log_line",
    ],
    "client/scripts/ui/interaction_prompt_formatter.gd": [
        "DemoDevicePanelOperationFormatter.format_outpost_core_panel_line",
        "DemoDevicePanelOperationFormatter.format_outfitting_station_panel_line",
    ],
    "client/scripts/systems/processing_system.gd": [
        '"device_operation"',
        "DemoDevicePanelOperationFormatter.format_result_feedback_line",
    ],
    "client/scripts/ui/hud_log_presenter.gd": [
        '"device_operation"',
        '"设备"',
    ],
    "client/scripts/checks/demo_device_panel_operation_readability_check.gd": [
        "Demo device panel operation readability checks passed.",
        "_check_core_buffer_device_panel_operation_line",
        "_check_pollution_filter_prompt_and_log_operation_line",
        "_check_outpost_core_and_outfitting_prompts",
        "_check_processing_result_log_operation_line",
    ],
    "scripts/check-client.sh": [
        "check-client-demo-device-panel-operation-readability.py",
        "demo_device_panel_operation_readability_check.gd",
    ],
    "scripts/check-client.ps1": [
        "check-client-demo-device-panel-operation-readability.ps1",
    ],
    "scripts/check-client-flow.ps1": [
        "demo_device_panel_operation_readability_check.gd",
    ],
}

LINE_BUDGET_BY_FILE = {
    "client/scripts/ui/interaction_prompt_formatter.gd": 1450,
    "client/scripts/ui/hud_device_panel_presenter.gd": 320,
    "client/scripts/systems/processing_system.gd": 1000,
    "client/scripts/map/vertical_slice_map.gd": 1500,
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
                errors.append(f"{relative_path}: missing device panel operation text '{required_text}'")

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

    print("Client demo device panel operation readability checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
