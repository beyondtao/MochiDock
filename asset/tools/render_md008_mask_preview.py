#!/usr/bin/env python3
"""Render the versioned MD-008 permission regions over the v0.4 master."""

from __future__ import annotations

import json
import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[2]
COLORS = {
    "attentionHead": (0, 166, 255, 82),
    "tailMotion": (255, 183, 0, 82),
    "bodyReconstruction": (55, 200, 120, 95),
    "tailRootAnchor": (255, 54, 95, 120),
}


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--version", choices=("v1", "v2", "v3"), default="v1")
    args = parser.parse_args()
    mask_spec = ROOT / f"asset/character/red-panda/masks/v0.4/md008-attention-masks-{args.version}.json"
    output = ROOT / f"asset/workbench/md-008-pointer-attention-v1/md008-attention-masks-{args.version}-overlay.png"
    spec = json.loads(mask_spec.read_text(encoding="utf-8"))
    reference = ROOT / spec["reference"]
    base = Image.open(reference).convert("RGBA")
    if base.size != (spec["canvas"]["width"], spec["canvas"]["height"]):
        raise ValueError(f"Unexpected reference canvas: {base.size}")

    checker = Image.new("RGBA", base.size, (246, 246, 246, 255))
    checker_draw = ImageDraw.Draw(checker)
    tile = 32
    for y in range(0, base.height, tile):
        for x in range(0, base.width, tile):
            if (x // tile + y // tile) % 2:
                checker_draw.rectangle((x, y, x + tile - 1, y + tile - 1), fill=(222, 222, 222, 255))
    checker.alpha_composite(base)

    overlay = Image.new("RGBA", base.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    for name, region in spec["regions"].items():
        points = [tuple(point) for point in region["points"]]
        color = COLORS[name]
        draw.polygon(points, fill=color, outline=color[:3] + (255,), width=5)

    checker.alpha_composite(overlay)
    legend = Image.new("RGBA", (650, 118), (20, 20, 24, 226))
    legend_draw = ImageDraw.Draw(legend)
    font = ImageFont.load_default(size=20)
    labels = [
        ("attentionHead - permitted head/ear change", COLORS["attentionHead"]),
        ("tailMotion - permitted outer-tail change", COLORS["tailMotion"]),
    ]
    if "bodyReconstruction" in spec["regions"]:
        labels.append(("bodyReconstruction - restore hidden body", COLORS["bodyReconstruction"]))
    labels.append(("tailRootAnchor - hard stable connection", COLORS["tailRootAnchor"]))
    for index, (label, color) in enumerate(labels):
        y = 12 + index * 34
        legend_draw.rounded_rectangle((14, y, 40, y + 22), radius=4, fill=color[:3] + (255,))
        legend_draw.text((52, y), label, fill=(255, 255, 255, 255), font=font)
    checker.alpha_composite(legend, (24, 24))

    output.parent.mkdir(parents=True, exist_ok=True)
    checker.convert("RGB").save(output, optimize=True)
    print(output)


if __name__ == "__main__":
    main()
