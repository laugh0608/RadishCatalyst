#!/usr/bin/env python3
"""Offline design audit, never a Godot/runtime or client-data validation result."""
import argparse
from collections import Counter, deque
from fractions import Fraction
import hashlib
import json
from math import hypot
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
EVIDENCE = REPO / "tools/runtime-intake/design-references/2026-11-01-integrated-contracts"
NODES = {
    "B0": (1, [], {}),
    "B1": (1, ["B0"], {"metal_plate": 4, "porous_carrier": 1}),
    "M1": (1, ["B0"], {"metal_plate": 3, "porous_carrier": 2}),
    "X1": (1, ["B0"], {"metal_plate": 2}),
    "E1": (2, ["B1", "M1", "X1"], {"metal_plate": 2, "porous_carrier": 1, "catalyst": 1}),
    "M2": (2, ["B1", "M1"], {"metal_plate": 4, "carbon_powder": 2}),
    "M3": (2, ["M2"], {"mineral_slag": 2, "crystal": 1}),
}
EFFECT_ITEMS = {"B0": {"metal_plate", "porous_carrier"}, "B1": {"construction_pack"},
                "M1": {"iron_powder", "carbon_powder"}, "X1": {"catalyst", "crust_solvent"},
                "E1": {"industrial_cell"}, "M2": {"mineral_slag"}, "M3": {"porous_carrier"}}
ENTITIES = {
    "core": (-11, 22, 6, 6), "I": (-28, -12, 2, 2), "Q": (-20, 11, 2, 2),
    "F": (-25, 23, 2, 3), "R": (-18, 24, 3, 3),
    "J1": (-24, -10, 1, 1), "J2": (-24, 0, 1, 1), "J3": (-24, 8, 1, 1),
    "J4": (-16, 16, 1, 1), "J5": (-24, 21, 1, 1), "J6": (-16, 22, 1, 1),
}
# Neighbor cells outside actual output/input port; each path includes both ends.
PATHS = {
    "I-core-N3": [(-26, -11), (-26, 10), (-7, 10), (-7, 21)],
    "Q-core-N1": [(-18, 12), (-18, 18), (-9, 18), (-9, 21)],
    "core-E0-F": [(-5, 23), (-4, 23), (-4, 30), (-27, 30), (-27, 23), (-26, 23)],
    "F-core-N0": [(-23, 23), (-23, 19), (-10, 19), (-10, 21)],
    "core-W0-R": [(-12, 24), (-12, 20), (-20, 20), (-20, 26), (-19, 26)],
    "R-core-W1": [(-15, 26), (-12, 26)],
}
# (source entity, local output cell, outward normal, target, local input, normal)
ENDPOINTS = {
    "I-core-N3": ("I", (1, 1), (1, 0), "core", (4, 0), (0, -1)),
    "Q-core-N1": ("Q", (1, 1), (1, 0), "core", (2, 0), (0, -1)),
    "core-E0-F": ("core", (5, 1), (1, 0), "F", (0, 0), (-1, 0)),
    "F-core-N0": ("F", (1, 0), (1, 0), "core", (1, 0), (0, -1)),
    "core-W0-R": ("core", (0, 2), (-1, 0), "R", (0, 2), (-1, 0)),
    "R-core-W1": ("R", (2, 2), (1, 0), "core", (0, 4), (-1, 0)),
}
PORTS = {
    "inputs": [([x, 0], [0, -1]) for x in range(1, 5)] + [([0, z], [-1, 0]) for z in [1, 4]],
    "outputs": [([5, z], [1, 0]) for z in range(1, 5)] + [([0, z], [-1, 0]) for z in [2, 3]],
}
SUPPLY = {"collector": 3, "reactor": 1, "crusher": 1, "refinery": 1, "assembler": 1,
          "storage": 2, "power_junction": 12, "belt": 256,
          "splitter": 4, "merger": 4, "admission_gate": 4}


def expand(points):
    result = [points[0]]
    for a, b in zip(points, points[1:]):
        assert (a[0] == b[0]) != (a[1] == b[1]), (a, b)
        dx = (b[0] > a[0]) - (b[0] < a[0])
        dz = (b[1] > a[1]) - (b[1] < a[1])
        while result[-1] != b:
            x, z = result[-1]
            result.append((x + dx, z + dz))
    return result


def rect_distance(point, rect):
    x, z, w, d = rect
    return hypot(max(x - point[0], 0, point[0] - x - w),
                 max(z - point[1], 0, point[1] - z - d))


