#!/usr/bin/env python3
"""Derive one belt-scale crystal cargo sprite from the approved crystal art.

L4 needs a single transported unit, not a miniaturized cluster. This driver
therefore hash-locks the approved small cluster, isolates its dominant central
shard with a fixed per-row mask, and keeps the source pixels byte-identical.
It also writes one nearest-neighbour QA sheet over all four approved conveyor
frames. Runtime code only loads the resulting static sprite.
"""

from __future__ import annotations

import hashlib
import os
import sys

import normalize_pixel_asset as npa


SOURCE = "client/assets/sprites/slice/crystal_cluster_small.png"
SOURCE_SHA256 = (
    "5949909384066d99dc2158c51cb6efcbb1e571d733b2892f6875167e7f3db718"
)
OUTPUT = "client/assets/sprites/slice/cargo_crystal.png"
PREVIEW = (
    "assets/art-intake/2026-07-25-l4a-preview/"
    "crystal_cargo_conveyor_contact_sheet.png"
)

SOURCE_SIZE = (21, 22)
CROP_ORIGIN = (7, 0)
OUTPUT_SIZE = (10, 12)

# Inclusive x bounds inside the 10x12 crop. The rows isolate the tall central
# shard and deliberately discard the lower side shards of the source cluster.
ROW_BOUNDS = (
    (4, 6),
    (2, 6),
    (1, 6),
    (1, 6),
    (1, 6),
    (1, 7),
    (0, 7),
    (0, 6),
    (0, 6),
    (0, 7),
    (1, 7),
    (1, 6),
)

CONVEYORS = (
    "client/assets/sprites/slice/conveyor_up.png",
    "client/assets/sprites/slice/conveyor_right.png",
    "client/assets/sprites/slice/conveyor_down.png",
    "client/assets/sprites/slice/conveyor_left.png",
)
FLOOR = "client/assets/tiles/slice/industrial_floor_terrain.png"

SHADOW = npa.STANDARD_PALETTE["shadow_deep"]
PANEL = (18, 25, 28)
GAP = 8
SCALE = 4


def load_source() -> npa.Image:
    with open(SOURCE, "rb") as handle:
        digest = hashlib.sha256(handle.read()).hexdigest()
    if digest != SOURCE_SHA256:
        raise ValueError(f"unexpected L4-A crystal source hash: {digest}")

    source = npa.load_png(SOURCE)
    if (source.width, source.height) != SOURCE_SIZE:
        raise ValueError(
            f"unexpected L4-A crystal source size: "
            f"{source.width}x{source.height}"
        )
    return source


def derive_cargo(source: npa.Image) -> npa.Image:
    cargo = npa.Image.blank(*OUTPUT_SIZE)
    origin_x, origin_y = CROP_ORIGIN
    for y, (left, right) in enumerate(ROW_BOUNDS):
        for x in range(left, right + 1):
            pixel = source.pixel(origin_x + x, origin_y + y)
            if pixel[3]:
                cargo.put(x, y, pixel)
    return cargo


def opaque_pixels(image: npa.Image) -> list[tuple[int, int, tuple[int, ...]]]:
    return [
        (x, y, image.pixel(x, y))
        for y in range(image.height)
        for x in range(image.width)
        if image.pixel(x, y)[3]
    ]


def validate_cargo(source: npa.Image, cargo: npa.Image) -> None:
    if (cargo.width, cargo.height) != OUTPUT_SIZE:
        raise ValueError(
            f"unexpected L4-A cargo size: {cargo.width}x{cargo.height}"
        )

    opaque = opaque_pixels(cargo)
    if not 55 <= len(opaque) <= 80:
        raise ValueError(f"unexpected L4-A opaque pixel count: {len(opaque)}")

    source_colors = {
        source.pixel(x, y)
        for y in range(source.height)
        for x in range(source.width)
        if source.pixel(x, y)[3]
    }
    cargo_colors = {pixel for _, _, pixel in opaque}
    if not cargo_colors.issubset(source_colors):
        raise ValueError("L4-A cargo contains pixels not present in source")
    if len(cargo_colors) < 8:
        raise ValueError("L4-A cargo lost too much crystal facet contrast")

    occupied_rows = {
        y for _, y, _pixel in opaque
    }
    if occupied_rows != set(range(OUTPUT_SIZE[1])):
        raise ValueError("L4-A cargo has an empty silhouette row")


