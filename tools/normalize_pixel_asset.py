#!/usr/bin/env python3
"""Normalize AI pixel-art intake PNGs into grid/palette-conformant client assets.

Zero-dependency (Python stdlib only). Implements the repo pixel pipeline step
"仓库侧归一" from docs/reference/pixel-art-and-grid-standard.md:

- integer block downscale (per-block per-channel median, no interpolation)
- near-black background removal (border flood fill + enclosed holes)
- limited palette quantization (median cut, capped color count,
  snapped onto the standard world-palette anchors when close)
- ground macroblock output (128x128 = 4x4 tiles of 32px)
- horizontal multi-object sheet splitting (core states, walk frames, clusters)
- brightness matching against a reference asset (walk sheet -> d1 baseline)

CLI is for inspection and one-off runs; batch processing for a pack lives in a
driver script (see tools/normalize_slice_pack1.py) that imports this module.
"""

from __future__ import annotations

import argparse
import struct
import sys
import zlib
from collections import deque

# Standard world palette anchors, docs/reference/pixel-art-and-grid-standard.md
STANDARD_PALETTE = {
    "sand_light": (0xA9, 0x95, 0x72),
    "shadow_deep": (0x15, 0x1C, 0x1E),
    "platform_warm_gray": (0x6F, 0x6B, 0x5E),
    "metal_mid": (0x2E, 0x41, 0x45),
    "metal_highlight": (0x4A, 0x61, 0x65),
    "energy_teal": (0x56, 0xC8, 0xC4),
    "crystal_cyan": (0x7F, 0xD8, 0xE8),
    "amber_lamp": (0xE0, 0xA4, 0x3C),
    "alert_red": (0xC7, 0x50, 0x3F),
    "pollution_olive": (0xB7, 0xB6, 0x46),
}


class Image:
    """Flat RGBA byte buffer with width/height."""

    def __init__(self, width: int, height: int, data: bytearray):
        assert len(data) == width * height * 4
        self.width = width
        self.height = height
        self.data = data

    @classmethod
    def blank(cls, width: int, height: int) -> "Image":
        return cls(width, height, bytearray(width * height * 4))

    def pixel(self, x: int, y: int) -> tuple[int, int, int, int]:
        i = (y * self.width + x) * 4
        d = self.data
        return d[i], d[i + 1], d[i + 2], d[i + 3]

    def put(self, x: int, y: int, rgba: tuple[int, int, int, int]) -> None:
        i = (y * self.width + x) * 4
        self.data[i : i + 4] = bytes(rgba)


def _paeth(a: int, b: int, c: int) -> int:
    p = a + b - c
    pa = abs(p - a)
    pb = abs(p - b)
    pc = abs(p - c)
    if pa <= pb and pa <= pc:
        return a
    if pb <= pc:
        return b
    return c