def audit():
    checks = []

    def check(condition, label):
        checks.append({"check": label, "ok": bool(condition)})
        if not condition:
            raise ValueError(label)

    occupied = {}
    for name, (x, z, w, d) in ENTITIES.items():
        for cell in [(i, j) for i in range(x, x + w) for j in range(z, z + d)]:
            check(-32 <= cell[0] < 4 and -32 <= cell[1] < 32 and cell not in occupied, "footprint " + name + str(cell))
            occupied[cell] = name
    port_cells = [tuple(cell) for group in PORTS.values() for cell, _ in group]
    check(len(set(port_cells)) == 12, "six input and six output ports occupy different boundary cells")
    belts = set()
    routes = {}
    for name, points in PATHS.items():
        cells = expand(points)
        check(len(cells) == len(set(cells)), "no self crossing " + name)
        source, sp, sn, target, tp, tn = ENDPOINTS[name]
        start_cell = (ENTITIES[source][0] + sp[0] + sn[0], ENTITIES[source][1] + sp[1] + sn[1])
        end_cell = (ENTITIES[target][0] + tp[0] + tn[0], ENTITIES[target][1] + tp[1] + tn[1])
        check(cells[0] == start_cell and cells[-1] == end_cell, "real port neighbors " + name)
        check((cells[-1][0] - cells[-2][0], cells[-1][1] - cells[-2][1]) == (-tn[0], -tn[1]), "input facing " + name)
        for cell in cells:
            check(-32 <= cell[0] < 4 and -32 <= cell[1] < 32 and cell not in occupied and cell not in belts, "legal noncrossing belt " + name + str(cell))
            belts.add(cell)
        routes[name] = {"points": points, "belts": len(cells)}
    power_nodes = {k: (r[0] + r[2] / 2, r[1] + r[3] / 2) for k, r in ENTITIES.items() if k in ["core", "G"] or k.startswith("J")}
    reached = {"core"}
    while True:
        found = {b for b, pb in power_nodes.items() for a in reached if hypot(pb[0] - power_nodes[a][0], pb[1] - power_nodes[a][1]) <= 12}
        if found <= reached:
            break
        reached |= found
    check(len(reached) == len(power_nodes), "all sources and junctions share one range-connected network")
    distances = {}
    for name in ["I", "Q", "F", "R"] + (["K", "C", "E"] if "G" in ENTITIES else []):
        r = ENTITIES[name]
        center = r[0] + r[2] / 2, r[1] + r[3] / 2
        distance = min(hypot(center[0] - p[0], center[1] - p[1]) for p in power_nodes.values())
        distances[name] = distance
        check(distance <= 6, "consumer range " + name)
    # Conservative half-cell walking grid, all solid footprints expanded by 0.3.
    def free(p):
        return -31.7 <= p[0] <= 3.7 and -31.7 <= p[1] <= 31.7 and all(rect_distance(p, r) > 0.3 for r in ENTITIES.values())
    start = (-16, 40)  # world position (-8,20)
    check(free((start[0] / 2, start[1] / 2)), "spawn is clear")
    visited, queue = {start}, deque([start])
    while queue:
        x, z = queue.popleft()
        for p in [(x + 1, z), (x - 1, z), (x, z + 1), (x, z - 1)]:
            if p not in visited and free((p[0] / 2, p[1] / 2)):
                visited.add(p)
                queue.append(p)
    for name, rect in ENTITIES.items():
        check(any(rect_distance((x / 2, z / 2), rect) <= 2 for x, z in visited), "walkable approach " + name)
    check((5, 5) in visited, "the unique sample at (2.5,2.5) remains approachable")
    completed = set()
    available = {"iron_ore", "crystal", "carbon_ore"}
    order = []
    while len(completed) < len(NODES):
        ready = [k for k, (_, deps, _) in NODES.items() if k not in completed and set(deps) <= completed]
        check(bool(ready), "research DAG advances")
        for key in ready:
            check(set(NODES[key][2]) <= available, "research cost items are producible before unlock " + key)
            if NODES[key][0] == 2:
                check({"B1", "M1", "X1"} <= completed and "construction_pack" in available, "core II is reachable before " + key)
            completed.add(key)
            available |= EFFECT_ITEMS[key]
            order.append(key)
    check("crust_sample" not in NODES["X1"][2] and "catalyst" not in NODES["X1"][2], "X1 cannot consume unique sample or its own unlocked catalyst")
    needed = Counter({"construction_pack": 9, "industrial_cell": 1})
    for key in ["B1", "M1", "X1", "E1"]:
        needed.update(NODES[key][2])
    derived = {}
    for item, count, ingredients in [
        ("construction_pack", 1, {"metal_plate": 2, "porous_carrier": 1}),
        ("industrial_cell", 1, {"metal_plate": 1, "carbon_powder": 2, "catalyst": 1}),
        ("metal_plate", 1, {"iron_ore": 2}),
        ("porous_carrier", 1, {"crystal": 3}),
        ("catalyst", 1, {"crystal": 2}),
        ("carbon_powder", 2, {"carbon_ore": 1}),
    ]:
        batches = Fraction(needed.pop(item, 0), count)
        check(batches.denominator == 1, "exact direct-route batches " + item)
        derived[item] = int(batches)
        needed.update({k: int(batches) * n for k, n in ingredients.items()})
    check(dict(needed) == {"iron_ore": 60, "crystal": 43, "carbon_ore": 1}, "full first-core-and-energy bill of materials")
    check(len(belts) <= SUPPLY["belt"], "selected layout fits candidate initial belt supply")
    return {"kind": "offline-contract-audit-not-runtime", "checks": checks,
            "layout": {"entities": ENTITIES, "ports": PORTS, "routes": routes,
                          "belts": len(belts), "non_belt_entities": len(ENTITIES),
                          "occupied_cells": len(occupied) + len(belts), "consumer_distances": distances},
            "research_order": order, "first_goal_raw_materials": dict(needed), "direct_batches": derived,
            "power_kw": {"S0_running": 140, "energy_chain": 220, "with_other_production": 320, "candidate_core": 360, "candidate_one_G_capacity": 480},
            "candidate_supply": SUPPLY, "initial_owned_including_core": sum(SUPPLY.values()) + 1,
            "limits": ["geometry only, with full energy-chain geometry in S1",
                       "parallel energy+construction routing and natural throughput remain unverified",
                       "no runtime, visual, dynamic logistics or player-time evidence"]}


