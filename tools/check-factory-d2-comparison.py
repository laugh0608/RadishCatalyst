#!/usr/bin/env python3
"""Isolated D2 preparation and preflight. Failed samples are never overwritten."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import runpy
import shutil
import subprocess
import sys
import time

REPO = Path(__file__).resolve().parents[1]
ROOT = REPO / "tools/runtime-intake/check-runs/factory-d2-production-v1"
FAULT_MODES = {"fault-preflight-v2", "fault-preflight-v3", "fault-preflight-v4"}
V4_PREPARE = "fault-prepare-v4"
V5_PREPARE = "fault-prepare-v5"
V5_MODES = {"fault-v5-cycle", "fault-v5-recheck", "fault-preflight-v5"}
FD_MODES = {"fault-fd-cycle", "fault-fd-diagnostic"}


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def hashes(folder):
    return {str(p.relative_to(folder)): digest(p) for p in sorted(folder.rglob("*")) if p.is_file()}


def write(path, data):
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def write_fault_report(folder, result):
    diagnostic = result.get("execution_mode") == "fd_drain_fixed_step"
    title = "D2 Fd 排空后开放 A 的固定步诊断" if diagnostic else f"D2 C3 v{result['revision']} 成对固定步预检"
    lines = [
        f"# {title}",
        "",
        f"批次 `{folder.name}` · `{result['status']}`",
        "",
        "| 组 / 窗 | 峰值请求 kW | 峰值缺口 kW | 平均缺口 kW | 全窗缺电 kWh | 故障归因缺电 Wh | 储能期初 → 期末 Wh | R08 / R11 / Fd 实收 |",
        "| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |",
    ]
    arms = ("O4", "Fd-drain") if diagnostic else (f"O{result['revision']}", f"L{result['revision']}")
    for arm in arms:
        run = result["arms"].get(arm)
        if run is None:
            continue
        for index, window in enumerate(run["windows"]):
            start = run["boundaries"][index]
            end = run["boundaries"][index + 1]
            seconds = (window["end_tick"] - window["start_tick"]) / 20
            deficit = window["deficit_kj"]
            storage = " → ".join(f"{b['supply']['stored_j'] / 3600:.3f}" for b in (start, end))
            receipts = " / ".join(str(window["receipts"][name]) for name in ("R08_core", "R11_T", "Fd_Td"))
            lines.append(
                f"| {arm} / {index + 1} | {window['peak_request_kw']:.3f} | {window['peak_deficit_kw']:.3f} | "
                f"{deficit / seconds:.3f} | {deficit / 3600:.6f} | {window['fault_deficit_kj'] / 3.6:.3f} | "
                f"{storage} | {receipts} |"
            )
    if diagnostic and "Fd-drain" in result["arms"]:
        run = result["arms"]["Fd-drain"]
        lines.extend(["", "C3 关闭。Fd 尾批完工后开放 A。", "",
                      "| 周期 | Fd 尾批完工相位 s | A 开放相位 s | 两单入仓相位 s |",
                      "| --- | ---: | ---: | --- |"])
        for edge in run["opening_edges"]:
            origin = (edge["cycle"] - 1) * 2400
            state = edge["production_state"]
            arrivals = " / ".join(
                f"{(order['received'] - origin) / 20:.2f}" if order["received"] >= 0 else "未入仓"
                for order in run["orders"] if order["release"] == origin + 1200
            )
            lines.append(f"| {edge['cycle']} | {(state['fd_finished_tick'] - origin) / 20:.2f} | "
                         f"{(state['tick'] - origin) / 20:.2f} | {arrivals} |")
    elif not diagnostic:
        matched = [str(edge["cycle"]) for edge in result["paired_edges"] if edge["matched"]]
        lines.extend(["", "观测到成对阻断与恢复的周期为 " + ("、".join(matched) if matched else "无") + "。"])
    for heading, key in (("样本资格", "sample_invalid_reasons"), ("策略收益", "strategy_reasons")):
        if result[key]:
            lines.extend(["", f"## {heading}", "", *(f"- {reason}" for reason in result[key])])
    lines.extend(["", "展示值仅供阅读，判定与残差以 `result.json` 原始账本为准。"])
    (folder / "report.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=["prepare", "preflight", "feasibility", V4_PREPARE, V5_PREPARE, *sorted(FAULT_MODES | FD_MODES | V5_MODES)])
    parser.add_argument("batch")
    parser.add_argument("--parent")
    parser.add_argument("--preflight-parent", help="Successful two-cycle check of the same candidate for paired fault preflight")
    parser.add_argument("--cycle-parent", help="Successful Fd cycle check of the same derived candidate")
    parser.add_argument("--recheck-parent", help="Successful second-batch interlock recheck")
    parser.add_argument("--reference", help="Recorded v4 paired run containing O4")
    parser.add_argument("--godot", default=os.environ.get("GODOT_EXE", "/Applications/Godot.app/Contents/MacOS/Godot"))
    args = parser.parse_args()
    for value in [args.batch, args.parent, args.preflight_parent, args.cycle_parent, args.recheck_parent, args.reference]:
        if value is not None and not re.fullmatch(r"[a-zA-Z0-9_-]+", value):
            parser.error("Batch names must contain only letters, digits, underscores and hyphens.")
    if (args.mode != "prepare") != bool(args.parent):
        parser.error("Every preflight mode requires --parent; prepare does not consume a parent.")
    needs_original_preflight = args.mode in (FAULT_MODES | {V4_PREPARE}) - {"fault-preflight-v4"}
    if needs_original_preflight != bool(args.preflight_parent):
        parser.error("v2/v3 paired preflight and v4 preparation require --preflight-parent.")
    full_fd_diagnostic = args.mode == "fault-fd-diagnostic"
    needs_cycle = full_fd_diagnostic or args.mode in {"fault-v5-recheck", "fault-preflight-v5"}
    if (needs_cycle != bool(args.cycle_parent) or full_fd_diagnostic != bool(args.reference)
            or (args.mode == "fault-preflight-v5") != bool(args.recheck_parent)):
        parser.error("Missing or unexpected cycle, recheck, or diagnostic reference batch.")
    folder = ROOT / args.batch
    folder.mkdir(parents=True, exist_ok=False)
    source_files = [p for p in (REPO / "client").rglob("*")
                    if p.is_file() and ".godot" not in p.parts
                    and p.suffix in {".gd", ".tscn", ".godot", ".uid"}]
    source_files += [REPO / "tools/design/audit-four-sided-core-layout.py",
                     REPO / "tools/design/audit-frontier-layout.py",
                     REPO / "docs/features/factory-d2-production-comparison.md"]
    source_files += list((REPO / "tools").glob("check-factory-d2-comparison.*"))
    if args.mode in FAULT_MODES | FD_MODES | V5_MODES | {V5_PREPARE}:
        source_files.append(REPO / "docs/features/factory-d2-c3-fault-revision-v2.md")
    write(folder / "code.json", {str(p.relative_to(REPO)): digest(p) for p in sorted(source_files)})
    source_hashes = {}
    if args.mode == "prepare":
        starter = runpy.run_path(str(REPO / "tools/design/audit-four-sided-core-layout.py"))["audit"]("S1-P")
        layout = runpy.run_path(str(REPO / "tools/design/audit-frontier-layout.py"))["audit"]()
        write(folder / "starter.json", starter)
        write(folder / "layout.json", layout)
    else:
        parent = ROOT / args.parent
        result = json.loads((parent / "result.json").read_text(encoding="utf-8"))
        v4_candidate = args.mode == "fault-preflight-v4" or args.mode in FD_MODES | {V5_PREPARE}
        expected_parent = ("interlock_parent_prepared" if args.mode in V5_MODES else
                           "fault_v4_prepared" if v4_candidate else "prepared_candidate")
        if result.get("status") != expected_parent:
            raise ValueError(f"Parent must have status {expected_parent}.")
        parent_hashes = hashes(parent)
        source_hashes[parent] = parent_hashes
        for filename in ["candidate.json", "preparation.json", "layout.json"]:
            shutil.copyfile(parent / filename, folder / filename)
        write(folder / "source.json", {"parent": args.parent, "sha256": parent_hashes})
        if needs_original_preflight:
            preflight = ROOT / args.preflight_parent
            report = json.loads((preflight / "result.json").read_text(encoding="utf-8"))
            source = json.loads((preflight / "source.json").read_text(encoding="utf-8"))
            if report.get("status") != "preflight_passed" or report.get("two_cycle_checks_passed") is not True:
                raise ValueError("Expected a successful two-cycle preflight.")
            if source != {"parent": args.parent, "sha256": parent_hashes}:
                raise ValueError("Two-cycle preflight did not consume this unchanged prepared candidate.")
            for filename in ["candidate.json", "preparation.json", "layout.json"]:
                if digest(preflight / filename) != parent_hashes[filename]:
                    raise ValueError(f"Two-cycle preflight copy changed: {filename}")
            source_hashes[preflight] = hashes(preflight)
            write(folder / "two-cycle-source.json", {"batch": args.preflight_parent, "sha256": source_hashes[preflight]})
        if args.mode in FAULT_MODES | FD_MODES | {V4_PREPARE, V5_PREPARE}:
            candidate = json.loads((folder / "candidate.json").read_text(encoding="utf-8"))
            world_id = candidate["world_id"]
            if not re.fullmatch(r"[a-f0-9]{32}", world_id):
                raise ValueError("Invalid factory world ID.")
            save_folder = parent / "factory" / world_id
            if args.mode == V4_PREPARE:
                destination = folder / "factory" / world_id
                destination.mkdir(parents=True)
                for filename in ("autosave.json", "metadata.json"):
                    shutil.copyfile(save_folder / filename, destination / filename)
            else:
                shutil.copyfile(save_folder / "autosave.json", folder / "prepared-autosave.json")
            if v4_candidate:
                proof = json.loads((parent / "carrier-proof.json").read_text(encoding="utf-8"))
                if not proof["ok"] or proof["candidate_sha256"] != digest(folder / "candidate.json"):
                    raise ValueError("The derived candidate has no matching successful carrier proof.")
                shutil.copyfile(parent / "carrier-proof.json", folder / "carrier-proof.json")
        if args.mode in V5_MODES:
            for name in ("prepared-autosave.json", "carrier-proof.json", "interlock-candidate.json"):
                shutil.copyfile(parent / name, folder / name)
            derived_hash = digest(folder / "interlock-candidate.json")
            if (result.get("derived_sha256") != derived_hash
                    or result.get("candidate_sha256") != digest(folder / "candidate.json")):
                raise ValueError("Invalid schema 16 derivation manifest.")
            required = [(args.cycle_parent, "interlock_cycle_passed"), (args.recheck_parent, "interlock_recheck_passed")]
            for name, status in required:
                if name is None:
                    continue
                gate = ROOT / name
                gate_result = json.loads((gate / "result.json").read_text(encoding="utf-8"))
                gate_source = json.loads((gate / "source.json").read_text(encoding="utf-8"))
                if (gate_result.get("status") != status or gate_result.get("derived_sha256") != derived_hash
                        or gate_source != {"parent": args.parent, "sha256": parent_hashes}):
                    raise ValueError(f"{name} did not pass against this unchanged schema 16 parent.")
                source_hashes[gate] = hashes(gate)
                if status == "interlock_cycle_passed" and args.mode == "fault-v5-recheck":
                    shutil.copyfile(gate / "first-order-checkpoint.json", folder / "first-order-checkpoint.json")
            if args.mode == "fault-preflight-v5":
                recheck_source = json.loads((ROOT / args.recheck_parent / "gates.json").read_text(encoding="utf-8"))
                if recheck_source != {args.cycle_parent: source_hashes[ROOT / args.cycle_parent]}:
                    raise ValueError("The restart recheck did not consume the approved cycle checkpoint.")
            write(folder / "gates.json", {name: source_hashes[ROOT / name] for name, _ in required if name})
        if full_fd_diagnostic:
            candidate_hash = digest(folder / "candidate.json")
            cycle = ROOT / args.cycle_parent
            cycle_result = json.loads((cycle / "result.json").read_text(encoding="utf-8"))
            cycle_source = json.loads((cycle / "source.json").read_text(encoding="utf-8"))
            if (cycle_result.get("status") != "fd_cycle_passed" or cycle_result.get("candidate_sha256") != candidate_hash
                    or cycle_source != {"parent": args.parent, "sha256": parent_hashes}):
                raise ValueError("The same derived parent must pass the short Fd cycle gate.")
            reference = ROOT / args.reference
            reference_result = json.loads((reference / "result.json").read_text(encoding="utf-8"))
            reference_source = json.loads((reference / "source.json").read_text(encoding="utf-8"))
            o4 = reference_result.get("arms", {}).get("O4", {})
            if (reference_result.get("revision") != 4 or reference_result.get("candidate_sha256") != candidate_hash
                    or reference_source != cycle_source or reference_result.get("sample_invalid_reasons")
                    or o4.get("observed_steps") != 28800 or len(o4.get("windows", [])) != 2):
                raise ValueError("Expected a complete valid O4 reference from this derived parent.")
            for path in (cycle, reference):
                source_hashes[path] = hashes(path)
            write(folder / "diagnostic-sources.json", {path.name: source_hashes[path] for path in (cycle, reference)})
            shutil.copyfile(reference / "result.json", folder / "reference-result.json")
    command = [args.godot, "--headless", "--path", str(REPO / "client"),
               "--log-file", str(folder / "godot.log"), "--script",
               "res://scripts/checks/factory_d2_comparison_check.gd", "--",
               f"--batch={args.batch}", f"--mode={args.mode}"]
    status = 1
    started = time.monotonic()
    timeout = 600 if args.mode in FAULT_MODES | FD_MODES | V5_MODES else 300
    env = os.environ.copy()
    for name, directory in {
        "HOME": "home", "XDG_DATA_HOME": "data", "XDG_CONFIG_HOME": "config",
        "XDG_CACHE_HOME": "cache", "APPDATA": "roaming", "LOCALAPPDATA": "local",
    }.items():
        path = folder / "engine-profile" / directory
        path.mkdir(parents=True)
        env[name] = str(path)
    (Path(env["HOME"]) / "Library/Application Support/Godot/app_userdata/RadishCatalyst/logs").mkdir(parents=True)
    try:
        with (folder / "console.log").open("w", encoding="utf-8") as log:
            process = subprocess.Popen(command, cwd=REPO, env=env, stdout=log, stderr=subprocess.STDOUT)
            deadline = time.monotonic() + timeout
            while process.poll() is None:
                current_log = (folder / "console.log").read_text(encoding="utf-8")
                if re.search(r"^(SCRIPT ERROR|ERROR:)", current_log, re.MULTILINE):
                    process.terminate()
                    break
                if time.monotonic() >= deadline:
                    process.terminate()
                    write(folder / "runner-failure.json", {"reason": f"{timeout}-second stage timeout", "partial": True})
                    break
                time.sleep(0.2)
            try:
                status = process.wait(timeout=10)
            except subprocess.TimeoutExpired:
                process.kill()
                status = process.wait()
    except KeyboardInterrupt:
        if process.poll() is None:
            process.terminate()
            status = process.wait(timeout=10)
        write(folder / "runner-failure.json", {"reason": "cancelled", "partial": True})
    write(folder / "execution.json", {"command": command, "exit_code": status,
                                      "wall_seconds": time.monotonic() - started, "mode": args.mode,
                                      "natural_clock_result": False})
    output = (folder / "console.log").read_text(encoding="utf-8")
    print("\n".join(output.splitlines()[-35:]))
    for source, before in source_hashes.items():
        if hashes(source) != before:
            raise ValueError(f"Read-only source changed during preflight: {source.name}")
    logs = output + ((folder / "godot.log").read_text(encoding="utf-8") if (folder / "godot.log").exists() else "")
    if re.search(r"^(SCRIPT ERROR|ERROR:)", logs, re.MULTILINE) or not (folder / "result.json").exists():
        write(folder / "runner-failure.json", {"reason": "engine error or missing result", "exit_code": status})
        return 1
    result = json.loads((folder / "result.json").read_text(encoding="utf-8"))
    print(json.dumps({"batch": args.batch, "status": result["status"],
                      "reason": result.get("reason", ""), "reasons": result.get("reasons", [])}, ensure_ascii=False))
    expected_status = {"prepare": "prepared_candidate", "preflight": "preflight_passed", V4_PREPARE: "fault_v4_prepared",
                       "fault-fd-cycle": "fd_cycle_passed", "fault-fd-diagnostic": "fd_diagnostic_passed",
                       "feasibility": "feasibility_passed", V5_PREPARE: "interlock_parent_prepared",
                       "fault-v5-cycle": "interlock_cycle_passed", "fault-v5-recheck": "interlock_recheck_passed",
                       "fault-preflight-v5": "fault_preflight_passed",
                       **dict.fromkeys(FAULT_MODES, "fault_preflight_passed")}[args.mode]
    if status == 0 and result["status"] != expected_status:
        return 1
    if args.mode in {"fault-preflight-v3", "fault-preflight-v4", "fault-v5-cycle", "fault-preflight-v5"} | FD_MODES:
        write_fault_report(folder, result)
    return status


if __name__ == "__main__":
    sys.exit(main())
