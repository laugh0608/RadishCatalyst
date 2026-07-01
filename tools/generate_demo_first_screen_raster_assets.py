#!/usr/bin/env python3
"""Generate deterministic low-fi raster sprites for the demo first screen."""

from __future__ import annotations

import hashlib
import math
import struct
import zlib
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
ASSET_DIR = REPO_ROOT / "client" / "assets" / "sprites" / "demo_first_screen"


def _rgba(color: tuple[int, int, int, int]) -> tuple[int, int, int, int]:
    return color


def _clamp(value: int) -> int:
    return max(0, min(255, value))


def _noise(x: int, y: int, seed: int) -> int:
    value = (x * 374761393 + y * 668265263 + seed * 1442695041) & 0xFFFFFFFF
    value = (value ^ (value >> 13)) * 1274126177
    return (value ^ (value >> 16)) & 0xFF


class Canvas:
    def __init__(self, width: int, height: int) -> None:
        self.width = width
        self.height = height
        self.pixels = bytearray(width * height * 4)

    def blend_pixel(self, x: int, y: int, color: tuple[int, int, int, int]) -> None:
        if x < 0 or x >= self.width or y < 0 or y >= self.height:
            return
        r, g, b, a = color
        if a <= 0:
            return
        idx = (y * self.width + x) * 4
        dst_a = self.pixels[idx + 3]
        inv_a = 255 - a
        out_a = a + (dst_a * inv_a + 127) // 255
        if out_a <= 0:
            return
        self.pixels[idx] = (r * a + self.pixels[idx] * dst_a * inv_a // 255) // out_a
        self.pixels[idx + 1] = (g * a + self.pixels[idx + 1] * dst_a * inv_a // 255) // out_a
        self.pixels[idx + 2] = (b * a + self.pixels[idx + 2] * dst_a * inv_a // 255) // out_a
        self.pixels[idx + 3] = out_a

    def polygon(
        self,
        points: list[tuple[float, float]],
        color: tuple[int, int, int, int],
        jitter: int = 0,
        seed: int = 0,
    ) -> None:
        min_x = max(0, int(math.floor(min(point[0] for point in points))))
        max_x = min(self.width - 1, int(math.ceil(max(point[0] for point in points))))
        min_y = max(0, int(math.floor(min(point[1] for point in points))))
        max_y = min(self.height - 1, int(math.ceil(max(point[1] for point in points))))
        for y in range(min_y, max_y + 1):
            for x in range(min_x, max_x + 1):
                if not _point_in_polygon(x + 0.5, y + 0.5, points):
                    continue
                if jitter > 0:
                    n = _noise(x, y, seed) - 128
                    textured = (
                        _clamp(color[0] + n * jitter // 128),
                        _clamp(color[1] + n * jitter // 128),
                        _clamp(color[2] + n * jitter // 128),
                        color[3],
                    )
                    self.blend_pixel(x, y, textured)
                else:
                    self.blend_pixel(x, y, color)

    def rect(
        self,
        x: int,
        y: int,
        width: int,
        height: int,
        color: tuple[int, int, int, int],
        jitter: int = 0,
        seed: int = 0,
    ) -> None:
        self.polygon(
            [(x, y), (x + width, y), (x + width, y + height), (x, y + height)],
            color,
            jitter,
            seed,
        )

    def ellipse(
        self,
        cx: float,
        cy: float,
        rx: float,
        ry: float,
        color: tuple[int, int, int, int],
        jitter: int = 0,
        seed: int = 0,
    ) -> None:
        min_x = max(0, int(cx - rx))
        max_x = min(self.width - 1, int(cx + rx))
        min_y = max(0, int(cy - ry))
        max_y = min(self.height - 1, int(cy + ry))
        for y in range(min_y, max_y + 1):
            for x in range(min_x, max_x + 1):
                dx = (x + 0.5 - cx) / max(rx, 0.01)
                dy = (y + 0.5 - cy) / max(ry, 0.01)
                if dx * dx + dy * dy > 1.0:
                    continue
                if jitter > 0:
                    n = _noise(x, y, seed) - 128
                    textured = (
                        _clamp(color[0] + n * jitter // 128),
                        _clamp(color[1] + n * jitter // 128),
                        _clamp(color[2] + n * jitter // 128),
                        color[3],
                    )
                    self.blend_pixel(x, y, textured)
                else:
                    self.blend_pixel(x, y, color)

    def line(
        self,
        points: list[tuple[float, float]],
        width: float,
        color: tuple[int, int, int, int],
    ) -> None:
        radius = max(width * 0.5, 1.0)
        for start, end in zip(points, points[1:]):
            sx, sy = start
            ex, ey = end
            length = math.hypot(ex - sx, ey - sy)
            steps = max(1, int(length / max(radius * 0.45, 1.0)))
            for step in range(steps + 1):
                t = step / steps
                self.ellipse(sx + (ex - sx) * t, sy + (ey - sy) * t, radius, radius, color)

    def save_png(self, path: Path) -> None:
        rows = bytearray()
        stride = self.width * 4
        for y in range(self.height):
            rows.append(0)
            rows.extend(self.pixels[y * stride : (y + 1) * stride])
        compressed = zlib.compress(bytes(rows), level=9)
        payload = [
            _png_chunk(b"IHDR", struct.pack(">IIBBBBB", self.width, self.height, 8, 6, 0, 0, 0)),
            _png_chunk(b"IDAT", compressed),
            _png_chunk(b"IEND", b""),
        ]
        path.write_bytes(b"\x89PNG\r\n\x1a\n" + b"".join(payload))


def _point_in_polygon(x: float, y: float, points: list[tuple[float, float]]) -> bool:
    inside = False
    j = len(points) - 1
    for i, point in enumerate(points):
        xi, yi = point
        xj, yj = points[j]
        crosses = (yi > y) != (yj > y)
        if crosses:
            slope_x = (xj - xi) * (y - yi) / ((yj - yi) or 0.000001) + xi
            if x < slope_x:
                inside = not inside
        j = i
    return inside


def _png_chunk(kind: bytes, data: bytes) -> bytes:
    crc = zlib.crc32(kind + data) & 0xFFFFFFFF
    return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", crc)


def write_import_file(path: Path) -> None:
    rel = path.relative_to(REPO_ROOT / "client").as_posix()
    source_file = f"res://{rel}"
    digest = hashlib.md5(source_file.encode("utf-8")).hexdigest()
    uid_alphabet = "0123456789abcdefghijklmnopqrstuvwxyz"
    uid_number = int(hashlib.sha1(source_file.encode("utf-8")).hexdigest()[:16], 16)
    uid_chars = []
    while uid_number and len(uid_chars) < 13:
        uid_number, remainder = divmod(uid_number, len(uid_alphabet))
        uid_chars.append(uid_alphabet[remainder])
    uid = "uid://" + ("".join(uid_chars) or "0").ljust(13, "0")
    imported_name = f"{path.name}-{digest}.ctex"
    import_text = "\n".join(
        [
                "[remap]",
                "",
                'importer="texture"',
                'type="CompressedTexture2D"',
                f'uid="{uid}"',
                f'path="res://.godot/imported/{imported_name}"',
                "metadata={",
                '"vram_texture": false',
                "}",
                "",
                "[deps]",
                "",
                f'source_file="{source_file}"',
                f'dest_files=["res://.godot/imported/{imported_name}"]',
                "",
                "[params]",
                "",
                "compress/mode=0",
                "compress/high_quality=false",
                "compress/lossy_quality=0.7",
                "compress/uastc_level=0",
                "compress/rdo_quality_loss=0.0",
                "compress/hdr_compression=1",
                "compress/normal_map=0",
                "compress/channel_pack=0",
                "mipmaps/generate=false",
                "mipmaps/limit=-1",
                "roughness/mode=0",
                'roughness/src_normal=""',
                "process/channel_remap/red=0",
                "process/channel_remap/green=1",
                "process/channel_remap/blue=2",
                "process/channel_remap/alpha=3",
                "process/fix_alpha_border=true",
                "process/premult_alpha=false",
                "process/normal_map_invert_y=false",
                "process/hdr_as_srgb=false",
                "process/hdr_clamp_exposure=false",
                "process/size_limit=0",
                "detect_3d/compress_to=1",
                "editor/scale_with_editor_scale=false",
                "editor/convert_colors_with_editor_theme=false",
                "",
        ]
    )
    with path.with_suffix(path.suffix + ".import").open("w", encoding="utf-8", newline="\n") as import_file:
        import_file.write(import_text)


def save(canvas: Canvas, filename: str) -> None:
    path = ASSET_DIR / filename
    canvas.save_png(path)
    write_import_file(path)


def draw_floor() -> Canvas:
    canvas = Canvas(900, 540)
    floor = [(22, 94), (134, 42), (742, 39), (867, 126), (834, 418), (646, 503), (128, 475), (34, 361)]
    canvas.polygon(floor, _rgba((185, 194, 182, 238)), jitter=18, seed=10)
    inner = [(88, 116), (202, 76), (696, 82), (802, 144), (768, 386), (613, 455), (169, 435), (86, 331)]
    canvas.polygon(inner, _rgba((210, 215, 203, 112)), jitter=22, seed=11)
    work_worn = [(152, 163), (282, 130), (610, 136), (696, 186), (668, 334), (560, 376), (230, 365), (160, 286)]
    canvas.polygon(work_worn, _rgba((154, 165, 154, 78)), jitter=28, seed=12)
    for cx, cy, rx, ry in [(223, 172, 82, 24), (542, 144, 92, 22), (650, 320, 74, 20), (303, 366, 112, 24)]:
        canvas.ellipse(cx, cy, rx, ry, _rgba((106, 118, 108, 62)), jitter=10, seed=int(cx))
    for x in range(68, 832, 31):
        y = 86 + ((x * 17) % 340)
        if _point_in_polygon(x, y, floor):
            radius = 2 + (x % 7)
            shade = 76 + (x % 32)
            canvas.ellipse(x, y, radius, radius * 0.72, _rgba((shade, shade + 8, shade, 70)), seed=x)
    for points in [
        [(177, 107), (244, 86), (317, 88), (388, 102)],
        [(446, 91), (548, 80), (638, 93), (721, 137)],
        [(128, 301), (220, 334), (327, 346), (451, 337)],
        [(231, 241), (352, 222), (470, 238), (592, 216)],
    ]:
        canvas.line(points, 3, _rgba((82, 94, 86, 44)))
        canvas.line(points, 1.2, _rgba((235, 238, 224, 54)))
    return canvas


def draw_foundation_pads() -> Canvas:
    canvas = Canvas(900, 540)
    pads = [
        [(154, 118), (260, 96), (338, 128), (320, 202), (184, 214), (126, 172)],
        [(374, 133), (510, 122), (575, 166), (548, 230), (392, 236), (338, 190)],
        [(210, 344), (356, 328), (424, 372), (386, 438), (226, 440), (164, 392)],
        [(496, 288), (630, 276), (692, 326), (660, 396), (514, 402), (458, 344)],
    ]
    for index, pad in enumerate(pads):
        canvas.ellipse(sum(p[0] for p in pad) / len(pad), max(p[1] for p in pad) + 8, 120, 18, _rgba((0, 0, 0, 76)))
        canvas.polygon(pad, _rgba((30, 45, 42, 222)), jitter=16, seed=30 + index)
        inset = [(x * 0.90 + sum(p[0] for p in pad) / len(pad) * 0.10, y * 0.90 + sum(p[1] for p in pad) / len(pad) * 0.10) for x, y in pad]
        canvas.polygon(inset, _rgba((56, 75, 70, 150)), jitter=12, seed=34 + index)
        canvas.line([pad[0], pad[1], pad[2]], 5, _rgba((210, 166, 72, 78)))
        for x, y in pad[::2]:
            canvas.ellipse(x, y, 6, 6, _rgba((218, 175, 80, 128)))
    return canvas


def draw_pipe_network() -> Canvas:
    canvas = Canvas(900, 540)
    segments = [
        [(240, 168), (292, 182), (334, 184), (382, 174), (428, 164), (484, 190)],
        [(260, 188), (260, 252), (248, 300), (282, 358)],
        [(330, 372), (420, 356), (488, 331), (572, 338)],
        [(474, 193), (524, 236), (548, 296), (572, 338)],
    ]
    for points in segments:
        canvas.line(points, 31, _rgba((4, 12, 11, 84)))
        canvas.line(points, 21, _rgba((47, 72, 67, 224)))
        canvas.line(points, 5, _rgba((134, 170, 162, 96)))
    for x, y in [(240, 168), (484, 190), (282, 358), (572, 338), (385, 170), (438, 348)]:
        canvas.ellipse(x, y, 14, 14, _rgba((12, 22, 20, 180)))
        canvas.ellipse(x, y, 8, 8, _rgba((214, 178, 86, 172)))
    return canvas


def draw_cliff_edge() -> Canvas:
    canvas = Canvas(900, 540)
    canvas.polygon([(590, 28), (850, 54), (884, 450), (632, 518), (548, 344), (566, 164)], _rgba((44, 80, 76, 196)), jitter=20, seed=50)
    for index, poly in enumerate(
        [
            [(635, 78), (708, 42), (762, 118), (706, 168)],
            [(724, 168), (814, 128), (846, 236), (754, 278)],
            [(610, 302), (702, 244), (766, 352), (654, 410)],
            [(744, 374), (846, 326), (866, 438), (780, 486)],
        ]
    ):
        canvas.polygon(poly, _rgba((75, 103, 96, 190)), jitter=28, seed=53 + index)
        canvas.line([poly[0], poly[2]], 3, _rgba((165, 226, 216, 62)))
    for cx, top, base, height in [(682, 92, 34, 138), (770, 168, 42, 170), (704, 316, 36, 130), (830, 388, 30, 112)]:
        canvas.polygon([(cx - base, top + height), (cx, top), (cx + base, top + height)], _rgba((69, 190, 211, 150)), jitter=10, seed=cx)
        canvas.line([(cx, top + 12), (cx + base * 0.28, top + height - 12)], 2, _rgba((190, 246, 238, 96)))
    return canvas


def draw_pollution_seep() -> Canvas:
    canvas = Canvas(900, 540)
    pools = [
        (690, 384, 112, 34, (188, 208, 76, 92)),
        (760, 430, 84, 28, (218, 220, 88, 74)),
        (636, 302, 62, 22, (154, 194, 64, 70)),
    ]
    for index, (cx, cy, rx, ry, color) in enumerate(pools):
        canvas.ellipse(cx, cy, rx, ry, _rgba(color), jitter=24, seed=70 + index)
        canvas.ellipse(cx + 12, cy - 3, rx * 0.52, ry * 0.46, _rgba((230, 236, 120, 60)), jitter=18, seed=80 + index)
    for x, y in [(606, 256), (668, 278), (744, 338), (805, 392), (706, 452), (636, 416)]:
        canvas.line([(x, y), (x + 22, y + 26), (x + 8, y + 54)], 7, _rgba((190, 210, 86, 56)))
    for x in range(610, 844, 29):
        y = 274 + ((x * 23) % 176)
        canvas.ellipse(x, y, 3 + x % 5, 2 + x % 3, _rgba((228, 235, 112, 62)))
    return canvas


def draw_core() -> Canvas:
    canvas = Canvas(260, 190)
    canvas.ellipse(128, 150, 96, 24, _rgba((0, 0, 0, 126)), jitter=6, seed=100)
    canvas.polygon([(31, 122), (43, 68), (82, 33), (174, 28), (220, 67), (229, 122), (190, 156), (73, 158)], _rgba((18, 43, 39, 250)), jitter=14, seed=101)
    canvas.polygon([(58, 134), (70, 75), (107, 52), (166, 55), (199, 84), (195, 126), (164, 143), (87, 144)], _rgba((10, 29, 27, 238)), jitter=12, seed=102)
    canvas.rect(82, 67, 74, 52, _rgba((27, 74, 61, 218)), jitter=10, seed=103)
    canvas.rect(91, 79, 55, 11, _rgba((146, 200, 120, 92)))
    canvas.rect(92, 99, 21, 12, _rgba((7, 22, 21, 190)))
    canvas.rect(121, 99, 24, 12, _rgba((7, 22, 21, 150)))
    canvas.polygon([(48, 86), (74, 69), (81, 126), (54, 132)], _rgba((34, 68, 58, 226)), jitter=8, seed=104)
    canvas.polygon([(159, 61), (200, 85), (190, 131), (151, 120)], _rgba((23, 58, 53, 224)), jitter=8, seed=105)
    canvas.rect(111, 35, 33, 31, _rgba((24, 59, 53, 224)), jitter=8, seed=106)
    canvas.rect(184, 96, 31, 24, _rgba((7, 22, 21, 230)))
    canvas.rect(191, 103, 16, 9, _rgba((242, 199, 94, 142)))
    for x, y in [(167, 74), (62, 128), (176, 138)]:
        canvas.ellipse(x, y, 5, 5, _rgba((233, 189, 86, 204)))
    canvas.line([(67, 61), (90, 77), (79, 105)], 5, _rgba((7, 22, 21, 178)))
    canvas.line([(44, 69), (82, 34), (175, 29), (219, 66)], 3, _rgba((145, 218, 192, 86)))
    return canvas


def draw_reactor() -> Canvas:
    canvas = Canvas(220, 160)
    canvas.ellipse(112, 129, 80, 20, _rgba((0, 0, 0, 118)), jitter=6, seed=120)
    canvas.polygon([(34, 118), (42, 60), (72, 35), (150, 32), (186, 58), (198, 113), (171, 136), (64, 138)], _rgba((26, 53, 47, 242)), jitter=13, seed=121)
    canvas.polygon([(72, 48), (107, 20), (144, 48)], _rgba((44, 61, 49, 196)), jitter=9, seed=122)
    canvas.rect(73, 60, 66, 54, _rgba((10, 33, 31, 232)), jitter=8, seed=123)
    canvas.rect(86, 70, 40, 9, _rgba((215, 181, 82, 122)))
    canvas.rect(86, 88, 42, 8, _rgba((145, 198, 120, 86)))
    canvas.polygon([(144, 66), (179, 75), (183, 112), (150, 118)], _rgba((18, 42, 40, 220)), jitter=8, seed=124)
    canvas.line([(30, 88), (54, 90)], 5, _rgba((227, 184, 78, 148)))
    canvas.line([(184, 94), (209, 91)], 5, _rgba((227, 184, 78, 148)))
    for x, y in [(58, 91), (182, 94), (134, 51)]:
        canvas.ellipse(x, y, 5, 5, _rgba((232, 189, 86, 198)))
    return canvas


def draw_storage() -> Canvas:
    canvas = Canvas(220, 150)
    canvas.ellipse(110, 124, 86, 18, _rgba((0, 0, 0, 112)), jitter=6, seed=140)
    canvas.polygon([(34, 105), (45, 50), (86, 31), (177, 43), (194, 99), (164, 125), (66, 126)], _rgba((17, 42, 37, 230)), jitter=12, seed=141)
    for rect, color, seed in [
        ((54, 57, 44, 42), (32, 61, 53, 224), 142),
        ((101, 51, 50, 49), (26, 58, 51, 230), 143),
        ((152, 64, 26, 35), (39, 66, 55, 194), 144),
    ]:
        canvas.rect(*rect, _rgba(color), jitter=8, seed=seed)
    canvas.rect(62, 67, 26, 8, _rgba((212, 174, 77, 108)))
    canvas.rect(112, 62, 28, 9, _rgba((169, 199, 119, 86)))
    canvas.rect(110, 82, 32, 7, _rgba((7, 22, 21, 144)))
    canvas.line([(48, 109), (180, 109)], 6, _rgba((226, 186, 88, 108)))
    return canvas


def draw_outfitting() -> Canvas:
    canvas = Canvas(200, 170)
    canvas.ellipse(100, 139, 76, 20, _rgba((0, 0, 0, 106)), jitter=6, seed=160)
    canvas.polygon([(42, 130), (46, 52), (75, 27), (137, 27), (166, 54), (171, 129), (148, 146), (66, 146)], _rgba((17, 40, 34, 224)), jitter=12, seed=161)
    canvas.polygon([(66, 125), (70, 64), (91, 48), (113, 48), (134, 64), (139, 125), (120, 134), (84, 134)], _rgba((7, 25, 24, 230)), jitter=10, seed=162)
    canvas.polygon([(88, 55), (104, 41), (120, 55), (113, 87), (94, 88)], _rgba((29, 72, 64, 204)), jitter=9, seed=163)
    canvas.rect(82, 91, 44, 20, _rgba((23, 58, 51, 184)), jitter=7, seed=164)
    canvas.line([(62, 74), (41, 83), (35, 113)], 5, _rgba((229, 186, 82, 148)))
    canvas.line([(141, 76), (164, 86), (172, 112)], 5, _rgba((229, 186, 82, 108)))
    canvas.rect(52, 125, 96, 12, _rgba((214, 180, 82, 62)))
    for x, y in [(36, 113), (170, 113), (104, 112)]:
        canvas.ellipse(x, y, 5, 5, _rgba((231, 189, 86, 194)))
    return canvas


def draw_crystal_edge() -> Canvas:
    canvas = Canvas(256, 220)
    canvas.ellipse(119, 174, 100, 29, _rgba((217, 228, 210, 52)), jitter=10, seed=180)
    canvas.polygon([(28, 161), (64, 134), (99, 121), (142, 133), (181, 145), (236, 145), (227, 184), (171, 208), (78, 204), (27, 186)], _rgba((43, 81, 75, 198)), jitter=18, seed=181)
    crystals = [
        [(64, 150), (83, 75), (105, 147)],
        [(101, 150), (130, 40), (158, 151)],
        [(145, 154), (178, 84), (195, 158)],
        [(38, 161), (55, 108), (72, 163)],
    ]
    for index, crystal in enumerate(crystals):
        canvas.polygon(crystal, _rgba((82, 201, 221, 150 + index * 16)), jitter=10, seed=182 + index)
        canvas.line([crystal[1], ((crystal[0][0] + crystal[2][0]) / 2, crystal[2][1] - 8)], 2, _rgba((183, 244, 239, 108)))
    for x, y in [(30, 139), (82, 183), (199, 136), (222, 166)]:
        canvas.ellipse(x, y, 5, 5, _rgba((125, 238, 231, 88)))
    return canvas


def main() -> int:
    ASSET_DIR.mkdir(parents=True, exist_ok=True)
    assets = {
        "base_first_screen_rocky_ground.png": draw_floor(),
        "base_first_screen_foundation_pads.png": draw_foundation_pads(),
        "base_first_screen_pipe_network.png": draw_pipe_network(),
        "base_first_screen_cliff_edge.png": draw_cliff_edge(),
        "base_first_screen_pollution_seep.png": draw_pollution_seep(),
        "base_first_screen_outpost_core_machine.png": draw_core(),
        "base_first_screen_basic_reactor_module.png": draw_reactor(),
        "base_first_screen_storage_crate_bank.png": draw_storage(),
        "base_first_screen_outfitting_station_rack.png": draw_outfitting(),
        "base_first_screen_crystal_edge.png": draw_crystal_edge(),
    }
    for filename, canvas in assets.items():
        save(canvas, filename)
    print(f"Generated {len(assets)} demo first screen raster assets in {ASSET_DIR}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
