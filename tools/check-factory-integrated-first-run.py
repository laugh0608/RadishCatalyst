#!/usr/bin/env python3
"""Run the same isolated foundation first run through Shell or PowerShell."""

import argparse
import json
import os
from pathlib import Path
import platform
import re
import runpy
import shutil
import subprocess
import time

TOOLS = Path(__file__).resolve().parent
REPO = TOOLS.parent
RUNS = TOOLS / "runtime-intake/check-runs/factory-integrated-first-run-v1"
CHECK = "res://scripts/checks/factory_integrated_first_run.gd"


def write_json(path, data):
    path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")


def run_phase(godot, mode, root, phase, artifact):
    log = root / f"{phase}.log"
    console_log = root / f"{phase}-console.log"
    command = [godot, "--path", str(REPO / "client"), "--log-file", str(log)]
    if mode == "state":
        command.extend(["--headless", "--quit-after", "900"])
    command.extend(["--script", CHECK, "--", f"--batch={root.name}"])
    if phase == "read":
        command.append("--read")
    elif mode == "live":
        command.append("--live")

    with console_log.open("wb") as console:
        result = subprocess.run(command, stdout=console, stderr=subprocess.STDOUT, check=False)
    console_lines = console_log.read_text(encoding="utf-8", errors="replace").splitlines()
    print("\n".join(console_lines[-38:]), flush=True)
    if result.returncode:
        raise SystemExit(result.returncode)

    log_lines = log.read_text(encoding="utf-8-sig", errors="replace").splitlines()
    for line in console_lines + log_lines:
        if line.startswith(("SCRIPT ERROR", "ERROR:")):
            raise SystemExit(f"{phase} reported a Godot error; see {root}")
    summary = json.loads((root / f"{phase}-result.json").read_text(encoding="utf-8"))
    windowed = mode != "state"
    if summary["assertions"] <= 0 or summary["failures"] != [] or summary["window"] is not windowed:
        raise SystemExit(f"{phase} did not pass in {mode} mode; see {root}")
    if not (root / artifact).is_file():
        raise SystemExit(f"{phase} did not produce {artifact}; see {root}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", nargs="?", choices=("state", "window", "live"), default="state")
    parser.add_argument("batch", nargs="?")
    parser.add_argument("--godot", required=True)
    args = parser.parse_args()
    batch = args.batch if args.batch is not None else f"{args.mode}-{int(time.time())}-{os.getpid()}"
    if not re.fullmatch(r"[A-Za-z0-9_-]+", batch):
        parser.error("Invalid batch name")

    godot = shutil.which(args.godot)
    if godot is None:
        parser.error(f"Godot executable not found: {args.godot}")
    godot_path = Path(godot)
    if os.name == "nt" and not godot_path.stem.lower().endswith("_console"):
        console = godot_path.with_name(f"{godot_path.stem}_console{godot_path.suffix}")
        if console.is_file():
            godot = str(console)

    root = RUNS / batch
    try:
        root.mkdir(parents=True)
    except FileExistsError:
        parser.error(f"Use a new batch; existing evidence is retained: {root}")
    print(f"Evidence: {root}", flush=True)
    write_json(root / "platform.json", {
        "mode": args.mode,
        "os": platform.platform(),
        "machine": platform.machine(),
        "python": platform.python_version(),
        "godot_executable": godot,
    })
    audit = runpy.run_path(str(TOOLS / "design/audit-four-sided-core-layout.py"))["audit"]
    write_json(root / "layout.json", audit("S1-P"))
    run_phase(godot, args.mode, root, "write", "first-run.json")
    if args.mode == "live" and not (root / "live-production.json").is_file():
        raise SystemExit(f"Live production evidence missing: {root}")
    run_phase(godot, args.mode, root, "read", "restore-result.json")


if __name__ == "__main__":
    main()
