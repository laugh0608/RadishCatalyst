#!/usr/bin/env python3
"""Derive L3-E storage cardinal-hatch frames from one immutable runtime body.

The two generated L3-E candidates preserved the hatch idea but both replaced
the approved four-silo body with a three-silo redesign. This offline driver
therefore keeps the reviewed runtime raster and changes only one compact
physical hatch region:

1. verifies the approved 87x88 storage hash;
2. clones that exact raster four times;
3. replaces one controlled edge region with a bidirectional hatch;
4. validates that every pixel outside that region remains byte-identical;
5. writes four static runtime sprites and an industrial-floor QA sheet.

Runtime code does not draw or rotate the storage body or its hatch.
"""

from __future__ import annotations

import hashlib
import os
import sys

import normalize_pixel_asset as npa


SOURCE = "client/assets/sprites/slice/storage.png"
SOURCE_SHA256 = (
    "4a07cd86892dd8ab2f93794c45ff9fe760d91b4101bfcddb0f8df59f3ad56ea0"
)
OUTPUTS = {
    "up": "client/assets/sprites/slice/storage_up.png",
    "right": "client/assets/sprites/slice/storage_right.png",
    "down": "client/assets/sprites/slice/storage_down.png",
    "left": "client/assets/sprites/slice/storage_left.png",
}
FLOOR_SOURCE = "client/assets/tiles/slice/industrial_floor_terrain.png"
PREVIEW_DIR = (
    "assets/art-intake/2026-07-25-batch03/l3e-deterministic-preview"
)

SOURCE_SIZE = (87, 88)
DIRECTIONS = ("up", "right", "down", "left")

# Inclusive edge bounds. Each module overlaps only an outer structural
# attachment area and remains clear of the four approved cylindrical tanks.
HATCH_REGIONS = {
    "up": (55, 0, 66, 7),
    "right": (79, 48, 86, 59),
    "down": (20, 80, 31, 87),
    "left": (0, 50, 7, 61),
}

SHADOW = npa.STANDARD_PALETTE["shadow_deep"]
METAL_MID = npa.STANDARD_PALETTE["metal_mid"]
METAL_HIGHLIGHT = npa.STANDARD_PALETTE["metal_highlight"]
CRYSTAL_CYAN = npa.STANDARD_PALETTE["crystal_cyan"]
AMBER_LAMP = npa.STANDARD_PALETTE["amber_lamp"]
DARK_TEAL = (28, 77, 81)


def clone(img: npa.Image) -> npa.Image:
    return npa.Image(img.width, img.height, bytearray(img.data))


def fill_rect(
    img: npa.Image,
    bounds: tuple[int, int, int, int],
    color: tuple[int, int, int],
) -> None:
    x0, y0, x1, y1 = bounds
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            img.put(x, y, (*color, 255))


def inset(
    bounds: tuple[int, int, int, int], amount: int
) -> tuple[int, int, int, int]:
    x0, y0, x1, y1 = bounds
    result = (x0 + amount, y0 + amount, x1 - amount, y1 - amount)
    if result[0] > result[2] or result[1] > result[3]:
        raise ValueError(f"cannot inset hatch region {bounds} by {amount}")
    return result


def draw_highlight(
    img: npa.Image, bounds: tuple[int, int, int, int]
) -> None:
    x0, y0, x1, y1 = bounds
    for x in range(x0, x1 + 1):
        img.put(x, y0, (*METAL_HIGHLIGHT, 255))
    for y in range(y0, y1 + 1):
        img.put(x0, y, (*METAL_HIGHLIGHT, 255))


def notch_pixels(
    direction: str, bounds: tuple[int, int, int, int]
) -> tuple[tuple[int, int], tuple[int, int]]:
    x0, y0, x1, y1 = bounds
    center_x = (x0 + x1) // 2
    center_y = (y0 + y1) // 2
    if direction == "up":
        return ((center_x, y0), (center_x + 1, y0))
    if direction == "right":
        return ((x1, center_y), (x1, center_y + 1))
    if direction == "down":
        return ((center_x, y1), (center_x + 1, y1))
    if direction == "left":
        return ((x0, center_y), (x0, center_y + 1))
    raise ValueError(f"unknown hatch direction: {direction}")


def latch_pixels(
    direction: str, bounds: tuple[int, int, int, int]
) -> tuple[tuple[int, int], tuple[int, int]]:
    x0, y0, x1, y1 = bounds
    center_x = (x0 + x1) // 2
    center_y = (y0 + y1) // 2
    if direction in ("up", "down"):
        return ((center_x, center_y), (center_x + 1, center_y))
    return ((center_x, center_y), (center_x, center_y + 1))


def draw_hatch(img: npa.Image, direction: str) -> None:
    bounds = HATCH_REGIONS[direction]
    inner = inset(bounds, 1)
    recess = inset(bounds, 2)

    fill_rect(img, bounds, SHADOW)
    fill_rect(img, inner, METAL_MID)
    draw_highlight(img, inner)
    fill_rect(img, recess, DARK_TEAL)

    for x, y in notch_pixels(direction, recess):
        img.put(x, y, (*CRYSTAL_CYAN, 255))
    for x, y in latch_pixels(direction, recess):
        img.put(x, y, (*AMBER_LAMP, 255))


def load_body() -> npa.Image:
    with open(SOURCE, "rb") as handle:
        digest = hashlib.sha256(handle.read()).hexdigest()
    if digest != SOURCE_SHA256:
        raise ValueError(f"unexpected L3-E storage source hash: {digest}")

    body = npa.load_png(SOURCE)
    if (body.width, body.height) != SOURCE_SIZE:
        raise ValueError(
            f"unexpected L3-E storage size: {body.width}x{body.height}"
        )
    return body


