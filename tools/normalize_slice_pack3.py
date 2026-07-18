#!/usr/bin/env python3
"""Slice pack 3 batch driver (viewpoint correction round): normalize the
S4''/S4''-R/S4''-R2 high-oblique character walk sheets and swap them over the
old character sprites under client/assets/sprites/slice/.

Zero-dependency; builds on tools/normalize_pixel_asset.py.

Jobs (docs/features/slice-viewpoint-correction-v1.md, pack 3):
  side sheet  batch05 d1w  v2 -> engineer_walk_0..3.png        (luma baseline)
  up sheet    batch04 d1wu v1 -> engineer_walk_up_0..3.png     (gain-matched)
  down sheet  batch06 d1wd v2 -> engineer_walk_down_0..3.png   (gain-matched)
  static      derived from the down sheet frame STATIC_FRAME_INDEX
                              -> engineer.png
All 13 sprites share one pooled limited palette (no color jumps across
directions) and the 48x64 bottom-anchored frame box.
"""

from __future__ import annotations

import math
import os

import normalize_pixel_asset as npa

INTAKE = "assets/art-intake"
SPRITES_DIR = "client/assets/sprites/slice"
PREVIEW_DIR = os.path.join(INTAKE, "2026-07-18-pack3-preview")

TOL_EDGE = 10
TOL_HOLE = 6
MIN_HOLE = 400
SHEET_GAP = 40

SPRITE_COLORS = 32
SPRITE_SNAP_DIST = 24
FRAME_BOX = (48, 64)

SIDE_SHEET = "2026-07-18-batch05/d1w_walk_sheet_oblique_px_v2.png"
UP_SHEET = "2026-07-18-batch04/d1wu_walk_up_sheet_oblique_px_v1.png"
DOWN_SHEET = "2026-07-18-batch06/d1wd_walk_down_sheet_oblique_px_v2.png"

# Which down-sheet frame becomes the idle sprite (picked by preview review).
STATIC_FRAME_INDEX = 2


def load_masked(path: str) -> tuple[npa.Image, bytearray]:
    img = npa.load_png(path)
    bg = npa.estimate_background(img)
    mask = npa.build_background_mask(img, bg, TOL_EDGE, TOL_HOLE, MIN_HOLE)
    return img, mask


def scale_factor(content_h: int, target_h: int) -> int:
    return max(1, math.ceil(content_h / target_h))


def split_sheet(path: str, expected: int, target_h: int) -> list[npa.Image]:
    img, mask = load_masked(path)
    runs = npa.content_columns(mask, img.width, img.height, SHEET_GAP)
    if len(runs) != expected:
        raise ValueError(f"{path}: expected {expected} objects, found runs {runs}")
    bboxes = [
        npa.bbox_in_columns(mask, img.width, img.height, x0, x1) for x0, x1 in runs
    ]
    factor = scale_factor(max(b[3] - b[1] + 1 for b in bboxes), target_h)
    return [
        npa.crop_to_content(npa.downscale_sprite(img, mask, bbox, factor))
        for bbox in bboxes
    ]


def sheet_luma(frames: list[npa.Image]) -> float:
    pooled_data = bytearray()
    for frame in frames:
        pooled_data.extend(frame.data)
    pooled = npa.Image(1, len(pooled_data) // 4, pooled_data)
    return npa.mean_luma(pooled)


def save_sprite(img: npa.Image, name: str, records: list[str]) -> None:
    out_path = os.path.join(SPRITES_DIR, name)
    npa.save_png(out_path, img)
    npa.save_png(
        os.path.join(PREVIEW_DIR, name.replace(".png", "_x4.png")),
        npa.upscale_nearest(img, 4),
    )
    records.append(f"{out_path}: {img.width}x{img.height}")


def main() -> int:
    os.makedirs(PREVIEW_DIR, exist_ok=True)
    records: list[str] = []

    side = split_sheet(os.path.join(INTAKE, SIDE_SHEET), 4, FRAME_BOX[1])
    up = split_sheet(os.path.join(INTAKE, UP_SHEET), 4, FRAME_BOX[1])
    down = split_sheet(os.path.join(INTAKE, DOWN_SHEET), 4, FRAME_BOX[1])

    # The side sheet (the approved character reference) sets the luma
    # baseline; the other sheets get one sheet-wide gain each.
    baseline = sheet_luma(side)
    for name, frames in (("up", up), ("down", down)):
        gain = baseline / sheet_luma(frames)
        records.append(f"{name} sheet luma gain: {gain:.3f}")
        for frame in frames:
            npa.apply_gain(frame, gain)

    source_frame = down[STATIC_FRAME_INDEX]
    static = npa.Image(
        source_frame.width, source_frame.height, bytearray(source_frame.data)
    )
    records.append(f"static derived from down frame {STATIC_FRAME_INDEX}")

    group = side + up + down + [static]
    pooled: list[tuple[int, int, int]] = []
    for img in group:
        pooled.extend(npa.opaque_colors(img))
    palette = npa.median_cut(pooled, SPRITE_COLORS)
    palette = npa.snap_palette_to_anchors(palette, SPRITE_SNAP_DIST)
    for img in group:
        npa.apply_palette(img, palette)

    boxed = [npa.place_in_box(img, FRAME_BOX[0], FRAME_BOX[1]) for img in group]
    for i in range(4):
        save_sprite(boxed[i], f"engineer_walk_{i}.png", records)
    for i in range(4):
        save_sprite(boxed[4 + i], f"engineer_walk_up_{i}.png", records)
    for i in range(4):
        save_sprite(boxed[8 + i], f"engineer_walk_down_{i}.png", records)
    save_sprite(boxed[12], "engineer.png", records)

    print("\n".join(records))
    return 0


if __name__ == "__main__":
    import sys

    tool_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(os.path.join(tool_dir, ".."))
    sys.path.insert(0, tool_dir)
    sys.exit(main())
