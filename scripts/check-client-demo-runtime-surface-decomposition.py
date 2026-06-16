#!/usr/bin/env python3
import sys
from pathlib import Path


REQUIRED_TEXT_BY_FILE = {
    "docs/features/demo-runtime-surface-decomposition-v1.md": [
        "Demo Runtime Surface Decomposition V1",
        "运行时承载面拆分",
        "vertical_slice_flow_check.gd",
        "onboarding_hint_runtime_check.gd",
        "不新增资源、配方、区域、任务链、完整背包、完整装备栏或自动化物流",
    ],
    "client/scripts/checks/onboarding_hint_runtime_check.gd": [
        "Onboarding hint runtime checks passed.",
        "HudHintPresenter",
        "VerticalSliceMapScene",
        "_expect_hint_contains",
    ],
    "scripts/check-client.sh": [
        "check-client-demo-runtime-surface-decomposition.py",
        "onboarding_hint_runtime_check.gd",
    ],
    "scripts/check-client.ps1": [
        "check-client-demo-runtime-surface-decomposition.ps1",
    ],
    "scripts/check-client-flow.ps1": [
        "onboarding_hint_runtime_check.gd",
    ],
}

FORBIDDEN_TEXT_BY_FILE = {
    "client/scripts/checks/vertical_slice_flow_check.gd": [
        "_check_onboarding_hints",
        "VerticalSliceMapScene",
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
                errors.append(f"{relative_path}: missing demo runtime surface decomposition text '{required_text}'")

    for relative_path, forbidden_texts in FORBIDDEN_TEXT_BY_FILE.items():
        path = repo_root / relative_path
        if not path.is_file():
            errors.append(f"{relative_path}: missing file")
            continue
        content = path.read_text(encoding="utf-8")
        for forbidden_text in forbidden_texts:
            if forbidden_text in content:
                errors.append(f"{relative_path}: should not contain '{forbidden_text}' after runtime surface decomposition")

    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1

    print("Client demo runtime surface decomposition checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
