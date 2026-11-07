#!/usr/bin/env python3
"""Audit the four-sided core routes without running the factory simulation."""
import argparse
from collections import Counter, deque
from hashlib import sha256
import json
from math import dist, floor
from pathlib import Path
import runpy

REPO = Path(__file__).resolve().parents[2]
LEGACY = runpy.run_path(str(Path(__file__).with_name("audit-demo-integration.py")))
PORT_MANIFEST = REPO / "client/assets/prototypes/base_core_outline/source-manifest.json"
EVIDENCE = REPO / "tools/runtime-intake/design-references/2026-11-07-four-sided-core"


def ports_from_manifest():
    ports = {}
    for port in json.loads(PORT_MANIFEST.read_text())["ports"]:
        x, _, z = port["point"]
        nx, nz = port["normal"]
        ports[port["id"]] = (port["role"], (floor(x + 3 - nx / 2), floor(z + 3 - nz / 2)), (nx, nz))
    return ports


def build_layout(name):
    entities = dict(LEGACY["ENTITIES"])
    routes = []

    def link(item, source, target, *points):
        routes.append((item, source, target, points))

    link("catalyst", ("R", (2, 2), (1, 0)), "IN_W0", (-15, 26), (-12, 26))
    if name == "S0":
        link("crystal", "OUT_W0", ("R", (0, 2), (-1, 0)),
             (-12, 23), (-12, 20), (-20, 20), (-20, 26), (-19, 26))
        link("iron_ore", ("I", (1, 1), (1, 0)), "IN_N2",
             (-26, -11), (-26, 10), (-8, 10), (-8, 21))
        link("crystal", ("Q", (1, 1), (1, 0)), "IN_N1",
             (-18, 12), (-18, 18), (-9, 18), (-9, 21))
        link("iron_ore", "OUT_S0", ("F", (0, 0), (-1, 0)),
             (-10, 28), (-10, 30), (-27, 30), (-27, 23), (-26, 23))
        link("metal_plate", ("F", (1, 0), (1, 0)), "IN_N0",
             (-23, 23), (-23, 19), (-10, 19), (-10, 21))
        return entities, routes

    entities.update({
        "F": (-24, 4, 2, 3), "K": (-28, 10, 2, 2), "C": (-24, 12, 2, 2),
        "E": (-2, 24, 3, 2), "G": (1, 20, 2, 2),
        "F2": (-15, 13, 2, 3), "A": (-12, 13, 3, 2), "T": (-9, 13, 2, 2),
        "Sq": (-18, 13, 1, 1), "Sp": (-11, 10, 1, 1),
    })
    link("crystal", "OUT_W0", ("R", (0, 2), (-1, 0)),
         (-12, 23), (-12, 21), (-20, 21), (-20, 26), (-19, 26))
    link("iron_ore", ("I", (1, 1), (1, 0)), ("F", (0, 0), (-1, 0)),
         (-26, -11), (-26, 4), (-25, 4))
    link("metal_plate", ("F", (1, 0), (1, 0)), ("Sp", (0, 0), (0, -1)),
         (-22, 4), (-11, 4), (-11, 9))
    link("metal_plate", ("Sp", (0, 0), (1, 0)), "IN_N2",
         (-10, 10), (-7, 10), (-7, 17), (-8, 17), (-8, 21))
    link("metal_plate", ("Sp", (0, 0), (0, 1)), ("A", (1, 0), (0, -1)), (-11, 11), (-11, 12))
    link("crystal", ("Q", (1, 1), (1, 0)), ("Sq", (0, 0), (0, -1)), (-18, 12))
    link("crystal", ("Sq", (0, 0), (0, 1)), "IN_N1",
         (-18, 14), (-18, 18), (-9, 18), (-9, 21))
    link("crystal", ("Sq", (0, 0), (1, 0)), ("F2", (0, 0), (-1, 0)), (-17, 13), (-16, 13))
    link("porous_carrier", ("F2", (1, 0), (1, 0)), ("A", (0, 0), (-1, 0)), (-13, 13))
    link("construction_pack", ("A", (2, 1), (1, 0)), ("T", (0, 1), (-1, 0)))
    link("carbon_ore", ("K", (1, 1), (1, 0)), ("C", (0, 1), (-1, 0)),
         (-26, 11), (-26, 13), (-25, 13))
    link("carbon_powder", ("C", (1, 1), (1, 0)), "IN_N0",
         (-22, 13), (-22, 19), (-10, 19), (-10, 21))
    link("catalyst", "OUT_N0", ("E", (1, 0), (0, -1)),
         (-7, 21), (-2, 21), (-2, 22), (-1, 22), (-1, 23))
    link("metal_plate", "OUT_E0", ("E", (0, 0), (-1, 0)), (-5, 26), (-5, 24), (-3, 24))
    link("carbon_powder", "OUT_S0", ("E", (0, 1), (-1, 0)),
         (-10, 28), (-4, 28), (-4, 25), (-3, 25))
    link("industrial_cell", ("E", (2, 1), (1, 0)), ("G", (0, 1), (-1, 0)),
         (1, 25), (3, 25), (3, 19), (-1, 19), (-1, 21), (0, 21))
    return entities, routes


