#!/usr/bin/env python3
import sys
from pathlib import Path


REQUIRED_TEXT_BY_FILE = {
    "docs/features/demo-save-state-contract-v1.md": [
        "Demo Save State Contract V1",
        "存档 / 状态",
        "世界、角色、库存、建筑、任务、区域、敌人",
        "不新增资源、配方、区域、任务链、完整背包、完整装备栏或自动化物流",
    ],
    "client/scripts/checks/demo_save_state_contract_check.gd": [
        "Demo save state contract checks passed.",
        "_check_demo_main_path_roundtrip",
        "_check_contract_validation_rejects_display_name_region",
        "_check_contract_validation_rejects_enemy_source_mismatch",
        "SaveService",
        "DevelopmentBaselineBuilder",
        "DemoResourceChainStateFormatter",
    ],
    "scripts/check-client.sh": [
        "check-client-demo-save-state-contract.py",
        "demo_save_state_contract_check.gd",
    ],
    "scripts/check-client.ps1": [
        "check-client-demo-save-state-contract.ps1",
    ],
    "scripts/check-client-flow.ps1": [
        "demo_save_state_contract_check.gd",
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
                errors.append(f"{relative_path}: missing demo save state contract text '{required_text}'")

    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1

    print("Client demo save state contract checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
