#!/usr/bin/env python3
"""Normalize the reviewed L3-C conveyor V1 cardinal-direction sheet.

The source contains four independently rendered copies ordered up, right,
down, left. Runtime frames must keep their source scale and one-cell anchor
consistent, so this driver:

1. verifies the approved source hash, object runs, and bounds;
2. centers every object in the same 384x384 source window;
3. integer-downscales every window by the same factor into a 32x32 frame;
4. quantizes all four frames through one pooled limited palette;
5. validates pairwise bounds, direction colors, and frame distinctness;
6. writes runtime PNGs and an industrial-floor QA contact sheet.
"""

from __future__ import annotations

import hashlib
import os
import sys

import normalize_pixel_asset as npa


SOURCE = "assets/art-intake/2026-07-25-batch01/l3c_conveyor_cardinal_frames_v1.png"
SOURCE_SHA256 = "513dd1e13aef29aa5ed8e351de40b5698efa91e2875e5227e0e66380e7271b29"
OUTPUTS = {
    "up": "client/assets/sprites/slice/conveyor_up.png",
    "right": "client/assets/sprites/slice/conveyor_right.png",
    "down": "client/assets/sprites/slice/conveyor_down.png",
    "left": "client/assets/sprites/slice/conveyor_left.png",
}
FLOOR_SOURCE = "client/assets/tiles/slice/industrial_floor_terrain.png"
PREVIEW_DIR = "assets/art-intake/2026-07-25-batch01/l3c-normalization-preview"

SOURCE_SIZE = (2172, 724)
EXPECTED_RUNS = (
    (178, 501),
    (647, 1021),
    (1167, 1489),
    (1634, 2002),
)
EXPECTED_BBOXES = (
    (178, 176, 501, 520),
    (647, 203, 1021, 510),
    (1167, 178, 1489, 521),
    (1634, 205, 2002, 511),
)
DIRECTIONS = ("up", "right", "down", "left")

FRAME_SIZE = 32
SOURCE_BOX_SIZE = 384
DOWNSCALE_FACTOR = 12
PALETTE_COLORS = 24
PALETTE_SNAP_DISTANCE = 24
BODY_GAIN = 1.08

TOL_EDGE = 16
TOL_HOLE = 6
MIN_HOLE = 400
SHEET_GAP = 80
MIN_COVERAGE = 0.35

SHADOW = npa.STANDARD_PALETTE["shadow_deep"]
METAL_MID = npa.STANDARD_PALETTE["metal_mid"]
METAL_HIGHLIGHT = npa.STANDARD_PALETTE["metal_highlight"]
ENERGY_TEAL = npa.STANDARD_PALETTE["energy_teal"]
CRYSTAL_CYAN = npa.STANDARD_PALETTE["crystal_cyan"]
AMBER_LAMP = npa.STANDARD_PALETTE["amber_lamp"]
POLLUTION_OLIVE = npa.STANDARD_PALETTE["pollution_olive"]


def crop(
    img: npa.Image, bounds: tuple[int, int, int, int]
) -> npa.Image:
    x0, y0, x1, y1 = bounds
    out = npa.Image.blank(x1 - x0 + 1, y1 - y0 + 1)
    for y in range(out.height):
        src = ((y0 + y) * img.width + x0) * 4
        dst = y * out.width * 4
        out.data[dst : dst + out.width * 4] = img.data[
            src : src + out.width * 4
        ]
    return out


def alpha_paste(dst: npa.Image, src: npa.Image, x0: int, y0: int) -> None:
    if x0 < 0 or y0 < 0 or x0 + src.width > dst.width or y0 + src.height > dst.height:
        raise ValueError("alpha paste exceeds destination bounds")
    for y in range(src.height):
        for x in range(src.width):
            pixel = src.pixel(x, y)
            if pixel[3]:
                dst.put(x0 + x, y0 + y, pixel)


def fill(img: npa.Image, rgb: tuple[int, int, int]) -> None:
    rgba = (*rgb, 255)
    for y in range(img.height):
        for x in range(img.width):
            img.put(x, y, rgba)


def centered_source_box(
    bounds: tuple[int, int, int, int]
) -> tuple[int, int, int, int]:
    x0, y0, x1, y1 = bounds
    side_minus_one = SOURCE_BOX_SIZE - 1
    left = (x0 + x1 - side_minus_one) // 2
    top = (y0 + y1 - side_minus_one) // 2
    return (
        left,
        top,
        left + side_minus_one,
        top + side_minus_one,
    )


