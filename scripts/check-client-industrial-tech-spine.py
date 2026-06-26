#!/usr/bin/env python3
import sys
from pathlib import Path


REQUIRED_TEXT_BY_FILE = {
    "client/scripts/systems/industrial_tech_spine_formatter.gd": [
        "class_name IndustrialTechSpineFormatter",
        "format_hud_summary",
        "format_device_status_line",
        "format_processing_prompt_line",
        "format_outfitting_station_prompt_line",
        "format_processing_log_line",
        "污染沉积物 -> 抗污染药剂 + 污染浆液",
        "基础零件 + 过滤介质 -> 基础过滤模块",
        "核心稳压缓冲包",
    ],
    "client/scripts/ui/hud_status_presenter.gd": [
        "IndustrialTechSpineFormatter.format_hud_summary",
    ],
    "client/scripts/ui/hud_device_panel_presenter.gd": [
        "IndustrialTechSpineFormatter.format_device_status_line",
    ],
    "client/scripts/ui/processing_interaction_prompt_formatter.gd": [
        "IndustrialTechSpineFormatter.format_processing_prompt_line",
        "IndustrialTechSpineFormatter.format_processing_log_line",
    ],
    "client/scripts/ui/interaction_prompt_formatter.gd": [
        "IndustrialTechSpineFormatter.format_outfitting_station_prompt_line",
    ],
    "client/scripts/systems/processing_system.gd": [
        "industrial_spine",
        "IndustrialTechSpineFormatter.format_result_feedback_line",
    ],
    "client/scripts/ui/hud_log_presenter.gd": [
        '"工艺"',
        "industrial_spine",
    ],
    "client/scripts/checks/industrial_tech_spine_check.gd": [
        "Industrial tech spine checks passed.",
        "_check_hud_summary",
        "_check_device_panel_line",
        "_check_processing_prompt_and_log",
        "_check_outfitting_station_prompt",
        "_check_processing_result_feedback",
    ],
    "scripts/check-client.sh": [
        "industrial_tech_spine_check.gd",
    ],
    "scripts/check-client-flow.ps1": [
        "industrial_tech_spine_check.gd",
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
                errors.append(f"{relative_path}: missing industrial tech spine text '{required_text}'")

    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1

    print("Client industrial tech spine checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
