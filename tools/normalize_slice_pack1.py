#!/usr/bin/env python3
"""Slice pack 1 batch driver: normalize the evidence-round finalized intake
assets into client/assets/ for Slice Base First Screen Integration V1.

Zero-dependency; builds on tools/normalize_pixel_asset.py. Inputs are the
git-ignored assets/art-intake/ batches, so this script only reruns on machines
that hold those source images.

Jobs (docs/features/slice-base-first-screen-integration-v1.md, pack 1):
  reactor    a0 basic reactor                  -> sprites/slice/reactor.png
  core       b1b2 dual-state sheet split       -> outpost_core_damaged/_repaired.png
  storage    b3 storage tanks                  -> sprites/slice/storage.png
  workbench  b4 workbench                      -> sprites/slice/workbench.png
  collector  b6 collector                      -> sprites/slice/collector.png
  character  d1 static + d1w walk sheet        -> engineer.png, engineer_walk_0..3.png
             (walk frames brightness-matched to the d1 baseline, shared palette)
  crystals   e1 cluster sheet split            -> crystal_cluster_small/medium/large.png
  grounds    c1/c2/c3/c4 128x128 macroblocks   -> tiles/slice/ground_*.png
  portrait   p1 v2 copied verbatim (no pixel normalization)
                                               -> portraits/protagonist_portraits.png

Every job also writes QA previews (x4 nearest upscale for sprites, x2 2x2
tiling for grounds) into the git-ignored preview directory for manual review.
"""

from __future__ import annotations

import argparse
import math
import os
import shutil
import sys

import normalize_pixel_asset as npa

INTAKE = "assets/art-intake"
SPRITES_DIR = "client/assets/sprites/slice"
TILES_DIR = "client/assets/tiles/slice"
PORTRAITS_DIR = "client/assets/portraits"
PREVIEW_DIR = os.path.join(INTAKE, "2026-07-15-pack1-preview")

# Background keying defaults validated on this pack (see W29 devlog).
TOL_EDGE = 10
TOL_HOLE = 6
MIN_HOLE = 400
SHEET_GAP = 40

SPRITE_COLORS = 32
SPRITE_SNAP_DIST = 24
# Grounds live inside one color family; a looser cap and tighter snap keep
# texture ramps (e.g. c4 pollution olive) from collapsing into the sand anchor.
TILE_COLORS = 32
TILE_SNAP_DIST = 12

FRAME_BOX = (48, 64)  # engineer static + walk frames share one animation box


def load_masked(path: str) -> tuple[npa.Image, bytearray]:
    img = npa.load_png(path)
    bg = npa.estimate_background(img)
    mask = npa.build_background_mask(img, bg, TOL_EDGE, TOL_HOLE, MIN_HOLE)
    return img, mask


def scale_factor(content_h: int, target_h: int) -> int:
    """Integer factor keeping the result at or under the class target size."""
    return max(1, math.ceil(content_h / target_h))


def quantize_group(
    images: list[npa.Image], max_colors: int, snap_dist: int = SPRITE_SNAP_DIST
) -> None:
    """One shared limited palette for related images (states / frames)."""
    pooled: list[tuple[int, int, int]] = []
    for img in images:
        pooled.extend(npa.opaque_colors(img))
    palette = npa.median_cut(pooled, max_colors)
    palette = npa.snap_palette_to_anchors(palette, snap_dist)
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


def job_single_sprites(records: list[str]) -> None:
    jobs = [
        ("2026-07-13-batch01/a0_reactor_px_v1.png", "reactor.png", 96),
        ("2026-07-14-batch01/b3_storage_px_v1.png", "storage.png", 96),
        ("2026-07-14-batch01/b4_workbench_px_v1.png", "workbench.png", 96),
        ("2026-07-14-batch03/b6_collector_px_v1.png", "collector.png", 96),
    ]
    for rel, name, target_h in jobs:
        img, mask = load_masked(os.path.join(INTAKE, rel))
        bbox = npa.content_bbox(mask, img.width, img.height)
        factor = scale_factor(bbox[3] - bbox[1] + 1, target_h)
        out = npa.crop_to_content(npa.downscale_sprite(img, mask, bbox, factor))
        quantize_group([out], SPRITE_COLORS)
        save_sprite(out, name, records)


def split_sheet(
    path: str, expected: int, target_h: int
) -> list[npa.Image]:
    """Split a horizontal near-black sheet into per-object sprites that share
    one integer scale factor, so relative object sizes survive."""
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


def job_core(records: list[str]) -> None:
    damaged, repaired = split_sheet(
        os.path.join(INTAKE, "2026-07-14-batch01/b1b2_core_states_px_v1.png"),
        expected=2,
        target_h=96,
    )
    quantize_group([damaged, repaired], SPRITE_COLORS)
    save_sprite(damaged, "outpost_core_damaged.png", records)
    save_sprite(repaired, "outpost_core_repaired.png", records)


def job_crystals(records: list[str]) -> None:
    clusters = split_sheet(
        os.path.join(INTAKE, "2026-07-14-batch03/e1_crystal_clusters_px_v1.png"),
        expected=3,
        target_h=48,
    )
    heights = [c.height for c in clusters]
    if heights != sorted(heights):
        raise ValueError(f"crystal clusters not ordered small->large: {heights}")
    quantize_group(clusters, SPRITE_COLORS)
    for cluster, name in zip(
        clusters,
        ["crystal_cluster_small.png", "crystal_cluster_medium.png", "crystal_cluster_large.png"],
    ):
        save_sprite(cluster, name, records)


