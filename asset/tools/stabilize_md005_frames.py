#!/usr/bin/env python3
"""Build MD-005 expression frames on the immutable prone-idle pixel base."""

from __future__ import annotations

import json
import shutil
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[2]
ASSET_ROOT = ROOT / "asset/character/red-panda"
MASTER_DIR = ASSET_ROOT / "master/v0.4"
PREVIEW_DIR = ASSET_ROOT / "previews/v0.4"
MASK_PATH = ASSET_ROOT / "masks/v0.4/md005-expression-masks.json"
SOURCE_DIR = ROOT / "asset/workbench/md-005-master-frames-v1"
STABLE_DIR = ROOT / "asset/workbench/md-005-master-frames-stable-v2"
CATALOG_DIR = ROOT / "MochiDock/MochiDock/Assets.xcassets/Characters/RedPanda/Prone/v0.4"

IDLE_MASTER = MASTER_DIR / "mochidock-red-panda-prone-master-v0.4.png"
SIZES = (80, 120, 160, 240, 320)
STATES = {
    "half-blink": {
        "source": "mochidock-red-panda-half-blink-candidate-v1.png",
        "catalog_folder": "HalfBlink",
        "catalog_prefix": "RedPandaProneHalfBlinkV04",
    },
    "full-blink": {
        "source": "mochidock-red-panda-full-blink-candidate-v1.png",
        "catalog_folder": "FullBlink",
        "catalog_prefix": "RedPandaProneFullBlinkV04",
    },
    "happy": {
        "source": "mochidock-red-panda-happy-candidate-v1.png",
        "catalog_folder": "Happy",
        "catalog_prefix": "RedPandaProneHappyV04",
    },
}


def load_rgba(path: Path) -> Image.Image:
    with Image.open(path) as image:
        return image.convert("RGBA")


def expression_mask(size: tuple[int, int], state: str, *, feather: bool) -> Image.Image:
    definition = json.loads(MASK_PATH.read_text())
    source_width, source_height = definition["canvas"]
    scale_x = size[0] / source_width
    scale_y = size[1] / source_height
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)

    for region_name in definition["states"][state]:
        left, top, right, bottom = definition["regions"][region_name]
        box = tuple(
            round(value * scale)
            for value, scale in zip(
                (left, top, right, bottom),
                (scale_x, scale_y, scale_x, scale_y),
            )
        )
        radius = max(1, round(22 * min(scale_x, scale_y)))
        draw.rounded_rectangle(box, radius=radius, fill=255)

    if feather:
        blur_radius = max(0.5, 7 * min(scale_x, scale_y))
        mask = mask.filter(ImageFilter.GaussianBlur(blur_radius))

        # Gaussian blur may extend beyond the approved rectangles. Clip it back so
        # every pixel outside the versioned expression regions remains immutable.
        approved = expression_mask(size, state, feather=False)
        mask = Image.composite(mask, Image.new("L", size, 0), approved)

    return mask


def composite_on_idle(idle: Image.Image, source: Image.Image, state: str) -> Image.Image:
    if source.size != idle.size:
        raise ValueError(f"{state} source size {source.size} does not match idle {idle.size}")
    result = Image.composite(source, idle, expression_mask(idle.size, state, feather=True))
    result.putalpha(idle.getchannel("A"))
    return result


def resized_frame(master: Image.Image, state: str, size: int) -> Image.Image:
    dimensions = (size, size)
    idle_path = CATALOG_DIR / f"RedPandaProneV04_{size}.imageset/RedPandaProneV04_{size}.png"
    idle = load_rgba(idle_path)
    action = master.resize(dimensions, Image.Resampling.LANCZOS)

    # Resampling can spread changed RGB by a few samples. Re-apply the approved
    # region at the product size, then force the canonical idle alpha channel.
    result = Image.composite(action, idle, expression_mask(dimensions, state, feather=False))
    result.putalpha(idle.getchannel("A"))
    return result


def save_png(image: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, format="PNG", optimize=False, compress_level=9)


def main() -> None:
    idle_master = load_rgba(IDLE_MASTER)
    STABLE_DIR.mkdir(parents=True, exist_ok=True)

    for state, settings in STATES.items():
        source = load_rgba(SOURCE_DIR / settings["source"])
        stable_master = composite_on_idle(idle_master, source, state)
        stable_path = STABLE_DIR / f"mochidock-red-panda-prone-{state}-stable-v2.png"
        save_png(stable_master, stable_path)

        formal_master = MASTER_DIR / f"mochidock-red-panda-prone-{state}-master-v0.4.png"
        shutil.copyfile(stable_path, formal_master)

        for size in SIZES:
            product = resized_frame(stable_master, state, size)
            source_path = PREVIEW_DIR / f"mochidock-red-panda-prone-{state}-v0.4-{size}px.png"
            save_png(product, source_path)

            prefix = settings["catalog_prefix"]
            catalog_path = (
                CATALOG_DIR
                / settings["catalog_folder"]
                / f"{prefix}_{size}.imageset"
                / f"{prefix}_{size}.png"
            )
            catalog_path.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(source_path, catalog_path)


if __name__ == "__main__":
    main()