def audit(name):
    entities, routes = build_layout(name)
    ports = ports_from_manifest()
    checks = 0

    def check(condition, label):
        nonlocal checks
        if not condition:
            raise ValueError(label)
        checks += 1

    def add(a, b):
        return a[0] + b[0], a[1] + b[1]

    def in_map(cell):
        x, z = cell
        return -32 <= x < 4 and -32 <= z < 32

    def endpoint(spec, role):
        if isinstance(spec, str):
            port_role, cell, normal = ports[spec]
            check(port_role == role, f"{spec} role")
            spec = ("core", cell, normal)
        device, cell, normal = spec
        x, z, width, depth = entities[device]
        check(0 <= cell[0] < width and 0 <= cell[1] < depth, f"{device} local port")
        edge = add(cell, normal)
        check(not (0 <= edge[0] < width and 0 <= edge[1] < depth), f"{device} outward port")
        return add((x, z), cell), normal

    counts = Counter((role, normal) for role, _, normal in ports.values())
    for normal in ((0, -1), (1, 0), (0, 1), (-1, 0)):
        check(counts["input", normal] == 3 and counts["output", normal] == 1, f"port distribution {normal}")
    check(len(ports) == len({cell for _, cell, _ in ports.values()}) == 16, "unique port cells")
    occupied = set()
    for key, (x, z, w, d) in entities.items():
        for i in range(x, x + w):
            for j in range(z, z + d):
                check(in_map((i, j)) and (i, j) not in occupied, f"footprint {key} {(i,j)}")
                occupied.add((i, j))

    belts = set()
    outputs = {}
    routing = []
    for item, source, target, points in routes:
        start, outgoing = endpoint(source, "output")
        end, incoming = endpoint(target, "input")
        cells = LEGACY["expand"](points) if points else []
        if cells:
            check(cells[0] == add(start, outgoing) and cells[-1] == add(end, incoming),
                  f"facing endpoints for {item} {source} to {target}")
        else:
            check(end == add(start, outgoing) and start == add(end, incoming),
                  f"direct handoff {source} to {target}")
        for cell in cells:
            check(in_map(cell) and cell not in occupied and cell not in belts, f"noncrossing belt {cell}")
            belts.add(cell)
        if isinstance(source, str):
            check(source not in outputs, f"one item per output {source}")
            outputs[source] = item
        routing.append({"item": item, "source": source, "target": target,
                        "points": points, "belts": len(cells)})

    center = {key: (x + w / 2, z + d / 2) for key, (x, z, w, d) in entities.items()}
    nodes = {k for k in center if k.startswith("J") or k in {"core", "G"}}
    reached = {"core"}
    while (adjacent := {k for k in nodes if any(dist(center[k], center[n]) <= 12 for n in reached)}) != reached:
        reached = adjacent
    check(reached == nodes, "linked grid, including unlit G in S1-P")
    consumers = {"I", "Q", "F", "R", "K", "C", "E", "F2", "A"} & entities.keys()
    distances = {k: min(dist(center[k], center[n]) for n in nodes) for k in sorted(consumers)}
    for key, distance in distances.items():
        check(distance <= 6, f"consumer range {key}")

    rect_distance = LEGACY["rect_distance"]

    def walkable(point):
        x, z = (n / 2 for n in point)
        return -31.7 <= x <= 3.7 and -31.7 <= z <= 31.7 and all(
            rect_distance((x, z), rect) > 0.3 for rect in entities.values())

    start = (-16, 40)
    check(walkable(start), "spawn clear")
    seen, queue = {start}, deque([start])
    while queue:
        x, z = queue.popleft()
        for p in ((x + 1, z), (x - 1, z), (x, z + 1), (x, z - 1)):
            if p not in seen and walkable(p):
                seen.add(p)
                queue.append(p)
    for key, rect in entities.items():
        check(any(rect_distance((x / 2, z / 2), rect) <= 2 for x, z in seen), f"approach {key}")
    check((5, 5) in seen, "unique sample is reachable")
    cap = LEGACY["SUPPLY"]["belt"]
    check(len(belts) <= cap, "within starter belt budget")
    return {"layout": name, "scope": "offline layout, no simulated material flow", "checks": checks,
            "entities": entities, "routes": routing, "core_output_items": outputs,
            "belts": len(belts), "belts_remaining": cap - len(belts), "power_distances": distances,
            "port_manifest_sha256": sha256(PORT_MANIFEST.read_bytes()).hexdigest(),
            "script_sha256": sha256(Path(__file__).read_bytes()).hexdigest()}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("layout", choices=("S0", "S1-P"))
    args = parser.parse_args()
    report = audit(args.layout)
    EVIDENCE.mkdir(parents=True, exist_ok=True)
    path = EVIDENCE / f"audit-{args.layout.lower()}.json"
    path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"{args.layout}: {report['checks']} checks, {report['belts']} belts, "
          f"{report['belts_remaining']} remaining; {path.relative_to(REPO)}")


if __name__ == "__main__":
    main()
