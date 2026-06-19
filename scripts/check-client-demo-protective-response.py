#!/usr/bin/env python3
import sys
from pathlib import Path


REQUIRED_TEXT_BY_FILE = {
    "docs/features/demo-protective-response-v1.md": [
        "Demo Protective Response V1",
        "基础防护服",
        "基础过滤模块",
        "防护响应",
    ],
    "client/scripts/systems/field_outfitting_runtime.gd": [
        "PROTECTIVE_RESPONSE_READY_FLAG",
        "PROTECTIVE_RESPONSE_TRIGGERED_FLAG",
        "can_confirm_protective_response",
        "consume_protective_response",
        "format_protective_response_counter_feedback",
    ],
    "client/scripts/systems/gather_system.gd": [
        "_confirm_protective_response",
        "protective_response_ready",
        "防护响应已待命",
    ],
    "client/scripts/map/enemy_counterattack_runtime.gd": [
        "consume_protective_response",
        "PROTECTIVE_RESPONSE_COUNTER_MULT",
        "format_protective_response_counter_feedback",
    ],
    "client/scripts/ui/departure_readiness_formatter.gd": [
        "format_protective_response_compact_state",
        "防护响应待命",
    ],
    "client/scripts/ui/interaction_prompt_formatter.gd": [
        "format_protective_response_prompt_line",
        "E 确认防护响应",
    ],
    "client/scripts/checks/demo_protective_response_check.gd": [
        "Demo protective response checks passed.",
        "_check_outfitting_prompt_and_confirmation",
        "_check_calibration_keeps_priority",
        "_check_counterattack_consumes_response",
        "_check_triggered_response_requires_refit_before_reconfirm",
    ],
    "scripts/check-client.sh": [
        "check-client-demo-protective-response.py",
        "demo_protective_response_check.gd",
    ],
    "scripts/check-client-flow.ps1": [
        "demo_protective_response_check.gd",
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
                errors.append(f"{relative_path}: missing demo protective response text '{required_text}'")

    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1

    print("Client demo protective response checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