def job_character(records: list[str]) -> None:
    img, mask = load_masked(
        os.path.join(INTAKE, "2026-07-14-batch02/d1_engineer_px_v1.png")
    )
    bbox = npa.content_bbox(mask, img.width, img.height)
    factor = scale_factor(bbox[3] - bbox[1] + 1, FRAME_BOX[1])
    static = npa.crop_to_content(npa.downscale_sprite(img, mask, bbox, factor))

    frames = split_sheet(
        os.path.join(INTAKE, "2026-07-14-batch02/d1w_walk_sheet_px_v1.png"),
        expected=4,
        target_h=FRAME_BOX[1],
    )

    # Walk sheet came out darker than the d1 static baseline (W29 review);
    # one sheet-wide gain keeps frame-to-frame brightness stable.
    pooled_data = bytearray()
    for frame in frames:
        pooled_data.extend(frame.data)
    pooled = npa.Image(1, len(pooled_data) // 4, pooled_data)
    static_luma = npa.mean_luma(static)
    sheet_luma = npa.mean_luma(pooled)
    gain = static_luma / sheet_luma
    records.append(
        f"walk sheet luma gain: {gain:.3f}"
        f" (static {static_luma:.1f}, sheet {sheet_luma:.1f})"
    )
    for frame in frames:
        npa.apply_gain(frame, gain)

    group = [static] + frames
    quantize_group(group, SPRITE_COLORS)
    boxed = [npa.place_in_box(m, FRAME_BOX[0], FRAME_BOX[1]) for m in group]
    save_sprite(boxed[0], "engineer.png", records)
    for i, frame in enumerate(boxed[1:]):
        save_sprite(frame, f"engineer_walk_{i}.png", records)


def job_grounds(records: list[str]) -> None:
    jobs = [
        ("2026-07-13-batch02/c1_rock_ground_px_v1.png", "ground_rock.png"),
        ("2026-07-13-batch02/c2_metal_platform_px_v1.png", "ground_metal_platform.png"),
        ("2026-07-13-batch02/c3_crystal_ground_px_v1.png", "ground_crystal.png"),
        ("2026-07-14-batch03/c4_polluted_ground_px_v1.png", "ground_polluted.png"),
    ]
    for rel, name in jobs:
        img = npa.load_png(os.path.join(INTAKE, rel))
        out = npa.downscale_tile(img, 128)
        quantize_group([out], TILE_COLORS, TILE_SNAP_DIST)
        out_path = os.path.join(TILES_DIR, name)
        npa.save_png(out_path, out, with_alpha=False)
        seam_x, seam_y = npa.tile_seam_ratios(out)
        npa.save_png(
            os.path.join(PREVIEW_DIR, name.replace(".png", "_tiled2x2_x2.png")),
            npa.upscale_nearest(npa.tile_preview(out, 2), 2),
        )
        records.append(
            f"{out_path}: {out.width}x{out.height} macroblock,"
            f" seam ratio x={seam_x:.2f} y={seam_y:.2f}"
        )
        for line in npa.color_report(out, 4):
            records.append("  " + line)


def job_portrait(records: list[str]) -> None:
    src = os.path.join(INTAKE, "2026-07-14-batch04/p1_protagonist_portraits_v2.png")
    dst = os.path.join(PORTRAITS_DIR, "protagonist_portraits.png")
    shutil.copyfile(src, dst)
    records.append(f"{dst}: verbatim copy of p1_protagonist_portraits_v2.png")


def job_character_directions(records: list[str]) -> None:
    """Pack 3.5 directional walk sheets (S7). New frames are forced onto the
    palette of the already-shipped engineer set so directions never color-pop,
    and brightness-matched to the same d1 baseline."""
    shipped = [npa.load_png(os.path.join(SPRITES_DIR, "engineer.png"))] + [
        npa.load_png(os.path.join(SPRITES_DIR, f"engineer_walk_{i}.png"))
        for i in range(4)
    ]
    palette = sorted(set(sum((npa.opaque_colors(img) for img in shipped), [])))
    baseline_luma = npa.mean_luma(shipped[0])

    jobs = [
        ("2026-07-16-batch01/d1wu_walk_up_sheet_px_v1.png", "engineer_walk_up"),
        ("2026-07-16-batch01/d1wd_walk_down_sheet_px_v1.png", "engineer_walk_down"),
    ]
    for rel, prefix in jobs:
        frames = split_sheet(
            os.path.join(INTAKE, rel), expected=4, target_h=FRAME_BOX[1]
        )
        pooled_data = bytearray()
        for frame in frames:
            pooled_data.extend(frame.data)
        pooled = npa.Image(1, len(pooled_data) // 4, pooled_data)
        gain = baseline_luma / npa.mean_luma(pooled)
        records.append(f"{prefix} luma gain: {gain:.3f}")
        for frame in frames:
            npa.apply_gain(frame, gain)
            npa.apply_palette(frame, palette)
        for i, frame in enumerate(frames):
            boxed = npa.place_in_box(frame, FRAME_BOX[0], FRAME_BOX[1])
            save_sprite(boxed, f"{prefix}_{i}.png", records)


JOBS = {
    "devices": job_single_sprites,
    "core": job_core,
    "crystals": job_crystals,
    "character": job_character,
    "character_directions": job_character_directions,
    "grounds": job_grounds,
    "portrait": job_portrait,
}


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--only",
        choices=sorted(JOBS),
        action="append",
        help="run a subset of jobs (repeatable); default: all",
    )
    args = parser.parse_args(argv)
    selected = args.only or list(JOBS)

    for path in (SPRITES_DIR, TILES_DIR, PORTRAITS_DIR, PREVIEW_DIR):
        os.makedirs(path, exist_ok=True)

    records: list[str] = []
    for name in JOBS:
        if name not in selected:
            continue
        print(f"[{name}]", flush=True)
        JOBS[name](records)
    print("\n== summary ==")
    for line in records:
        print(line)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
