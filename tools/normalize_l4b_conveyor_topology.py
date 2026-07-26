#!/usr/bin/env python3
"""Derive fixed L4-B conveyor turn and storage-endpoint frames.

The four reviewed L3-C straight frames remain immutable. This driver
hash-locks them, preserves their chassis and output rollers, and replaces only
the belt-bed pixels needed for eight orthogonal turns. Storage source / sink
endpoints are full fixed frames with a cyan intake collar or amber delivery
collar. Runtime code selects these PNGs; it never rotates or draws track art.
"""

from __future__ import annotations

import hashlib
import os
import sys

import normalize_pixel_asset as npa


DIRECTIONS = {
    "up": (0, -1),
    "right": (1, 0),
    "down": (0, 1),
    "left": (-1, 0),
}
OPPOSITE = {
    "up": "down",
    "right": "left",
    "down": "up",
    "left": "right",
}
STRAIGHT_PATHS = {
    "up": "client/assets/sprites/slice/conveyor_up.png",
    "right": "client/assets/sprites/slice/conveyor_right.png",
    "down": "client/assets/sprites/slice/conveyor_down.png",
    "left": "client/assets/sprites/slice/conveyor_left.png",
}
STRAIGHT_HASHES = {
    "up": "2e235947899c4b396c61368c802451571b6dd16d6649a1b455eae959e57e4260",
    "right": "1b4ee1cb28909aa7a20c195aa22ba3c73009e84beb4181e8c432bfc7c7ccdf89",
    "down": "8eb0bc61671a6cbf218c2119f43b186e000b20ab23d1eb364172ff40606a3ac3",
    "left": "d69f24e3b3263326ce958ec722d329687f7d033ea6d86d4ee57edecd8e45a586",
}
OUTPUT_DIR = "client/assets/sprites/slice"
PREVIEW = (
    "assets/art-intake/2026-07-25-l4b-preview/"
    "conveyor_topology_contact_sheet.png"
)
MERGE_PREVIEW = (
    "assets/art-intake/2026-07-25-l4b-preview/"
    "conveyor_merge_contact_sheet.png"
)

FRAME_SIZE = 32
CENTER = (15, 15)
EDGE_CENTER = {
    "up": (15, 2),
    "right": (29, 15),
    "down": (15, 29),
    "left": (2, 15),
}

SHADOW = (*npa.STANDARD_PALETTE["shadow_deep"], 255)
METAL = (*npa.STANDARD_PALETTE["metal_mid"], 255)
HIGHLIGHT = (*npa.STANDARD_PALETTE["metal_highlight"], 255)
CYAN = (*npa.STANDARD_PALETTE["crystal_cyan"], 255)
AMBER = (*npa.STANDARD_PALETTE["amber_lamp"], 255)
BELT_DARK = (38, 45, 45, 255)
BELT_MID = (71, 78, 75, 255)
CHASSIS = (46, 65, 69, 255)
PLATFORM = (111, 107, 94, 255)


def clone(image: npa.Image) -> npa.Image:
    return npa.Image(image.width, image.height, bytearray(image.data))


def load_straights() -> dict[str, npa.Image]:
    frames = {}
    for direction, path in STRAIGHT_PATHS.items():
        with open(path, "rb") as handle:
            digest = hashlib.sha256(handle.read()).hexdigest()
        if digest != STRAIGHT_HASHES[direction]:
            raise ValueError(
                f"unexpected {direction} straight conveyor hash: {digest}"
            )
        image = npa.load_png(path)
        if (image.width, image.height) != (FRAME_SIZE, FRAME_SIZE):
            raise ValueError(
                f"unexpected {direction} frame size: "
                f"{image.width}x{image.height}"
            )
        frames[direction] = image
    return frames


def in_bounds(x: int, y: int) -> bool:
    return 0 <= x < FRAME_SIZE and 0 <= y < FRAME_SIZE


def put(image: npa.Image, x: int, y: int, color: tuple[int, ...]) -> None:
    if in_bounds(x, y):
        image.put(x, y, color)


def rect(
    image: npa.Image,
    left: int,
    top: int,
    right: int,
    bottom: int,
    color: tuple[int, ...],
) -> None:
    for y in range(top, bottom + 1):
        for x in range(left, right + 1):
            put(image, x, y, color)