def load_png(path: str) -> Image:
    """Decode an 8-bit non-interlaced grayscale/RGB/RGBA/palette PNG."""
    with open(path, "rb") as fh:
        blob = fh.read()
    if blob[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError(f"{path}: not a PNG file")
    pos = 8
    width = height = 0
    bit_depth = color_type = interlace = 0
    palette: list[tuple[int, int, int]] = []
    trns = b""
    idat = bytearray()
    while pos < len(blob):
        length = struct.unpack(">I", blob[pos : pos + 4])[0]
        ctype = blob[pos + 4 : pos + 8]
        body = blob[pos + 8 : pos + 8 + length]
        pos += 12 + length
        if ctype == b"IHDR":
            width, height, bit_depth, color_type, _, _, interlace = struct.unpack(
                ">IIBBBBB", body
            )
        elif ctype == b"PLTE":
            palette = [tuple(body[i : i + 3]) for i in range(0, len(body), 3)]
        elif ctype == b"tRNS":
            trns = bytes(body)
        elif ctype == b"IDAT":
            idat.extend(body)
        elif ctype == b"IEND":
            break
    if bit_depth != 8:
        raise ValueError(f"{path}: unsupported bit depth {bit_depth}")
    if interlace != 0:
        raise ValueError(f"{path}: interlaced PNG not supported")
    channels = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}.get(color_type)
    if channels is None:
        raise ValueError(f"{path}: unsupported color type {color_type}")

    raw = zlib.decompress(bytes(idat))
    stride = width * channels
    out = bytearray(height * stride)
    prev = bytearray(stride)
    src = 0
    for y in range(height):
        ftype = raw[src]
        src += 1
        row = bytearray(raw[src : src + stride])
        src += stride
        if ftype == 1:  # Sub
            for i in range(channels, stride):
                row[i] = (row[i] + row[i - channels]) & 0xFF
        elif ftype == 2:  # Up
            for i in range(stride):
                row[i] = (row[i] + prev[i]) & 0xFF
        elif ftype == 3:  # Average
            for i in range(stride):
                left = row[i - channels] if i >= channels else 0
                row[i] = (row[i] + ((left + prev[i]) >> 1)) & 0xFF
        elif ftype == 4:  # Paeth
            for i in range(stride):
                left = row[i - channels] if i >= channels else 0
                up_left = prev[i - channels] if i >= channels else 0
                row[i] = (row[i] + _paeth(left, prev[i], up_left)) & 0xFF
        elif ftype != 0:
            raise ValueError(f"{path}: unknown filter type {ftype}")
        out[y * stride : (y + 1) * stride] = row
        prev = row

    rgba = bytearray(width * height * 4)
    if color_type == 6:
        rgba[:] = out
    elif color_type == 2:
        for i in range(width * height):
            rgba[i * 4 : i * 4 + 3] = out[i * 3 : i * 3 + 3]
            rgba[i * 4 + 3] = 255
    elif color_type == 0:
        for i in range(width * height):
            g = out[i]
            rgba[i * 4 : i * 4 + 4] = bytes((g, g, g, 255))
    elif color_type == 4:
        for i in range(width * height):
            g = out[i * 2]
            rgba[i * 4 : i * 4 + 4] = bytes((g, g, g, out[i * 2 + 1]))
    else:  # palette
        for i in range(width * height):
            r, g, b = palette[out[i]]
            alpha = trns[out[i]] if out[i] < len(trns) else 255
            rgba[i * 4 : i * 4 + 4] = bytes((r, g, b, alpha))
    return Image(width, height, rgba)


def save_png(path: str, img: Image, with_alpha: bool = True) -> None:
    """Encode as 8-bit RGBA (or RGB when with_alpha=False), filter 0 rows."""
    channels = 4 if with_alpha else 3
    stride = img.width * channels
    raw = bytearray((stride + 1) * img.height)
    for y in range(img.height):
        base = y * (stride + 1)
        raw[base] = 0
        src = y * img.width * 4
        if with_alpha:
            raw[base + 1 : base + 1 + stride] = img.data[src : src + stride]
        else:
            row = raw
            for x in range(img.width):
                s = src + x * 4
                d = base + 1 + x * 3
                row[d : d + 3] = img.data[s : s + 3]

    def chunk(ctype: bytes, body: bytes) -> bytes:
        return (
            struct.pack(">I", len(body))
            + ctype
            + body
            + struct.pack(">I", zlib.crc32(ctype + body) & 0xFFFFFFFF)
        )

    color_type = 6 if with_alpha else 2
    ihdr = struct.pack(">IIBBBBB", img.width, img.height, 8, color_type, 0, 0, 0)
    payload = zlib.compress(bytes(raw), 9)
    with open(path, "wb") as fh:
        fh.write(b"\x89PNG\r\n\x1a\n")
        fh.write(chunk(b"IHDR", ihdr))
        fh.write(chunk(b"IDAT", payload))
        fh.write(chunk(b"IEND", b""))


# ---------------------------------------------------------------------------
# Background removal


