#!/usr/bin/env python3
"""Derive two fixed pixel overlays for the L5 reactor processing state."""

from __future__ import annotations

import hashlib
import os
import sys

import normalize_pixel_asset as npa


OUTPUTS = {
    "client/assets/sprites/slice/reactor_processing_pulse_a.png": {
        "deep": [
            (3, 1), (4, 1), (5, 1), (6, 1), (7, 1), (8, 1),
            (2, 2), (9, 2), (2, 3), (9, 3), (2, 4), (9, 4),
            (3, 5), (4, 5), (5, 5), (6, 5), (7, 5), (8, 5),
        ],
        "teal": [
            (4, 2), (5, 2), (6, 2), (7, 2),
            (3, 3), (8, 3), (4, 4), (7, 4),
        ],
        "amber": [(5, 3), (6, 3), (5, 4), (6, 4)],
    },
    "client/assets/sprites/slice/reactor_processing_pulse_b.png": {
        "deep": [
            (3, 0), (4, 0), (5, 0), (6, 0), (7, 0), (8, 0),
            (1, 2), (10, 2), (1, 3), (10, 3),
            (2, 5), (9, 5), (3, 6), (4, 6), (5, 6),
            (6, 6), (7, 6), (8, 6),
        ],
        "teal": [
            (3, 1), (8, 1), (2, 2), (9, 2),
            (2, 3), (9, 3), (3, 5), (8, 5),
        ],
        "amber": [
            (4, 2), (5, 2), (6, 2), (7, 2),
            (4, 3), (7, 3), (4, 4), (5, 4), (6, 4), (7, 4),
        ],
    },
}

COLORS = {
    "deep": (*npa.STANDARD_PALETTE["shadow_deep"], 255),
    "teal": (*npa.STANDARD_PALETTE["energy_teal"], 255),
    "amber": (*npa.STANDARD_PALETTE["amber_lamp"], 255),
}
SIZE = (12, 7)
EXPECTED_SHA256 = {
    "client/assets/sprites/slice/reactor_processing_pulse_a.png":
        "892c6d1579cd5816ceddafb279381a9a57b701b027b71d34a6107a576c81fd1d",
    "client/assets/sprites/slice/reactor_processing_pulse_b.png":
        "e378b0d82caf20024a699080860409fa23b2dee3043cba0cde6dfd01b3f55add",
}


def sha256(path: str) -> str:
    with open(path, "rb") as handle:
        return hashlib.sha256(handle.read()).hexdigest()


def derive(path: str, pixels: dict[str, list[tuple[int, int]]]) -> None:
    image = npa.Image.blank(*SIZE)
    occupied: set[tuple[int, int]] = set()
    for color_name, points in pixels.items():
        for point in points:
            if point in occupied:
                raise ValueError(f"{path}: overlapping pixel {point}")
            x, y = point
            if not (0 <= x < SIZE[0] and 0 <= y < SIZE[1]):
                raise ValueError(f"{path}: pixel outside overlay {point}")
            image.put(x, y, COLORS[color_name])
            occupied.add(point)
    if len(occupied) < 28:
        raise ValueError(f"{path}: processing pulse is too sparse")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    npa.save_png(path, image)


def main() -> int:
    os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    for path, pixels in OUTPUTS.items():
        derive(path, pixels)
        digest = sha256(path)
        if digest != EXPECTED_SHA256[path]:
            raise ValueError(f"{path}: unexpected derived hash {digest}")
        print(
            "L5-B processing overlay derived:",
            path,
            f"{SIZE[0]}x{SIZE[1]}",
            f"sha256={digest}",
        )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        raise SystemExit(1)