def load_frames() -> list[npa.Image]:
    with open(SOURCE, "rb") as handle:
        digest = hashlib.sha256(handle.read()).hexdigest()
    if digest != SOURCE_SHA256:
        raise ValueError(f"unexpected L3-C source hash: {digest}")

    source = npa.load_png(SOURCE)
    if (source.width, source.height) != SOURCE_SIZE:
        raise ValueError(
            f"unexpected L3-C source size: {source.width}x{source.height}"
        )

    background = npa.estimate_background(source)
    mask = npa.build_background_mask(
        source, background, TOL_EDGE, TOL_HOLE, MIN_HOLE
    )
    runs = tuple(npa.content_columns(mask, source.width, source.height, SHEET_GAP))
    if runs != EXPECTED_RUNS:
        raise ValueError(f"unexpected L3-C object runs: {runs}")

    bboxes = tuple(
        npa.bbox_in_columns(mask, source.width, source.height, x0, x1)
        for x0, x1 in runs
    )
    if bboxes != EXPECTED_BBOXES:
        raise ValueError(f"unexpected L3-C object bounds: {bboxes}")

    frames = []
    for bbox in bboxes:
        source_box = centered_source_box(bbox)
        left, top, right, bottom = source_box
        if left < 0 or top < 0 or right >= source.width or bottom >= source.height:
            raise ValueError(f"L3-C source window exceeds sheet: {source_box}")
        frame = npa.downscale_sprite(
            source,
            mask,
            source_box,
            DOWNSCALE_FACTOR,
            coverage=MIN_COVERAGE,
        )
        if (frame.width, frame.height) != (FRAME_SIZE, FRAME_SIZE):
            raise ValueError(
                f"unexpected L3-C normalized frame: {frame.width}x{frame.height}"
            )
        npa.apply_gain(frame, BODY_GAIN)
        frames.append(frame)
    return frames


def normalize_semantic_colors(frames: list[npa.Image]) -> None:
    """Lock generated lamp hues to the cross-asset semantic anchors."""
    for frame in frames:
        for y in range(frame.height):
            for x in range(frame.width):
                red, green, blue, alpha = frame.pixel(x, y)
                if not alpha:
                    continue
                if red >= 110 and red > green + 20 and green > blue + 20:
                    frame.put(x, y, (*AMBER_LAMP, 255))
                elif (
                    green >= 100
                    and blue >= 100
                    and min(green, blue) > red + 25
                ):
                    color = CRYSTAL_CYAN if max(green, blue) >= 205 else ENERGY_TEAL
                    frame.put(x, y, (*color, 255))


def quantize_shared(frames: list[npa.Image]) -> list[tuple[int, int, int]]:
    normalize_semantic_colors(frames)
    pooled: list[tuple[int, int, int]] = []
    for frame in frames:
        pooled.extend(npa.opaque_colors(frame))
    palette = npa.median_cut(pooled, PALETTE_COLORS)
    palette = npa.snap_palette_to_anchors(palette, PALETTE_SNAP_DISTANCE)
    palette = sorted(
        set(
            palette
            + [
                SHADOW,
                METAL_MID,
                METAL_HIGHLIGHT,
                ENERGY_TEAL,
                CRYSTAL_CYAN,
                AMBER_LAMP,
                POLLUTION_OLIVE,
            ]
        )
    )
    for frame in frames:
        npa.apply_palette(frame, palette)
    return palette


def alpha_bounds(img: npa.Image) -> tuple[int, int, int, int]:
    opaque = [
        (x, y)
        for y in range(img.height)
        for x in range(img.width)
        if img.pixel(x, y)[3]
    ]
    if not opaque:
        raise ValueError("normalized conveyor frame is empty")
    xs = [x for x, _ in opaque]
    ys = [y for _, y in opaque]
    return min(xs), min(ys), max(xs), max(ys)


def count_exact(img: npa.Image, rgb: tuple[int, int, int]) -> int:
    return sum(
        1
        for y in range(img.height)
        for x in range(img.width)
        if img.pixel(x, y) == (*rgb, 255)
    )


def frame_fingerprint(img: npa.Image) -> str:
    return hashlib.sha256(img.data).hexdigest()


