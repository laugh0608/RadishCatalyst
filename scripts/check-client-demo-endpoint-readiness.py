#!/usr/bin/env python3
import sys
from pathlib import Path


REQUIRED_TEXT_BY_FILE = {
    "docs/features/demo-endpoint-readiness-v1.md": [
        "Demo Endpoint Readiness V1",
        "终点前综合准备读法",
        "不新增资源、配方、区域、任务链、完整背包、完整装备栏、终局菜单或发布准备流程",
    ],
    "client/scripts/systems/demo_endpoint_readiness_formatter.gd": [
        "class_name DemoEndpointReadinessFormatter",
        "is_endpoint_readiness_context",
        "format_hud_summary",
        "format_departure_gate_next_step",
        "format_core_object_status_line",
    ],
    "client/scripts/ui/hud_status_presenter.gd": [
        "DemoEndpointReadinessFormatter.format_hud_summary",
    ],
    "client/scripts/ui/departure_readiness_formatter.gd": [
        "DemoEndpointReadinessFormatter.format_outpost_core_prompt_line",
        "DemoEndpointReadinessFormatter.format_departure_gate_status_line",
        "DemoEndpointReadinessFormatter.format_departure_gate_next_step",
    ],
    "client/scripts/ui/interaction_prompt_formatter.gd": [
        "DemoEndpointReadinessFormatter.format_core_object_status_line",
        "DemoEndpointReadinessFormatter.format_core_object_next_step",
    ],
    "client/scripts/checks/demo_endpoint_readiness_check.gd": [
        "Demo endpoint readiness checks passed.",
        "_check_hud_outpost_and_departure_gate_readiness",
        "_check_core_device_write_readiness",
        "_check_context_boundaries",
    ],
    "scripts/check-client.sh": [
        "check-client-demo-endpoint-readiness.py",
        "demo_endpoint_readiness_check.gd",
    ],
    "scripts/check-client-flow.ps1": [
        "demo_endpoint_readiness_check.gd",
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
                errors.append(f"{relative_path}: missing demo endpoint readiness text '{required_text}'")

    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1

    print("Client demo endpoint readiness checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
