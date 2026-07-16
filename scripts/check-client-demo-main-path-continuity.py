#!/usr/bin/env python3
import sys
from pathlib import Path


REQUIRED_TEXT_BY_FILE = {
    "docs/archive/features-demo-v1/demo-main-path-continuity-v1.md": [
        "Demo Main Path Continuity V1",
        "主路径连续性",
        "S0",
        "S21",
        "quest.write_demo_stabilization_core",
        "不新增资源、配方、区域、任务链、完整背包、完整装备栏或自动化物流",
    ],
    "client/scripts/checks/demo_main_path_continuity_check.gd": [
        "Demo main path continuity checks passed.",
        "DevelopmentBaselineBuilder",
        "GatherSystem",
        "ProcessingSystem",
        "EnemyCounterattackRuntime",
        "_check_baseline_main_path_milestones",
        "_check_first_playable_core_loop_rhythm",
        "_check_s21_to_demo_completion_path",
        "DemoCoreLoopRhythmFormatter",
    ],
    "client/scripts/systems/demo_core_loop_rhythm_formatter.gd": [
        "class_name DemoCoreLoopRhythmFormatter",
        "format_hud_summary",
        "get_stage_id",
        "format_result_feedback_line",
        "核心循环",
        "循环接力",
    ],
    "client/scripts/ui/hud_status_presenter.gd": [
        "DemoCoreLoopRhythmFormatter.format_hud_summary",
    ],
    "client/scripts/systems/processing_system.gd": [
        "core_loop",
        "show_core_loop",
        "DemoCoreLoopRhythmFormatter.format_result_feedback_line",
    ],
    "scripts/check-client.sh": [
        "check-client-demo-main-path-continuity.py",
        "demo_main_path_continuity_check.gd",
    ],
    "scripts/check-client.ps1": [
        "check-client-demo-main-path-continuity.ps1",
    ],
    "scripts/check-client-flow.ps1": [
        "demo_main_path_continuity_check.gd",
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
                errors.append(f"{relative_path}: missing demo main path continuity text '{required_text}'")

    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1

    print("Client demo main path continuity checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
