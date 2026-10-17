#!/usr/bin/env python3
"""Run versioned ordinary statistics checks in immutable-source, fresh batches."""

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
INTAKE = REPO / "tools/runtime-intake"
RUNS = INTAKE / "check-runs/factory-statistics-v1"
C_RUNS = INTAKE / "check-runs/factory-conveyor-combination-v1"
MODES = ("prepare", "window", "prepare-v5", "verify-v5", "interrupt-v5", "window-v5")


def load(path):
    return json.loads(path.read_text(encoding="utf-8"))


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def real_path(path, root):
    path = Path(path)
    if not path.is_absolute() or not path.resolve().is_relative_to(root.resolve()):
        raise ValueError(f"Path must stay inside {root}.")
    for part in (path, *path.parents):
        if part.is_symlink():
            raise ValueError(f"Symlink is not an evidence source: {part}")
        if part == root:
            break
    return path


def batch_path(root, name):
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_-]*", name):
        raise ValueError("Use a simple unique batch name, not a path.")
    return real_path(root / name, root)


def file_hashes(root):
    result = {}
    for path in sorted(root.rglob("*")):
        if path.is_symlink() or path.name.endswith(".lock"):
            raise ValueError(f"Source must be unlocked and contain no symlinks: {path}")
        if path.is_file():
            result[str(path.relative_to(root))] = digest(path)
    return result


def code_hashes():
    paths = set()
    for folder in ("client/scripts/factory", "client/data/factory"):
        paths.update((REPO / folder).rglob("*.gd"))
    for name in ("factory_statistics_performance_check", "factory_statistics_performance_fixture",
                 "factory_performance_check", "factory_combination_layout", "factory_window_driver",
                 "factory_diagnostic_gate", "factory_discovery_check"):
        paths.add(REPO / "client/scripts/checks" / (name + ".gd"))
    paths.add(Path(__file__))
    return {str(path.relative_to(REPO)): digest(path) for path in sorted(paths)}


def require_success(parent, filename):
    result = load(parent / filename)
    if result.get("assertions", 0) <= 0 or result.get("failures") != []:
        raise ValueError(f"Source requires successful {filename}.")
    runner = load(parent / "runner-result.json")
    if runner.get("exit_code") != 0 or runner.get("errors") != [] or runner.get("parent_unchanged") is not True:
        raise ValueError("Source runner did not pass; assertions alone are insufficient.")
    return result


def prepare_inputs(mode, destination, source):
    """Freeze inputs, recording all parent files without consuming any parent save."""
    parent = None
    extras = []
    if mode in ("prepare", "window"):
        snapshot = real_path(Path(source), INTAKE)
        if not snapshot.is_file():
            raise ValueError("Explicit legacy source snapshot is missing.")
        before = {str(snapshot): digest(snapshot)}
    else:
        parent = batch_path(C_RUNS if mode == "prepare-v5" else RUNS, source)
        if mode == "prepare-v5":
            require_success(parent, "complete-read-result.json")
            snapshot = parent / "completion-read-final.json"
        else:
            report = require_success(parent, "result.json")
            if report.get("mode") != "prepare-v5" or report.get("preparation_details", {}).get("ready") is not True:
                raise ValueError("Use a completed V5 preparation batch, not a consumed verification or window run.")
            manifest = load(parent / "execution-inputs.json")
            if manifest.get("code_sha256") != code_hashes():
                raise ValueError("Check or model sources changed; create a fresh preparation batch.")
            snapshot = parent / "prepared.json"
            extras = [parent / "continuation.json"]
            artifacts = load(parent / "runner-result.json").get("artifacts", {})
            for path in [snapshot, *extras]:
                if artifacts.get(path.name) != digest(path):
                    raise ValueError("Prepared artifact changed after successful preparation.")
        before = file_hashes(parent)
    needed = [snapshot, *extras]
    for path in needed:
        if not path.is_file():
            raise ValueError(f"Missing required source: {path}")
    destination.mkdir(parents=True, exist_ok=False)
    copied = {}
    for path in needed:
        target = destination / ("source.json" if path == snapshot else path.name)
        shutil.copyfile(path, target)
        source_hash = before[str(path.relative_to(parent))] if parent else before[str(path)]
        if digest(target) != source_hash:
            raise ValueError("Source changed while copying; retain failed batch and retry from a stable source.")
        copied[target.name] = {"source": str(path), "sha256": source_hash}
    after = file_hashes(parent) if parent else {str(snapshot): digest(snapshot)}
    if after != before:
        raise ValueError("Parent changed during preparation.")
    (destination / "origin.json").write_text(json.dumps({
        "parent": str(parent) if parent else None, "source_hashes": before, "copied": copied,
    }, indent=2) + "\n", encoding="utf-8")
    return parent, snapshot, before


