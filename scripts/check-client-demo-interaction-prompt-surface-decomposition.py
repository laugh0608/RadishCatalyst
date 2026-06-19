#!/usr/bin/env python3
import sys
from pathlib import Path


REQUIRED_TEXT_BY_FILE = {
    "docs/features/demo-interaction-prompt-surface-decomposition-v1.md": [
        "Demo Interaction Prompt Surface Decomposition V1",
        "交互提示承载面拆分",
        "加工设备交互提示",
    ],
    "client/scripts/ui/processing_interaction_prompt_formatter.gd": [
        "class_name ProcessingInteractionPromptFormatter",
        "format_processing_prompt",
        "format_processing_log",
        "DemoRouteReturnAndBaseReentryFormatter.format_device_status_line",
    ],
    "client/scripts/ui/interaction_prompt_formatter.gd": [
        "processing_prompt_formatter",
        "ProcessingInteractionPromptFormatter.new",
        "processing_prompt_formatter.format_processing_prompt",
        "processing_prompt_formatter.format_processing_log",
    ],
    "client/scripts/checks/demo_interaction_prompt_surface_decomposition_check.gd": [
        "Demo interaction prompt surface decomposition checks passed.",
        "_check_processing_prompt_delegation",
        "_check_processing_prompt_keeps_base_reentry_line",
        "_check_processing_log_delegation",
    ],
    "scripts/check-client.sh": [
        "check-client-demo-interaction-prompt-surface-decomposition.py",
        "demo_interaction_prompt_surface_decomposition_check.gd",
    ],
    "scripts/check-client.ps1": [
        "check-client-demo-interaction-prompt-surface-decomposition.ps1",
    ],
    "scripts/check-client-flow.ps1": [
        "demo_interaction_prompt_surface_decomposition_check.gd",
    ],
}

LINE_BUDGET_BY_FILE = {
    "client/scripts/ui/interaction_prompt_formatter.gd": 1450,
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
                errors.append(f"{relative_path}: missing interaction prompt surface text '{required_text}'")

    for relative_path, max_lines in LINE_BUDGET_BY_FILE.items():
        path = repo_root / relative_path
        if not path.is_file():
            errors.append(f"{relative_path}: missing file")
            continue
        line_count = len(path.read_text(encoding="utf-8").splitlines())
        if line_count >= max_lines:
            errors.append(f"{relative_path}: expected fewer than {max_lines} lines, got {line_count}")

    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1

    print("Client demo interaction prompt surface decomposition checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
