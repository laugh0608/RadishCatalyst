#!/usr/bin/env python3
"""Derive L3-D reactor cardinal-port frames from one immutable runtime body.

The two generated L3-D candidates proved that a generative edit can preserve
the port idea but cannot guarantee pixel-identical reactor bodies. This
driver therefore changes medium without changing the approved art identity:

1. verifies the reviewed 96px runtime reactor hash;
2. clones that exact raster four times;
3. replaces only two compact cardinal docking-module regions per frame;
4. validates that every pixel outside those regions remains byte-identical;
5. writes four static runtime sprites and an industrial-floor QA sheet.

This is offline asset derivation. Runtime code does not rotate or draw the
reactor, its ports, or any fallback geometry.
"""

from __future__ import annotations

import hashlib
import os
import sys

import normalize_pixel_asset as npa


SOURCE = "client/assets/sprites/slice/reactor.png"
SOURCE_SHA256 = "55ad08be86664bc35ea3a32e08ce53a446e11e99b7b5f9b3a44740dc710ec2d1"
OUTPUTS = {
    "up": "client/assets/sprites/slice/reactor_up.png",
    "right": "client/assets/sprites/slice/reactor_right.png",
    "down": "client/assets/sprites/slice/reactor_down.png",
    "left": "client/assets/sprites/slice/reactor_left.png",
}
FLOOR_SOURCE = "client/assets/tiles/slice/industrial_floor_terrain.png"
PREVIEW_DIR = (
    "assets/art-intake/2026-07-25-batch02/l3d-deterministic-preview"
)

SOURCE_SIZE = (96, 90)
DIRECTIONS = ("up", "right", "down", "left")
DIRECTION_PAIRS = {
    "up": ("top", "bottom"),
    "right": ("right", "left"),
    "down": ("bottom", "top"),
    "left": ("left", "right"),
}

# Inclusive bounds around four existing structural attachment points. The
# overlay stays small and flush with the approved silhouette; the underlying
# body raster is never rescaled or regenerated.
PORT_REGIONS = {
    "top": (43, 0, 52, 6),
    "right": (89, 47, 95, 56),
    "bottom": (43, 83, 52, 89),
    "left": (0, 47, 6, 56),
}

SHADOW = npa.STANDARD_PALETTE["shadow_deep"]
METAL_MID = npa.STANDARD_PALETTE["metal_mid"]
METAL_HIGHLIGHT = npa.STANDARD_PALETTE["metal_highlight"]
ENERGY_TEAL = npa.STANDARD_PALETTE["energy_teal"]
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
        raise ValueError(f"cannot inset port region {bounds} by {amount}")
    return result


def module_notch(
    anchor: str, bounds: tuple[int, int, int, int]
) -> tuple[tuple[int, int], ...]:
    x0, y0, x1, y1 = bounds
    center_x = (x0 + x1) // 2
    center_y = (y0 + y1) // 2
    if anchor in ("top", "bottom"):
        return ((center_x, center_y), (center_x + 1, center_y))
    return ((center_x, center_y), (center_x, center_y + 1))


def draw_module(img: npa.Image, anchor: str, kind: str) -> None:
    bounds = PORT_REGIONS[anchor]
    inner = inset(bounds, 1)
    window = inset(bounds, 2)

    fill_rect(img, bounds, SHADOW)
    fill_rect(img, inner, METAL_MID)

    x0, y0, x1, y1 = inner
    for x in range(x0, x1 + 1):
        img.put(x, y0, (*METAL_HIGHLIGHT, 255))
    for y in range(y0, y1 + 1):
        img.put(x0, y, (*METAL_HIGHLIGHT, 255))

    if kind == "output":
        fill_rect(img, window, AMBER_LAMP)
        return
    if kind != "input":
        raise ValueError(f"unknown docking-module kind: {kind}")

    fill_rect(img, window, DARK_TEAL)
    notch = module_notch(anchor, window)
    for index, (x, y) in enumerate(notch):
        color = CRYSTAL_CYAN if index == 0 else ENERGY_TEAL
        img.put(x, y, (*color, 255))


def load_body() -> npa.Image:
    with open(SOURCE, "rb") as handle:
        digest = hashlib.sha256(handle.read()).hexdigest()
    if digest != SOURCE_SHA256:
        raise ValueError(f"unexpected L3-D reactor source hash: {digest}")

    body = npa.load_png(SOURCE)
    if (body.width, body.height) != SOURCE_SIZE:
        raise ValueError(
            f"unexpected L3-D reactor size: {body.width}x{body.height}"
        )
    return body