def estimate_background(img: Image, ring: int = 4) -> tuple[int, int, int]:
    """Median RGB of the outer border ring."""
    rs: list[int] = []
    gs: list[int] = []
    bs: list[int] = []
    w, h = img.width, img.height
    for y in range(h):
        if ring <= y < h - ring:
            xs: tuple[range, ...] = (range(ring), range(w - ring, w))
        else:
            xs = (range(w),)
        for xr in xs:
            for x in xr:
                r, g, b, _ = img.pixel(x, y)
                rs.append(r)
                gs.append(g)
                bs.append(b)
    rs.sort()
    gs.sort()
    bs.sort()
    mid = len(rs) // 2
    return rs[mid], gs[mid], bs[mid]


def _dist_sq(c1: tuple[int, int, int], c2: tuple[int, int, int]) -> int:
    return (c1[0] - c2[0]) ** 2 + (c1[1] - c2[1]) ** 2 + (c1[2] - c2[2]) ** 2


def build_background_mask(
    img: Image,
    bg: tuple[int, int, int],
    tol_edge: int,
    tol_hole: int,
    min_hole: int,
) -> bytearray:
    """1 = background pixel. Flood fill from borders, then enclosed bg holes.

    tol_edge / tol_hole are euclidean RGB distances; holes only count when a
    connected bg-colored region has at least min_hole pixels, so dark shading
    inside a sprite is not punched out.
    """
    w, h = img.width, img.height
    data = img.data
    n = w * h
    edge_sq = tol_edge * tol_edge
    hole_sq = tol_hole * tol_hole
    bg_r, bg_g, bg_b = bg

    def is_bg_like(idx: int, limit_sq: int) -> bool:
        base = idx * 4
        dr = data[base] - bg_r
        dg = data[base + 1] - bg_g
        db = data[base + 2] - bg_b
        return dr * dr + dg * dg + db * db <= limit_sq

    mask = bytearray(n)
    queue: deque[int] = deque()
    for x in range(w):
        for idx in (x, (h - 1) * w + x):
            if not mask[idx] and is_bg_like(idx, edge_sq):
                mask[idx] = 1
                queue.append(idx)
    for y in range(h):
        for idx in (y * w, y * w + w - 1):
            if not mask[idx] and is_bg_like(idx, edge_sq):
                mask[idx] = 1
                queue.append(idx)
    while queue:
        idx = queue.popleft()
        x = idx % w
        if x > 0 and not mask[idx - 1] and is_bg_like(idx - 1, edge_sq):
            mask[idx - 1] = 1
            queue.append(idx - 1)
        if x < w - 1 and not mask[idx + 1] and is_bg_like(idx + 1, edge_sq):
            mask[idx + 1] = 1
            queue.append(idx + 1)
        if idx >= w and not mask[idx - w] and is_bg_like(idx - w, edge_sq):
            mask[idx - w] = 1
            queue.append(idx - w)
        if idx < n - w and not mask[idx + w] and is_bg_like(idx + w, edge_sq):
            mask[idx + w] = 1
            queue.append(idx + w)

    # Enclosed holes: connected bg-colored regions not reached from the border.
    seen = bytearray(n)
    for start in range(n):
        if mask[start] or seen[start] or not is_bg_like(start, hole_sq):
            continue
        component = [start]
        seen[start] = 1
        queue.append(start)
        while queue:
            idx = queue.popleft()
            x = idx % w
            for nb in (idx - 1, idx + 1, idx - w, idx + w):
                if nb < 0 or nb >= n:
                    continue
                if abs(nb % w - x) > 1:
                    continue
                if mask[nb] or seen[nb] or not is_bg_like(nb, hole_sq):
                    continue
                seen[nb] = 1
                component.append(nb)
                queue.append(nb)
        if len(component) >= min_hole:
            for idx in component:
                mask[idx] = 1
    return mask


def content_bbox(mask: bytearray, width: int, height: int) -> tuple[int, int, int, int]:
    """(x0, y0, x1, y1) inclusive bounds of non-background pixels."""
    x0, y0, x1, y1 = width, height, -1, -1
    for y in range(height):
        row = y * width
        for x in range(width):
            if not mask[row + x]:
                if x < x0:
                    x0 = x
                if x > x1:
                    x1 = x
                if y < y0:
                    y0 = y
                if y > y1:
                    y1 = y
    if x1 < 0:
        raise ValueError("no content pixels found")
    return x0, y0, x1, y1


