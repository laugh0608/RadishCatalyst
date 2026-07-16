#!/usr/bin/env python3
import sys
from pathlib import Path


REQUIRED_TEXT_BY_FILE = {
    "docs/archive/features-demo-v1/demo-industrial-module-task-rhythm-v1.md": [
        "Demo Industrial Module Task Rhythm V1",
        "工业模块职责与任务节奏第一包",
        "DemoIndustrialModuleTaskRhythmFormatter",
        "demo_industrial_module_task_rhythm_check.gd",
    ],
    "docs/archive/features-demo-v1/demo-playable-content-substance-v1.md": [
        "工业模块职责与任务节奏第一包",
        "DemoIndustrialModuleTaskRhythmFormatter",
        "不新增第 13 区域",
    ],
    "client/scripts/systems/demo_industrial_module_task_rhythm_formatter.gd": [
        "class_name DemoIndustrialModuleTaskRhythmFormatter",
        "BASIC_STORAGE_ID",
        "FIELD_OUTFITTING_STATION_ID",
        "format_hud_summary",
        "format_build_prompt_line",
    ],
    "client/scripts/ui/hud_status_presenter.gd": [
        "DemoIndustrialModuleTaskRhythmFormatter.format_hud_summary",
        "DemoIndustrialModuleTaskRhythmFormatter.format_recipe_task_hint",
        "DemoIndustrialModuleTaskRhythmFormatter.format_build_task_hint",
    ],
    "client/scripts/ui/hud_device_panel_presenter.gd": [
        "DemoIndustrialModuleTaskRhythmFormatter.format_device_status_line",
    ],
    "client/scripts/ui/interaction_prompt_formatter.gd": [
        "DemoIndustrialModuleTaskRhythmFormatter.format_build_prompt_line",
        "DemoIndustrialModuleTaskRhythmFormatter.format_outpost_core_prompt_line",
        "DemoIndustrialModuleTaskRhythmFormatter.format_outfitting_station_prompt_line",
    ],
    "client/scripts/ui/processing_interaction_prompt_formatter.gd": [
        "DemoIndustrialModuleTaskRhythmFormatter.format_processing_prompt_line",
        "DemoIndustrialModuleTaskRhythmFormatter.format_processing_log_line",
    ],
    "client/scripts/ui/hud_log_presenter.gd": [
        "\"任务节奏\"",
        "\"module_task\"",
    ],
    "client/scripts/systems/build_system.gd": [
        "DemoIndustrialModuleTaskRhythmFormatter.format_build_result_line",
        "\"module_task\"",
    ],
    "client/scripts/systems/processing_system.gd": [
        "DemoIndustrialModuleTaskRhythmFormatter.format_result_feedback_line",
        "\"module_task\"",
    ],
    "client/scripts/checks/demo_industrial_module_task_rhythm_check.gd": [
        "Demo industrial module task rhythm checks passed.",
        "_check_hud_and_build_prompt_task_rhythm",
        "_check_device_panel_and_processing_prompt_task_rhythm",
        "_check_processing_and_build_result_logs",
    ],
    "scripts/check-client.sh": [
        "check-client-demo-industrial-module-task-rhythm.py",
        "demo_industrial_module_task_rhythm_check.gd",
    ],
    "scripts/check-client.ps1": [
        "check-client-demo-industrial-module-task-rhythm.ps1",
    ],
    "scripts/check-client-flow.ps1": [
        "demo_industrial_module_task_rhythm_check.gd",
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
                errors.append(f"{relative_path}: missing demo industrial module task rhythm text '{required_text}'")

    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1

    print("Client demo industrial module task rhythm checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
