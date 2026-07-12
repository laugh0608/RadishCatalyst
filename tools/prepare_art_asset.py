#!/usr/bin/env python3
"""Prepare reviewed PNG art assets for Godot runtime use.

This tool intentionally keeps Pillow as an opt-in local dependency. Run
``--check-env`` with the system Python to get clear setup guidance; use a
project-local virtual environment for actual image processing.
"""

from __future__ import annotations

import argparse
import hashlib
import shutil
import sys
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
CLIENT_ROOT = REPO_ROOT / "client"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Crop, trim, resize, and write import metadata for reviewed PNG assets."
    )
    parser.add_argument("--check-env", action="store_true", help="Report local art tool readiness and exit.")
    parser.add_argument("--input", type=Path, help="Source PNG from assets/art-intake or another reviewed source.")
    parser.add_argument("--output", type=Path, help="Destination PNG, usually under client/assets/.")
    parser.add_argument(
        "--mode",
        choices=("sprite", "tile"),
        default="sprite",
        help="sprite keeps RGBA output; tile writes RGB output unless the source still needs alpha.",
    )
    parser.add_argument(
        "--crop",
        help="Crop box as left,top,right,bottom in source pixels. Right and bottom are exclusive.",
    )
    parser.add_argument(
        "--trim-background",
        action="store_true",
        help="Make the plain background transparent and trim to the remaining alpha bounds.",
    )
    parser.add_argument(
        "--background-color",
        help="Override sampled background as R,G,B, for example 12,16,18.",
    )
    parser.add_argument(
        "--background-threshold",
        type=int,
        default=18,
        help="RGB distance threshold used by --trim-background.",
    )
    parser.add_argument(
        "--alpha-threshold",
        type=int,
        default=8,
        help="Alpha threshold used when finding trim bounds.",
    )
    parser.add_argument("--pad", type=int, default=0, help="Transparent padding after trim, in pixels.")
    parser.add_argument("--max-size", type=int, help="Resize so the longest side is this many pixels.")
    parser.add_argument("--tile-size", type=int, help="Resize exactly to NxN pixels for tile textures.")
    parser.add_argument(
        "--write-godot-import",
        action="store_true",
        help="Write a Godot .import sidecar for outputs under client/.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.check_env:
        return check_env()
    validate_processing_args(args)
    image_module = require_pillow()

    image = image_module.open(args.input).convert("RGBA")
    if args.crop:
        image = image.crop(parse_box(args.crop))
    if args.trim_background:
        image = remove_background(image, parse_background(args.background_color, image), args.background_threshold)
        image = trim_alpha(image, args.alpha_threshold, args.pad)
    if args.tile_size:
        image = image.resize((args.tile_size, args.tile_size), image_module.Resampling.LANCZOS)
    elif args.max_size:
        image.thumbnail((args.max_size, args.max_size), image_module.Resampling.LANCZOS)

    if args.mode == "tile":
        image = image.convert("RGB")

    args.output.parent.mkdir(parents=True, exist_ok=True)
    image.save(args.output)
    if args.write_godot_import:
        write_import_file(args.output)
    print(f"Wrote {args.output.relative_to(REPO_ROOT)} ({image.width}x{image.height}, {image.mode})")
    return 0


def check_env() -> int:
    print(f"Python: {sys.executable}")
    try:
        import PIL  # type: ignore[import-not-found]
    except ModuleNotFoundError:
        print("Pillow: missing")
        print("Setup: python3 -m venv .venv-art")
        print("Setup: .venv-art/bin/python -m pip install -r tools/requirements-art.txt")
        print("Run:   .venv-art/bin/python tools/prepare_art_asset.py --input ... --output ...")
    else:
        version = getattr(PIL, "__version__", "unknown")
        print(f"Pillow: available ({version})")

    sips_path = shutil.which("sips")
    print(f"sips: {sips_path if sips_path else 'missing'}")
    print(f"art-intake: {REPO_ROOT / 'assets' / 'art-intake'}")
    print(f"client assets: {REPO_ROOT / 'client' / 'assets'}")
    return 0


def validate_processing_args(args: argparse.Namespace) -> None:
    if args.input is None or args.output is None:
        raise SystemExit("--input and --output are required unless --check-env is used.")
    if not args.input.exists():
        raise SystemExit(f"Input file does not exist: {args.input}")
    if args.input.suffix.lower() != ".png" or args.output.suffix.lower() != ".png":
        raise SystemExit("Only PNG input and output are supported.")
    if args.max_size and args.max_size <= 0:
        raise SystemExit("--max-size must be positive.")
    if args.tile_size and args.tile_size <= 0:
        raise SystemExit("--tile-size must be positive.")
    if args.pad < 0:
        raise SystemExit("--pad must not be negative.")
    if args.mode == "tile" and args.trim_background:
        raise SystemExit("--mode tile should not be combined with --trim-background.")


def require_pillow():
    try:
        from PIL import Image
    except ModuleNotFoundError as exc:
        raise SystemExit(
            "Pillow is required for image processing. "
            "Create a local venv and install tools/requirements-art.txt; "
            "do not rely on the system Python."
        ) from exc
    return Image


def parse_box(value: str) -> tuple[int, int, int, int]:
    parts = parse_int_list(value, 4, "--crop")
    left, top, right, bottom = parts
    if right <= left or bottom <= top:
        raise SystemExit("--crop requires right > left and bottom > top.")
    return left, top, right, bottom


def parse_background(value: str | None, image) -> tuple[int, int, int]:
    if value:
        return tuple(parse_int_list(value, 3, "--background-color"))  # type: ignore[return-value]
    width, height = image.size
    samples = [
        image.getpixel((0, 0)),
        image.getpixel((width - 1, 0)),
        image.getpixel((0, height - 1)),
        image.getpixel((width - 1, height - 1)),
    ]
    return tuple(sum(sample[index] for sample in samples) // len(samples) for index in range(3))


def parse_int_list(value: str, expected_count: int, label: str) -> list[int]:
    try:
        parts = [int(part.strip()) for part in value.split(",")]
    except ValueError as exc:
        raise SystemExit(f"{label} must contain integers separated by commas.") from exc
    if len(parts) != expected_count:
        raise SystemExit(f"{label} requires {expected_count} comma-separated integers.")
    if any(part < 0 for part in parts):
        raise SystemExit(f"{label} values must not be negative.")
    return parts


def remove_background(image, background: tuple[int, int, int], threshold: int):
    pixels = image.load()
    width, height = image.size
    threshold_sq = threshold * threshold
    for y in range(height):
        for x in range(width):
            red, green, blue, alpha = pixels[x, y]
            distance_sq = (
                (red - background[0]) * (red - background[0])
                + (green - background[1]) * (green - background[1])
                + (blue - background[2]) * (blue - background[2])
            )
            if distance_sq <= threshold_sq:
                pixels[x, y] = (red, green, blue, 0)
            elif alpha < 255:
                pixels[x, y] = (red, green, blue, alpha)
    return image


def trim_alpha(image, threshold: int, pad: int):
    alpha = image.getchannel("A")
    mask = alpha.point(lambda value: 255 if value > threshold else 0)
    bounds = mask.getbbox()
    if bounds is None:
        raise SystemExit("No visible pixels remain after background trimming.")
    cropped = image.crop(bounds)
    if pad <= 0:
        return cropped
    from PIL import Image

    padded = Image.new("RGBA", (cropped.width + pad * 2, cropped.height + pad * 2), (0, 0, 0, 0))
    padded.alpha_composite(cropped, (pad, pad))
    return padded


def write_import_file(path: Path) -> None:
    try:
        rel = path.resolve().relative_to(CLIENT_ROOT.resolve()).as_posix()
    except ValueError as exc:
        raise SystemExit("--write-godot-import requires --output to be under client/.") from exc

    source_file = f"res://{rel}"
    digest = hashlib.md5(source_file.encode("utf-8")).hexdigest()
    uid = make_uid(source_file)
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
    path.with_suffix(path.suffix + ".import").write_text(import_text, encoding="utf-8", newline="\n")


def make_uid(source_file: str) -> str:
    uid_alphabet = "0123456789abcdefghijklmnopqrstuvwxyz"
    uid_number = int(hashlib.sha1(source_file.encode("utf-8")).hexdigest()[:16], 16)
    uid_chars: list[str] = []
    while uid_number and len(uid_chars) < 13:
        uid_number, remainder = divmod(uid_number, len(uid_alphabet))
        uid_chars.append(uid_alphabet[remainder])
    return "uid://" + ("".join(uid_chars) or "0").ljust(13, "0")


if __name__ == "__main__":
    raise SystemExit(main())
