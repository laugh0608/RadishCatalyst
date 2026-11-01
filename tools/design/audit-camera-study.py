#!/usr/bin/env python3
"""Offline R1 design math and asset metadata; no Godot or asset writes."""
import hashlib
import json
from math import cos, sin, tan, radians
from pathlib import Path
import struct

ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / "tools/runtime-intake/design-references/2026-11-01-camera-study/design-audit.json"
# Left/top cell and footprint; this is a static review board, not a save fixture.
BOARD = {"core_reserved": (-3, -3, 6, 6), "collector": (-9, -2, 2, 2),
         "reactor": (5, -1, 3, 3), "storage": (1, 6, 2, 2),
         "generator": (7, 5, 2, 2), "junction": (2, 3, 1, 1)}
ASSETS = ["reactor.glb", "refinement/reactor.glb", "collector.glb", "storage.glb",
          "engineer.glb", "yard.glb", "power/power-junction.glb", "ore.glb",
          "energy/cell_generator.glb", "expansion/refinery.glb"] + [f"belt-{n}.glb" for n in [2, 4, 6, 8, 10, 12, 14]]
TARGET = (0.0, 0.25, 1.0)
PORTS = [(f"IN_N{i}", (i - 1.5, 0.31, -3), (0, -1)) for i in range(4)]
PORTS += [("IN_W0", (-3, 0.31, -1.5), (-1, 0)), ("IN_W1", (-3, 0.31, 1.5), (-1, 0))]
PORTS += [(f"OUT_E{i}", (3, 0.31, i - 1.5), (1, 0)) for i in range(4)]
PORTS += [("OUT_W0", (-3, 0.31, -0.5), (-1, 0)), ("OUT_W1", (-3, 0.31, 0.5), (-1, 0))]


def dot(a, b):
    return sum(x * y for x, y in zip(a, b))


def project(point, camera, aspect):
    pitch, yaw = radians(camera["pitch"]), radians(camera["yaw"])
    axis = (sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch))
    right = (cos(yaw), 0, -sin(yaw))
    up = (-sin(pitch) * sin(yaw), cos(pitch), -sin(pitch) * cos(yaw))
    delta = tuple(q - t for q, t in zip(point, TARGET))
    depth = camera["distance"] - dot(delta, axis)
    span = camera["span"] if camera["projection"] == "orthogonal" else 2 * depth * tan(radians(camera["vfov"]) / 2)
    return (2 * dot(delta, right) / (span * aspect), 2 * dot(delta, up) / span, depth)


def main():
    checks = []

    def check(condition, label):
        if not condition:
            raise ValueError(label)
        checks.append(label)

    occupied = set()
    for name, (x, z, w, d) in BOARD.items():
        cells = {(i, j) for i in range(x, x + w) for j in range(z, z + d)}
        check(not occupied.intersection(cells), "nonoverlapping board " + name)
        check(all(-12 <= i < 12 and -12 <= j < 12 for i, j in cells), "board bounds " + name)
        occupied |= cells
    belt_cells = {(x, -4) for x in range(-2, 2)} | {(-4, z) for z in range(-2, 2)} | {(3, z) for z in range(-2, 2)}
    check(len(belt_cells) == 12 and not belt_cells.intersection(occupied), "12 independent core neighbor belt cells")
    check(len({p for _, p, _ in PORTS}) == 12, "12 unique mouth anchors")
    # Continuous primitive centers fit the ring outside the 3.6x3.6 central body.
    check(all(max(abs(p[0]), abs(p[2])) == 3 for _, p, _ in PORTS), "all mouths on footprint boundary")
    cameras = []
    for name, projection, pitch, yaw, vfov in [
        ("C0", "orthogonal", 50, 25, None), ("C1", "orthogonal", 50, 0, None),
        ("C2", "perspective", 50, 0, 35), ("C3", "perspective", 50, 0, 25),
        ("C4", "perspective", 45, 0, 35)]:
        distance = 40.0 if vfov is None else 21 / (2 * tan(radians(vfov) / 2))
        camera = {"id": name, "projection": projection, "pitch": pitch, "yaw": yaw,
                  "span": 21.0, "vfov": vfov, "distance": distance,
                  "height_above_target": distance * sin(radians(pitch)), "samples": []}
        if vfov is not None:
            check(abs(2 * distance * tan(radians(vfov) / 2) - 21) < 1e-10, "target-plane scale match " + name)
        for width, height in [(1440, 650), (1100, 480)]:
            aspect = width / height
            # This tests framing, not visible surfaces or occlusion through a model.
            corners = [(x, y, z) for x in [-9, 9] for z in [-3, 8] for y in [0, 3.6]]
            points = [project(p, camera, aspect) for p in corners]
            check(all(0.1 < p[2] < 120 and abs(p[0]) < 1 and abs(p[1]) < 1 for p in points), f"board envelope in frustum {name} {width}x{height}")
            screen_ports = [project(p, camera, aspect) for _, p, _ in PORTS]
            min_spacing = min(((a[0] - b[0])**2 * (width / 2)**2 + (a[1] - b[1])**2 * (height / 2)**2)**0.5 for i, a in enumerate(screen_ports) for b in screen_ports[i+1:])
            camera["samples"].append({"viewport": [width, height], "min_mouth_center_spacing_px": min_spacing})
        cameras.append(camera)
    materials = {"core": [2048, 2048, 1024, 512], "reactor": [1024] * 3,
                 "shared_trim": [1024] * 3, "rock": [1024] * 3, "soil": [1024] * 3}
    texture_bytes = 0
    for sizes in materials.values():
        for size in sizes:
            n = size
            while n:
                texture_bytes += n * n * 4
                n //= 2
    asset_meta = []
    for name in ASSETS:
        path = ROOT / "client/assets/factory" / name
        raw = path.read_bytes()
        magic, version, length, chunk, kind = struct.unpack_from("<4sIIII", raw)
        check(magic == b"glTF" and version == 2 and length == len(raw) and kind == 0x4E4F534A, "GLB metadata " + name)
        data = json.loads(raw[20:20 + chunk])
        attrs = [primitive["attributes"] for mesh in data.get("meshes", []) for primitive in mesh["primitives"]]
        asset_meta.append({"path": path.relative_to(ROOT).as_posix(), "sha256": hashlib.sha256(raw).hexdigest(),
                           "primitive_count": len(attrs), "all_have_uv0": all("TEXCOORD_0" in a for a in attrs),
                           "all_have_tangents": all("TANGENT" in a for a in attrs),
                           "images": len(data.get("images", [])), "textures": len(data.get("textures", [])),
                           "nodes": [node.get("name", "") for node in data.get("nodes", [])]})
    report = {"kind": "offline-camera-and-asset-design-not-runtime", "script_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
              "checks": checks, "target": TARGET, "board": BOARD, "core_ports": PORTS, "cameras": cameras,
              "texture_sets_candidate": materials, "rgba8_with_full_mips_bytes": texture_bytes,
              "rgba8_with_full_mips_mib": texture_bytes / 1024**2, "assets": asset_meta,
              "limits": ["3D viewport examples are design dimensions, not native window measurements", "mouth center spacing does not prove labels or hidden surfaces are readable", "no Godot, runtime geometry, collision, shaders, image or performance result", "static board is not the full S1 logistics layout or an ordinary save"]}
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"checks": len(checks), "assets": len(asset_meta), "texture_mib": report["rgba8_with_full_mips_mib"],
                      "camera_distances": {c["id"]: round(c["distance"], 4) for c in cameras}, "output": str(OUTPUT)}, ensure_ascii=False))


if __name__ == "__main__":
    main()