def bbox_in_columns(
    mask: bytearray, width: int, height: int, x0: int, x1: int
) -> tuple[int, int, int, int]:
    """Content bbox restricted to an inclusive column range (sheet objects)."""
    bx0, by0, bx1, by1 = x1 + 1, height, -1, -1
    for y in range(height):
        row = y * width
        for x in range(x0, x1 + 1):
            if not mask[row + x]:
                if x < bx0:
                    bx0 = x
                if x > bx1:
                    bx1 = x
                if y < by0:
                    by0 = y
                if y > by1:
                    by1 = y
    if bx1 < 0:
        raise ValueError(f"no content pixels in columns {x0}..{x1}")
    return bx0, by0, bx1, by1


def content_columns(
    mask: bytearray, width: int, height: int, gap: int
) -> list[tuple[int, int]]:
    """Merge x-projection runs of content separated by < gap background cols."""
    has_content = [False] * width
    for y in range(height):
        row = y * width
        for x in range(width):
            if not mask[row + x]:
                has_content[x] = True
    runs: list[list[int]] = []
    for x, filled in enumerate(has_content):
        if not filled:
            continue
        if runs and x - runs[-1][1] <= gap:
            runs[-1][1] = x
        else:
            runs.append([x, x])
    return [(a, b) for a, b in runs]


# ---------------------------------------------------------------------------
# Downscale


def downscale_sprite(
    img: Image,
    mask: bytearray,
    bbox: tuple[int, int, int, int],
    factor: int,
    coverage: float = 0.5,
) -> Image:
    """Integer-block downscale. Cell opaque when non-bg coverage >= threshold;
    cell color is the per-channel median of its non-bg source pixels.
    Grid is anchored at the bbox bottom-left so ground contact stays stable."""
    x0, y0, x1, y1 = bbox
    src_w = x1 - x0 + 1
    src_h = y1 - y0 + 1
    out_w = (src_w + factor - 1) // factor
    out_h = (src_h + factor - 1) // factor
    grid_x0 = x0
    grid_y0 = y1 + 1 - out_h * factor  # bottom-anchored, may pad above bbox
    out = Image.blank(out_w, out_h)
    w, h = img.width, img.height
    data = img.data
    for cy in range(out_h):
        sy0 = grid_y0 + cy * factor
        for cx in range(out_w):
            sx0 = grid_x0 + cx * factor
            rs: list[int] = []
            gs: list[int] = []
            bs: list[int] = []
            total = 0
            for sy in range(max(sy0, 0), min(sy0 + factor, h)):
                row = sy * w
                for sx in range(max(sx0, 0), min(sx0 + factor, w)):
                    total += 1
                    if mask[row + sx]:
                        continue
                    base = (row + sx) * 4
                    rs.append(data[base])
                    gs.append(data[base + 1])
                    bs.append(data[base + 2])
            if total == 0 or len(rs) / total < coverage:
                continue
            rs.sort()
            gs.sort()
            bs.sort()
            mid = len(rs) // 2
            out.put(cx, cy, (rs[mid], gs[mid], bs[mid], 255))
    return out


