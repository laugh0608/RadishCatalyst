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
MODES = ("state", "process-read", "menu", "background-write", "background-read", "background-complete-read", "background-off", "background-recovered-read", "review", "feedback", "feedback-window")
REPORTS = {"state": "state-result.json", "process-read": "read-result.json", "menu": "menu-result.json",
           "background-write": "write-result.json", "background-read": "read-result.json",
           "background-complete-read": "complete-read-result.json", "background-off": "complete-read-result.json", "background-recovered-read": "recovered-read-result.json", "review": "review-result.json", "feedback": "review-result.json", "feedback-window": "review-result.json"}


def load(path):
    return json.loads(path.read_text(encoding="utf-8"))


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def batch_path(name, root=None):
    root = RUNS if root is None else root
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_-]*", name):
        raise ValueError("Use a safe, explicit batch name.")
    path = root / name
    if path.is_symlink() or not path.resolve().is_relative_to(root.resolve()):
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
    parser.add_argument("--energy", action="store_true", help="Run the E2 energy contract in its separate evidence root.")
    parser.add_argument("--standby", action="store_true", help="E2 v2 standby and focus feedback checks.")
    parser.add_argument("--legacy-source", action="store_true", help="Copy a successful V7 parent from the original E2 evidence root.")
    parser.add_argument("mode", choices=MODES)
    parser.add_argument("batch")
    parser.add_argument("source", nargs="?")
    args = parser.parse_args()
    global RUNS
    if args.energy:
        RUNS = REPO / "tools/runtime-intake/check-runs/factory-production-expansion-e2"
        if args.mode in ("feedback", "feedback-window") and not args.standby:
            raise ValueError("E2 has dedicated review; E1 feedback modes are not applicable.")
    if args.standby:
        if not args.energy: raise ValueError("Standby checks require --energy.")
        RUNS = REPO / "tools/runtime-intake/check-runs/factory-energy-and-focus-feedback-v1"
    if args.legacy_source and (not args.standby or not args.source):
        raise ValueError("Legacy input requires a standby check and an explicit source batch.")
    destination = batch_path(args.batch)
    if destination.exists():
        raise ValueError("Always use a new batch; failed evidence is retained.")
    derived = args.mode in ("process-read", "background-read", "background-complete-read", "background-off", "background-recovered-read", "review", "feedback", "feedback-window")
    if derived != bool(args.source):
        raise ValueError("Recovery/review modes require one parent; new checks take no parent.")
    if args.mode in ("background-off", "background-recovered-read") and not args.energy:
        raise ValueError("Additional energy continuation modes are only available for E2.")
    source_root = REPO / "tools/runtime-intake/check-runs/factory-production-expansion-e2" if args.legacy_source else RUNS
    source = batch_path(args.source, source_root) if args.source else None
    before = None
    if source:
        parent_report = "state-result.json" if args.mode == "process-read" else "write-result.json" if args.mode == "background-read" else "read-result.json"
        if args.mode in ("review", "feedback", "feedback-window") and not (source / parent_report).exists():
            parent_report = "write-result.json"
        if args.mode == "background-recovered-read": parent_report = "complete-read-result.json"
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
    if args.mode in ("feedback", "feedback-window"): script = "factory_feedback_boot_check.gd"
    if args.energy:
        script = "factory_energy_check.gd" if state else "factory_energy_menu_check.gd" if args.mode == "menu" else "factory_energy_boot_check.gd"
    if args.standby:
        script = "factory_standby_check.gd" if state else "factory_energy_menu_check.gd" if args.mode == "menu" else "factory_energy_feedback_boot_check.gd"
    log = destination / (args.mode + ".log")
    command = [godot] + ([] if args.mode in ("review", "feedback-window") else ["--headless"])
    command += ["--path", str(REPO / "client"), "--script", "res://scripts/checks/" + script, "--no-header", "--log-file", str(log), "--"]
    if state or args.mode == "menu":
        command += ["--evidence=" + str(destination)]
        if args.mode == "process-read": command += ["--read"]
    else:
        command += ["--batch=" + args.batch]
        if args.mode not in ("review", "feedback-window"): command += ["--background"]
        if derived: command += ["--read"]
        if args.mode in ("background-complete-read", "background-off"): command += ["--complete-read"]
        if args.mode == "background-off": command += ["--generator-off"]
        if args.mode == "background-recovered-read": command += ["--recovered-read"]
        if args.mode in ("review", "feedback", "feedback-window"): command += ["--visual-only"]
    if args.standby:
        command += ["--standby-feedback"]
        if args.legacy_source: command += ["--copy-standby"]
    sources = sorted((REPO / "client/scripts/factory").rglob("*.gd")) + sorted((REPO / "client/data/factory").glob("*.gd")) + sorted((REPO / "client/scripts/checks").glob("factory_expansion_*.gd")) + [REPO / "client/scripts/checks/factory_feedback_boot_check.gd"]
    if args.energy:
        sources += sorted((REPO / "client/scripts/checks").glob("factory_energy_*.gd"))
        sources += [REPO / "client/scripts/checks/factory_standby_check.gd"]
        sources += sorted((REPO / "client/scripts/factory").glob("*.gdshader"))
        sources += sorted((REPO / "client/scripts/boot").glob("*.gd"))
        sources += [REPO / "client/scripts/checks" / name for name in
                    ("factory_routing_boot_check.gd", "factory_device_interaction_boot_check.gd",
                     "factory_statistics_boot_check.gd", "factory_window_driver.gd")]
        sources += [REPO / "client/scenes/boot/Boot.tscn", REPO / "client/project.godot",
                    REPO / "client/assets/factory/energy/source-manifest.json",
                    REPO / "client/assets/factory/energy/cell_generator.glb",
                    REPO / "client/assets/icons/factory_industrial_cell.svg"]
    (destination / "execution-inputs.json").write_text(json.dumps({"command": command, "code_sha256": {str(path.relative_to(REPO)): digest(path) for path in sources}, "runner_sha256": digest(Path(__file__))}, indent=2) + "\n", encoding="utf-8")
    errors = []
    try:
        with (destination / "process.log").open("w", encoding="utf-8") as output:
            result = subprocess.run(command, cwd=REPO, check=False, stdout=output, stderr=subprocess.STDOUT, timeout=1800 if args.energy else 1200 if args.mode == "review" else 900)
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
    print(f"{'E2' if args.energy else 'E1'} {args.mode} passed: {destination}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (ValueError, OSError, json.JSONDecodeError) as exc:
        print(f"E1 runner: {exc}", file=sys.stderr)
        raise SystemExit(2)
