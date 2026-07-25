#!/usr/bin/env python3
"""Prepare target-size review candidates for the approved L3-F V5 collector.

This review driver intentionally stops before runtime replacement:

1. verifies the V5 source and terrain hashes;
2. removes only border-connected near-black background pixels while keeping
   the enclosed dark drill bore opaque;
3. derives three integer-downscaled candidates through one shared palette;
4. validates alpha, semantic lamps, dimensions, and grounded bottom edges;
5. writes isolated, crystal-ground, and industrial-floor QA contact sheets.

After visual review, a separately authorized integration step can choose one
candidate for ``client/assets/sprites/slice/collector.png``.
"""

from __future__ import annotations

import hashlib
import os
import sys

import normalize_pixel_asset as npa


SOURCE = (
    "assets/art-intake/2026-07-25-batch04/"
    "l3f_collector_corner_gantry_v5.png"
)
SOURCE_SHA256 = (
    "bbd36623c30bc54996e0c351fdda804c4f6396ad47ff9b739a1580434a3ea650"
)
CRYSTAL_SOURCE = "client/assets/tiles/slice/ground_crystal.png"
CRYSTAL_SHA256 = (
    "3d73fc0fc92925fa5cad1d18243d51025ca3ac0420fc34ce8c71861ee7db3886"
)
FLOOR_SOURCE = "client/assets/tiles/slice/industrial_floor_terrain.png"
FLOOR_SHA256 = (
    "dd9a0705fe3935b7c0155ab3364eafdf7d3f53bc3d63aff8490e0ac62347d8e0"
)
OUTPUT_DIR = (
    "assets/art-intake/2026-07-25-batch04/l3f-normalization-preview"
)

SOURCE_SIZE = (1254, 1254)
BACKGROUND = (2, 2, 9)
EXPECTED_BBOX = (183, 95, 1070, 1176)
TOL_EDGE = 16
TOL_HOLE = 6
# Deliberately larger than the full image: the enclosed dark drill bore is
# physical sprite content, not a transparent background hole.
MIN_HOLE = 2_000_000
COVERAGE = 0.40

FACTORS = (9, 10, 11)
EXPECTED_SIZES = {
    9: (99, 120),
    10: (89, 108),
    11: (81, 98),
}
PALETTE_COLORS = 25
PALETTE_SNAP_DISTANCE = 24

SHADOW = npa.STANDARD_PALETTE["shadow_deep"]
PLATFORM_GRAY = npa.STANDARD_PALETTE["platform_warm_gray"]
METAL_MID = npa.STANDARD_PALETTE["metal_mid"]
METAL_HIGHLIGHT = npa.STANDARD_PALETTE["metal_highlight"]
ENERGY_TEAL = npa.STANDARD_PALETTE["energy_teal"]
CRYSTAL_CYAN = npa.STANDARD_PALETTE["crystal_cyan"]
AMBER_LAMP = npa.STANDARD_PALETTE["amber_lamp"]

REQUIRED_ANCHORS = (
    SHADOW,
    PLATFORM_GRAY,
    METAL_MID,
    METAL_HIGHLIGHT,
    ENERGY_TEAL,
    CRYSTAL_CYAN,
    AMBER_LAMP,
)

CONTACT_COLUMN_WIDTH = 576
CONTACT_GAP = 16
ISOLATED_FRAME = (128, 136)
SCENE_FRAME = (192, 160)
SCENE_BASELINE = 148


def sha256(path: str) -> str:
    with open(path, "rb") as handle:
        return hashlib.sha256(handle.read()).hexdigest()


def verify_source(path: str, expected: str, label: str) -> None:
    digest = sha256(path)
    if digest != expected:
        raise ValueError(f"unexpected {label} hash: {digest}")


def clone(img: npa.Image) -> npa.Image:
    return npa.Image(img.width, img.height, bytearray(img.data))


def fill(img: npa.Image, color: tuple[int, int, int]) -> None:
    rgba = (*color, 255)
    for y in range(img.height):
        for x in range(img.width):
            img.put(x, y, rgba)


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


