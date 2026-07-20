#!/usr/bin/env python3
"""Build stable MD-008 review masters on immutable pixel bases."""

from __future__ import annotations

import argparse
import json
import shutil
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[2]
ASSET_ROOT = ROOT / "asset/character/red-panda"
IDLE_MASTER = ASSET_ROOT / "master/v0.4/mochidock-red-panda-prone-master-v0.4.png"
MASK_PATH = ASSET_ROOT / "masks/v0.4/md008-attention-masks-v3.json"
SOURCE_DIR = ROOT / "asset/workbench/md-008-master-frames-v1"
OUTPUT_DIR = ROOT / "asset/workbench/md-008-master-frames-stable-v1"
MASTER_DIR = ASSET_ROOT / "master/v0.4"
PREVIEW_DIR = ASSET_ROOT / "previews/v0.4"
CATALOG_DIR = ROOT / "MochiDock/MochiDock/Assets.xcassets/Characters/RedPanda/Prone/v0.4"
SIZES = (80, 120, 160, 240, 320)
STATES = {
    "attention-base": ("AttentionBase", "RedPandaProneAttentionBaseV04"),
    "attention-tail": ("AttentionTail", "RedPandaProneAttentionTailV04"),
}


def load_rgba(path: Path) -> Image.Image:
    with Image.open(path) as image:
        return image.convert("RGBA")


def region_mask(name: str, *, feather: bool, size: tuple[int, int] | None = None) -> Image.Image:
    definition = json.loads(MASK_PATH.read_text(encoding="utf-8"))
    source_size = (definition["canvas"]["width"], definition["canvas"]["height"])
    size = size or source_size
    region = definition["regions"][name]
    mask = Image.new("L", size, 0)
    scale_x, scale_y = size[0] / source_size[0], size[1] / source_size[1]
    points = [(round(x * scale_x), round(y * scale_y)) for x, y in region["points"]]
    ImageDraw.Draw(mask).polygon(points, fill=255)
    if feather and region["featherPixels"]:
        radius = max(0.5, region["featherPixels"] * min(scale_x, scale_y))
        softened = mask.filter(ImageFilter.GaussianBlur(radius))
        mask = Image.composite(softened, Image.new("L", size, 0), mask)
    return mask


def composite(source: Image.Image, base: Image.Image, mask: Image.Image) -> Image.Image:
    if source.size != base.size:
        raise ValueError(f"source {source.size} does not match base {base.size}")
    return Image.composite(source, base, mask)


def save(image: Image.Image, name: str) -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    image.save(OUTPUT_DIR / name, format="PNG", optimize=False, compress_level=9)


def write_catalog_contents(path: Path, filename: str) -> None:
    contents = {
        "images": [
            {"filename": filename, "idiom": "universal", "scale": "1x"},
            {"idiom": "universal", "scale": "2x"},
            {"idiom": "universal", "scale": "3x"},
        ],
        "info": {"author": "xcode", "version": 1},
    }
    path.write_text(json.dumps(contents, indent=2) + "\n", encoding="utf-8")


def promote(attention_base: Image.Image, attention_tail: Image.Image) -> None:
    accepted = {
        "attention-base": attention_base,
        "attention-tail": attention_tail,
    }
    for state, image in accepted.items():
        stable_path = OUTPUT_DIR / f"mochidock-red-panda-{state}-stable-v1.png"
        formal_path = MASTER_DIR / f"mochidock-red-panda-prone-{state}-master-v0.4.png"
        shutil.copyfile(stable_path, formal_path)

    for size in SIZES:
        dimensions = (size, size)
        idle_path = CATALOG_DIR / f"RedPandaProneV04_{size}.imageset/RedPandaProneV04_{size}.png"
        idle = load_rgba(idle_path)
        scaled_base = attention_base.resize(dimensions, Image.Resampling.LANCZOS)
        product_base = composite(
            scaled_base,
            idle,
            region_mask("attentionHead", feather=False, size=dimensions),
        )

        scaled_tail = attention_tail.resize(dimensions, Image.Resampling.LANCZOS)
        tail_permission = ImageChops.lighter(
            region_mask("tailMotion", feather=False, size=dimensions),
            region_mask("bodyReconstruction", feather=False, size=dimensions),
        )
        product_tail = composite(scaled_tail, product_base, tail_permission)
        anchor = region_mask("tailRootAnchor", feather=False, size=dimensions)
        product_tail = composite(product_base, product_tail, anchor)

        products = {"attention-base": product_base, "attention-tail": product_tail}
        for state, product in products.items():
            source_name = f"mochidock-red-panda-prone-{state}-v0.4-{size}px.png"
            source_path = PREVIEW_DIR / source_name
            source_path.parent.mkdir(parents=True, exist_ok=True)
            product.save(source_path, format="PNG", optimize=False, compress_level=9)

            folder, prefix = STATES[state]
            imageset = CATALOG_DIR / folder / f"{prefix}_{size}.imageset"
            imageset.mkdir(parents=True, exist_ok=True)
            filename = f"{prefix}_{size}.png"
            shutil.copyfile(source_path, imageset / filename)
            write_catalog_contents(imageset / "Contents.json", filename)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--promote", action="store_true")
    args = parser.parse_args()
    idle = load_rgba(IDLE_MASTER)
    base_source = load_rgba(SOURCE_DIR / "mochidock-red-panda-attention-base-source-v1.png")
    integrated_source = load_rgba(SOURCE_DIR / "mochidock-red-panda-integrated-tail-source-v2.png")
    attention_base = composite(base_source, idle, region_mask("attentionHead", feather=True))

    tail_motion = region_mask("tailMotion", feather=False)
    anchor = region_mask("tailRootAnchor", feather=False)
    body_patch = region_mask("bodyReconstruction", feather=True)
    change_mask = ImageChops.lighter(tail_motion, body_patch)
    change_mask = ImageChops.subtract(change_mask, anchor)
    attention_tail = composite(integrated_source, attention_base, change_mask)

    # The hard anchor wins after all feathering and compositing.
    attention_tail = composite(attention_base, attention_tail, anchor)

    save(attention_base, "mochidock-red-panda-attention-base-stable-v1.png")
    save(attention_tail, "mochidock-red-panda-attention-tail-stable-v1.png")
    if args.promote:
        promote(attention_base, attention_tail)


if __name__ == "__main__":
    main()
