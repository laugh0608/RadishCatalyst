#!/usr/bin/env python3
import sys
from pathlib import Path


REQUIRED_TEXT_BY_FILE = {
    "docs/archive/features-demo-v1/demo-supply-pressure-pacing-v1.md": [
        "Demo Supply Pressure Pacing V1",
        "补给节奏与承压价值",
        "demo_supply_pressure_pacing_check.gd",
        "不新增资源、配方、区域、任务链、UI 面板、目标箭头或同类 HUD 提示",
    ],
    "client/scripts/checks/demo_supply_pressure_pacing_check.gd": [
        "Demo supply pressure pacing checks passed.",
        "_check_repair_gel_craft_and_treatment_pressure_value",
        "_check_resistance_vial_craft_and_gate_pressure_value",
        "_check_outpost_core_restocks_pressure_vial",
        "_check_core_write_pressure_uses_vial",
    ],
    "scripts/check-client.sh": [
        "check-client-demo-supply-pressure-pacing.py",
        "demo_supply_pressure_pacing_check.gd",
    ],
    "scripts/check-client.ps1": [
        "check-client-demo-supply-pressure-pacing.ps1",
    ],
    "scripts/check-client-flow.ps1": [
        "demo_supply_pressure_pacing_check.gd",
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
                errors.append(f"{relative_path}: missing demo supply pressure pacing text '{required_text}'")

    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1

    print("Client demo supply pressure pacing checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
