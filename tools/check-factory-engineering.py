#!/usr/bin/env python3
"""Isolated engineering checks: fresh batches, immutable parents, strict results."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys

REPO = Path(__file__).resolve().parents[1]
RUNS = REPO / "tools/runtime-intake/check-runs/factory-engineering-scale-v1"


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def hashes(root):
    result = {}
    for path in sorted(root.rglob("*")):
        if path.is_symlink() or path.name.endswith(".lock"):
            raise ValueError(f"Evidence must be unlocked and not linked: {path}")
        if path.is_file():
            result[str(path.relative_to(root))] = digest(path)
    return result


def batch_path(name):
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_-]*", name):
        raise ValueError("Explicit simple batch name required.")
    path = RUNS / name
    for part in [path, *path.parents]:
        if part.is_symlink():
            raise ValueError(f"No linked evidence directories: {part}")
    return path


def code_hashes():
    paths = []
    for folder in ["client/scripts/factory", "client/data/factory", "client/scripts/boot"]:
        paths.extend((REPO / folder).glob("**/*.gd"))
    paths.extend((REPO / "client/scripts/checks").glob("factory_engineering*.gd"))
    paths.append(Path(__file__))
    return {str(path.relative_to(REPO)): digest(path) for path in sorted(paths)}


def write(path, data):
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=["identity", "identity-read"])
    parser.add_argument("batch")
    parser.add_argument("source", nargs="?")
    args = parser.parse_args()
    if (args.mode == "identity-read") != bool(args.source):
        raise ValueError("Only identity-read requires a successful parent batch.")
    destination = batch_path(args.batch)
    if destination.exists():
        raise ValueError("Batch already exists; retain evidence and choose a new batch.")
    parent = batch_path(args.source) if args.source else None
    before = {}
    if parent:
        result = json.loads((parent / "result.json").read_text())
        runner = json.loads((parent / "runner-result.json").read_text())
        manifest = json.loads((parent / "execution-inputs.json").read_text())
        if result.get("assertions", 0) <= 0 or result.get("failures") != [] or runner.get("exit_code") != 0 or runner.get("errors") != [] or manifest.get("code_sha256") != code_hashes():
            raise ValueError("Parent did not pass or code changed; make a fresh parent.")
        before = hashes(parent)
        for name in ["source.json", "continuation.json"]:
            if runner.get("artifacts", {}).get(name) != before.get(name):
                raise ValueError("Parent artifact changed after verification.")
    godot = os.environ.get("GODOT_EXE") or shutil.which("godot") or "/Applications/Godot.app/Contents/MacOS/Godot"
    if not Path(godot).is_file():
        raise ValueError("Set GODOT_EXE to an installed executable.")
    destination.mkdir(parents=True, exist_ok=False)
    if parent:
        for name in ["source.json", "continuation.json"]:
            shutil.copyfile(parent / name, destination / name)
            if digest(destination / name) != before[name]:
                raise ValueError("Source changed during copying.")
    command = [godot, "--headless", "--path", str(REPO / "client"), "--script",
               "res://scripts/checks/factory_engineering_check.gd", "--no-header", "--log-file",
               str(destination / "godot.log"), "--", f"--evidence={destination}"]
    if parent:
        command.append("--read")
    write(destination / "execution-inputs.json", {"mode": args.mode, "command": command,
          "code_sha256": code_hashes(), "parent": str(parent) if parent else None, "parent_sha256": before})
    with (destination / "console.log").open("w", encoding="utf-8") as stream:
        completed = subprocess.run(command, stdout=stream, stderr=subprocess.STDOUT, timeout=180)
    errors = []
    log = (destination / "console.log").read_text()
    if completed.returncode != 0:
        errors.append(f"Godot exit {completed.returncode}")
    for line in log.splitlines():
        if line.startswith(("SCRIPT ERROR", "ERROR:")) and 'Condition "ret != noErr"' not in line:
            errors.append(line)
    report_path = destination / "result.json"
    report = json.loads(report_path.read_text()) if report_path.exists() else {}
    if report.get("assertions", 0) <= 0 or report.get("failures") != []:
        errors.append("Missing or failed assertions.")
    unchanged = not parent or hashes(parent) == before
    if not unchanged:
        errors.append("Parent changed.")
    write(destination / "runner-result.json", {"exit_code": completed.returncode, "errors": errors,
          "parent_unchanged": unchanged, "artifacts": {name: digest(destination / name) for name in
          ["source.json", "continuation.json"] if (destination / name).exists()}})
    print(log[-6000:])
    print(json.dumps({"evidence": str(destination), "errors": errors[:10], "error_count": len(errors)}, ensure_ascii=False))
    return 1 if errors else 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (ValueError, OSError, subprocess.SubprocessError) as exc:
        print(f"Engineering check failed: {exc}", file=sys.stderr)
        sys.exit(1)