def side_bar(
    image: npa.Image,
    direction: str,
    outer: tuple[int, ...],
    inner: tuple[int, ...],
) -> None:
    if direction == "up":
        rect(image, 10, 1, 20, 3, outer)
        rect(image, 12, 2, 18, 3, inner)
    elif direction == "right":
        rect(image, 28, 10, 30, 20, outer)
        rect(image, 28, 12, 29, 18, inner)
    elif direction == "down":
        rect(image, 10, 27, 20, 30, outer)
        rect(image, 12, 27, 18, 29, inner)
    else:
        rect(image, 1, 10, 3, 20, outer)
        rect(image, 2, 12, 3, 18, inner)


def distance_to_segment(
    x: int,
    y: int,
    start: tuple[int, int],
    finish: tuple[int, int],
) -> int:
    x0, y0 = start
    x1, y1 = finish
    if x0 == x1:
        return abs(x - x0) + max(0, min(y0, y1) - y, y - max(y0, y1))
    return abs(y - y0) + max(0, min(x0, x1) - x, x - max(x0, x1))


def route_distance(x: int, y: int, entry: str, output: str) -> int:
    return min(
        distance_to_segment(x, y, EDGE_CENTER[entry], CENTER),
        distance_to_segment(x, y, CENTER, EDGE_CENTER[output]),
    )


def clear_belt_bed(image: npa.Image) -> None:
    for y in range(4, 27):
        for x in range(4, 27):
            image.put(x, y, CHASSIS)
    rect(image, 6, 6, 25, 25, SHADOW)


def draw_turn_bed(image: npa.Image, entry: str, output: str) -> None:
    clear_belt_bed(image)
    for y in range(1, 31):
        for x in range(1, 31):
            distance = route_distance(x, y, entry, output)
            if distance <= 8:
                image.put(x, y, METAL)
            if distance <= 6:
                image.put(x, y, BELT_MID)
            if distance <= 4:
                image.put(x, y, BELT_DARK)

    # Two fixed ribs on each leg keep the path mechanical at 32px.
    entry_x, entry_y = DIRECTIONS[entry]
    output_x, output_y = DIRECTIONS[output]
    for offset in (5, 9):
        rib_x = CENTER[0] + entry_x * offset
        rib_y = CENTER[1] + entry_y * offset
        draw_cross_rib(image, rib_x, rib_y, entry, PLATFORM)
    for offset in (5, 9):
        rib_x = CENTER[0] + output_x * offset
        rib_y = CENTER[1] + output_y * offset
        draw_cross_rib(image, rib_x, rib_y, output, PLATFORM)

    # A three-pixel elbow bearing prevents the two legs reading as an overlap.
    rect(image, 14, 14, 16, 16, HIGHLIGHT)
    put(image, 15, 15, SHADOW)
    side_bar(image, entry, METAL, CYAN)
    side_bar(image, output, PLATFORM, AMBER)
    draw_chevron(image, output, 7)


def draw_merge_bed(
    image: npa.Image,
    entries: tuple[str, ...],
    output: str,
) -> None:
    clear_belt_bed(image)
    segments = [(EDGE_CENTER[entry], CENTER) for entry in entries]
    segments.append((CENTER, EDGE_CENTER[output]))
    for y in range(1, 31):
        for x in range(1, 31):
            distance = min(
                distance_to_segment(x, y, start, finish)
                for start, finish in segments
            )
            if distance <= 8:
                image.put(x, y, METAL)
            if distance <= 6:
                image.put(x, y, BELT_MID)
            if distance <= 4:
                image.put(x, y, BELT_DARK)

    for entry in entries:
        entry_x, entry_y = DIRECTIONS[entry]
        for offset in (5, 9):
            draw_cross_rib(
                image,
                CENTER[0] + entry_x * offset,
                CENTER[1] + entry_y * offset,
                entry,
                PLATFORM,
            )
        side_bar(image, entry, METAL, CYAN)

    output_x, output_y = DIRECTIONS[output]
    for offset in (5, 9):
        draw_cross_rib(
            image,
            CENTER[0] + output_x * offset,
            CENTER[1] + output_y * offset,
            output,
            PLATFORM,
        )
    rect(image, 13, 13, 17, 17, HIGHLIGHT)
    rect(image, 14, 14, 16, 16, METAL)
    put(image, 15, 15, SHADOW)
    side_bar(image, output, PLATFORM, AMBER)
    draw_chevron(image, output, 7)


