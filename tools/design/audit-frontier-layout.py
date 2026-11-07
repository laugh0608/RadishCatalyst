#!/usr/bin/env python3
"""Check D1's complete comparison layout and its theoretical material budget."""
from collections import deque
from fractions import Fraction
from math import dist, floor
from pathlib import Path
import json
import runpy

BASE = runpy.run_path(str(Path(__file__).with_name("audit-four-sided-core-layout.py")))
EXPAND = BASE["LEGACY"]["expand"]
RECT_DISTANCE = BASE["LEGACY"]["rect_distance"]
ADD = {
    "M": (-26, 12, 1, 1), "Kh": (10, 7, 2, 2),
    "J7": (2, 10, 1, 1), "J8": (2, 0, 1, 1), "J9": (9, 0, 1, 1), "J10": (13, 6, 1, 1),
    "Si": (-26, -7, 1, 1), "Sc": (-22, 14, 1, 1),
    "Ci": (-25, 1, 2, 2), "Fd": (-22, -7, 2, 3), "Td": (-19, -8, 2, 2), "Ts": (-19, 5, 2, 2),
}
W, N, E, S = (-1, 0), (0, -1), (1, 0), (0, 1)
REMOVE = {("I", "F"), ("K", "C"), ("C", "IN_N0")}
MODES = ((False, False, False), (True, False, False), (True, True, False), (True, False, True))


def open_cell(cell, flags):
    x, z = cell
    outer, inner, frontier = flags
    if not (-32 <= x < 32 and -32 <= z < 32):
        return False
    if x < 4:
        return True
    if not outer:
        return False
    if x < 8:
        return -2 <= z <= 1
    if 8 <= x <= 15 and 4 <= z <= 11:
        return frontier and ((10 <= x <= 13 and 4 <= z <= 5) or (9 <= x <= 14 and 6 <= z <= 10))
    return x < 20 or (inner and (x >= 24 or -2 <= z <= 1))


def line_open(a, b, flags):
    # The same closed-cell segment test as automatic power wiring.
    for x in range(floor(min(a[0], b[0])) - 1, floor(max(a[0], b[0])) + 1):
        for z in range(floor(min(a[1], b[1])) - 1, floor(max(a[1], b[1])) + 1):
            if open_cell((x, z), flags):
                continue
            low, high = 0.0, 1.0
            for start, end, edge in zip(a, b, (x, z)):
                if start == end:
                    if not edge <= start <= edge + 1:
                        high = -1
                        break
                else:
                    t0, t1 = sorted(((edge - start) / (end - start), (edge + 1 - start) / (end - start)))
                    low, high = max(low, t0), min(high, t1)
            if low <= high + 1e-12:
                return False
    return True


def endpoint_name(endpoint):
    return endpoint if isinstance(endpoint, str) else endpoint[0]


