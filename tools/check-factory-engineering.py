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
MODES = ["identity", "identity-read", "prepare", "prepare-read", "capacity", "density", "repair",
         "competition", "checkpoint-write", "boot-restore", "interrupt", "short-window", "sustained", "sustained-preflight", "sustained-interrupt", "workload-check"]
CHECKPOINTS = {
    "prepare": ["source.json"], "repair": ["deficit.json", "endpoint.json"],
    "competition": ["quota-held.json", "quota-stopped-held.json", "quota-exhausted.json", "quota-reset.json", "endpoint.json"],
    "density": ["endpoint.json"], "capacity": ["endpoint.json"],
}


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


def state_hashes():
    # State compatibility: actual runtime/model plus fixed layout. Producer and
    # consumer scripts retain separate execution hashes; adding a reader does not
    # invalidate a previously verified world produced by unchanged runtime code.
    paths = []
    for folder in ["client/scripts/factory", "client/data/factory", "client/scripts/boot"]:
        paths.extend((REPO / folder).glob("**/*.gd"))
    paths.append(REPO / "client/scripts/checks/factory_engineering_layout.gd")
    return {str(path.relative_to(REPO)): digest(path) for path in sorted(paths) if path.exists()}


def code_hashes(mode=None):
    checks = ["factory_engineering_check"]
    if mode not in ["identity", "identity-read"]:
        checks += ["factory_engineering_preparation", "factory_engineering_prepare_check", "factory_engineering_observer"]
    if mode in [None, "capacity", "density", "repair", "competition"]:
        checks.append("factory_engineering_load_check")
    if mode in [None, "checkpoint-write"]:
        checks.append("factory_engineering_restore_check")
    if mode in [None, "boot-restore", "interrupt", "short-window", "sustained", "sustained-preflight", "sustained-interrupt", "workload-check"]:
        checks.append("factory_engineering_boot_check")
    if mode in [None, "sustained", "sustained-preflight", "sustained-interrupt", "workload-check"]:
        checks += ["factory_engineering_sustained_check", "factory_engineering_live_observer", "factory_engineering_workload_check"]
    paths = [REPO / f"client/scripts/checks/{name}.gd" for name in checks]
    for name in ["factory_discovery_check", "factory_performance_check", "factory_window_driver", "factory_diagnostic_gate"]:
        paths.append(REPO / f"client/scripts/checks/{name}.gd")
    paths.extend((REPO / "client/scenes/factory").glob("**/*.tscn"))
    paths.extend((REPO / "client/scenes/boot").glob("**/*.tscn"))
    paths.extend([REPO / "client/project.godot", Path(__file__)])
    return state_hashes() | {str(path.relative_to(REPO)): digest(path) for path in sorted(paths)}