def load_source() -> tuple[npa.Image, bytearray]:
    verify_source(SOURCE, SOURCE_SHA256, "L3-F V5 source")
    source = npa.load_png(SOURCE)
    if (source.width, source.height) != SOURCE_SIZE:
        raise ValueError(
            f"unexpected L3-F source size: {source.width}x{source.height}"
        )

    background = npa.estimate_background(source)
    if background != BACKGROUND:
        raise ValueError(f"unexpected L3-F background: {background}")
    mask = npa.build_background_mask(
        source,
        background,
        TOL_EDGE,
        TOL_HOLE,
        MIN_HOLE,
    )
    bbox = npa.content_bbox(mask, source.width, source.height)
    if bbox != EXPECTED_BBOX:
        raise ValueError(f"unexpected L3-F content bounds: {bbox}")
    return source, mask


def snap_status_emitters(img: npa.Image) -> None:
    """Preserve small generated status windows through shared quantization."""
    for y in range(img.height):
        for x in range(img.width):
            red, green, blue, alpha = img.pixel(x, y)
            if (
                alpha
                and green >= 100
                and blue >= 100
                and green >= red + 20
                and blue >= red + 30
            ):
                color = CRYSTAL_CYAN if max(green, blue) >= 180 else ENERGY_TEAL
                img.put(x, y, (*color, 255))
            elif (
                alpha
                and red >= 100
                and green >= 55
                and blue <= 80
                and red >= green + 25
                and green >= blue + 15
            ):
                img.put(x, y, (*AMBER_LAMP, 255))


def build_candidates() -> dict[int, npa.Image]:
    source, mask = load_source()
    candidates = {}
    for factor in FACTORS:
        candidate = npa.downscale_sprite(
            source,
            mask,
            EXPECTED_BBOX,
            factor,
            coverage=COVERAGE,
        )
        candidate = npa.crop_to_content(candidate)
        expected_size = EXPECTED_SIZES[factor]
        size = (candidate.width, candidate.height)
        if size != expected_size:
            raise ValueError(
                f"factor {factor} size drift: {size}, expected {expected_size}"
            )
        snap_status_emitters(candidate)
        candidates[factor] = candidate

    pooled = []
    for candidate in candidates.values():
        pooled.extend(npa.opaque_colors(candidate))
    palette = npa.median_cut(pooled, PALETTE_COLORS)
    palette = npa.snap_palette_to_anchors(
        palette, PALETTE_SNAP_DISTANCE
    )
    palette = sorted(set(palette + list(REQUIRED_ANCHORS)))
    if len(palette) > 32:
        raise ValueError(f"L3-F shared palette exceeds 32 colors: {len(palette)}")
    for candidate in candidates.values():
        npa.apply_palette(candidate, palette)
    return candidates


def count_color(
    img: npa.Image, color: tuple[int, int, int]
) -> int:
    return sum(
        1
        for y in range(img.height)
        for x in range(img.width)
        if img.pixel(x, y) == (*color, 255)
    )