def draw_cross_rib(
    image: npa.Image,
    center_x: int,
    center_y: int,
    travel: str,
    color: tuple[int, ...],
) -> None:
    dx, dy = DIRECTIONS[travel]
    perpendicular = (-dy, dx)
    for offset in range(-3, 4):
        put(
            image,
            center_x + perpendicular[0] * offset,
            center_y + perpendicular[1] * offset,
            color,
        )


def draw_chevron(image: npa.Image, output: str, distance: int) -> None:
    dx, dy = DIRECTIONS[output]
    perpendicular = (-dy, dx)
    tip_x = CENTER[0] + dx * distance
    tip_y = CENTER[1] + dy * distance
    for depth in range(4):
        base_x = tip_x - dx * depth
        base_y = tip_y - dy * depth
        spread = min(depth, 2)
        put(
            image,
            base_x + perpendicular[0] * spread,
            base_y + perpendicular[1] * spread,
            HIGHLIGHT,
        )
        put(
            image,
            base_x - perpendicular[0] * spread,
            base_y - perpendicular[1] * spread,
            HIGHLIGHT,
        )


def derive_turns(straights: dict[str, npa.Image]) -> dict[str, npa.Image]:
    result = {}
    for output in DIRECTIONS:
        for entry in DIRECTIONS:
            if entry in (output, OPPOSITE[output]):
                continue
            image = clone(straights[output])
            draw_turn_bed(image, entry, output)
            result[f"in_{entry}_out_{output}"] = image
    return result


def derive_endpoints(
    straights: dict[str, npa.Image],
) -> dict[str, npa.Image]:
    result = {}
    for output, straight in straights.items():
        entry = OPPOSITE[output]
        source = clone(straight)
        side_bar(source, entry, METAL, CYAN)
        draw_chevron(source, output, 7)
        result[f"source_{output}"] = source

        sink = clone(straight)
        side_bar(sink, output, PLATFORM, AMBER)
        draw_chevron(sink, output, 7)
        result[f"sink_{output}"] = sink
    return result


def derive_merges(straights: dict[str, npa.Image]) -> dict[str, npa.Image]:
    result = {}
    direction_names = tuple(DIRECTIONS)
    for output in direction_names:
        entries = [
            direction
            for direction in direction_names
            if direction != output
        ]
        combinations = [
            (entries[0], entries[1]),
            (entries[0], entries[2]),
            (entries[1], entries[2]),
            tuple(entries),
        ]
        for selected in combinations:
            image = clone(straights[output])
            draw_merge_bed(image, selected, output)
            input_label = "_".join(selected)
            result[f"merge_in_{input_label}_out_{output}"] = image
    return result


def alpha_bounds(image: npa.Image) -> tuple[int, int, int, int]:
    pixels = [
        (x, y)
        for y in range(image.height)
        for x in range(image.width)
        if image.pixel(x, y)[3]
    ]
    if not pixels:
        raise ValueError("derived conveyor frame is empty")
    xs = [x for x, _ in pixels]
    ys = [y for _, y in pixels]
    return min(xs), min(ys), max(xs), max(ys)


def validate(
    turns: dict[str, npa.Image],
    endpoints: dict[str, npa.Image],
    merges: dict[str, npa.Image],
) -> None:
    if len(turns) != 8:
        raise ValueError(f"expected 8 turn frames, found {len(turns)}")
    if len(endpoints) != 8:
        raise ValueError(f"expected 8 endpoint frames, found {len(endpoints)}")
    if len(merges) != 16:
        raise ValueError(f"expected 16 merge frames, found {len(merges)}")
    fingerprints = set()
    for name, image in {**turns, **endpoints, **merges}.items():
        if (image.width, image.height) != (FRAME_SIZE, FRAME_SIZE):
            raise ValueError(f"{name} is not 32x32")
        bounds = alpha_bounds(image)
        if bounds[0] > 3 or bounds[1] > 3 or bounds[2] < 28 or bounds[3] < 28:
            raise ValueError(f"{name} lost its one-cell footprint: {bounds}")
        colors = {
            image.pixel(x, y)
            for y in range(FRAME_SIZE)
            for x in range(FRAME_SIZE)
            if image.pixel(x, y)[3]
        }
        if AMBER not in colors:
            raise ValueError(f"{name} lost amber output semantics")
        if not name.startswith("sink_") and CYAN not in colors:
            raise ValueError(f"{name} lost cyan input semantics")
        fingerprints.add(hashlib.sha256(image.data).hexdigest())
    if len(fingerprints) != 32:
        raise ValueError("derived topology frames are not all distinct")


