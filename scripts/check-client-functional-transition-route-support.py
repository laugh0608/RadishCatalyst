#!/usr/bin/env python3
import sys
from pathlib import Path


REQUIRED_TEXT_BY_FILE = {
    "docs/features/demo-functional-transition-route-support-v1.md": [
        "Demo Functional Transition Route Support V1",
        "功能 / 过渡路线支撑",
        "封锁遗迹",
        "锚定桥",
    ],
    "client/scripts/systems/functional_transition_route_support_formatter.gd": [
        "class_name FunctionalTransitionRouteSupportFormatter",
        "format_hud_summary",
        "format_map_route_hint",
        "format_object_route_line",
        "封锁遗迹机制展示线",
        "锚定桥稳定工程接入线",
    ],
    "client/scripts/ui/hud_map_presenter.gd": [
        "FunctionalTransitionRouteSupportFormatter.format_map_route_hint",
    ],
    "client/scripts/ui/hud_status_presenter.gd": [
        "FunctionalTransitionRouteSupportFormatter.format_hud_summary",
    ],
    "client/scripts/ui/interaction_prompt_formatter.gd": [
        "FunctionalTransitionRouteSupportFormatter.format_object_route_line",
        "_with_functional_transition_line",
    ],
    "client/scripts/checks/functional_transition_route_support_check.gd": [
        "Functional transition route support checks passed.",
        "_check_formatter_covers_functional_and_transition_regions",
        "_check_hud_and_map_readouts",
        "_check_object_prompts",
        "_check_region_count_boundary",
    ],
    "scripts/check-client.sh": [
        "check-client-functional-transition-route-support.py",
        "functional_transition_route_support_check.gd",
    ],
    "scripts/check-client-flow.ps1": [
        "functional_transition_route_support_check.gd",
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
                errors.append(f"{relative_path}: missing functional transition route support text '{required_text}'")

    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1

    print("Client functional transition route support checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