def main():
    global ENTITIES, PATHS, ENDPOINTS
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--layout", choices=["S0", "S1"], default="S0")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    if args.layout == "S1":
        ENTITIES = ENTITIES | {"K": (-28, 10, 2, 2), "C": (-24, 12, 2, 2),
                               "E": (-2, 24, 3, 2), "G": (1, 20, 2, 2)}
        PATHS = {k: v for k, v in PATHS.items() if k not in ["core-E0-F", "Q-core-N1"]}
        ENDPOINTS = {k: v for k, v in ENDPOINTS.items() if k not in ["core-E0-F", "Q-core-N1"]}
        PATHS.update({
            "Q-core-N2": [(-18, 12), (-18, 18), (-8, 18), (-8, 21)],
            "F-core-N0": [(-23, 23), (-23, 20), (-10, 20), (-10, 21)],
            "core-W0-R": [(-12, 24), (-12, 21), (-20, 21), (-20, 26), (-19, 26)],
            "K-C": [(-26, 11), (-26, 13), (-25, 13)],
            "C-core-N1": [(-22, 13), (-22, 19), (-9, 19), (-9, 21)],
            "core-E3-F": [(-5, 26), (3, 26), (3, 30), (-27, 30), (-27, 23), (-26, 23)],
            "core-E0-E": [(-5, 23), (-5, 22), (-1, 22), (-1, 23)],
            "core-E1-E": [(-5, 24), (-3, 24)],
            "core-E2-E": [(-5, 25), (-3, 25)],
            "E-G": [(1, 25), (3, 25), (3, 19), (-1, 19), (-1, 21), (0, 21)],
        })
        ENDPOINTS.update({
            "Q-core-N2": ("Q", (1, 1), (1, 0), "core", (3, 0), (0, -1)),
            "K-C": ("K", (1, 1), (1, 0), "C", (0, 1), (-1, 0)),
            "C-core-N1": ("C", (1, 1), (1, 0), "core", (2, 0), (0, -1)),
            "core-E3-F": ("core", (5, 4), (1, 0), "F", (0, 0), (-1, 0)),
            "core-E0-E": ("core", (5, 1), (1, 0), "E", (1, 0), (0, -1)),
            "core-E1-E": ("core", (5, 2), (1, 0), "E", (0, 0), (-1, 0)),
            "core-E2-E": ("core", (5, 3), (1, 0), "E", (0, 1), (-1, 0)),
            "E-G": ("E", (2, 1), (1, 0), "G", (0, 1), (-1, 0)),
        })
    output = (args.output or EVIDENCE / ("audit.json" if args.layout == "S0" else "audit-s1.json")).resolve()
    if not output.is_relative_to(EVIDENCE.resolve()):
        raise ValueError("Design evidence must stay in the designated ignored directory.")
    report = audit()
    report["layout_name"] = args.layout
    report["script_sha256"] = hashlib.sha256(Path(__file__).read_bytes()).hexdigest()
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"checks": len(report["checks"]), "belts": report["layout"]["belts"],
                      "occupied_cells": report["layout"]["occupied_cells"], "raw": report["first_goal_raw_materials"], "output": str(output)}, ensure_ascii=False))


if __name__ == "__main__":
    main()
