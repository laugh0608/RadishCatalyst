#!/usr/bin/env python3
"""Normalize the reviewed pipe atlas into an isolated 32px visual study.

Source pixels remain the body artwork. Explicit piecewise source anchors reduce
oversized collars and align apertures; integer source blocks are median-sampled
without interpolation. The separately generated binary masks are dynamic-layer
clipping data, not substitute pipe artwork.
"""

from __future__ import annotations

import hashlib
import json
import math
from pathlib import Path

import normalize_pixel_asset as npa


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/art-intake/2026-09-06-pipe-modules/pipe-modules-source-v2.png"
SOURCE_HASH = "7d5d5ad143ffdd41a9495fa73ce236bde8fb9de9aaffbbfea2b893fb4f0fb361"
OUTPUT = ROOT / "client/assets/sprites/visual_studies/transparent_pipe_v1"
PREVIEW = ROOT / "assets/art-intake/2026-09-06-pipe-modules/normalization-preview"
SIZE = 32

# Each pair is (target pixel boundary, source pixel boundary). No source
# coordinate is guessed at runtime; these correspond to the v2 hash above.
ANCHORS = {
    "horizontal": {
        "x": [(0, 122), (3, 237), (29, 433), (32, 543)],
        "y": [(6, 242), (8, 266), (11, 321), (21, 402), (24, 438), (26, 463)],
    },
    "vertical": {
        "x": [(6, 809), (8, 832), (11, 872), (21, 958), (24, 1003), (26, 1024)],
        "y": [(0, 151), (3, 254), (29, 436), (32, 544)],
    },
    "elbow_left_down": {
        "x": [(0, 122), (3, 237), (8, 319), (11, 386), (21, 444), (24, 504), (26, 525)],
        "y": [(6, 714), (8, 736), (11, 795), (21, 864), (24, 914), (29, 964), (32, 1097)],
    },
    "port_right": {
        "x": [(0, 735), (9, 835), (13, 884), (29, 1035), (32, 1134)],
        "y": [(0, 733), (7, 815), (11, 873), (21, 947), (26, 1009), (32, 1064)],
    },
}


def source_boundary(value: int, knots: list[tuple[int, int]]) -> float | None:
    for (a, x), (b, y) in zip(knots, knots[1:]):
        if a <= value <= b:
            return x + (value - a) * (y - x) / (b - a)
    return None


def is_background(pixel: tuple[int, int, int, int]) -> bool:
    red, green, blue, alpha = pixel
    return alpha < 128 or (
        min(red, green, blue) >= 222 and max(red, green, blue) - min(red, green, blue) <= 20
    )


