#!/usr/bin/env python3
"""Normalize the reviewed L3-A industrial-floor V2 sheet.

The generated source is a 4x4 sheet with uneven gutters. This driver verifies
the approved source hash, crops every cell before downscaling, quantizes all 16
tiles through one shared palette, packs the final 128x128 atlas, and writes
multi-size platform previews for seam/corner/variant review.

The row contract comes from
docs/features/slice-building-placement-and-power-grid-v1.md:

  row 0: center + three center variants
  row 1: north / east / south / west edges
  row 2: northwest / northeast / southeast / southwest outer corners
  row 3: northwest / northeast / southeast / southwest inner notches
"""

from __future__ import annotations

import hashlib
import os
import sys

import normalize_pixel_asset as npa


SOURCE = "assets/art-intake/2026-07-21-batch01/l3a_industrial_floor_terrain_v2.png"
SOURCE_SHA256 = "f7463ba37612030fe17040aac9bde2a143d7605865c4b36b948c815b86eb36ea"
OUTPUT = "client/assets/tiles/slice/industrial_floor_terrain.png"
ROCK_SOURCE = "client/assets/tiles/slice/ground_rock.png"
PREVIEW_DIR = "assets/art-intake/2026-07-21-batch01/l3a-normalization-preview"

TILE_SIZE = 32
PALETTE_COLORS = 24
PALETTE_SNAP_DISTANCE = 24

# Inclusive source-cell bounds, derived from the full-height/full-width gutter
# runs in the approved 1254x1254 V2 source. Uneven source cells are normalized
# independently so no dark separator pixels leak into adjacent gameplay tiles.
X_RANGES = ((26, 290), (338, 606), (650, 917), (961, 1221))
Y_RANGES = ((26, 282), (334, 597), (645, 907), (955, 1217))


def crop(img: npa.Image, bounds: tuple[int, int, int, int]) -> npa.Image:
    x0, y0, x1, y1 = bounds
    out = npa.Image.blank(x1 - x0 + 1, y1 - y0 + 1)
    for y in range(out.height):
        src = ((y0 + y) * img.width + x0) * 4
        dst = y * out.width * 4
        out.data[dst : dst + out.width * 4] = img.data[
            src : src + out.width * 4
        ]
    return out


def paste(dst: npa.Image, src: npa.Image, x0: int, y0: int) -> None:
    if x0 < 0 or y0 < 0 or x0 + src.width > dst.width or y0 + src.height > dst.height:
        raise ValueError("paste exceeds destination bounds")
    for y in range(src.height):
        src_start = y * src.width * 4
        dst_start = ((y0 + y) * dst.width + x0) * 4
        dst.data[dst_start : dst_start + src.width * 4] = src.data[
            src_start : src_start + src.width * 4
        ]


def load_tiles() -> list[npa.Image]:
    with open(SOURCE, "rb") as handle:
        digest = hashlib.sha256(handle.read()).hexdigest()
    if digest != SOURCE_SHA256:
        raise ValueError(f"unexpected L3-A source hash: {digest}")

    source = npa.load_png(SOURCE)
    if (source.width, source.height) != (1254, 1254):
        raise ValueError(
            f"unexpected L3-A source size: {source.width}x{source.height}"
        )

    tiles = []
    for y0, y1 in Y_RANGES:
        for x0, x1 in X_RANGES:
            cell = crop(source, (x0, y0, x1, y1))
            tiles.append(npa.downscale_tile(cell, TILE_SIZE))

    pooled: list[tuple[int, int, int]] = []
    for tile in tiles:
        pooled.extend(npa.opaque_colors(tile))
    palette = npa.median_cut(pooled, PALETTE_COLORS)
    palette = npa.snap_palette_to_anchors(palette, PALETTE_SNAP_DISTANCE)
    for tile in tiles:
        npa.apply_palette(tile, palette)
    return tiles