def downscale_tile(img: Image, out_size: int) -> Image:
    """Full-coverage block downscale of a ground texture to out_size x out_size.

    Block edges follow floor(i * src / out) so the whole source is consumed and
    the wrap-around seam behaviour of the source texture is preserved."""
    w, h = img.width, img.height
    xs = [i * w // out_size for i in range(out_size + 1)]
    ys = [i * h // out_size for i in range(out_size + 1)]
    out = Image.blank(out_size, out_size)
    data = img.data
    for cy in range(out_size):
        for cx in range(out_size):
            rs: list[int] = []
            gs: list[int] = []
            bs: list[int] = []
            for sy in range(ys[cy], ys[cy + 1]):
                row = sy * w
                for sx in range(xs[cx], xs[cx + 1]):
                    base = (row + sx) * 4
                    rs.append(data[base])
                    gs.append(data[base + 1])
                    bs.append(data[base + 2])
            rs.sort()
            gs.sort()
            bs.sort()
            mid = len(rs) // 2
            out.put(cx, cy, (rs[mid], gs[mid], bs[mid], 255))
    return out


# ---------------------------------------------------------------------------
# Palette quantization


def opaque_colors(img: Image) -> list[tuple[int, int, int]]:
    colors = []
    data = img.data
    for i in range(img.width * img.height):
        base = i * 4
        if data[base + 3]:
            colors.append((data[base], data[base + 1], data[base + 2]))
    return colors


def median_cut(colors: list[tuple[int, int, int]], max_colors: int) -> list[tuple[int, int, int]]:
    boxes = [colors]
    while len(boxes) < max_colors:
        widest = None
        widest_range = 1  # boxes with a single color can not be split
        widest_channel = 0
        for box in boxes:
            for ch in range(3):
                values = [c[ch] for c in box]
                span = max(values) - min(values)
                if span >= widest_range:
                    widest = box
                    widest_range = span + 1
                    widest_channel = ch
        if widest is None:
            break
        widest.sort(key=lambda c: c[widest_channel])
        mid = len(widest) // 2
        boxes.remove(widest)
        boxes.append(widest[:mid])
        boxes.append(widest[mid:])
    palette = []
    for box in boxes:
        if not box:
            continue
        n = len(box)
        palette.append(
            (
                round(sum(c[0] for c in box) / n),
                round(sum(c[1] for c in box) / n),
                round(sum(c[2] for c in box) / n),
            )
        )
    return sorted(set(palette))


def snap_palette_to_anchors(
    palette: list[tuple[int, int, int]], snap_dist: int
) -> list[tuple[int, int, int]]:
    """Snap palette entries onto standard anchors when within snap_dist."""
    snapped = []
    limit_sq = snap_dist * snap_dist
    for color in palette:
        best = min(STANDARD_PALETTE.values(), key=lambda a: _dist_sq(a, color))
        snapped.append(best if _dist_sq(best, color) <= limit_sq else color)
    return sorted(set(snapped))


def apply_palette(img: Image, palette: list[tuple[int, int, int]]) -> None:
    cache: dict[tuple[int, int, int], tuple[int, int, int]] = {}
    data = img.data
    for i in range(img.width * img.height):
        base = i * 4
        if not data[base + 3]:
            continue
        color = (data[base], data[base + 1], data[base + 2])
        mapped = cache.get(color)
        if mapped is None:
            mapped = min(palette, key=lambda p: _dist_sq(p, color))
            cache[color] = mapped
        data[base : base + 3] = bytes(mapped)


# ---------------------------------------------------------------------------
# Brightness matching


def mean_luma(img: Image) -> float:
    total = 0.0
    count = 0
    data = img.data
    for i in range(img.width * img.height):
        base = i * 4
        if not data[base + 3]:
            continue
        total += 0.2126 * data[base] + 0.7152 * data[base + 1] + 0.0722 * data[base + 2]
        count += 1
    if count == 0:
        raise ValueError("no opaque pixels for luma measurement")
    return total / count


def apply_gain(img: Image, gain: float) -> None:
    data = img.data
    for i in range(img.width * img.height):
        base = i * 4
        if not data[base + 3]:
            continue
        for ch in range(3):
            data[base + ch] = min(255, round(data[base + ch] * gain))


# ---------------------------------------------------------------------------
# Composition helpers


def crop_to_content(img: Image) -> Image:
    x0, y0, x1, y1 = None, None, None, None
    for y in range(img.height):
        for x in range(img.width):
            if img.data[(y * img.width + x) * 4 + 3]:
                x0 = x if x0 is None else min(x0, x)
                x1 = x if x1 is None else max(x1, x)
                y0 = y if y0 is None else min(y0, y)
                y1 = y if y1 is None else max(y1, y)
    if x0 is None:
        raise ValueError("empty image")
    out = Image.blank(x1 - x0 + 1, y1 - y0 + 1)
    for y in range(out.height):
        src = ((y + y0) * img.width + x0) * 4
        dst = y * out.width * 4
        out.data[dst : dst + out.width * 4] = img.data[src : src + out.width * 4]
    return out


def place_in_box(img: Image, box_w: int, box_h: int) -> Image:
    """Bottom-center the sprite in a fixed frame box (for animation frames)."""
    if img.width > box_w or img.height > box_h:
        raise ValueError(
            f"content {img.width}x{img.height} exceeds frame box {box_w}x{box_h}"
        )
    out = Image.blank(box_w, box_h)
    off_x = (box_w - img.width) // 2
    off_y = box_h - img.height
    for y in range(img.height):
        src = y * img.width * 4
        dst = ((y + off_y) * box_w + off_x) * 4
        out.data[dst : dst + img.width * 4] = img.data[src : src + img.width * 4]
    return out


def tile_preview(img: Image, repeat: int = 2) -> Image:
    out = Image.blank(img.width * repeat, img.height * repeat)
    for ty in range(repeat):
        for tx in range(repeat):
            for y in range(img.height):
                src = y * img.width * 4
                dst = ((ty * img.height + y) * out.width + tx * img.width) * 4
                out.data[dst : dst + img.width * 4] = img.data[src : src + img.width * 4]
    return out


def upscale_nearest(img: Image, factor: int) -> Image:
    out = Image.blank(img.width * factor, img.height * factor)
    for y in range(img.height):
        row = bytearray()
        for x in range(img.width):
            row.extend(img.data[(y * img.width + x) * 4 : (y * img.width + x) * 4 + 4] * factor)
        for fy in range(factor):
            dst = (y * factor + fy) * out.width * 4
            out.data[dst : dst + len(row)] = row
    return out


def tile_seam_ratios(img: Image) -> tuple[float, float]:
    """Wrap-seam severity of a tileable texture: mean abs RGB diff across the
    horizontal / vertical wrap edge divided by the mean interior neighbour
    diff. Values near 1.0 mean the wrap seam is no stronger than the texture's
    own detail; values far above 1.0 flag a visible seam."""
    w, h = img.width, img.height
    data = img.data

    def px_diff(i1: int, i2: int) -> int:
        b1, b2 = i1 * 4, i2 * 4
        return (
            abs(data[b1] - data[b2])
            + abs(data[b1 + 1] - data[b2 + 1])
            + abs(data[b1 + 2] - data[b2 + 2])
        )

    interior = 0
    samples = 0
    for y in range(h):
        for x in range(w - 1):
            interior += px_diff(y * w + x, y * w + x + 1)
            samples += 1
    for y in range(h - 1):
        for x in range(w):
            interior += px_diff(y * w + x, (y + 1) * w + x)
            samples += 1
    interior_mean = interior / samples if samples else 1.0

    seam_x = sum(px_diff(y * w + w - 1, y * w) for y in range(h)) / h
    seam_y = sum(px_diff((h - 1) * w + x, x) for x in range(w)) / w
    if interior_mean == 0:
        return 0.0, 0.0
    return seam_x / interior_mean, seam_y / interior_mean


def color_report(img: Image, top: int = 8) -> list[str]:
    counts: dict[tuple[int, int, int], int] = {}
    data = img.data
    opaque = 0
    for i in range(img.width * img.height):
        base = i * 4
        if not data[base + 3]:
            continue
        opaque += 1
        color = (data[base], data[base + 1], data[base + 2])
        counts[color] = counts.get(color, 0) + 1
    lines = [f"distinct colors: {len(counts)} over {opaque} opaque px"]
    ranked = sorted(counts.items(), key=lambda kv: -kv[1])[:top]
    for color, count in ranked:
        name, anchor = min(
            STANDARD_PALETTE.items(), key=lambda kv: _dist_sq(kv[1], color)
        )
        dist = _dist_sq(anchor, color) ** 0.5
        lines.append(
            f"  #{color[0]:02X}{color[1]:02X}{color[2]:02X} x{count}"
            f" -> nearest anchor {name} (d={dist:.1f})"
        )
    return lines


# ---------------------------------------------------------------------------
# CLI (inspection / one-off use)


def cmd_inspect(args: argparse.Namespace) -> int:
    img = load_png(args.input)
    print(f"{args.input}: {img.width}x{img.height}")
    bg = estimate_background(img)
    print(f"border background median: #{bg[0]:02X}{bg[1]:02X}{bg[2]:02X} {bg}")
    hist = {tol: 0 for tol in (4, 8, 12, 16, 24, 32)}
    data = img.data
    for i in range(img.width * img.height):
        base = i * 4
        d = _dist_sq((data[base], data[base + 1], data[base + 2]), bg) ** 0.5
        for tol in hist:
            if d <= tol:
                hist[tol] += 1
    total = img.width * img.height
    for tol, count in hist.items():
        print(f"  px within dist {tol:>2} of bg: {count} ({100 * count / total:.1f}%)")
    mask = build_background_mask(img, bg, args.tol_edge, args.tol_hole, args.min_hole)
    bbox = content_bbox(mask, img.width, img.height)
    print(f"content bbox: x {bbox[0]}..{bbox[2]}  y {bbox[1]}..{bbox[3]}")
    print(f"  content size: {bbox[2] - bbox[0] + 1}x{bbox[3] - bbox[1] + 1}")
    runs = content_columns(mask, img.width, img.height, args.gap)
    print(f"content column runs (gap>{args.gap}): {runs}")
    return 0


def cmd_sprite(args: argparse.Namespace) -> int:
    img = load_png(args.input)
    bg = estimate_background(img)
    mask = build_background_mask(img, bg, args.tol_edge, args.tol_hole, args.min_hole)
    bbox = content_bbox(mask, img.width, img.height)
    src_h = bbox[3] - bbox[1] + 1
    factor = max(1, round(src_h / args.target_height))
    out = downscale_sprite(img, mask, bbox, factor)
    out = crop_to_content(out)
    palette = median_cut(opaque_colors(out), args.colors)
    palette = snap_palette_to_anchors(palette, args.snap_dist)
    apply_palette(out, palette)
    save_png(args.output, out)
    print(f"{args.output}: {out.width}x{out.height} (factor {factor})")
    for line in color_report(out):
        print(line)
    return 0


def cmd_tile(args: argparse.Namespace) -> int:
    img = load_png(args.input)
    out = downscale_tile(img, args.macro_size)
    palette = median_cut(opaque_colors(out), args.colors)
    palette = snap_palette_to_anchors(palette, args.snap_dist)
    apply_palette(out, palette)
    save_png(args.output, out, with_alpha=False)
    print(f"{args.output}: {out.width}x{out.height} macroblock")
    for line in color_report(out):
        print(line)
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)

    def common(p: argparse.ArgumentParser) -> None:
        p.add_argument("--input", required=True)
        p.add_argument("--tol-edge", type=int, default=10)
        p.add_argument("--tol-hole", type=int, default=6)
        p.add_argument("--min-hole", type=int, default=400)
        p.add_argument("--gap", type=int, default=40)

    p_inspect = sub.add_parser("inspect", help="print bg/bbox/column stats")
    common(p_inspect)
    p_inspect.set_defaults(func=cmd_inspect)

    p_sprite = sub.add_parser("sprite", help="normalize a single sprite")
    common(p_sprite)
    p_sprite.add_argument("--output", required=True)
    p_sprite.add_argument("--target-height", type=int, required=True)
    p_sprite.add_argument("--colors", type=int, default=32)
    p_sprite.add_argument("--snap-dist", type=int, default=24)
    p_sprite.set_defaults(func=cmd_sprite)

    p_tile = sub.add_parser("tile", help="normalize a ground macroblock")
    p_tile.add_argument("--input", required=True)
    p_tile.add_argument("--output", required=True)
    p_tile.add_argument("--macro-size", type=int, default=128)
    p_tile.add_argument("--colors", type=int, default=24)
    p_tile.add_argument("--snap-dist", type=int, default=24)
    p_tile.set_defaults(func=cmd_tile)
    return parser


def main(argv: list[str]) -> int:
    args = build_parser().parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
