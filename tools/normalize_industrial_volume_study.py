#!/usr/bin/env python3
"""Normalize independent generated volume parts; never sample the scene concept."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

import normalize_pixel_asset as npa


ROOT = Path(__file__).resolve().parents[1]
INTAKE = ROOT / "assets/art-intake/2026-09-06-industrial-volume-assets"
SOURCE = INTAKE / "industrial-volume-parts-source-v1.png"
SOURCE_HASH = "9b1347ba5908f7e14a449474974fd899cf3befa79a27b01bd42cd8295f7a5e86"
OUTPUT = ROOT / "client/assets/sprites/visual_studies/industrial_volume_v1"
# Inclusive source bounds, uniform integer sampling factor, output canvas.
PARTS = {
    "machine": ((69, 164, 457, 487), 4, (128, 128)),
    "pipe": ((555, 263, 964, 380), 5, (96, 32)),
    "support": ((156, 777, 285, 987), 8, (32, 32)),
    "machine_shadow": ((543, 708, 927, 1023), 4, (128, 96)),
    "pipe_shadow": ((86, 1279, 463, 1350), 5, (96, 16)),
    "support_shadow": ((631, 1268, 766, 1374), 8, (32, 16)),
}


def background(pixel: tuple[int, int, int, int]) -> bool:
    red, green, blue, alpha = pixel
    return alpha < 128 or (red - green > 30 and blue - green > 30)


def place(image: npa.Image, size: tuple[int, int]) -> npa.Image:
    if image.width > size[0] or image.height > size[1]:
        raise ValueError("Normalized artwork exceeds its declared canvas")
    result = npa.Image.blank(*size)
    left = (result.width - image.width) // 2
    top = (result.height - image.height) // 2
    for y in range(image.height):
        for x in range(image.width):
            result.put(left + x, top + y, image.pixel(x, y))
    return result


def glass_alpha(pipe: npa.Image) -> None:
    # The reference-backed source contains a gray clear-glass band. Preserve its
    # sampled RGB and opaque highlights; reduce only this explicit material area.
    for y in range(9, 20):
        for x in range(17, 79):
            red, green, blue, alpha = pipe.pixel(x, y)
            if alpha and min(red, green, blue) >= 95 and max(red, green, blue) - min(red, green, blue) < 55:
                pipe.put(x, y, (red, green, blue, 110 if max(red, green, blue) < 190 else 220))


def composite(dst: npa.Image, src: npa.Image, left: int, top: int,
              opacity: float = 1.0, vertical_half: bool = False) -> None:
    height = src.height // 2 if vertical_half else src.height
    for y in range(height):
        for x in range(src.width):
            red, green, blue, alpha = src.pixel(x, y * 2 if vertical_half else y)
            if not alpha:
                continue
            old = dst.pixel(left + x, top + y)
            amount = alpha / 255.0 * opacity
            color = tuple(round(value * amount + old[i] * (1 - amount)) for i, value in enumerate((red, green, blue)))
            dst.put(left + x, top + y, (*color, 255))


def main() -> None:
    digest = hashlib.sha256(SOURCE.read_bytes()).hexdigest()
    if digest != SOURCE_HASH:
        raise ValueError(f"Unexpected source hash: {digest}")
    source = npa.load_png(str(SOURCE))
    if (source.width, source.height) != (1024, 1536):
        raise ValueError("Unexpected volume source dimensions")
    mask = bytearray(background(source.pixel(x, y)) for y in range(source.height) for x in range(source.width))
    images = {}
    for name, (bounds, factor, size) in PARTS.items():
        images[name] = place(npa.downscale_sprite(source, mask, bounds, factor, 0.4), size)
    colors = [color for name in ("machine", "pipe", "support") for color in npa.opaque_colors(images[name])]
    palette = npa.snap_palette_to_anchors(npa.median_cut(colors, 28), 24)
    # Keep small semantic areas from being outvoted by the larger painted shell.
    for key in ("amber_lamp", "energy_teal"):
        if npa.STANDARD_PALETTE[key] not in palette:
            palette.append(npa.STANDARD_PALETTE[key])
    for name in ("machine", "pipe", "support"):
        npa.apply_palette(images[name], palette)
    glass_alpha(images["pipe"])
    for name in ("machine_shadow", "pipe_shadow", "support_shadow"):
        npa.apply_palette(images[name], [npa.STANDARD_PALETTE["shadow_deep"]])

    checks = {
        "declared_canvas_sizes": all((image.width, image.height) == PARTS[name][2] for name, image in images.items()),
        "no_magenta_background": all(not background((*image.pixel(x, y)[:3], 255)) for image in images.values() for y in range(image.height) for x in range(image.width) if image.pixel(x, y)[3]),
        "machine_foot_gap": images["machine"].pixel(64, 98)[3] == 0,
        "clear_glass_alpha": any(0 < alpha < 255 for alpha in images["pipe"].data[3::4]),
        "pipe_cyan_content": any(green > red * 1.25 and blue > red * 1.25 and alpha == 255 for red, green, blue, alpha in (images["pipe"].pixel(x, y) for y in range(32) for x in range(96))),
        "all_parts_have_coverage": all(sum(alpha > 0 for alpha in image.data[3::4]) >= 60 for image in images.values()),
        "shadow_masks_binary": all(set(images[name].data[3::4]) <= {0, 255} for name in images if name.endswith("shadow")),
    }
    failures = [name for name, result in checks.items() if not result]
    if failures:
        raise ValueError("Volume normalization failed: " + ", ".join(failures))
    OUTPUT.mkdir(parents=True, exist_ok=True)
    report = {
        "purpose": "isolated-volume-visual-study",
        "source": str(SOURCE.relative_to(ROOT)),
        "source_sha256": digest,
        "method": "source-bounded uniform integer block medians, magenta removal, shared material palette",
        "glass_alpha": {"region": [17, 9, 79, 20], "midtones": 110, "highlights": 220},
        "palette": palette,
        "checks": checks,
        "assets": {},
    }
    for name, image in images.items():
        path = OUTPUT / f"{name}.png"
        npa.save_png(str(path), image)
        report["assets"][path.name] = {
            "source_bounds": PARTS[name][0], "integer_factor": PARTS[name][1],
            "canvas": PARTS[name][2], "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
        }
    (OUTPUT / "manifest.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    # Offline arrangement at exactly one logical pixel per pixel, then a nearest
    # enlarged review copy. This is not a replacement for the formal Boot image.
    preview = npa.Image.blank(288, 192)
    for y in range(preview.height):
        for x in range(preview.width):
            preview.put(x, y, (*npa.STANDARD_PALETTE["platform_warm_gray"], 255))
    ox, oy = 24, 24
    composite(preview, images["machine_shadow"], ox + 14, oy + 70, 0.34, True)
    composite(preview, images["pipe_shadow"], ox + 108, oy + 86, 0.32)
    for x in (118, 163):
        composite(preview, images["support_shadow"], ox + x + 3, oy + 81, 0.30)
        composite(preview, images["support"], ox + x, oy + 55)
    composite(preview, images["pipe"], ox + 100, oy + 44)
    composite(preview, images["machine"], ox, oy)
    folder = INTAKE / "normalization-preview"
    folder.mkdir(exist_ok=True)
    npa.save_png(str(folder / "assembled-native.png"), preview)
    npa.save_png(str(folder / "assembled-4x.png"), npa.upscale_nearest(preview, 4))
    print(f"Industrial volume normalization passed ({len(checks)} checks; {len(palette)} shared colors).")


if __name__ == "__main__":
    main()
