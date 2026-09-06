#!/usr/bin/env python3
"""Source-anchored raster normalization for the raised pipe visual specimen."""

from __future__ import annotations

import hashlib
import json
import math
from pathlib import Path

import normalize_pixel_asset as npa
from normalize_industrial_volume_study import composite
from normalize_pipe_visual_study import align_cuffs, is_background, route_distance, source_boundary

ROOT = Path(__file__).resolve().parents[1]
INTAKE = ROOT / "assets/art-intake/2026-09-06-raised-pipe-modules"
SOURCE = INTAKE / "raised-pipe-modules-source-v2.png"
SOURCE_HASH = "25548eb4ffd497819b4ed15b98360845aea480bb6035d2ba49e96caa89577997"
OUTPUT = ROOT / "client/assets/sprites/visual_studies/raised_pipe_v1"
ANCHORS = {
    "horizontal": {
        "x": [(0, 212), (2, 268), (30, 430), (32, 491)],
        "y": [(6, 260), (8, 274), (24, 456), (26, 471)],
    },
    "vertical": {
        "x": [(6, 814), (8, 827), (24, 1013), (26, 1028)],
        "y": [(0, 213), (2, 280), (30, 451), (32, 510)],
    },
    "elbow_left_down": {
        "x": [(0, 211), (2, 271), (8, 307), (16, 389), (24, 465), (26, 480)],
        "y": [(6, 736), (8, 759), (16, 833), (24, 918), (30, 971), (32, 1030)],
    },
    "port_right": {
        "x": [(0, 786), (9, 868), (13, 910), (30, 1035), (32, 1085)],
        "y": [(0, 725), (6, 788), (8, 802), (16, 881), (24, 962), (26, 979), (32, 1039)],
    },
}


