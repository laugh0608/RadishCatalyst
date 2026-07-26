#!/usr/bin/env python3
"""Normalize the reviewed L3-B power-relay V5 dual-state sheet.

The generated sheet contains two almost-identical poles, but runtime state
frames must not inherit small geometry drift from separately generated
objects. This driver therefore:

1. verifies the approved source hash and the two expected object runs;
2. integer-downscales the unpowered pole as the one canonical body;
3. bottom-centers that body in a 32x64 frame;
4. derives both runtime states from the same pixels;
5. replaces only the fault/status lamps and a restrained four-pixel pulse;
6. writes shared-palette assets and actual-size QA previews.
"""

from __future__ import annotations

import hashlib
import math
import os
import sys

import normalize_pixel_asset as npa


SOURCE = "assets/art-intake/2026-07-21-batch03/l3b_power_relay_states_v5.png"
SOURCE_SHA256 = "310357e5007feec940b077864230ae36cc632e71a5836c7690f2768e912c6ec0"
OUTPUT_UNPOWERED = "client/assets/sprites/slice/power_relay_unpowered.png"
OUTPUT_POWERED = "client/assets/sprites/slice/power_relay_powered.png"
FLOOR_SOURCE = "client/assets/tiles/slice/industrial_floor_terrain.png"
PREVIEW_DIR = (
    "assets/art-intake/2026-07-21-batch03/l3b-normalization-preview"
)

SOURCE_SIZE = (1536, 1024)
EXPECTED_RUNS = ((334, 625), (910, 1201))
EXPECTED_BBOXES = ((334, 114, 625, 902), (910, 114, 1201, 902))

FRAME_WIDTH = 32
FRAME_HEIGHT = 64
TARGET_HEIGHT = 64
PALETTE_COLORS = 28
PALETTE_SNAP_DISTANCE = 24
BODY_GAIN = 1.18

TOL_EDGE = 10
TOL_HOLE = 6
MIN_HOLE = 400
SHEET_GAP = 80

SHADOW = npa.STANDARD_PALETTE["shadow_deep"]
METAL_MID = npa.STANDARD_PALETTE["metal_mid"]
ENERGY_TEAL = npa.STANDARD_PALETTE["energy_teal"]
CRYSTAL_CYAN = npa.STANDARD_PALETTE["crystal_cyan"]
ALERT_RED = npa.STANDARD_PALETTE["alert_red"]

# Coordinates in the fixed 32x64 frame after the guarded V5 integer downscale.
# Both electrode windows are dark in the unpowered frame and cyan only when
# powered. Structural amber lamps below the crossarm and at the base are never
# touched, so they remain byte-identical across the two states.
ELECTRODE_WINDOW_PIXELS = ((8, 8), (9, 8), (23, 8), (24, 8))
FAULT_LAMP_REGION = (14, 33, 18, 38)  # x0, y0, x1, y1, exclusive
PULSE_PIXELS = ((14, 6), (15, 6), (16, 6), (17, 6))


def clone(img: npa.Image) -> npa.Image:
    return npa.Image(img.width, img.height, bytearray(img.data))


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


def load_canonical_body() -> tuple[npa.Image, int]:
    with open(SOURCE, "rb") as handle:
        digest = hashlib.sha256(handle.read()).hexdigest()
    if digest != SOURCE_SHA256:
        raise ValueError(f"unexpected L3-B source hash: {digest}")

    source = npa.load_png(SOURCE)
    if (source.width, source.height) != SOURCE_SIZE:
        raise ValueError(
            f"unexpected L3-B source size: {source.width}x{source.height}"
        )

    background = npa.estimate_background(source)
    mask = npa.build_background_mask(
        source, background, TOL_EDGE, TOL_HOLE, MIN_HOLE
    )
    runs = tuple(npa.content_columns(mask, source.width, source.height, SHEET_GAP))
    if runs != EXPECTED_RUNS:
        raise ValueError(f"unexpected L3-B object runs: {runs}")

    bboxes = tuple(
        npa.bbox_in_columns(mask, source.width, source.height, x0, x1)
        for x0, x1 in runs
    )
    if bboxes != EXPECTED_BBOXES:
        raise ValueError(f"unexpected L3-B object bounds: {bboxes}")

    content_height = max(y1 - y0 + 1 for _, y0, _, y1 in bboxes)
    factor = math.ceil(content_height / TARGET_HEIGHT)
    if factor != 13:
        raise ValueError(f"unexpected L3-B downscale factor: {factor}")

    canonical = npa.downscale_sprite(source, mask, bboxes[0], factor)
    canonical = npa.crop_to_content(canonical)
    if (canonical.width, canonical.height) != (22, 61):
        raise ValueError(
            f"unexpected L3-B normalized body: {canonical.width}x{canonical.height}"
        )
    return npa.place_in_box(canonical, FRAME_WIDTH, FRAME_HEIGHT), factor


