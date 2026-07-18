#!/usr/bin/env python3
import sys
from pathlib import Path


REQUIRED_TEXT_BY_FILE = {
    "docs/archive/features-demo-v1/demo-playable-ui-and-art-pass-v1.md": [
        "启动界面与基地首屏第一印象",
        "新游戏",
        "载入存档",
        "联机（暂不开放）",
        "不开发真实联机",
    ],
    "client/scenes/boot/Boot.tscn": [
        "res://scripts/boot/boot.gd",
    ],
    "client/scripts/boot/boot.gd": [
        "STARTUP_MENU_SCENE",
        "StartupMenu",
        "SliceSaveService",
        "startup_load",
    ],
    "client/scenes/ui/StartupMenu.tscn": [
        "StartupMenu",
        "新游戏",
        "载入存档",
        "联机（暂不开放）",
        "设置",
        "退出",
    ],
    "client/scripts/ui/startup_menu.gd": [
        "class_name StartupMenu",
        "draw_rect",
        "draw_line",
        "configure_save_summary",
        "multiplayer_button.disabled = true",
    ],
    "client/scripts/game/game_root.gd": [
        "startup_load_slot_id",
        "_load_from_slot(startup_load_slot_id)",
    ],
    "client/scripts/checks/demo_startup_shell_check.gd": [
        "Demo startup shell checks passed.",
        "_check_startup_menu_structure",
        "_check_startup_menu_save_state",
        "_check_boot_starts_on_menu",
    ],
    "scripts/check-client.sh": [
        "check-client-demo-startup-shell.py",
        "demo_startup_shell_check.gd",
    ],
    "scripts/check-client.ps1": [
        "check-client-demo-startup-shell.ps1",
    ],
    "scripts/check-client-flow.ps1": [
        "demo_startup_shell_check.gd",
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
                errors.append(f"{relative_path}: missing demo startup shell text '{required_text}'")

    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1

    print("Client demo startup shell checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
