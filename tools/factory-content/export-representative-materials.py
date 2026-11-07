#!/usr/bin/env python3
"""Bake periodic R1-C material tiles from project-authored patterns."""
import argparse
import hashlib
import json
import math
from pathlib import Path
import random
import struct
import zlib

REPO = Path(__file__).resolve().parents[2]
ASSETS = REPO / "client/assets/prototypes/factory_material_study"
SIZE = 256


def periodic_field(cells, seed):
    rng = random.Random(seed)
    grid = [[rng.random() for _ in range(cells)] for _ in range(cells)]

    def sample(x, y):
        u, v = x * cells, y * cells
        i, j = math.floor(u), math.floor(v)
        a, b = u - i, v - j
        a, b = a * a * (3 - 2 * a), b * b * (3 - 2 * b)
        top = grid[j % cells]
        bottom = grid[(j + 1) % cells]
        left, right = i % cells, (i + 1) % cells
        return (1 - b) * ((1 - a) * top[left] + a * top[right]) + b * (
            (1 - a) * bottom[left] + a * bottom[right]
        )
    return sample


def channel(value):
    return min(255, max(0, round(value)))


def write_png(path, pixels):
    def chunk(kind, data):
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data))

    rows = bytearray()
    for j in range(SIZE):
        rows.append(0)
        for i in range(SIZE):
            rows.extend(map(channel, pixels((i + 0.5) / SIZE, (j + 0.5) / SIZE)))
    header = struct.pack(">IIBBBBB", SIZE, SIZE, 8, 2, 0, 0, 0)
    path.write_bytes(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", header) +
                     chunk(b"IDAT", zlib.compress(rows, level=9)) + chunk(b"IEND", b""))


def build_tiles(root):
    broad = periodic_field(5, 118)
    mid = periodic_field(14, 127)
    grit = periodic_field(63, 131)
    streak = periodic_field(20, 139)

    def enamel(x, y):
        # Modest coating mottling and rolled microtexture, with no baked light direction.
        shade = 237 + 14 * (broad(x, y) - 0.5) + 11 * (grit(x, y) - 0.5)
        return shade, shade, shade

    def trim(x, y):
        grain = streak(x, 0.12 + 0.018 * math.sin(y * math.tau))
        shade = 224 + 23 * (grain - 0.5) + 14 * (mid(x, y) - 0.5)
        return shade - 2, shade, shade + 3

    def rock_height(x, y):
        return 0.57 * broad(x, y) + 0.28 * mid(x, y) + 0.15 * grit(x, y)

    def rock(x, y):
        height = rock_height(x, y) - 0.5
        dust = mid(x, y) - 0.5
        return 139 + 48 * height + 9 * dust, 138 + 43 * height, 117 + 38 * height - 5 * dust

    def work_surface(x, y):
        height = 0.55 * (mid(x, y) - 0.5) + 0.45 * (grit(x, y) - 0.5)
        return 147 + 31 * height, 151 + 29 * height, 137 + 27 * height

    def rock_normal(x, y):
        step = 1 / SIZE
        dx = 4 * (rock_height(x - step, y) - rock_height(x + step, y))
        dy = 4 * (rock_height(x, y + step) - rock_height(x, y - step))
        length = math.sqrt(1 + dx * dx + dy * dy)
        return 127.5 * (1 + dx / length), 127.5 * (1 + dy / length), 127.5 * (1 + 1 / length)

    for name, pixels, role in [
        ("enamel", enamel, "sRGB modulation for core and reactor coatings"),
        ("trim", trim, "sRGB modulation for shared metal and trim"),
        ("rock", rock, "sRGB mineral ground"),
        ("work-surface", work_surface, "sRGB compacted working ground"),
        ("rock-normal", rock_normal, "linear OpenGL +Y normal for mineral ground"),
    ]:
        path = root / f"{name}.png"
        write_png(path, pixels)
        yield path, role


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("batch")
    parser.add_argument("--copy-to-study", action="store_true")
    args = parser.parse_args()
    if not args.batch or not all(c in "abcdefghijklmnopqrstuvwxyz0123456789-" for c in args.batch):
        parser.error("batch must use lowercase ASCII, digits or hyphens")
    root = REPO / "assets/art-intake/2026-11-07-factory-representative-assets" / args.batch
    root.mkdir(parents=True, exist_ok=False)
    files = {path.name: {"sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
                         "size": [SIZE, SIZE], "role": role}
             for path, role in build_tiles(root)}
    script = Path(__file__).resolve()
    manifest = {
        "scope": "R1-C isolated material study",
        "source": str(script.relative_to(REPO)),
        "source_sha256": hashlib.sha256(script.read_bytes()).hexdigest(),
        "license": "Project-authored periodic maps",
        "batch": args.batch,
        "projection": "Triplanar with mipmaps; no exclusive UV bake",
        "files": files,
    }
    (root / script.name).write_bytes(script.read_bytes())
    (root / "source-manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    if args.copy_to_study:
        ASSETS.mkdir(parents=True, exist_ok=True)
        for filename in (*files, "source-manifest.json"):
            (ASSETS / filename).write_bytes((root / filename).read_bytes())
    print(f"{len(files)} periodic {SIZE}² maps in {root.relative_to(REPO)}")


if __name__ == "__main__":
    main()