def audit():
    entities, baseline = BASE["build_layout"]("S1-P")
    entities.update(ADD)
    added = []

    def link(item, source, target, *points):
        added.append((item, source, target, points))

    link("iron_ore", ("I", (1, 1), E), ("Si", (0, 0), N), (-26, -11), (-26, -8))
    link("iron_ore", ("Si", (0, 0), S), ("Ci", (0, 1), W), (-26, -6), (-26, 1), (-27, 1), (-27, 2), (-26, 2))
    link("iron_ore", ("Si", (0, 0), E), ("Fd", (0, 0), W), (-25, -7), (-23, -7))
    link("iron_powder", ("Ci", (1, 1), E), ("F", (0, 0), W), (-23, 2), (-23, 3), (-26, 3), (-26, 4), (-25, 4))
    link("metal_plate", ("Fd", (1, 0), E), ("Td", (0, 1), W), (-20, -7))
    link("mineral_slag", ("F", (1, 2), E), ("Ts", (0, 1), W), (-22, 6), (-20, 6))
    link("carbon_ore", ("K", (1, 1), E), ("M", (0, 0), N), (-26, 11))
    link("carbon_ore", ("Kh", (1, 1), E), ("M", (0, 0), W),
         (12, 8), (12, -1), (-17, -1), (-17, -9), (-25, -9), (-25, -12),
         (-26, -12), (-26, -13), (-29, -13), (-29, 12), (-27, 12))
    link("carbon_ore", ("M", (0, 0), S), ("C", (0, 1), W), (-26, 13), (-25, 13))
    link("carbon_powder", ("C", (1, 1), E), ("Sc", (0, 0), N), (-22, 13))
    link("carbon_powder", ("Sc", (0, 0), S), "IN_N0", (-22, 15), (-22, 19), (-10, 19), (-10, 21))
    link("carbon_powder", ("Sc", (0, 0), E), ("F", (0, 2), W), (-21, 14), (-21, 7), (-26, 7), (-26, 6), (-25, 6))
    retained = [r for r in baseline if tuple(map(endpoint_name, r[1:3])) not in REMOVE]

    checks = 0

    def check(ok, label):
        nonlocal checks
        if not ok:
            raise ValueError(label)
        checks += 1

    ports = BASE["ports_from_manifest"]()

    def endpoint(spec, role):
        if isinstance(spec, str):
            port_role, local, normal = ports[spec]
            check(port_role == role, spec)
            spec = ("core", local, normal)
        device, (dx, dz), (nx, nz) = spec
        x, z, width, depth = entities[device]
        check(0 <= dx < width and 0 <= dz < depth, str(spec))
        check(not (0 <= dx + nx < width and 0 <= dz + nz < depth), str(spec))
        return (x + dx, z + dz), (x + dx + nx, z + dz + nz)

    _, locked, inner, opened = MODES
    occupied = set()
    for key, (x, z, w, d) in entities.items():
        for i in range(x, x + w):
            for j in range(z, z + d):
                cell = i, j
                check(open_cell(cell, opened) and cell not in occupied, f"{key} overlaps at {cell}")
                occupied.add(cell)

    belts = set()
    routing = []
    for item, source, target, points in retained + added:
        start, first = endpoint(source, "output")
        end, last = endpoint(target, "input")
        cells = EXPAND(points) if points else []
        check((cells[0], cells[-1]) == (first, last) if cells else (end, start) == (first, last), f"{source} → {target}")
        if len(cells) > 1:
            check(tuple(2 * near - port for near, port in zip(last, end)) == cells[-2], f"final belt direction: {target}")
        for cell in cells:
            check(open_cell(cell, opened) and cell not in occupied | belts, f"belt overlaps at {cell}")
            belts.add(cell)
        routing.append({"item": item, "source": source, "target": target, "points": points, "belts": len(cells)})

    centers = {key: (x + w / 2, z + d / 2) for key, (x, z, w, d) in entities.items()}
    nodes = {key for key in centers if key.startswith("J") or key in {"core", "G"}}
    reached = {"core"}
    while (adjacent := {k for k in nodes if any(dist(centers[k], centers[n]) <= 12
                                               and line_open(centers[k], centers[n], opened) for n in reached)}) != reached:
        reached = adjacent
    check(reached == nodes, "connected power grid")
    for key in {"I", "Q", "F", "R", "K", "C", "E", "F2", "A", "Kh", "Ci", "Fd"}:
        check(any(dist(centers[key], centers[n]) <= 6 and line_open(centers[key], centers[n], opened)
                  for n in nodes), f"{key} has power")
    check(not line_open(centers["J9"], centers["J10"], locked), "closed frontier blocks power")

    def walk(flags, placed):
        def free(point):
            x, z = (v / 2 for v in point)
            return (all(open_cell((floor(x + dx), floor(z + dz)), flags) for dx in (-0.3, 0.3) for dz in (-0.3, 0.3))
                    and all(RECT_DISTANCE((x, z), rect) > 0.3 for rect in placed))
        start = (-16, 40)
        check(free(start), "spawn accessible")
        seen, queue = {start}, deque([start])
        while queue:
            x, z = queue.popleft()
            for cell in ((x - 1, z), (x + 1, z), (x, z - 1), (x, z + 1)):
                if cell not in seen and free(cell):
                    seen.add(cell)
                    queue.append(cell)
        return seen

    before = [rect for key, rect in entities.items() if key not in {"Kh", "J10"}]
    locked_seen = walk(locked, before)
    check((24, 6) in locked_seen and (25, 15) not in locked_seen, "reach gate but not closed mine")
    check((52, 0) in walk(inner, before), "inner passage independent")
    seen = walk(opened, entities.values())
    check((25, 15) in seen, "walk through the frontier mouth")
    for key, rect in entities.items():
        check(any(RECT_DISTANCE((x / 2, z / 2), rect) <= 2 for x, z in seen), f"walk to {key}")

    belt_batches = (len(belts) - 256 + 7) // 8
    check(belt_batches == 3 and len(nodes) - 2 <= 12, "three belt batches and starter junctions")
    # Per minute at six R08 batches, one R12 cell, and a fully supplied R05.
    iron = 2 * 6 + 2 * Fraction(60, 8)
    carbon = Fraction(6, 2) + 1
    check(iron == 27 and carbon == 4, "iron and carbon demand")
    check(3 < carbon <= min(12, 10), "ore rate and carbon crusher ceiling")
    check(6 * 6 < 200 and 12 * Fraction(60, 8) < 200, "slag and direct plate can be received during both windows")
    check(360 < 320 + 20 + 60 <= 480, "simultaneous demand ceiling")
    return {"layout": "D1", "checks": checks, "entities": entities, "routes": routing,
            "replaced": sorted(REMOVE), "belts": len(belts), "belt_batches": belt_batches,
            "iron_per_minute": int(iron), "carbon_per_minute": int(carbon),
            "incremental_packs": 2 * 4 + belt_batches, "peak_kw_bound": 400}


if __name__ == "__main__":
    print(json.dumps(audit(), indent=2))