def alpha_paste(dst: npa.Image, src: npa.Image, x0: int, y0: int) -> None:
    for y in range(src.height):
        for x in range(src.width):
            pixel = src.pixel(x, y)
            if pixel[3]:
                dst.put(x0 + x, y0 + y, pixel)


def crop(
    image: npa.Image,
    x0: int,
    y0: int,
    width: int,
    height: int,
) -> npa.Image:
    result = npa.Image.blank(width, height)
    for y in range(height):
        for x in range(width):
            result.put(x, y, image.pixel(x0 + x, y0 + y))
    return result


def fill(image: npa.Image, color: tuple[int, int, int]) -> None:
    for y in range(image.height):
        for x in range(image.width):
            image.put(x, y, (*color, 255))


def nearest_scale(image: npa.Image, factor: int) -> npa.Image:
    result = npa.Image.blank(image.width * factor, image.height * factor)
    for y in range(result.height):
        for x in range(result.width):
            result.put(x, y, image.pixel(x // factor, y // factor))
    return result


def conveyor_panel(
    floor_tile: npa.Image,
    conveyor: npa.Image,
    cargo: npa.Image,
) -> npa.Image:
    panel = npa.Image.blank(32, 32)
    alpha_paste(panel, floor_tile, 0, 0)
    alpha_paste(panel, conveyor, 0, 0)
    alpha_paste(
        panel,
        cargo,
        (panel.width - cargo.width) // 2,
        (panel.height - cargo.height) // 2,
    )
    return nearest_scale(panel, SCALE)


def build_preview(cargo: npa.Image) -> npa.Image:
    floor_atlas = npa.load_png(FLOOR)
    floor_tile = crop(floor_atlas, 0, 0, 32, 32)
    panels = [
        conveyor_panel(floor_tile, npa.load_png(path), cargo)
        for path in CONVEYORS
    ]

    cargo_panel = npa.Image.blank(32, 32)
    fill(cargo_panel, PANEL)
    alpha_paste(
        cargo_panel,
        cargo,
        (cargo_panel.width - cargo.width) // 2,
        (cargo_panel.height - cargo.height) // 2,
    )
    panels.insert(0, nearest_scale(cargo_panel, SCALE))

    width = len(panels) * panels[0].width + (len(panels) + 1) * GAP
    height = panels[0].height + GAP * 2
    preview = npa.Image.blank(width, height)
    fill(preview, SHADOW)
    for index, panel in enumerate(panels):
        alpha_paste(preview, panel, GAP + index * (panel.width + GAP), GAP)
    return preview


def main() -> None:
    os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    source = load_source()
    cargo = derive_cargo(source)
    validate_cargo(source, cargo)

    os.makedirs(os.path.dirname(OUTPUT), exist_ok=True)
    npa.save_png(OUTPUT, cargo)
    preview = build_preview(cargo)
    os.makedirs(os.path.dirname(PREVIEW), exist_ok=True)
    npa.save_png(PREVIEW, preview)

    with open(OUTPUT, "rb") as handle:
        output_hash = hashlib.sha256(handle.read()).hexdigest()
    print(
        "L4-A crystal cargo normalized:",
        f"{cargo.width}x{cargo.height}",
        f"opaque={len(opaque_pixels(cargo))}",
        f"sha256={output_hash}",
    )
    print(f"QA preview: {PREVIEW}")


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        raise SystemExit(1)
