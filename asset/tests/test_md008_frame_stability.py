import json
import hashlib
import unittest
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
ASSET_ROOT = ROOT / "asset/character/red-panda"
MASTER_DIR = ASSET_ROOT / "master/v0.4"
MASK_PATH = ASSET_ROOT / "masks/v0.4/md008-attention-masks-v3.json"
IDLE_MASTER = MASTER_DIR / "mochidock-red-panda-prone-master-v0.4.png"
STABLE_DIR = ROOT / "asset/workbench/md-008-master-frames-stable-v1"
ATTENTION_BASE = STABLE_DIR / "mochidock-red-panda-attention-base-stable-v1.png"
ATTENTION_TAIL = STABLE_DIR / "mochidock-red-panda-attention-tail-stable-v1.png"
PREVIEW_DIR = ASSET_ROOT / "previews/v0.4"
CATALOG_DIR = ROOT / "MochiDock/MochiDock/Assets.xcassets/Characters/RedPanda/Prone/v0.4"
SIZES = (80, 120, 160, 240, 320)
FORMAL = {
    "attention-base": MASTER_DIR / "mochidock-red-panda-prone-attention-base-master-v0.4.png",
    "attention-tail": MASTER_DIR / "mochidock-red-panda-prone-attention-tail-master-v0.4.png",
}
CATALOG_NAMES = {
    "attention-base": ("AttentionBase", "RedPandaProneAttentionBaseV04"),
    "attention-tail": ("AttentionTail", "RedPandaProneAttentionTailV04"),
}


def rgba(path: Path) -> Image.Image:
    with Image.open(path) as image:
        return image.convert("RGBA")


def region_mask(name: str | tuple[str, ...]) -> Image.Image:
    definition = json.loads(MASK_PATH.read_text(encoding="utf-8"))
    size = (definition["canvas"]["width"], definition["canvas"]["height"])
    mask = Image.new("L", size, 0)
    names = (name,) if isinstance(name, str) else name
    for region_name in names:
        points = [tuple(point) for point in definition["regions"][region_name]["points"]]
        ImageDraw.Draw(mask).polygon(points, fill=255)
    return mask


def assert_equal_outside(
    test: unittest.TestCase,
    expected: Image.Image,
    actual: Image.Image,
    region: str | tuple[str, ...],
) -> None:
    outside = ImageChops.invert(region_mask(region))
    difference = ImageChops.difference(expected, actual)
    test.assertIsNone(
        Image.composite(difference, Image.new("RGBA", expected.size), outside).getbbox(),
        f"pixels changed outside {region}",
    )


class MD008FrameStabilityTests(unittest.TestCase):
    def test_review_attention_masters_exist_as_rgba_on_locked_canvas(self) -> None:
        idle_corner_alpha = rgba(IDLE_MASTER).getpixel((0, 0))[3]
        for path in (ATTENTION_BASE, ATTENTION_TAIL):
            with self.subTest(path=path.name):
                self.assertTrue(path.exists(), f"missing stable review master: {path.name}")
                with Image.open(path) as image:
                    self.assertEqual(image.mode, "RGBA")
                    self.assertEqual(image.size, (1254, 1254))
                    self.assertEqual(image.getpixel((0, 0))[3], idle_corner_alpha)

    def test_attention_base_only_changes_inside_head_permission_region(self) -> None:
        assert_equal_outside(self, rgba(IDLE_MASTER), rgba(ATTENTION_BASE), "attentionHead")

    def test_attention_tail_only_changes_inside_tail_and_body_reconstruction_regions(self) -> None:
        assert_equal_outside(
            self,
            rgba(ATTENTION_BASE),
            rgba(ATTENTION_TAIL),
            ("tailMotion", "bodyReconstruction"),
        )

    def test_tail_root_anchor_is_pixel_stable_between_attention_frames(self) -> None:
        base = rgba(ATTENTION_BASE)
        tail = rgba(ATTENTION_TAIL)
        anchor = region_mask("tailRootAnchor")
        difference = ImageChops.difference(base, tail)
        self.assertIsNone(
            Image.composite(difference, Image.new("RGBA", base.size), anchor).getbbox(),
            "tail root anchor changed between attention frames",
        )

    def test_formal_masters_match_accepted_stable_sources(self) -> None:
        accepted = {
            "attention-base": ATTENTION_BASE,
            "attention-tail": ATTENTION_TAIL,
        }
        for state, formal in FORMAL.items():
            with self.subTest(state=state):
                self.assertTrue(formal.exists())
                self.assertEqual(
                    hashlib.sha256(accepted[state].read_bytes()).hexdigest(),
                    hashlib.sha256(formal.read_bytes()).hexdigest(),
                )

    def test_five_sized_sources_and_catalog_copies_match(self) -> None:
        for state, (folder, prefix) in CATALOG_NAMES.items():
            for size in SIZES:
                source = PREVIEW_DIR / f"mochidock-red-panda-prone-{state}-v0.4-{size}px.png"
                catalog = CATALOG_DIR / folder / f"{prefix}_{size}.imageset/{prefix}_{size}.png"
                with self.subTest(state=state, size=size):
                    self.assertTrue(source.exists())
                    self.assertTrue(catalog.exists())
                    with Image.open(source) as image:
                        self.assertEqual(image.mode, "RGBA")
                        self.assertEqual(image.size, (size, size))
                    self.assertEqual(
                        hashlib.sha256(source.read_bytes()).hexdigest(),
                        hashlib.sha256(catalog.read_bytes()).hexdigest(),
                    )


if __name__ == "__main__":
    unittest.main()