def paste(
    target: npa.Image,
    source: npa.Image,
    left: int,
    top: int,
) -> None:
    for y in range(source.height):
        for x in range(source.width):
            color = source.pixel(x, y)
            if color[3]:
                target.put(left + x, top + y, color)


def write_preview(
    turns: dict[str, npa.Image],
    endpoints: dict[str, npa.Image],
) -> None:
    panel = npa.Image.blank(288, 168)
    for y in range(panel.height):
        for x in range(panel.width):
            panel.put(x, y, SHADOW)

    ordered_turns = [
        "in_left_out_up",
        "in_right_out_up",
        "in_up_out_right",
        "in_down_out_right",
        "in_left_out_down",
        "in_right_out_down",
        "in_up_out_left",
        "in_down_out_left",
    ]
    for index, name in enumerate(ordered_turns):
        paste(panel, turns[name], 8 + index * 35, 8)

    ordered_sources = [f"source_{direction}" for direction in DIRECTIONS]
    ordered_sinks = [f"sink_{direction}" for direction in DIRECTIONS]
    for index, name in enumerate(ordered_sources):
        paste(panel, endpoints[name], 38 + index * 56, 64)
    for index, name in enumerate(ordered_sinks):
        paste(panel, endpoints[name], 38 + index * 56, 112)

    os.makedirs(os.path.dirname(PREVIEW), exist_ok=True)
    npa.save_png(PREVIEW, npa.upscale_nearest(panel, 4), with_alpha=False)


def write_merge_preview(merges: dict[str, npa.Image]) -> None:
    panel = npa.Image.blank(176, 176)
    for y in range(panel.height):
        for x in range(panel.width):
            panel.put(x, y, SHADOW)
    for row, output in enumerate(DIRECTIONS):
        names = [
            name
            for name in merges
            if name.endswith(f"_out_{output}")
        ]
        for column, name in enumerate(names):
            paste(panel, merges[name], 8 + column * 42, 8 + row * 42)
    os.makedirs(os.path.dirname(MERGE_PREVIEW), exist_ok=True)
    npa.save_png(
        MERGE_PREVIEW,
        npa.upscale_nearest(panel, 4),
        with_alpha=False,
    )


def write_frames(
    turns: dict[str, npa.Image],
    endpoints: dict[str, npa.Image],
    merges: dict[str, npa.Image],
) -> None:
    for name, image in {**turns, **endpoints, **merges}.items():
        path = os.path.join(OUTPUT_DIR, f"conveyor_{name}.png")
        npa.save_png(path, image)


def main() -> int:
    straights = load_straights()
    turns = derive_turns(straights)
    endpoints = derive_endpoints(straights)
    merges = derive_merges(straights)
    validate(turns, endpoints, merges)
    write_frames(turns, endpoints, merges)
    write_preview(turns, endpoints)
    write_merge_preview(merges)

    for name in {**turns, **endpoints, **merges}:
        path = os.path.join(OUTPUT_DIR, f"conveyor_{name}.png")
        with open(path, "rb") as handle:
            digest = hashlib.sha256(handle.read()).hexdigest()
        print(f"{path}: 32x32 RGBA, SHA-256 {digest}")
    print(f"QA preview: {PREVIEW}")
    print(f"Merge QA preview: {MERGE_PREVIEW}")
    return 0


if __name__ == "__main__":
    tool_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(os.path.join(tool_dir, ".."))
    sys.path.insert(0, tool_dir)
    raise SystemExit(main())
