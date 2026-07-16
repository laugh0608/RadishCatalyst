#!/usr/bin/env python3
import sys
from pathlib import Path


REQUIRED_TEXT_BY_FILE = {
    "docs/archive/features-demo-v1/demo-field-loop-payoff-v1.md": [
        "Demo Field Loop Payoff V1",
        "外勤回基地收益兑现",
        "不新增资源、配方、区域、任务链、完整背包、完整装备栏或自动化物流",
    ],
    "client/scripts/systems/demo_field_loop_payoff_formatter.gd": [
        "class_name DemoFieldLoopPayoffFormatter",
        "FIELD_LOOP_PAYOFF_CONFIRMED_FLAG",
        "format_hud_summary",
        "format_outfitting_prompt_line",
        "format_pressure_feedback",
    ],
    "client/scripts/systems/field_outfitting_runtime.gd": [
        "should_confirm_field_loop_payoff",
        "mark_field_loop_payoff_confirmed",
        "has_active_field_loop_payoff",
        "FIELD_LOOP_PAYOFF_PRESSURE_MULT",
    ],
    "client/scripts/systems/gather_system.gd": [
        "_confirm_field_loop_payoff",
        "field_loop_payoff_confirmed",
        "外勤收益兑现完成",
    ],
    "client/scripts/ui/departure_readiness_formatter.gd": [
        "DemoFieldLoopPayoffFormatter.format_hud_summary",
        "format_departure_next_step",
        "DemoFieldLoopPayoffFormatter.format_compact_state",
    ],
    "client/scripts/ui/interaction_prompt_formatter.gd": [
        "DemoFieldLoopPayoffFormatter.format_outfitting_prompt_line",
        "E 确认外勤收益整备",
    ],
    "client/scripts/save/save_content_validator.gd": [
        "field_loop_payoff_confirmed",
    ],
    "client/scripts/checks/demo_field_loop_payoff_check.gd": [
        "Demo field loop payoff checks passed.",
        "_check_outfitting_prompt_and_confirmation",
        "_check_pressure_payoff_runtime",
        "_check_payoff_state_roundtrip",
    ],
    "scripts/check-client.sh": [
        "check-client-demo-field-loop-payoff.py",
        "demo_field_loop_payoff_check.gd",
    ],
    "scripts/check-client-flow.ps1": [
        "demo_field_loop_payoff_check.gd",
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
                errors.append(f"{relative_path}: missing demo field loop payoff text '{required_text}'")

    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1

    print("Client demo field loop payoff checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