def build_frames(body: npa.Image) -> list[npa.Image]:
    frames = []
    for direction in DIRECTIONS:
        output_anchor, input_anchor = DIRECTION_PAIRS[direction]
        frame = clone(body)
        draw_module(frame, output_anchor, "output")
        draw_module(frame, input_anchor, "input")
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
    img: npa.Image,
    bounds: tuple[int, int, int, int],
    color: tuple[int, int, int],
) -> int:
    return sum(
        1
        for x, y in region_pixels(bounds)
        if img.pixel(x, y) == (*color, 255)
    )


def masked_body_fingerprint(img: npa.Image) -> str:
    masked = clone(img)
    for bounds in PORT_REGIONS.values():
        fill_rect(masked, bounds, SHADOW)
    return hashlib.sha256(masked.data).hexdigest()


def validate_frames(body: npa.Image, frames: list[npa.Image]) -> None:
    if len(frames) != 4:
        raise ValueError(f"expected four reactor frames, found {len(frames)}")

    body_fingerprints = {masked_body_fingerprint(frame) for frame in frames}
    if len(body_fingerprints) != 1:
        raise ValueError("reactor bodies differ outside cardinal port masks")

    for direction, frame in zip(DIRECTIONS, frames):
        output_anchor, input_anchor = DIRECTION_PAIRS[direction]
        expected_anchors = {output_anchor, input_anchor}
        changed_anchors = set()

        for anchor, bounds in PORT_REGIONS.items():
            pixels = region_pixels(bounds)
            if any(frame.pixel(x, y) != body.pixel(x, y) for x, y in pixels):
                changed_anchors.add(anchor)

        if changed_anchors != expected_anchors:
            raise ValueError(
                f"{direction} changed port anchors {sorted(changed_anchors)}, "
                f"expected {sorted(expected_anchors)}"
            )

        allowed = set()
        for anchor in expected_anchors:
            allowed.update(region_pixels(PORT_REGIONS[anchor]))
        leaked = [
            (x, y)
            for y in range(body.height)
            for x in range(body.width)
            if (x, y) not in allowed
            and frame.pixel(x, y) != body.pixel(x, y)
        ]
        if leaked:
            raise ValueError(
                f"{direction} changed immutable reactor pixels: {leaked[:8]}"
            )

        output_bounds = PORT_REGIONS[output_anchor]
        input_bounds = PORT_REGIONS[input_anchor]
        amber = count_exact(frame, output_bounds, AMBER_LAMP)
        input_cyan = count_exact(frame, input_bounds, CRYSTAL_CYAN)
        input_teal = count_exact(frame, input_bounds, ENERGY_TEAL)
        if amber < 8:
            raise ValueError(f"{direction} output coupler lost amber read")
        if (input_cyan, input_teal) != (1, 1):
            raise ValueError(
                f"{direction} input notch drift: "
                f"cyan={input_cyan}, teal={input_teal}"
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
    if x0 < 0 or y0 < 0 or x0 + src.width > dst.width or y0 + src.height > dst.height:
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

    isolated = npa.Image.blank(408, 90)
    fill(isolated, SHADOW)
    for index, frame in enumerate(frames):
        alpha_paste(isolated, frame, index * 104, 0)
    isolated_x2 = npa.upscale_nearest(isolated, 2)

    floor = repeated_floor(512, 128)
    for index, frame in enumerate(frames):
        alpha_paste(floor, frame, index * 128 + 16, 19)
    floor_x2 = npa.upscale_nearest(floor, 2)

    contact = npa.Image.blank(1024, 484)
    fill(contact, SHADOW)
    alpha_paste(contact, isolated_x2, 104, 8)
    alpha_paste(contact, floor_x2, 0, 228)

    path = os.path.join(
        PREVIEW_DIR, "reactor_cardinal_ports_contact_sheet.png"
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
        output_anchor, input_anchor = DIRECTION_PAIRS[direction]
        print(
            f"{OUTPUTS[direction]}: {frame.width}x{frame.height}, "
            f"{colors} colors, output={output_anchor}, input={input_anchor}"
        )
    print(f"QA preview: {preview}")
    return 0


if __name__ == "__main__":
    tool_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(os.path.join(tool_dir, ".."))
    sys.path.insert(0, tool_dir)
    raise SystemExit(main())
