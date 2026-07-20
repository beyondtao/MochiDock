#!/usr/bin/env python3
"""Export transparent-edit masks for the confirmed MD-008 v1 regions."""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
SPEC_PATH = ROOT / "asset/character/red-panda/masks/v0.4/md008-attention-masks-v1.json"
OUTPUT_DIR = ROOT / "asset/workbench/md-008-master-frames-native-v1"


def edit_mask(definition: dict, region_name: str, protected: str | None = None) -> Image.Image:
    size = (definition["canvas"]["width"], definition["canvas"]["height"])
    alpha = Image.new("L", size, 255)
    draw = ImageDraw.Draw(alpha)
    draw.polygon(definition["regions"][region_name]["points"], fill=0)
    if protected:
        draw.polygon(definition["regions"][protected]["points"], fill=255)
    mask = Image.new("RGBA", size, (0, 0, 0, 255))
    mask.putalpha(alpha)
    return mask


def main() -> None:
    definition = json.loads(SPEC_PATH.read_text(encoding="utf-8"))
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    edit_mask(definition, "attentionHead").save(OUTPUT_DIR / "attention-base-edit-mask-v1.png")
    edit_mask(definition, "tailMotion", protected="tailRootAnchor").save(
        OUTPUT_DIR / "attention-tail-edit-mask-v1.png"
    )


if __name__ == "__main__":
    main()
