#!/usr/bin/env python3
"""Slice pack 2 batch driver (viewpoint correction round): normalize the
S1''/S3'' high-oblique device sprites and swap them in-place over the old
3/4-elevation assets under client/assets/sprites/slice/.

Zero-dependency; builds on tools/normalize_pixel_asset.py. Inputs are the
git-ignored assets/art-intake/ batches.

Jobs (docs/features/slice-viewpoint-correction-v1.md, pack 2):
  reactor    a0 oblique anchor v2 (batch02)     -> reactor.png
  core       b1b2 oblique dual-state (batch03)  -> outpost_core_damaged/_repaired.png
  storage/workbench  b3b4 pair sheet (batch03)  -> storage.png / workbench.png
  collector  b6 oblique (batch03)               -> collector.png

QA previews (x4 nearest upscale) go to the git-ignored preview directory.
"""

from __future__ import annotations

import math
import os

import normalize_pixel_asset as npa

INTAKE = "assets/art-intake"
SPRITES_DIR = "client/assets/sprites/slice"
PREVIEW_DIR = os.path.join(INTAKE, "2026-07-18-pack2-preview")

TOL_EDGE = 10
TOL_HOLE = 6
MIN_HOLE = 400
SHEET_GAP = 40

SPRITE_COLORS = 32
SPRITE_SNAP_DIST = 24


def load_masked(path: str) -> tuple[npa.Image, bytearray]:
    img = npa.load_png(path)
    bg = npa.estimate_background(img)
    mask = npa.build_background_mask(img, bg, TOL_EDGE, TOL_HOLE, MIN_HOLE)
    return img, mask


def scale_factor(content_h: int, target_h: int) -> int:
    return max(1, math.ceil(content_h / target_h))


def quantize_group(images: list[npa.Image]) -> None:
    pooled: list[tuple[int, int, int]] = []
    for img in images:
        pooled.extend(npa.opaque_colors(img))
    palette = npa.median_cut(pooled, SPRITE_COLORS)
    palette = npa.snap_palette_to_anchors(palette, SPRITE_SNAP_DIST)
    for img in images:
        npa.apply_palette(img, palette)


def save_sprite(img: npa.Image, name: str, records: list[str]) -> None:
    out_path = os.path.join(SPRITES_DIR, name)
    npa.save_png(out_path, img)
    npa.save_png(
        os.path.join(PREVIEW_DIR, name.replace(".png", "_x4.png")),
        npa.upscale_nearest(img, 4),
    )
    records.append(f"{out_path}: {img.width}x{img.height}")
    for line in npa.color_report(img, 4):
        records.append("  " + line)


def normalize_single(rel: str, name: str, target_h: int, records: list[str]) -> None:
    img, mask = load_masked(os.path.join(INTAKE, rel))
    bbox = npa.content_bbox(mask, img.width, img.height)
    factor = scale_factor(bbox[3] - bbox[1] + 1, target_h)
    out = npa.crop_to_content(npa.downscale_sprite(img, mask, bbox, factor))
    quantize_group([out])
    save_sprite(out, name, records)


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


def main() -> int:
    os.makedirs(PREVIEW_DIR, exist_ok=True)
    records: list[str] = []

    normalize_single(
        "2026-07-18-batch02/a0_reactor_oblique_px_v2.png", "reactor.png", 96, records
    )

    damaged, repaired = split_sheet(
        os.path.join(INTAKE, "2026-07-18-batch03/b1b2_core_states_oblique_px_v1.png"),
        expected=2,
        target_h=96,
    )
    quantize_group([damaged, repaired])
    save_sprite(damaged, "outpost_core_damaged.png", records)
    save_sprite(repaired, "outpost_core_repaired.png", records)

    storage, workbench = split_sheet(
        os.path.join(
            INTAKE, "2026-07-18-batch03/b3b4_storage_workbench_oblique_px_v1.png"
        ),
        expected=2,
        target_h=96,
    )
    quantize_group([storage])
    quantize_group([workbench])
    save_sprite(storage, "storage.png", records)
    save_sprite(workbench, "workbench.png", records)

    normalize_single(
        "2026-07-18-batch03/b6_collector_oblique_px_v1.png", "collector.png", 96, records
    )

    print("\n".join(records))
    return 0


if __name__ == "__main__":
    os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
    import sys

    sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__))))
    sys.exit(main())
