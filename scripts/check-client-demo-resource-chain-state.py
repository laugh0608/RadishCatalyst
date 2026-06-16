#!/usr/bin/env python3
import sys
from pathlib import Path


REQUIRED_TEXT_BY_FILE = {
    "docs/features/demo-resource-chain-state-v1.md": [
        "Demo Resource Chain State V1",
        "资源 / 生产链",
        "状态序列化",
    ],
    "client/scripts/systems/demo_resource_chain_state_formatter.gd": [
        "class_name DemoResourceChainStateFormatter",
        "get_core_resource_ids",
        "format_hud_summary",
        "format_device_status_line",
        "format_result_feedback_line",
        "核心稳压缓冲包",
    ],
    "client/scripts/ui/hud_status_presenter.gd": [
        "DemoResourceChainStateFormatter.format_hud_summary",
    ],
    "client/scripts/ui/hud_device_panel_presenter.gd": [
        "DemoResourceChainStateFormatter.format_device_status_line",
    ],
    "client/scripts/systems/processing_system.gd": [
        "resource_chain",
        "show_resource_chain",
        "DemoResourceChainStateFormatter.format_result_feedback_line",
    ],
    "client/scripts/ui/hud_log_presenter.gd": [
        '"资源链"',
        "resource_chain",
    ],
    "client/scripts/checks/demo_resource_chain_state_check.gd": [
        "Demo resource chain state checks passed.",
        "_check_core_resource_scope",
        "_check_hud_resource_chain_state",
        "_check_device_panel_resource_chain_state",
        "_check_processing_result_resource_chain",
        "_check_resource_chain_state_roundtrip",
    ],
    "scripts/check-client.sh": [
        "check-client-demo-resource-chain-state.py",
        "demo_resource_chain_state_check.gd",
    ],
    "scripts/check-client-flow.ps1": [
        "demo_resource_chain_state_check.gd",
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
                errors.append(f"{relative_path}: missing demo resource chain state text '{required_text}'")

    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1

    print("Client demo resource chain state checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