def build_frames(body: npa.Image) -> list[npa.Image]:
    frames = []
    for direction in DIRECTIONS:
        frame = clone(body)
        draw_hatch(frame, direction)
        frames.append(frame)
    return frames


def region_pixels(
    bounds: tuple[int, int, int, int]
) -> set[tuple[int, int]]:
    x0, y0, x1, y1 = bounds
    return {
        (x, y)
        for y in range(y0, y1 + 1)
        for x in range(x0, x1 + 1)
    }


def count_exact(
    img: npa.Image, color: tuple[int, int, int]
) -> int:
    return sum(
        1
        for y in range(img.height)
        for x in range(img.width)
        if img.pixel(x, y) == (*color, 255)
    )


def masked_body_fingerprint(img: npa.Image) -> str:
    masked = clone(img)
    for bounds in HATCH_REGIONS.values():
        fill_rect(masked, bounds, SHADOW)
    return hashlib.sha256(masked.data).hexdigest()


def validate_frames(body: npa.Image, frames: list[npa.Image]) -> None:
    if len(frames) != 4:
        raise ValueError(f"expected four storage frames, found {len(frames)}")

    fingerprints = {masked_body_fingerprint(frame) for frame in frames}
    if len(fingerprints) != 1:
        raise ValueError("storage bodies differ outside cardinal hatch masks")

    source_cyan = count_exact(body, CRYSTAL_CYAN)
    source_amber = count_exact(body, AMBER_LAMP)
    if source_cyan or source_amber:
        raise ValueError(
            "source unexpectedly contains reserved hatch semantic colors"
        )

    for direction, frame in zip(DIRECTIONS, frames):
        active_region = HATCH_REGIONS[direction]
        active_pixels = region_pixels(active_region)
        changed_regions = set()

        for candidate, bounds in HATCH_REGIONS.items():
            pixels = region_pixels(bounds)
            if any(frame.pixel(x, y) != body.pixel(x, y) for x, y in pixels):
                changed_regions.add(candidate)

        if changed_regions != {direction}:
            raise ValueError(
                f"{direction} changed hatch regions {sorted(changed_regions)}"
            )

        leaked = [
            (x, y)
            for y in range(body.height)
            for x in range(body.width)
            if (x, y) not in active_pixels
            and frame.pixel(x, y) != body.pixel(x, y)
        ]
        if leaked:
            raise ValueError(
                f"{direction} changed immutable storage pixels: {leaked[:8]}"
            )

        cyan = count_exact(frame, CRYSTAL_CYAN)
        amber = count_exact(frame, AMBER_LAMP)
        if (cyan, amber) != (2, 2):
            raise ValueError(
                f"{direction} hatch accents drift: cyan={cyan}, amber={amber}"
            )


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
    if (
        x0 < 0
        or y0 < 0
        or x0 + src.width > dst.width
        or y0 + src.height > dst.height
    ):
        raise ValueError("alpha paste exceeds destination bounds")
    for y in range(src.height):
        for x in range(src.width):
            pixel = src.pixel(x, y)
            if pixel[3]:
                dst.put(x0 + x, y0 + y, pixel)


def fill(img: npa.Image, color: tuple[int, int, int]) -> None:
    fill_rect(img, (0, 0, img.width - 1, img.height - 1), color)


def repeated_floor(width: int, height: int) -> npa.Image:
    atlas = npa.load_png(FLOOR_SOURCE)
    if (atlas.width, atlas.height) != (128, 128):
        raise ValueError(
            f"unexpected industrial-floor atlas: {atlas.width}x{atlas.height}"
        )
    tile = crop(atlas, (0, 0, 31, 31))
    floor = npa.Image.blank(width, height)
    for y in range(0, height, 32):
        for x in range(0, width, 32):
            alpha_paste(floor, tile, x, y)
    return floor


def write_preview(frames: list[npa.Image]) -> str:
    os.makedirs(PREVIEW_DIR, exist_ok=True)

    isolated = npa.Image.blank(399, 88)
    fill(isolated, SHADOW)
    for index, frame in enumerate(frames):
        alpha_paste(isolated, frame, index * 104, 0)
    isolated_x2 = npa.upscale_nearest(isolated, 2)

    floor = repeated_floor(512, 128)
    for index, frame in enumerate(frames):
        alpha_paste(floor, frame, index * 128 + 20, 20)
    floor_x2 = npa.upscale_nearest(floor, 2)

    contact = npa.Image.blank(1024, 476)
    fill(contact, SHADOW)
    alpha_paste(contact, isolated_x2, 113, 8)
    alpha_paste(contact, floor_x2, 0, 220)

    path = os.path.join(
        PREVIEW_DIR, "storage_cardinal_hatch_contact_sheet.png"
    )
    npa.save_png(path, contact, with_alpha=False)
    return path


def main() -> int:
    body = load_body()
    frames = build_frames(body)
    validate_frames(body, frames)

    for direction, frame in zip(DIRECTIONS, frames):
        path = OUTPUTS[direction]
        os.makedirs(os.path.dirname(path), exist_ok=True)
        npa.save_png(path, frame)

    preview = write_preview(frames)
    fingerprint = masked_body_fingerprint(frames[0])
    print(f"immutable masked-body SHA-256: {fingerprint}")
    for direction, frame in zip(DIRECTIONS, frames):
        colors = len(set(npa.opaque_colors(frame)))
        print(
            f"{OUTPUTS[direction]}: {frame.width}x{frame.height}, "
            f"{colors} colors, hatch={direction}"
        )
    print(f"QA preview: {preview}")
    return 0


if __name__ == "__main__":
    tool_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(os.path.join(tool_dir, ".."))
    sys.path.insert(0, tool_dir)
    raise SystemExit(main())