def validate_frames(
    frames: list[npa.Image], palette: list[tuple[int, int, int]]
) -> tuple[tuple[int, int, int, int], ...]:
    if len(frames) != 4:
        raise ValueError(f"expected four conveyor frames, found {len(frames)}")
    if len(palette) > PALETTE_COLORS + 7:
        raise ValueError(f"shared L3-C palette unexpectedly large: {len(palette)}")

    bounds = tuple(alpha_bounds(frame) for frame in frames)
    sizes = tuple((x1 - x0 + 1, y1 - y0 + 1) for x0, y0, x1, y1 in bounds)
    for a, b in ((sizes[0], sizes[2]), (sizes[1], sizes[3])):
        if abs(a[0] - b[0]) > 1 or abs(a[1] - b[1]) > 1:
            raise ValueError(f"opposite conveyor bounds drift: {a} vs {b}")

    fingerprints = {frame_fingerprint(frame) for frame in frames}
    if len(fingerprints) != 4:
        raise ValueError("direction frames are not four distinct pixel states")

    cyan_counts = []
    for direction, frame in zip(DIRECTIONS, frames):
        amber = count_exact(frame, AMBER_LAMP)
        teal = count_exact(frame, ENERGY_TEAL) + count_exact(frame, CRYSTAL_CYAN)
        if amber < 3:
            raise ValueError(f"{direction} conveyor lost amber direction cue")
        cyan_counts.append(teal)
    if cyan_counts[0] < 1 or cyan_counts[2] < 1 or sum(cyan_counts) < 4:
        raise ValueError(
            "visible cyan family accents were lost: "
            f"{dict(zip(DIRECTIONS, cyan_counts))}"
        )
    return bounds


def repeated_floor(width: int, height: int) -> npa.Image:
    atlas = npa.load_png(FLOOR_SOURCE)
    if (atlas.width, atlas.height) != (128, 128):
        raise ValueError(
            f"unexpected industrial-floor atlas size: {atlas.width}x{atlas.height}"
        )
    tile = crop(atlas, (0, 0, 31, 31))
    floor = npa.Image.blank(width, height)
    for y in range(0, height, 32):
        for x in range(0, width, 32):
            alpha_paste(floor, tile, x, y)
    return floor


def write_preview(frames: list[npa.Image]) -> None:
    os.makedirs(PREVIEW_DIR, exist_ok=True)

    isolated = npa.Image.blank(152, 32)
    fill(isolated, SHADOW)
    for index, frame in enumerate(frames):
        alpha_paste(isolated, frame, index * 40, 0)
    isolated_x4 = npa.upscale_nearest(isolated, 4)

    floor = repeated_floor(384, 96)
    positions = ((32, 32), (128, 32), (224, 32), (320, 32))
    for frame, (x, y) in zip(frames, positions):
        alpha_paste(floor, frame, x, y)
    floor_x3 = npa.upscale_nearest(floor, 3)

    contact = npa.Image.blank(1152, 640)
    fill(contact, SHADOW)
    alpha_paste(contact, isolated_x4, 272, 8)
    alpha_paste(contact, floor_x3, 0, 352)
    npa.save_png(
        os.path.join(PREVIEW_DIR, "conveyor_cardinal_contact_sheet.png"),
        contact,
        with_alpha=False,
    )


def main() -> int:
    frames = load_frames()
    palette = quantize_shared(frames)
    bounds = validate_frames(frames, palette)

    os.makedirs(os.path.dirname(next(iter(OUTPUTS.values()))), exist_ok=True)
    for direction, frame in zip(DIRECTIONS, frames):
        npa.save_png(OUTPUTS[direction], frame)
    write_preview(frames)

    print(f"L3-C shared palette: {len(palette)} colors")
    for direction, frame, bounds_for_frame in zip(DIRECTIONS, frames, bounds):
        colors = len(set(npa.opaque_colors(frame)))
        luma = npa.mean_luma(frame)
        print(
            f"{OUTPUTS[direction]}: 32x32, {colors} colors, "
            f"luma {luma:.2f}, alpha bounds {bounds_for_frame}"
        )
    print(
        "QA preview: "
        f"{PREVIEW_DIR}/conveyor_cardinal_contact_sheet.png"
    )
    return 0


if __name__ == "__main__":
    tool_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(os.path.join(tool_dir, ".."))
    sys.path.insert(0, tool_dir)
    raise SystemExit(main())