def validate_candidate(factor: int, img: npa.Image) -> None:
    if (img.width, img.height) != EXPECTED_SIZES[factor]:
        raise ValueError(f"factor {factor} candidate size changed")
    corners = (
        img.pixel(0, 0),
        img.pixel(img.width - 1, 0),
        img.pixel(0, img.height - 1),
        img.pixel(img.width - 1, img.height - 1),
    )
    if any(pixel[3] for pixel in corners):
        raise ValueError(f"factor {factor} candidate corners are not transparent")

    opaque = sum(
        1
        for y in range(img.height)
        for x in range(img.width)
        if img.pixel(x, y)[3]
    )
    coverage = opaque / (img.width * img.height)
    if not 0.35 <= coverage <= 0.90:
        raise ValueError(
            f"factor {factor} implausible opaque coverage: {coverage:.3f}"
        )

    bottom_pixels = sum(
        1 for x in range(img.width) if img.pixel(x, img.height - 1)[3]
    )
    if bottom_pixels < max(8, img.width // 8):
        raise ValueError(
            f"factor {factor} lost grounded bottom edge: {bottom_pixels}px"
        )

    cyan = count_color(img, ENERGY_TEAL) + count_color(img, CRYSTAL_CYAN)
    amber = count_color(img, AMBER_LAMP)
    if cyan < 4:
        raise ValueError(f"factor {factor} lost cyan status read: {cyan}px")
    if amber < 2:
        raise ValueError(f"factor {factor} lost amber status read: {amber}px")


def repeated_texture(
    source: npa.Image, width: int, height: int
) -> npa.Image:
    out = npa.Image.blank(width, height)
    for y in range(height):
        for x in range(width):
            out.put(x, y, source.pixel(x % source.width, y % source.height))
    return out


def isolated_panel(candidate: npa.Image) -> npa.Image:
    frame = npa.Image.blank(*ISOLATED_FRAME)
    fill(frame, SHADOW)
    x = (frame.width - candidate.width) // 2
    y = frame.height - candidate.height - 4
    alpha_paste(frame, candidate, x, y)
    return npa.upscale_nearest(frame, 4)


def scene_panel(
    candidate: npa.Image, terrain: npa.Image
) -> npa.Image:
    scene = repeated_texture(terrain, *SCENE_FRAME)
    x = (scene.width - candidate.width) // 2
    y = SCENE_BASELINE - candidate.height
    alpha_paste(scene, candidate, x, y)
    return npa.upscale_nearest(scene, 3)


def build_contact_sheet(
    candidates: dict[int, npa.Image],
    crystal: npa.Image,
    floor: npa.Image,
) -> npa.Image:
    isolated_height = ISOLATED_FRAME[1] * 4
    scene_height = SCENE_FRAME[1] * 3
    width = CONTACT_COLUMN_WIDTH * len(FACTORS)
    height = (
        isolated_height
        + CONTACT_GAP
        + scene_height
        + CONTACT_GAP
        + scene_height
    )
    contact = npa.Image.blank(width, height)
    fill(contact, SHADOW)

    floor_center = crop(floor, (0, 0, 31, 31))
    for column, factor in enumerate(FACTORS):
        candidate = candidates[factor]
        x0 = column * CONTACT_COLUMN_WIDTH

        isolated = isolated_panel(candidate)
        alpha_paste(
            contact,
            isolated,
            x0 + (CONTACT_COLUMN_WIDTH - isolated.width) // 2,
            0,
        )

        crystal_panel = scene_panel(candidate, crystal)
        crystal_y = isolated_height + CONTACT_GAP
        alpha_paste(contact, crystal_panel, x0, crystal_y)

        floor_panel = scene_panel(candidate, floor_center)
        floor_y = crystal_y + scene_height + CONTACT_GAP
        alpha_paste(contact, floor_panel, x0, floor_y)
    return contact


def write_outputs(candidates: dict[int, npa.Image]) -> str:
    verify_source(CRYSTAL_SOURCE, CRYSTAL_SHA256, "crystal terrain")
    verify_source(FLOOR_SOURCE, FLOOR_SHA256, "industrial floor")
    crystal = npa.load_png(CRYSTAL_SOURCE)
    floor = npa.load_png(FLOOR_SOURCE)
    if (crystal.width, crystal.height) != (128, 128):
        raise ValueError("unexpected crystal terrain size")
    if (floor.width, floor.height) != (128, 128):
        raise ValueError("unexpected industrial floor size")

    os.makedirs(OUTPUT_DIR, exist_ok=True)
    for factor, candidate in candidates.items():
        width, height = EXPECTED_SIZES[factor]
        path = os.path.join(
            OUTPUT_DIR,
            f"collector_v5_factor{factor}_{width}x{height}.png",
        )
        npa.save_png(path, candidate)

    contact_path = os.path.join(
        OUTPUT_DIR, "collector_v5_target_size_contact_sheet.png"
    )
    contact = build_contact_sheet(candidates, crystal, floor)
    npa.save_png(contact_path, contact, with_alpha=False)
    return contact_path


def main() -> int:
    candidates = build_candidates()
    for factor, candidate in candidates.items():
        validate_candidate(factor, candidate)

    contact_path = write_outputs(candidates)
    for factor, candidate in candidates.items():
        colors = len(set(npa.opaque_colors(candidate)))
        cyan = count_color(candidate, ENERGY_TEAL) + count_color(
            candidate, CRYSTAL_CYAN
        )
        amber = count_color(candidate, AMBER_LAMP)
        print(
            f"factor {factor}: {candidate.width}x{candidate.height}, "
            f"{colors} colors, cyan={cyan}px, amber={amber}px"
        )
    print(f"QA contact sheet: {contact_path}")
    return 0


if __name__ == "__main__":
    tool_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(os.path.join(tool_dir, ".."))
    sys.path.insert(0, tool_dir)
    raise SystemExit(main())
