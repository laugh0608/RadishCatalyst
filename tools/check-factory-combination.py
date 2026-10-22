#!/usr/bin/env python3
"""Run C checks in fresh batches; derive recovery copies with file hashes."""

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
RUNS = REPO / "tools/runtime-intake/check-runs/factory-conveyor-combination-v1"
MODES = (
    "geometry", "state", "process-read", "background-write",
    "background-read", "background-complete-read", "review", "background-faults",
)
FAULTS = ("wrong-gap", "raw-closed", "sink-blocked", "g4-blocked", "quota-reset", "power-shortage")


def batch_path(name):
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_-]*", name):
        raise ValueError("Batch must contain only letters, digits, underscores and hyphens.")
    path = RUNS / name
    if path.is_symlink() or not path.resolve().is_relative_to(RUNS.resolve()):
        raise ValueError("Batch must stay inside the C run directory.")
    return path


def load(path):
    return json.loads(path.read_text(encoding="utf-8"))


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def require_success(source, filename):
    result = load(source / filename)
    if result.get("failures") != [] or result.get("assertions", 0) <= 0:
        raise ValueError(f"Source needs a successful {filename} with assertions.")


def require_parent(source, filename):
    require_success(source, filename)
    result = load(source / "runner-result.json")
    if result.get("exit_code") != 0 or result.get("errors") != [] or result.get("parent_unchanged") is not True:
        raise ValueError("Parent runner failed; script assertions alone are insufficient.")


def source_files(source):
    files = []
    for path in sorted(source.rglob("*")):
        if path.is_symlink():
            raise ValueError(f"Symlink not allowed in source batch: {path}")
        if path.name.endswith(".lock"):
            raise ValueError(f"Source still has a save lock: {path}")
        if path.is_file():
            files.append(path)
    return files