def sample_frame(source: npa.Image, axes: dict) -> npa.Image:
    image = npa.Image.blank(32, 32)
    for y in range(32):
        top, bottom = (source_boundary(v, axes["y"]) for v in (y, y + 1))
        if top is None or bottom is None:
            continue
        for x in range(32):
            left, right = (source_boundary(v, axes["x"]) for v in (x, x + 1))
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
            if len(colors) / count >= 0.35:
                color = tuple(
                    sorted(color[channel] for color in colors)[len(colors) // 2]
                    for channel in range(3)
                )
                image.put(x, y, (*color, 255))
    return image


def inside_glass(name: str, x: int, y: int) -> bool:
    if name == "port_right" and x < 13:
        return False
    if name in ("horizontal", "port_right") and not 2 <= x < 30:
        return False
    if name == "vertical" and not 2 <= y < 30:
        return False
    if name == "elbow_left_down" and (x < 2 or y >= 30):
        return False
    return route_distance(name, x + 0.5, y + 0.5) <= 6.0


def material_layers(name: str, body: npa.Image) -> tuple[npa.Image, npa.Image]:
    aperture, shadow = npa.Image.blank(32, 32), npa.Image.blank(32, 32)
    for y in range(32):
        for x in range(32):
            r, g, b, a = body.pixel(x, y)
            if a:
                shadow.put(x, y, (*npa.STANDARD_PALETTE["shadow_deep"], 255))
            if not a or not inside_glass(name, x, y):
                continue
            # Preserve the generated highlight and side bands above the live
            # content. Only the explicit clear-glass material becomes translucent.
            body.put(x, y, (r, g, b, 210 if max(r, g, b) >= 170 else 96))
            if route_distance(name, x + 0.5, y + 0.5) <= 5.0:
                aperture.put(x, y, (255, 255, 255, 255))
    return aperture, shadow


def verify(frames: dict, masks: dict, shadows: dict) -> dict:
    h, v, e, p = (frames[n] for n in ("horizontal", "vertical", "elbow_left_down", "port_right"))
    checks = {
        "horizontal_repeat": all(h.pixel(0, y) == h.pixel(31, y) for y in range(32)),
        "vertical_repeat": all(v.pixel(x, 0) == v.pixel(x, 31) for x in range(32)),
        "elbow_west_seam": all(e.pixel(0, y) == h.pixel(0, y) for y in range(32)),
        "elbow_south_seam": all(e.pixel(x, 31) == v.pixel(x, 0) for x in range(32)),
        "device_seam": all(p.pixel(31, y) == h.pixel(0, y) for y in range(32)),
        "declared_32px_canvas": all((i.width, i.height) == (32, 32) for i in [*frames.values(), *masks.values(), *shadows.values()]),
        "binary_dynamic_masks": all(set(i.data[3::4]) <= {0, 255} for i in [*masks.values(), *shadows.values()]),
        "glass_retains_material": all(any(0 < a < 255 for a in i.data[3::4]) for i in frames.values()),
        "mask_inside_source_art": all(not mask.pixel(x, y)[3] or frames[name].pixel(x, y)[3] for name, mask in masks.items() for y in range(32) for x in range(32)),
        "open_bend_centerline": all(masks["elbow_left_down"].pixel(x, y)[3] for x, y in [(3,16),(7,16),(11,17),(14,20),(16,24),(16,28)]),
        "16px_horizontal_tube": sum(h.pixel(16, y)[3] > 0 for y in range(32)) == 16,
        "16px_vertical_tube": sum(v.pixel(x, 16)[3] > 0 for x in range(32)) == 16,
    }
    failures = [name for name, passed in checks.items() if not passed]
    if failures:
        raise ValueError("Raised pipe normalization failed: " + ", ".join(failures))
    return checks


def preview(frames: dict, shadows: dict) -> None:
    image = npa.Image.blank(384, 224)
    for y in range(image.height):
        for x in range(image.width):
            image.put(x, y, (*npa.STANDARD_PALETTE["platform_warm_gray"], 255))
    assets = ROOT / "client/assets/sprites/visual_studies/industrial_volume_v1"
    support = npa.load_png(str(assets / "support.png"))
    machine = npa.load_png(str(assets / "machine.png"))
    layout = [("port_right",0,0),("horizontal",1,0),("horizontal",2,0),("horizontal",3,0),("horizontal",4,0),("elbow_left_down",5,0),("vertical",5,1),("vertical",5,2),("vertical",5,3)]
    for name, cx, cy in layout:
        composite(image, shadows[name], 100 + cx * 32, 70 + cy * 32, 0.3)
    for index in (1,3,5,7):
        _, cx, cy = layout[index]
        composite(image, support, 96 + cx * 32, 60 + cy * 32)
    for name, cx, cy in layout:
        composite(image, frames[name], 96 + cx * 32, 48 + cy * 32)
    composite(image, machine, 0, 0)
    directory = INTAKE / "normalization-preview"
    directory.mkdir(exist_ok=True)
    npa.save_png(str(directory / "assembled-native.png"), image)
    npa.save_png(str(directory / "assembled-4x.png"), npa.upscale_nearest(image, 4))


def main() -> None:
    digest = hashlib.sha256(SOURCE.read_bytes()).hexdigest()
    if digest != SOURCE_HASH:
        raise ValueError("Unexpected raised pipe source hash: " + digest)
    source = npa.load_png(str(SOURCE))
    if (source.width, source.height) != (1254, 1254):
        raise ValueError("Unexpected source dimensions")
    frames = {name: sample_frame(source, axes) for name, axes in ANCHORS.items()}
    palette = npa.snap_palette_to_anchors(npa.median_cut([c for i in frames.values() for c in npa.opaque_colors(i)], 20), 24)
    for frame in frames.values():
        npa.apply_palette(frame, palette)
    align_cuffs(frames)
    masks, shadows = {}, {}
    for name, frame in frames.items():
        masks[name], shadows[name] = material_layers(name, frame)
    checks = verify(frames, masks, shadows)
    OUTPUT.mkdir(parents=True, exist_ok=True)
    report = {"purpose": "raised-pipe-visual-study-only", "source": str(SOURCE.relative_to(ROOT)),
              "source_sha256": digest, "tile_size": 32, "elevation_pixels": 16,
              "normalization": "piecewise source-block medians, background removal, shared palette, same-source mating cuff pixels, explicit glass alpha",
              "source_anchors": ANCHORS, "palette": palette, "checks": checks, "assets": {}}
    for name in frames:
        for suffix, img in [("", frames[name]), ("_content_mask", masks[name]), ("_shadow", shadows[name])]:
            path = OUTPUT / (name + suffix + ".png")
            npa.save_png(str(path), img)
            report["assets"][path.name] = {"sha256": hashlib.sha256(path.read_bytes()).hexdigest(), "canvas": [32, 32]}
    (OUTPUT / "manifest.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    preview(frames, shadows)
    print(f"Raised pipe normalization passed ({len(checks)} checks; {len(palette)} shared colors).")


if __name__ == "__main__":
    main()