def write(path, data):
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def validated_parent(parent, mode):
    before = hashes(parent)
    result = json.loads((parent / "result.json").read_text())
    runner = json.loads((parent / "runner-result.json").read_text())
    manifest = json.loads((parent / "execution-inputs.json").read_text())
    if (result.get("assertions", 0) <= 0 or result.get("failures") != []
            or runner.get("exit_code") != 0 or runner.get("errors") != []
            or runner.get("parent_unchanged") is not True):
        raise ValueError("Parent did not pass every required check.")
    if any(manifest.get("code_sha256", {}).get(name) != value for name, value in state_hashes().items()):
        raise ValueError("Parent runtime or fixed layout changed; make a fresh parent.")
    parent_mode = manifest.get("mode")
    expected = "identity" if mode == "identity-read" else "checkpoint-write" if mode == "boot-restore" else "prepare"
    if (mode == "checkpoint-write" and parent_mode not in CHECKPOINTS) or (mode != "checkpoint-write" and parent_mode != expected):
        raise ValueError("Wrong parent mode.")
    if parent_mode == "prepare" and result.get("ready") is not True:
        raise ValueError("Parent preparation is not ready.")
    files = (CHECKPOINTS[parent_mode] if mode == "checkpoint-write" else
             ["checkpoints.json", *sorted(name for name in before if name.startswith("checkpoints/"))]
             if mode == "boot-restore" else ["source.json", "continuation.json"])
    late_hashes = []
    for name in files:
        if name not in before:
            raise ValueError(f"Missing parent artifact: {name}")
        recorded = runner.get("artifacts", {}).get(name)
        if recorded is None and mode == "checkpoint-write" and not runner.get("artifact_manifest_version"):
            # Historical D probes recorded their source pair only. Do not invent
            # producer-time hashes: disclose the late capture and retain the full
            # immutable producer directory before/after the new continuation run.
            late_hashes.append(name)
        elif recorded != before[name]:
            raise ValueError("Parent artifact changed after verification.")
    return before, files, late_hashes


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=MODES)
    parser.add_argument("batch")
    parser.add_argument("source", nargs="?")
    parser.add_argument("--interrupt-at", choices=["before", "sampling", "close"], default="before")
    args = parser.parse_args()
    if (args.mode not in ["identity", "prepare"]) != bool(args.source):
        raise ValueError("Only read modes require a successful parent batch.")
    destination = batch_path(args.batch)
    if destination.exists():
        raise ValueError("Batch already exists; retain evidence and choose a new batch.")
    parent = batch_path(args.source) if args.source else None
    before, files, late_hashes = validated_parent(parent, args.mode) if parent else ({}, [], [])
    godot = os.environ.get("GODOT_EXE") or shutil.which("godot") or shutil.which("godot4") or "/Applications/Godot.app/Contents/MacOS/Godot"
    if not Path(godot).is_file():
        raise ValueError("Set GODOT_EXE to an installed executable.")
    destination.mkdir(parents=True, exist_ok=False)
    for name in files:
        target = destination / ("inputs" if args.mode == "checkpoint-write" else "") / name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(parent / name, target)
        if digest(target) != before[name]:
            raise ValueError("Source changed during copying.")
    if args.mode == "checkpoint-write":
        write(destination / "selected-inputs.json", files)
    script = ("factory_engineering_check" if args.mode in ["identity", "identity-read"] else
              "factory_engineering_prepare_check" if args.mode in ["prepare", "prepare-read"] else
              "factory_engineering_restore_check" if args.mode == "checkpoint-write" else
              "factory_engineering_boot_check" if args.mode in ["boot-restore", "interrupt", "short-window", "sustained", "sustained-preflight", "sustained-interrupt", "workload-check"] else
              "factory_engineering_load_check")
    if args.mode.startswith("sustained"):
        script = "factory_engineering_sustained_check"
    elif args.mode == "workload-check":
        script = "factory_engineering_workload_check"
    command = [godot] + ([] if args.mode in ["short-window", "sustained"] else ["--headless"])
    command += ["--path", str(REPO / "client"), "--script", f"res://scripts/checks/{script}.gd", "--no-header",
                "--log-file", str(destination / "godot.log"), "--", f"--evidence={destination}", f"--mode={args.mode}",
                f"--interrupt-at={args.interrupt_at}"]
    if parent:
        command.append("--read")
    execution = code_hashes(args.mode)
    write(destination / "execution-inputs.json", {"mode": args.mode, "command": command,
          "code_sha256": execution, "state_sha256": state_hashes(), "parent": str(parent) if parent else None,
          "parent_sha256": before, "late_artifact_hash_capture": late_hashes})
    errors = []
    with (destination / "console.log").open("w", encoding="utf-8") as stream:
        try:
            completed = subprocess.run(command, stdout=stream, stderr=subprocess.STDOUT, timeout=2400 if args.mode == "sustained" else 1800)
            exit_code = completed.returncode
        except subprocess.TimeoutExpired:
            exit_code = -1
            errors.append("Godot timed out; partial evidence retained.")
    log = (destination / "console.log").read_text()
    if exit_code != 0:
        errors.append(f"Godot exit {exit_code}")
    for line in log.splitlines():
        if line.startswith(("SCRIPT ERROR", "ERROR:")) and 'Condition "ret != noErr"' not in line:
            errors.append(line)
    report_path = destination / "result.json"
    report = json.loads(report_path.read_text()) if report_path.exists() else {}
    if report.get("assertions", 0) <= 0 or report.get("failures") != []:
        errors.append("Missing or failed assertions.")
    if args.mode not in ["identity", "identity-read"] and report.get("mode") != args.mode:
        errors.append("Missing or mismatched result mode.")
    if args.mode == "prepare" and report.get("ready") is not True:
        errors.append("Preparation is not ready.")
    if args.mode == "sustained" and report.get("sustained_acceptance") is not True:
        errors.append("Sustained acceptance did not pass.")
    unchanged = not parent or hashes(parent) == before
    if not unchanged:
        errors.append("Parent changed.")
    if any(not (REPO / name).is_file() or digest(REPO / name) != value for name, value in execution.items()):
        errors.append("Execution code changed during run.")
    artifacts = {}
    for name in ["source.json", "continuation.json", "checkpoints.json", "endpoint.json", "deficit.json",
                 "quota-held.json", "quota-stopped-held.json", "quota-exhausted.json", "quota-reset.json"]:
        if (destination / name).is_file(): artifacts[name] = digest(destination / name)
    for path in sorted((destination / "checkpoints").glob("*.json")):
        artifacts[str(path.relative_to(destination))] = digest(path)
    write(destination / "runner-result.json", {"exit_code": exit_code, "errors": errors,
          "parent_unchanged": unchanged, "artifact_manifest_version": 2, "artifacts": artifacts})
    print(log[-6000:])
    print(json.dumps({"evidence": str(destination), "errors": errors[:10], "error_count": len(errors)}, ensure_ascii=False))
    return 1 if errors else 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (ValueError, OSError, subprocess.SubprocessError) as exc:
        print(f"Engineering check failed: {exc}", file=sys.stderr)
        sys.exit(1)