def sample_frame(source: npa.Image, name: str) -> npa.Image:
    image = npa.Image.blank(SIZE, SIZE)
    axes = ANCHORS[name]
    for y in range(SIZE):
        top = source_boundary(y, axes["y"])
        bottom = source_boundary(y + 1, axes["y"])
        if top is None or bottom is None:
            continue
        for x in range(SIZE):
            left = source_boundary(x, axes["x"])
            right = source_boundary(x + 1, axes["x"])
            if left is None or right is None:
                continue
            colors = []
            count = 0
            for sy in range(math.floor(top), math.ceil(bottom)):
                for sx in range(math.floor(left), math.ceil(right)):
                    count += 1
                    pixel = source.pixel(sx, sy)
                    if not is_background(pixel):
                        colors.append(pixel[:3])
            if len(colors) / count < 0.35:
                continue
            median = tuple(sorted(color[c] for color in colors)[len(colors) // 2] for c in range(3))
            image.put(x, y, (*median, 255))
    return image


def align_cuffs(frames: dict[str, npa.Image]) -> None:
    """Reuse actual cuff pixels at mating ends; do not paint new body shapes."""
    horizontal = frames["horizontal"]
    vertical = frames["vertical"]
    for y in range(SIZE):
        horizontal.put(0, y, horizontal.pixel(1, y))
        horizontal.put(31, y, horizontal.pixel(1, y))
    for x in range(SIZE):
        vertical.put(x, 0, vertical.pixel(x, 1))
        vertical.put(x, 31, vertical.pixel(x, 1))
    for y in range(SIZE):
        frames["elbow_left_down"].put(0, y, horizontal.pixel(0, y))
        frames["port_right"].put(31, y, horizontal.pixel(0, y))
    for x in range(SIZE):
        frames["elbow_left_down"].put(x, 31, vertical.pixel(x, 0))


def route_distance(name: str, x: float, y: float) -> float:
    if name in ("horizontal", "port_right"):
        return abs(y - 16.0)
    if name == "vertical":
        return abs(x - 16.0)
    if x <= 8.0:
        return abs(y - 16.0)
    if y >= 24.0:
        return abs(x - 16.0)
    return abs(math.hypot(x - 8.0, y - 24.0) - 8.0)


def make_mask(name: str) -> npa.Image:
    mask = npa.Image.blank(SIZE, SIZE)
    for y in range(SIZE):
        for x in range(SIZE):
            if name == "port_right" and x < 13:
                continue
            if route_distance(name, x + 0.5, y + 0.5) <= 5.0:
                mask.put(x, y, (255, 255, 255, 255))
    return mask


def verify(frames: dict[str, npa.Image], masks: dict[str, npa.Image]) -> dict:
    horizontal, vertical = frames["horizontal"], frames["vertical"]
    checks = {}
    checks["horizontal_repeat_edge"] = all(horizontal.pixel(0, y) == horizontal.pixel(31, y) for y in range(SIZE))
    checks["vertical_repeat_edge"] = all(vertical.pixel(x, 0) == vertical.pixel(x, 31) for x in range(SIZE))
    checks["elbow_horizontal_edge"] = all(frames["elbow_left_down"].pixel(0, y) == horizontal.pixel(0, y) for y in range(SIZE))
    checks["elbow_vertical_edge"] = all(frames["elbow_left_down"].pixel(x, 31) == vertical.pixel(x, 0) for x in range(SIZE))
    checks["port_horizontal_edge"] = all(frames["port_right"].pixel(31, y) == horizontal.pixel(0, y) for y in range(SIZE))
    checks["binary_alpha"] = all(set(img.data[3::4]) <= {0, 255} for img in [*frames.values(), *masks.values()])
    checks["32px_frames"] = all((img.width, img.height) == (SIZE, SIZE) for img in [*frames.values(), *masks.values()])
    checks["hollow_straight_centers"] = all(frames[name].pixel(16, 16)[3] == 0 for name in ("horizontal", "vertical"))
    checks["10px_content_width"] = sum(masks["horizontal"].pixel(16, y)[3] > 0 for y in range(SIZE)) == 10
    checks["body_art_has_coverage"] = all(120 < sum(a > 0 for a in image.data[3::4]) < 900 for image in frames.values())
    failures = [key for key, passed in checks.items() if not passed]
    if failures:
        raise ValueError("Pipe normalization failed: " + ", ".join(failures))
    return checks


def composite(dst: npa.Image, sprite: npa.Image, x0: int, y0: int, tint=None) -> None:
    for y in range(sprite.height):
        for x in range(sprite.width):
            pixel = sprite.pixel(x, y)
            if pixel[3]:
                dst.put(x0 + x, y0 + y, (*tint, 255) if tint else pixel)


def preview(frames: dict[str, npa.Image], masks: dict[str, npa.Image]) -> None:
    image = npa.Image.blank(256, 208)
    for y in range(image.height):
        for x in range(image.width):
            color = npa.STANDARD_PALETTE["platform_warm_gray"]
            image.put(x, y, (*color, 255))
    layout = [("port_right", 16, 16), ("horizontal", 48, 16), ("horizontal", 80, 16), ("elbow_left_down", 112, 16), ("vertical", 112, 48), ("vertical", 112, 80)]
    for name, x, y in layout:
        composite(image, masks[name], x, y, npa.STANDARD_PALETTE["energy_teal"])
        composite(image, frames[name], x, y)
    for index, name in enumerate(frames):
        x = 16 + index * 56
        composite(image, frames[name], x, 144)
    PREVIEW.mkdir(parents=True, exist_ok=True)
    npa.save_png(str(PREVIEW / "assembled-native.png"), image)
    zoom = npa.Image.blank(image.width * 4, image.height * 4)
    for y in range(zoom.height):
        for x in range(zoom.width):
            zoom.put(x, y, image.pixel(x // 4, y // 4))
    npa.save_png(str(PREVIEW / "assembled-4x.png"), zoom)


def main() -> None:
    digest = hashlib.sha256(SOURCE.read_bytes()).hexdigest()
    if digest != SOURCE_HASH:
        raise ValueError(f"Unexpected source hash: {digest}")
    source = npa.load_png(str(SOURCE))
    if (source.width, source.height) != (1254, 1254):
        raise ValueError("Unexpected source dimensions")
    frames = {name: sample_frame(source, name) for name in ANCHORS}
    pooled = [color for image in frames.values() for color in npa.opaque_colors(image)]
    palette = npa.snap_palette_to_anchors(npa.median_cut(pooled, 16), 28)
    for image in frames.values():
        npa.apply_palette(image, palette)
    align_cuffs(frames)
    masks = {name: make_mask(name) for name in ANCHORS}
    checks = verify(frames, masks)
    OUTPUT.mkdir(parents=True, exist_ok=True)
    report = {
        "purpose": "visual-study-only",
        "source": str(SOURCE.relative_to(ROOT)),
        "source_sha256": digest,
        "tile_size": SIZE,
        "content_width": 10,
        "source_anchors": ANCHORS,
        "palette": [list(rgb) for rgb in palette],
        "normalization": "piecewise source-block medians, checker removal, shared palette, sampled cuff edge alignment",
        "checks": checks,
        "assets": {},
    }
    for name in frames:
        for suffix, img in [("", frames[name]), ("_content_mask", masks[name])]:
            output = OUTPUT / (name + suffix + ".png")
            npa.save_png(str(output), img)
            report["assets"][output.name] = {
                "sha256": hashlib.sha256(output.read_bytes()).hexdigest(),
                "size": [img.width, img.height],
                "opaque_pixels": sum(a > 0 for a in img.data[3::4]),
            }
    (OUTPUT / "manifest.json").write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    preview(frames, masks)
    print(f"Pipe normalization passed ({len(checks)} mechanical checks; {len(palette)} shared colors).")
    print("Visual review still required: " + str(PREVIEW / "assembled-native.png"))


if __name__ == "__main__":
    main()
