#!/usr/bin/env python3
import sys
from pathlib import Path


REQUIRED_TEXT_BY_FILE = {
    "docs/features/demo-action-feedback-readability-v1.md": [
        "Demo Action Feedback Readability V1",
        "第一包实施范围",
        "DemoActionFeedbackFormatter",
        "不新增资源、配方、区域、任务链、敌人类型、完整背包或完整装备栏",
    ],
    "client/scripts/systems/demo_action_feedback_formatter.gd": [
        "class_name DemoActionFeedbackFormatter",
        "format_gather_success_feedback",
        "format_sample_success_feedback",
        "format_clear_success_feedback",
        "format_core_write_success_feedback",
        "format_enemy_defeat_success_feedback",
        "format_outpost_core_success_feedback",
    ],
    "client/scripts/systems/gather_system.gd": [
        "DemoActionFeedbackFormatter.format_gather_success_feedback",
        "DemoActionFeedbackFormatter.format_sample_success_feedback",
        "DemoActionFeedbackFormatter.format_clear_success_feedback",
        "DemoActionFeedbackFormatter.format_core_write_success_feedback",
        "DemoActionFeedbackFormatter.format_outpost_core_success_feedback",
    ],
    "client/scripts/map/vertical_slice_map.gd": [
        "DemoActionFeedbackFormatter.format_enemy_defeat_success_feedback",
    ],
    "client/scripts/checks/demo_action_feedback_readability_check.gd": [
        "Demo action feedback readability checks passed.",
        "_check_gather_sample_and_clear_feedback",
        "_check_build_and_processing_feedback",
        "_check_enemy_defeat_feedback",
        "_check_core_write_and_outpost_feedback",
    ],
    "scripts/check-client.sh": [
        "check-client-demo-action-feedback-readability.py",
        "demo_action_feedback_readability_check.gd",
    ],
    "scripts/check-client.ps1": [
        "check-client-demo-action-feedback-readability.ps1",
    ],
    "scripts/check-client-flow.ps1": [
        "demo_action_feedback_readability_check.gd",
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
                errors.append(f"{relative_path}: missing demo action feedback readability text '{required_text}'")

    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1

    print("Client demo action feedback readability checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