def in_fault_region(x: int, y: int) -> bool:
    x0, y0, x1, y1 = FAULT_LAMP_REGION
    return x0 <= x < x1 and y0 <= y < y1


def is_fault_light(pixel: tuple[int, int, int, int]) -> bool:
    red, green, blue, alpha = pixel
    return (
        alpha > 0
        and red > 80
        and red > green + 18
        and red > blue + 5
    )


def state_lamp_pixels(img: npa.Image) -> tuple[tuple[int, int], ...]:
    pixels = []
    for y in range(img.height):
        for x in range(img.width):
            if in_fault_region(x, y) and is_fault_light(img.pixel(x, y)):
                pixels.append((x, y))
    if len(pixels) < 3:
        raise ValueError(f"fault lamp lost during normalization: {pixels}")
    return tuple(pixels)


def quantize_body(img: npa.Image) -> None:
    palette = npa.median_cut(npa.opaque_colors(img), PALETTE_COLORS)
    palette = npa.snap_palette_to_anchors(palette, PALETTE_SNAP_DISTANCE)
    palette = sorted(
        set(
            palette
            + [
                SHADOW,
                METAL_MID,
                ENERGY_TEAL,
                CRYSTAL_CYAN,
                ALERT_RED,
            ]
        )
    )
    npa.apply_palette(img, palette)


def build_states() -> tuple[npa.Image, npa.Image, tuple[tuple[int, int], ...]]:
    body, _ = load_canonical_body()
    lamp_pixels = state_lamp_pixels(body)

    # Remove the generated amber electrode glow before quantization. These
    # pixels are status emitters, not always-on structural work lights.
    for x, y in ELECTRODE_WINDOW_PIXELS:
        if not body.pixel(x, y)[3]:
            raise ValueError(f"electrode window unexpectedly transparent: {(x, y)}")
        body.put(x, y, (*SHADOW, 255))

    # The relay is far narrower than the 2x2/3x3 device family. A restrained
    # common gain keeps its one- and two-pixel shaft highlights readable on the
    # brighter industrial floor without changing state semantics.
    npa.apply_gain(body, BODY_GAIN)
    quantize_body(body)
    unpowered = clone(body)
    powered = clone(body)

    for x, y in lamp_pixels:
        unpowered.put(x, y, (*ALERT_RED, 255))
        powered.put(x, y, (*ENERGY_TEAL, 255))

    # A single bright center pixel keeps the powered lamp readable at 1x.
    powered.put(16, 35, (*CRYSTAL_CYAN, 255))

    for index, (x, y) in enumerate(ELECTRODE_WINDOW_PIXELS):
        color = CRYSTAL_CYAN if index in (1, 2) else ENERGY_TEAL
        powered.put(x, y, (*color, 255))

    for index, (x, y) in enumerate(PULSE_PIXELS):
        color = CRYSTAL_CYAN if index == 2 else ENERGY_TEAL
        powered.put(x, y, (*color, 255))

    return unpowered, powered, lamp_pixels


def count_exact(img: npa.Image, rgb: tuple[int, int, int]) -> int:
    return sum(
        1
        for y in range(img.height)
        for x in range(img.width)
        if img.pixel(x, y) == (*rgb, 255)
    )