def pack_atlas(tiles: list[npa.Image]) -> npa.Image:
    atlas = npa.Image.blank(TILE_SIZE * 4, TILE_SIZE * 4)
    for index, tile in enumerate(tiles):
        paste(atlas, tile, index % 4 * TILE_SIZE, index // 4 * TILE_SIZE)
    return atlas


def rock_tile(rock: npa.Image, x: int, y: int) -> npa.Image:
    return crop(
        rock,
        (
            x % 4 * TILE_SIZE,
            y % 4 * TILE_SIZE,
            x % 4 * TILE_SIZE + TILE_SIZE - 1,
            y % 4 * TILE_SIZE + TILE_SIZE - 1,
        ),
    )


def platform_role(
    x: int,
    y: int,
    width: int,
    height: int,
    hole: tuple[int, int, int, int] | None,
) -> tuple[int, int] | None:
    if hole is not None:
        hx0, hy0, hx1, hy1 = hole
        if hx0 <= x < hx1 and hy0 <= y < hy1:
            return None

        # Inner-corner cells are diagonally adjacent to the rock opening.
        if (x + 1, y + 1) == (hx0, hy0):
            return (2, 3)  # southeast notch
        if (x - 1, y + 1) == (hx1 - 1, hy0):
            return (3, 3)  # southwest notch
        if (x - 1, y - 1) == (hx1 - 1, hy1 - 1):
            return (0, 3)  # northwest notch
        if (x + 1, y - 1) == (hx0, hy1 - 1):
            return (1, 3)  # northeast notch

        if hy0 <= y < hy1 and x == hx0 - 1:
            return (1, 1)  # east edge faces the opening
        if hy0 <= y < hy1 and x == hx1:
            return (3, 1)  # west edge faces the opening
        if hx0 <= x < hx1 and y == hy0 - 1:
            return (2, 1)  # south edge faces the opening
        if hx0 <= x < hx1 and y == hy1:
            return (0, 1)  # north edge faces the opening

    if x == 0 and y == 0:
        return (0, 2)
    if x == width - 1 and y == 0:
        return (1, 2)
    if x == width - 1 and y == height - 1:
        return (2, 2)
    if x == 0 and y == height - 1:
        return (3, 2)
    if y == 0:
        return (0, 1)
    if x == width - 1:
        return (1, 1)
    if y == height - 1:
        return (2, 1)
    if x == 0:
        return (3, 1)
    return ((x * 3 + y * 5) % 4, 0)


def compose_platform(
    tiles: list[npa.Image],
    rock: npa.Image,
    width: int,
    height: int,
    hole: tuple[int, int, int, int] | None = None,
) -> npa.Image:
    canvas = npa.Image.blank((width + 2) * TILE_SIZE, (height + 2) * TILE_SIZE)
    for y in range(height + 2):
        for x in range(width + 2):
            paste(canvas, rock_tile(rock, x, y), x * TILE_SIZE, y * TILE_SIZE)

    for y in range(height):
        for x in range(width):
            role = platform_role(x, y, width, height, hole)
            if role is None:
                continue
            tx, ty = role
            paste(
                canvas,
                tiles[ty * 4 + tx],
                (x + 1) * TILE_SIZE,
                (y + 1) * TILE_SIZE,
            )
    return canvas


def edge_difference(a: npa.Image, b: npa.Image, horizontal: bool) -> float:
    total = 0
    samples = TILE_SIZE
    for i in range(samples):
        if horizontal:
            pa = a.pixel(TILE_SIZE - 1, i)
            pb = b.pixel(0, i)
        else:
            pa = a.pixel(i, TILE_SIZE - 1)
            pb = b.pixel(i, 0)
        total += sum(abs(pa[channel] - pb[channel]) for channel in range(3))
    return total / (samples * 3)


def write_outputs(tiles: list[npa.Image]) -> None:
    os.makedirs(os.path.dirname(OUTPUT), exist_ok=True)
    os.makedirs(PREVIEW_DIR, exist_ok=True)

    atlas = pack_atlas(tiles)
    npa.save_png(OUTPUT, atlas, with_alpha=False)
    npa.save_png(
        os.path.join(PREVIEW_DIR, "industrial_floor_atlas_x4.png"),
        npa.upscale_nearest(atlas, 4),
        with_alpha=False,
    )

    rock = npa.load_png(ROCK_SOURCE)
    if (rock.width, rock.height) != (128, 128):
        raise ValueError(f"unexpected rock macroblock size: {rock.width}x{rock.height}")
    previews = (
        ("platform_3x3_x4.png", compose_platform(tiles, rock, 3, 3), 4),
        ("platform_6x4_x3.png", compose_platform(tiles, rock, 6, 4), 3),
        (
            "platform_10x6_hole_x2.png",
            compose_platform(tiles, rock, 10, 6, hole=(4, 2, 6, 4)),
            2,
        ),
    )
    for name, preview, scale in previews:
        npa.save_png(
            os.path.join(PREVIEW_DIR, name),
            npa.upscale_nearest(preview, scale),
            with_alpha=False,
        )


def main() -> int:
    tiles = load_tiles()
    fingerprints = {hashlib.sha256(bytes(tile.data)).hexdigest() for tile in tiles}
    if len(fingerprints) != 16:
        raise ValueError(f"expected 16 distinct normalized tiles, found {len(fingerprints)}")

    write_outputs(tiles)

    palette = sorted(set(npa.opaque_colors(pack_atlas(tiles))))
    center_h = max(
        edge_difference(left, right, True)
        for left in tiles[:4]
        for right in tiles[:4]
    )
    center_v = max(
        edge_difference(top, bottom, False)
        for top in tiles[:4]
        for bottom in tiles[:4]
    )
    print(f"{OUTPUT}: 128x128, 16 distinct tiles, {len(palette)} colors")
    print(
        "center-variant worst edge mean RGB difference: "
        f"horizontal={center_h:.2f}, vertical={center_v:.2f}"
    )
    print(f"QA previews: {PREVIEW_DIR}")
    return 0


if __name__ == "__main__":
    tool_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(os.path.join(tool_dir, ".."))
    sys.path.insert(0, tool_dir)
    raise SystemExit(main())
