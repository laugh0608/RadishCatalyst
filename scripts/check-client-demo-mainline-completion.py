#!/usr/bin/env python3
import sys
from pathlib import Path


REQUIRED_TEXT_BY_FILE = {
    "client/scripts/systems/demo_mainline_completion_formatter.gd": [
        "class_name DemoMainlineCompletionFormatter",
        "is_demo_complete",
        "format_goal_name",
        "format_hud_summary",
        "format_map_route_hint",
        "format_core_object_status",
        "format_outpost_core_prompt_line",
        "format_completion_note",
        "首版 Demo 主线已完成",
        "Demo 终点已完成",
    ],
    "client/scripts/ui/hud_status_presenter.gd": [
        "DemoMainlineCompletionFormatter.format_goal_name",
        "DemoMainlineCompletionFormatter.format_progress_line",
        "DemoMainlineCompletionFormatter.is_demo_complete",
    ],
    "client/scripts/ui/hud_map_presenter.gd": [
        "DemoMainlineCompletionFormatter.format_map_route_hint",
    ],
    "client/scripts/ui/interaction_prompt_formatter.gd": [
        "DemoMainlineCompletionFormatter.format_core_object_status",
        "DemoMainlineCompletionFormatter.format_core_object_next_step",
        "DemoMainlineCompletionFormatter.format_outpost_core_prompt_line",
    ],
    "client/scripts/quests/quest_completion_applier.gd": [
        "DemoMainlineCompletionFormatter.format_completion_note",
    ],
    "client/scripts/checks/demo_mainline_completion_check.gd": [
        "Demo mainline completion checks passed.",
        "_check_hud_and_map_completion_readout",
        "_check_core_object_and_outpost_prompts",
        "_check_completion_log_reuses_mainline_note",
    ],
    "scripts/check-client.sh": [
        "check-client-demo-mainline-completion.py",
        "demo_mainline_completion_check.gd",
    ],
    "scripts/check-client-flow.ps1": [
        "demo_mainline_completion_check.gd",
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
                errors.append(f"{relative_path}: missing demo mainline completion text '{required_text}'")

    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1

    print("Client demo mainline completion checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