def validate_states(
    unpowered: npa.Image,
    powered: npa.Image,
    lamp_pixels: tuple[tuple[int, int], ...],
) -> None:
    if (unpowered.width, unpowered.height) != (FRAME_WIDTH, FRAME_HEIGHT):
        raise ValueError("unpowered frame size drift")
    if (powered.width, powered.height) != (FRAME_WIDTH, FRAME_HEIGHT):
        raise ValueError("powered frame size drift")

    allowed_differences = set(ELECTRODE_WINDOW_PIXELS)
    allowed_differences.update(PULSE_PIXELS)
    allowed_differences.update(lamp_pixels)
    differences = {
        (x, y)
        for y in range(FRAME_HEIGHT)
        for x in range(FRAME_WIDTH)
        if unpowered.pixel(x, y) != powered.pixel(x, y)
    }
    if not differences <= allowed_differences:
        raise ValueError(
            "state frames differ outside controlled emitters: "
            f"{sorted(differences - allowed_differences)}"
        )
    if not set(PULSE_PIXELS) <= differences:
        raise ValueError("powered pulse pixels are missing")
    if count_exact(unpowered, ALERT_RED) < 3:
        raise ValueError("unpowered fault lamp is not readable")
    if count_exact(powered, ALERT_RED):
        raise ValueError("powered frame still contains alert-red pixels")
    if count_exact(powered, ENERGY_TEAL) + count_exact(powered, CRYSTAL_CYAN) < 10:
        raise ValueError("powered cyan emitters are not readable")


def repeated_floor(width: int, height: int) -> npa.Image:
    atlas = npa.load_png(FLOOR_SOURCE)
    if (atlas.width, atlas.height) != (128, 128):
        raise ValueError(f"unexpected industrial-floor atlas size: {atlas.width}x{atlas.height}")
    tile = crop(atlas, (0, 0, 31, 31))
    floor = npa.Image.blank(width, height)
    for y in range(0, height, 32):
        for x in range(0, width, 32):
            alpha_paste(floor, tile, x, y)
    return floor


def write_preview(unpowered: npa.Image, powered: npa.Image) -> None:
    os.makedirs(PREVIEW_DIR, exist_ok=True)

    isolated = npa.Image.blank(72, 64)
    fill(isolated, SHADOW)
    alpha_paste(isolated, unpowered, 0, 0)
    alpha_paste(isolated, powered, 40, 0)
    isolated_x4 = npa.upscale_nearest(isolated, 4)

    floor = repeated_floor(192, 96)
    alpha_paste(floor, unpowered, 32, 0)
    alpha_paste(floor, powered, 128, 0)
    floor_x3 = npa.upscale_nearest(floor, 3)

    contact = npa.Image.blank(576, 560)
    fill(contact, SHADOW)
    alpha_paste(contact, isolated_x4, 144, 8)
    alpha_paste(contact, floor_x3, 0, 272)
    npa.save_png(
        os.path.join(PREVIEW_DIR, "power_relay_states_contact_sheet.png"),
        contact,
        with_alpha=False,
    )


def main() -> int:
    unpowered, powered, lamp_pixels = build_states()
    validate_states(unpowered, powered, lamp_pixels)

    os.makedirs(os.path.dirname(OUTPUT_UNPOWERED), exist_ok=True)
    npa.save_png(OUTPUT_UNPOWERED, unpowered)
    npa.save_png(OUTPUT_POWERED, powered)
    write_preview(unpowered, powered)

    print(
        f"{OUTPUT_UNPOWERED}: {FRAME_WIDTH}x{FRAME_HEIGHT}, "
        f"{len(set(npa.opaque_colors(unpowered)))} colors"
    )
    print(
        f"{OUTPUT_POWERED}: {FRAME_WIDTH}x{FRAME_HEIGHT}, "
        f"{len(set(npa.opaque_colors(powered)))} colors"
    )
    print(f"controlled fault-lamp pixels: {lamp_pixels}")
    print(f"controlled pulse length: {len(PULSE_PIXELS)} px")
    print(f"QA preview: {PREVIEW_DIR}/power_relay_states_contact_sheet.png")
    return 0


if __name__ == "__main__":
    tool_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(os.path.join(tool_dir, ".."))
    sys.path.insert(0, tool_dir)
    raise SystemExit(main())
