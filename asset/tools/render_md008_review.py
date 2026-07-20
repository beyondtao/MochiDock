#!/usr/bin/env python3
"""Render compact multi-background review sheets for MD-008 candidates."""

from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
STABLE = ROOT / "asset/workbench/md-008-master-frames-stable-v1"
OUTPUT = STABLE / "md008-stable-v1-review.png"


def load(name: str) -> Image.Image:
    return Image.open(STABLE / name).convert("RGBA")


def checker(size: tuple[int, int], dark: bool = False) -> Image.Image:
    colors = ((38, 42, 48, 255), (54, 59, 66, 255)) if dark else ((246, 246, 246, 255), (222, 222, 222, 255))
    image = Image.new("RGBA", size, colors[0])
    draw = ImageDraw.Draw(image)
    tile = 20
    for y in range(0, size[1], tile):
        for x in range(0, size[0], tile):
            if (x // tile + y // tile) % 2:
                draw.rectangle((x, y, x + tile - 1, y + tile - 1), fill=colors[1])
    return image


def main() -> None:
    frames = [
        load("mochidock-red-panda-attention-base-stable-v1.png"),
        load("mochidock-red-panda-attention-tail-stable-v1.png"),
    ]
    cell = 420
    sheet = Image.new("RGBA", (cell * 2, cell * 2), (255, 255, 255, 255))
    for row, dark in enumerate((False, True)):
        for column, frame in enumerate(frames):
            background = checker((cell, cell), dark=dark)
            scaled = frame.resize((cell, cell), Image.Resampling.LANCZOS)
            background.alpha_composite(scaled)
            sheet.alpha_composite(background, (column * cell, row * cell))
    sheet.convert("RGB").save(OUTPUT, optimize=True)
    print(OUTPUT)


if __name__ == "__main__":
    main()