def outcome_errors(mode, report, interrupt_at):
    errors = []
    if not isinstance(report, dict):
        return ["Script result must be a JSON object."]
    if report.get("assertions", 0) <= 0 or report.get("failures") != [] or report.get("mode") != mode:
        errors.append("Missing, failed or wrong-mode script result.")
    if mode == "interrupt-v5":
        reason = "window_closed" if interrupt_at == "close" else "focus_lost"
        if report.get("interruption_check") is not True or report.get("interrupted") is not True or report.get("interruption_reason") != reason or report.get("phases") != []:
            errors.append("Interruption probe did not stop exactly as requested.")
    elif report.get("interrupted") is not False:
        errors.append("Unexpected interruption; partial runs never pass.")
    if mode in ("window", "window-v5") and report.get("performance_acceptance") is not True:
        errors.append("All three performance phases must pass.")
    if mode == "prepare-v5" and report.get("preparation_details", {}).get("ready") is not True:
        errors.append("V5 preparation did not prove a valid working load.")
    if mode == "verify-v5" and len(report.get("verification", [])) != 3:
        errors.append("All three independent Boot starting states must be verified.")
    if mode not in ("window", "window-v5") and report.get("performance_acceptance") is not False:
        errors.append("Preparation and probes cannot claim performance acceptance.")
    return errors


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=MODES)
    parser.add_argument("batch")
    parser.add_argument("source", help="Absolute isolated V2 snapshot, C completion batch for prepare-v5, or V5 preparation batch")
    parser.add_argument("--interrupt-at", choices=("before", "sampling", "close"))
    args = parser.parse_args()
    if (args.mode == "interrupt-v5") != bool(args.interrupt_at):
        raise ValueError("Only interrupt-v5 requires --interrupt-at before|sampling|close.")
    destination = batch_path(RUNS, args.batch)
    if destination.exists():
        raise ValueError("Batch already exists; use a new name and retain old evidence.")
    godot = os.environ.get("GODOT_EXE") or shutil.which("godot") or shutil.which("godot4") or "/Applications/Godot.app/Contents/MacOS/Godot"
    if not Path(godot).is_file():
        raise ValueError("Set GODOT_EXE to an installed Godot executable.")
    parent, snapshot, before = prepare_inputs(args.mode, destination, args.source)
    command = [godot]
    if args.mode not in ("window", "window-v5"):
        command.append("--headless")
    logfile = destination / (args.mode + ".log")
    command += ["--path", str(REPO / "client"), "--script", "res://scripts/checks/factory_statistics_performance_check.gd",
                "--no-header", "--log-file", str(logfile), "--", "--batch=" + args.batch,
                "--source=" + str(destination / "source.json"), "--mode=" + args.mode]
    if args.interrupt_at:
        command.append("--interrupt-at=" + args.interrupt_at)
    (destination / "execution-inputs.json").write_text(json.dumps({
        "command": command, "code_sha256": code_hashes(),
        "commit": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=REPO, text=True).strip(),
    }, indent=2) + "\n", encoding="utf-8")
    result = subprocess.run(command, cwd=REPO, check=False)
    errors = []
    if logfile.is_file():
        errors += [line for line in logfile.read_text(encoding="utf-8").splitlines()
                   if re.match(r"^(SCRIPT ERROR|ERROR:)", line) and 'Condition "ret != noErr"' not in line]
    else:
        errors.append("Godot did not create its required log.")
    try:
        errors += outcome_errors(args.mode, load(destination / "result.json"), args.interrupt_at)
    except (ValueError, OSError) as exc:
        errors.append(str(exc))
    try:
        after = file_hashes(parent) if parent else {str(snapshot): digest(snapshot)}
        unchanged = before == after
    except (ValueError, OSError) as exc:
        unchanged = False
        errors.append(str(exc))
    if not unchanged:
        errors.append("Source changed during execution.")
    (destination / "runner-result.json").write_text(json.dumps({
        "mode": args.mode, "exit_code": result.returncode, "errors": errors, "parent_unchanged": unchanged,
        "artifacts": {name: digest(destination / name) for name in ("prepared.json", "continuation.json")
                      if (destination / name).is_file()},
    }, indent=2) + "\n", encoding="utf-8")
    if result.returncode or errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    print(f"Statistics {args.mode} passed: {destination}")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (ValueError, OSError) as exc:
        print(exc, file=sys.stderr)
        sys.exit(1)