def prepare(mode, destination, source):
    """Copy immutable inputs only; preserve parent outputs and failed children."""
    if mode == "process-read":
        require_parent(source, "state-result.json")
        needed = {"state-partial.json", "state-expected.json", "state-context.json"}
        if not all((source / name).is_file() for name in needed):
            raise ValueError("State source lacks independent recovery snapshots.")
    else:
        completion = mode == "background-complete-read"
        require_parent(source, "read-result.json" if completion else "write-result.json")
        if not completion and (source / "read-result.json").exists():
            raise ValueError("Write source was already consumed in place; use its untouched copy.")
        expected = "completion-expected.json" if completion else "expected.json"
        if not (source / expected).is_file():
            raise ValueError(f"Missing source {expected}.")
        needed = None
    files = source_files(source)
    before = {str(path.relative_to(source)): digest(path) for path in files}
    destination.mkdir(parents=True, exist_ok=False)
    copied = {}
    for path in files:
        relative = path.relative_to(source)
        if needed is not None:
            if str(relative) not in needed:
                continue
        elif path.suffix != ".json" or path.name.endswith("-result.json") or path.name in ("origin.json", "runner-result.json"):
            continue
        target_relative = Path("expected.json") if mode == "background-complete-read" and str(relative) == "completion-expected.json" else relative
        if mode == "background-complete-read" and str(relative) == "expected.json":
            continue
        target = destination / target_relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(path, target)
        copied[str(target_relative)] = {"source": str(relative), "sha256": digest(target)}
        if copied[str(target_relative)]["sha256"] != before[str(relative)]:
            raise ValueError("Source changed while copying; keep this failed batch and retry from a stable source.")
    after = {str(path.relative_to(source)): digest(path) for path in source_files(source)}
    if before != after:
        raise ValueError("Source changed during preparation.")
    (destination / "origin.json").write_text(json.dumps({
        "parent_batch": source.name, "mode": mode, "source_hashes": before,
        "copied_files": copied,
    }, indent=2) + "\n", encoding="utf-8")
    return before


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=MODES)
    parser.add_argument("batch", help="Always a new batch, including every recovery/review attempt")
    parser.add_argument("source", nargs="?", help="C parent batch for recovery/state, or isolated snapshot for state")
    parser.add_argument("--fault", choices=FAULTS, help="One isolated operation branch; requires background-faults")
    args = parser.parse_args()
    if (args.mode == "background-faults") != bool(args.fault):
        raise ValueError("background-faults requires exactly one --fault; other modes do not accept it.")
    destination = batch_path(args.batch)
    if destination.exists():
        raise ValueError("Use a new batch; all evidence is retained.")
    needs_source = args.mode not in ("geometry", "background-write")
    if needs_source != bool(args.source):
        raise ValueError("This mode requires a source." if needs_source else "This mode does not take a source.")
    godot = os.environ.get("GODOT_EXE") or shutil.which("godot") or shutil.which("godot4") or "/Applications/Godot.app/Contents/MacOS/Godot"
    if not Path(godot).is_file():
        raise ValueError("Set GODOT_EXE to an installed Godot executable.")
    source = None
    before = None
    extra = []
    if args.mode == "state":
        snapshot = Path(args.source)
        source_kind = "explicit-snapshot"
        if not snapshot.is_absolute():
            source = batch_path(args.source)
            require_parent(source, "write-result.json")
            snapshot = source / "expected.json"
            source_kind = "natural-boot-write-batch"
        if snapshot.is_symlink() or not snapshot.resolve().is_relative_to((REPO / "tools/runtime-intake").resolve()) or not snapshot.is_file():
            raise ValueError("State snapshot must be a real file under this repository's runtime-intake.")
        destination.mkdir(parents=True, exist_ok=False)
        shutil.copyfile(snapshot, destination / "source-snapshot.json")
        checksum = digest(snapshot)
        if checksum != digest(destination / "source-snapshot.json"):
            raise ValueError("State snapshot changed while copying.")
        (destination / "origin.json").write_text(json.dumps({"source": str(snapshot), "sha256": checksum, "source_kind": source_kind}, indent=2) + "\n", encoding="utf-8")
        extra.append("--snapshot=" + str(destination / "source-snapshot.json"))
        extra.append("--source-kind=" + source_kind)
    elif needs_source:
        source = batch_path(args.source)
        before = prepare(args.mode, destination, source)
    else:
        destination.mkdir(parents=True, exist_ok=False)
    state_mode = args.mode in ("geometry", "state", "process-read")
    script = "factory_combination_check.gd" if state_mode else "factory_combination_boot_check.gd"
    command = [godot]
    if args.mode != "review":
        command.append("--headless")
    logfile = destination / (args.mode + ".log")
    command.extend(["--path", str(REPO / "client"), "--script", "res://scripts/checks/" + script,
                    "--no-header", "--log-file", str(logfile), "--"])
    if state_mode:
        command.append("--evidence=" + str(destination))
        if args.mode == "geometry": extra.append("--geometry")
        if args.mode == "process-read": extra.append("--read")
    else:
        command.append("--batch=" + args.batch)
        if args.mode != "review": extra.append("--background")
        if args.mode != "background-write": extra.append("--read")
        if args.mode == "background-complete-read": extra.append("--complete-read")
        if args.mode == "review": extra.append("--visual-only")
        if args.mode == "background-faults": extra.append("--fault=" + args.fault)
    command.extend(extra)
    check_sources = sorted((REPO / "client/scripts/checks").glob("factory_combination_*.gd"))
    (destination / "execution-inputs.json").write_text(json.dumps({
        "command": command,
        "check_source_sha256": {str(path.relative_to(REPO)): digest(path) for path in check_sources},
        "runner_sha256": digest(Path(__file__)),
    }, indent=2) + "\n", encoding="utf-8")
    result = subprocess.run(command, cwd=REPO, check=False)
    errors = []
    if logfile.is_file():
        errors = [line for line in logfile.read_text(encoding="utf-8").splitlines()
                  if re.match(r"^(SCRIPT ERROR|ERROR:)", line) and 'Condition "ret != noErr"' not in line]
    else:
        errors.append("Godot did not create the required log.")
    report_name = {
        "geometry": "geometry-result.json", "state": "state-result.json", "process-read": "read-result.json",
        "background-write": "write-result.json", "background-read": "read-result.json",
        "background-complete-read": "complete-read-result.json", "review": "review-result.json", "background-faults": "faults-result.json",
    }[args.mode]
    try:
        require_success(destination, report_name)
    except (ValueError, OSError) as exc:
        errors.append(str(exc))
    if before is not None:
        after = {str(path.relative_to(source)): digest(path) for path in source_files(source)}
        if before != after: errors.append("Parent batch changed during child execution.")
    (destination / "runner-result.json").write_text(json.dumps({
        "mode": args.mode, "exit_code": result.returncode, "errors": errors,
        "parent_unchanged": before is None or before == after,
    }, indent=2) + "\n", encoding="utf-8")
    if result.returncode or errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    print(f"C {args.mode} passed: {destination}")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (ValueError, OSError) as error:
        print(error, file=sys.stderr)
        sys.exit(1)
