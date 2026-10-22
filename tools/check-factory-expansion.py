#!/usr/bin/env python3
"""Run E1 checks with fresh evidence and immutable, hash-verified recovery parents."""

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
RUNS = REPO / "tools/runtime-intake/check-runs/factory-production-expansion-e1"
MODES = ("state", "process-read", "menu", "background-write", "background-read", "background-complete-read", "review")
REPORTS = {"state": "state-result.json", "process-read": "read-result.json", "menu": "menu-result.json",
           "background-write": "write-result.json", "background-read": "read-result.json",
           "background-complete-read": "complete-read-result.json", "review": "review-result.json"}


def load(path):
    return json.loads(path.read_text(encoding="utf-8"))


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def batch_path(name):
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_-]*", name):
        raise ValueError("Use a safe, explicit batch name.")
    path = RUNS / name
    if path.is_symlink() or not path.resolve().is_relative_to(RUNS.resolve()):
        raise ValueError("Batch must stay inside E1 runtime intake.")
    return path


def files(root):
    found = {}
    for path in sorted(root.rglob("*")):
        if path.is_symlink() or path.name.endswith(".lock"):
            raise ValueError(f"Unstable parent entry: {path}")
        if path.is_file():
            found[str(path.relative_to(root))] = digest(path)
    return found


def succeeded(root, report):
    result = load(root / report)
    if result.get("failures") != [] or result.get("assertions", 0) <= 0:
        raise ValueError(f"Requires successful {report}.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=MODES)
    parser.add_argument("batch")
    parser.add_argument("source", nargs="?")
    args = parser.parse_args()
    destination = batch_path(args.batch)
    if destination.exists():
        raise ValueError("Always use a new batch; failed evidence is retained.")
    derived = args.mode in ("process-read", "background-read", "background-complete-read", "review")
    if derived != bool(args.source):
        raise ValueError("Recovery/review modes require one parent; new checks take no parent.")
    source = batch_path(args.source) if args.source else None
    before = None
    if source:
        parent_report = "state-result.json" if args.mode == "process-read" else "write-result.json" if args.mode == "background-read" else "read-result.json"
        if args.mode == "review" and not (source / parent_report).exists():
            parent_report = "write-result.json"
        succeeded(source, parent_report)
        runner = load(source / "runner-result.json")
        if runner.get("exit_code") != 0 or runner.get("errors") != [] or not runner.get("parent_unchanged"):
            raise ValueError("Parent runner did not pass.")
        before = files(source)
    destination.mkdir(parents=True, exist_ok=False)
    copied = {}
    if source:
        for relative, checksum in before.items():
            path = Path(relative)
            if path.suffix != ".json" or path.name.endswith("-result.json") or path.name in ("origin.json", "execution-inputs.json"):
                continue
            if args.mode == "process-read" and len(path.parts) != 1:
                continue
            target = destination / path
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(source / path, target)
            if digest(target) != checksum:
                raise ValueError("Parent changed during copy.")
            copied[relative] = checksum
        (destination / "origin.json").write_text(json.dumps({"parent": args.source, "source_hashes": before, "copied_sha256": copied}, indent=2) + "\n", encoding="utf-8")
        if (destination / "expected.json").exists():
            shutil.copyfile(destination / "expected.json", destination / "restored-input.json")
    godot = os.environ.get("GODOT_EXE") or shutil.which("godot") or shutil.which("godot4") or "/Applications/Godot.app/Contents/MacOS/Godot"
    if not Path(godot).is_file():
        raise ValueError("Set GODOT_EXE to the installed Godot executable.")
    state = args.mode in ("state", "process-read")
    script = "factory_expansion_check.gd" if state else "factory_expansion_menu_check.gd" if args.mode == "menu" else "factory_expansion_boot_check.gd"
    log = destination / (args.mode + ".log")
    command = [godot] + ([] if args.mode == "review" else ["--headless"])
    command += ["--path", str(REPO / "client"), "--script", "res://scripts/checks/" + script, "--no-header", "--log-file", str(log), "--"]
    if state or args.mode == "menu":
        command += ["--evidence=" + str(destination)]
        if args.mode == "process-read": command += ["--read"]
    else:
        command += ["--batch=" + args.batch]
        if args.mode != "review": command += ["--background"]
        if derived: command += ["--read"]
        if args.mode == "background-complete-read": command += ["--complete-read"]
        if args.mode == "review": command += ["--visual-only"]
    sources = sorted((REPO / "client/scripts/factory").rglob("*.gd")) + sorted((REPO / "client/data/factory").glob("*.gd")) + sorted((REPO / "client/scripts/checks").glob("factory_expansion_*.gd"))
    (destination / "execution-inputs.json").write_text(json.dumps({"command": command, "code_sha256": {str(path.relative_to(REPO)): digest(path) for path in sources}, "runner_sha256": digest(Path(__file__))}, indent=2) + "\n", encoding="utf-8")
    errors = []
    try:
        with (destination / "process.log").open("w", encoding="utf-8") as output:
            result = subprocess.run(command, cwd=REPO, check=False, stdout=output, stderr=subprocess.STDOUT, timeout=1200 if args.mode == "review" else 900)
        code = result.returncode
    except subprocess.TimeoutExpired:
        code = 124
        errors.append("Timed out; incomplete evidence is retained.")
    if log.is_file():
        errors += list(dict.fromkeys(line for line in log.read_text(encoding="utf-8").splitlines() if re.match(r"^(SCRIPT ERROR|ERROR:)", line) and 'Condition "ret != noErr"' not in line))
    else:
        errors.append("Godot did not produce its required log.")
    try:
        succeeded(destination, REPORTS[args.mode])
    except (ValueError, OSError) as exc:
        errors.append(str(exc))
    unchanged = source is None or files(source) == before
    if not unchanged: errors.append("Parent evidence changed.")
    (destination / "runner-result.json").write_text(json.dumps({"exit_code": code, "errors": errors, "parent_unchanged": unchanged}, indent=2) + "\n", encoding="utf-8")
    if code or errors:
        print(json.dumps({"exit_code": code, "errors": errors}, ensure_ascii=False), file=sys.stderr)
        return 1
    print(f"E1 {args.mode} passed: {destination}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (ValueError, OSError, json.JSONDecodeError) as exc:
        print(f"E1 runner: {exc}", file=sys.stderr)
        raise SystemExit(2)
