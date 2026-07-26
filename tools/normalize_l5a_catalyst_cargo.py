#!/usr/bin/env python3
"""Promote the reviewed L5-A catalyst cargo into the runtime asset set.

The target-size candidate was selected after V2/V3 comparison on straight,
turning, merging, and reactor-output conveyor contexts. This driver hash-locks
that reviewed RGBA source, validates its pixel contract and crystal-cargo
separation, then writes the byte-stable runtime PNG.
"""

from __future__ import annotations

import hashlib
import os
import sys

import normalize_pixel_asset as npa


SOURCE = (
    "assets/art-intake/2026-07-26-batch01/"
    "l5a_catalyst_cargo_selected_12x8.png"
)
SOURCE_SHA256 = (
    "76187e97bcd025c2a12ad2348e3922a320165dfc9abd21f059da5c5c053f6a02"
)
OUTPUT = "client/assets/sprites/slice/cargo_catalyst.png"
OUTPUT_SHA256 = SOURCE_SHA256

CRYSTAL_CARGO = "client/assets/sprites/slice/cargo_crystal.png"
CRYSTAL_CARGO_SHA256 = (
    "e47cae97c2d145a31b36a31d42747132f789af6b2a0d422a784d614c42a879bd"
)

OUTPUT_SIZE = (12, 8)
OPAQUE_PIXELS = 92
AMBER_PIXELS = 18
PALETTE = {
    (21, 28, 30),
    (46, 65, 69),
    (74, 97, 101),
    (109, 127, 124),
    npa.STANDARD_PALETTE["amber_lamp"],
}

AMBER = npa.STANDARD_PALETTE["amber_lamp"]


def sha256(path: str) -> str:
    with open(path, "rb") as handle:
        return hashlib.sha256(handle.read()).hexdigest()


def verify_hash(path: str, expected: str, label: str) -> None:
    digest = sha256(path)
    if digest != expected:
        raise ValueError(f"unexpected {label} hash: {digest}")


def opaque_pixels(
    image: npa.Image,
) -> list[tuple[int, int, tuple[int, int, int, int]]]:
    return [
        (x, y, image.pixel(x, y))
        for y in range(image.height)
        for x in range(image.width)
        if image.pixel(x, y)[3]
    ]


def count_color(
    image: npa.Image,
    color: tuple[int, int, int],
) -> int:
    return sum(
        1
        for _x, _y, pixel in opaque_pixels(image)
        if pixel == (*color, 255)
    )


def count_cyan_identity_pixels(image: npa.Image) -> int:
    return sum(
        1
        for _x, _y, pixel in opaque_pixels(image)
        if (
            pixel[1] >= 170
            and pixel[2] >= 170
            and pixel[1] >= pixel[0] + 30
            and pixel[2] >= pixel[0] + 30
        )
    )


def validate_catalyst(image: npa.Image) -> None:
    if (image.width, image.height) != OUTPUT_SIZE:
        raise ValueError(
            "unexpected L5-A catalyst cargo size: "
            f"{image.width}x{image.height}"
        )

    opaque = opaque_pixels(image)
    if len(opaque) != OPAQUE_PIXELS:
        raise ValueError(
            f"unexpected L5-A opaque pixel count: {len(opaque)}"
        )
    if any(pixel[3] != 255 for _x, _y, pixel in opaque):
        raise ValueError("L5-A catalyst cargo contains partial alpha")

    corners = (
        image.pixel(0, 0),
        image.pixel(image.width - 1, 0),
        image.pixel(0, image.height - 1),
        image.pixel(image.width - 1, image.height - 1),
    )
    if any(pixel[3] for pixel in corners):
        raise ValueError("L5-A catalyst cargo corners must stay transparent")

    colors = {pixel[:3] for _x, _y, pixel in opaque}
    if colors != PALETTE:
        raise ValueError(
            f"unexpected L5-A catalyst cargo palette: {sorted(colors)}"
        )
    amber = count_color(image, AMBER)
    if amber != AMBER_PIXELS:
        raise ValueError(
            f"unexpected L5-A amber core coverage: {amber}px"
        )
    if count_cyan_identity_pixels(image):
        raise ValueError("L5-A catalyst cargo contains crystal-cyan pixels")


def validate_crystal_separation(catalyst: npa.Image) -> None:
    verify_hash(
        CRYSTAL_CARGO,
        CRYSTAL_CARGO_SHA256,
        "L4-A crystal cargo",
    )
    crystal = npa.load_png(CRYSTAL_CARGO)
    if (crystal.width, crystal.height) != (10, 12):
        raise ValueError(
            "unexpected L4-A crystal cargo size: "
            f"{crystal.width}x{crystal.height}"
        )
    if not catalyst.width > catalyst.height:
        raise ValueError("L5-A catalyst cargo must retain a horizontal profile")
    if not crystal.height > crystal.width:
        raise ValueError("L4-A crystal cargo lost its vertical profile")
    if count_color(crystal, AMBER):
        raise ValueError("L4-A crystal cargo unexpectedly uses catalyst amber")
    if count_cyan_identity_pixels(crystal) < 20:
        raise ValueError("L4-A crystal cargo lost its crystal-cyan identity")


def main() -> int:
    os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    verify_hash(SOURCE, SOURCE_SHA256, "reviewed L5-A source")
    catalyst = npa.load_png(SOURCE)
    validate_catalyst(catalyst)
    validate_crystal_separation(catalyst)

    os.makedirs(os.path.dirname(OUTPUT), exist_ok=True)
    npa.save_png(OUTPUT, catalyst)
    verify_hash(OUTPUT, OUTPUT_SHA256, "L5-A runtime output")

    print(
        "L5-A catalyst cargo normalized:",
        f"{catalyst.width}x{catalyst.height}",
        f"opaque={len(opaque_pixels(catalyst))}",
        f"colors={len(PALETTE)}",
        f"amber={count_color(catalyst, AMBER)}px",
        f"sha256={OUTPUT_SHA256}",
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        raise SystemExit(1)
