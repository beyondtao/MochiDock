import hashlib
import json
import unittest
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
MASTER = ROOT / "asset/character/red-panda/master/v0.4"
PREVIEWS = ROOT / "asset/character/red-panda/previews/v0.4"
CATALOG = ROOT / "MochiDock/MochiDock/Assets.xcassets/Characters/RedPanda/Prone/v0.4"
MASK_PATH = ROOT / "asset/character/red-panda/masks/v0.4/md005-expression-masks.json"
PET_VIEW = ROOT / "MochiDock/MochiDock/PetView.swift"

IDLE_MASTER = MASTER / "mochidock-red-panda-prone-master-v0.4.png"
ACTION_MASTER = {
    state: MASTER / f"mochidock-red-panda-prone-{state}-master-v0.4.png"
    for state in ("half-blink", "full-blink", "happy")
}
SIZES = (80, 120, 160, 240, 320)
CATALOG_NAMES = {
    "half-blink": ("HalfBlink", "RedPandaProneHalfBlinkV04"),
    "full-blink": ("FullBlink", "RedPandaProneFullBlinkV04"),
    "happy": ("Happy", "RedPandaProneHappyV04"),
}


def rgba(path: Path) -> Image.Image:
    with Image.open(path) as image:
        return image.convert("RGBA")


def allowed_mask(size: tuple[int, int], state: str) -> Image.Image:
    definition = json.loads(MASK_PATH.read_text())
    source_width, source_height = definition["canvas"]
    scale_x = size[0] / source_width
    scale_y = size[1] / source_height
    mask = Image.new("1", size, 0)
    draw = ImageDraw.Draw(mask)
    for region_name in definition["states"][state]:
        left, top, right, bottom = definition["regions"][region_name]
        draw.rectangle(
            (
                round(left * scale_x),
                round(top * scale_y),
                round(right * scale_x),
                round(bottom * scale_y),
            ),
            fill=1,
        )
    return mask


def assert_images_equal_outside_mask(
    test: unittest.TestCase,
    idle: Image.Image,
    action: Image.Image,
    state: str,
) -> None:
    test.assertEqual(idle.size, action.size)
    outside = ImageChops.invert(allowed_mask(idle.size, state).convert("L"))
    outside_difference = ImageChops.difference(idle, action)
    outside_difference = Image.composite(
        outside_difference,
        Image.new("RGBA", idle.size, (0, 0, 0, 0)),
        outside,
    )
    test.assertIsNone(
        outside_difference.getbbox(),
        f"{state} changes pixels outside its expression mask",
    )


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


class MD005FrameStabilityTests(unittest.TestCase):
    def test_action_master_alpha_exactly_matches_idle(self) -> None:
        idle_alpha = rgba(IDLE_MASTER).getchannel("A")
        for state, path in ACTION_MASTER.items():
            with self.subTest(state=state):
                self.assertIsNone(
                    ImageChops.difference(idle_alpha, rgba(path).getchannel("A")).getbbox()
                )

    def test_action_masters_only_change_expression_regions(self) -> None:
        idle = rgba(IDLE_MASTER)
        for state, path in ACTION_MASTER.items():
            with self.subTest(state=state):
                assert_images_equal_outside_mask(self, idle, rgba(path), state)

    def test_every_sized_action_has_stable_alpha_and_pixels(self) -> None:
        for size in SIZES:
            idle_path = CATALOG / f"RedPandaProneV04_{size}.imageset/RedPandaProneV04_{size}.png"
            idle = rgba(idle_path)
            for state in ACTION_MASTER:
                action_path = PREVIEWS / f"mochidock-red-panda-prone-{state}-v0.4-{size}px.png"
                action = rgba(action_path)
                with self.subTest(state=state, size=size):
                    self.assertIsNone(
                        ImageChops.difference(
                            idle.getchannel("A"), action.getchannel("A")
                        ).getbbox()
                    )
                    assert_images_equal_outside_mask(self, idle, action, state)

    def test_catalog_copies_match_formal_sized_sources(self) -> None:
        for size in SIZES:
            for state, (folder, prefix) in CATALOG_NAMES.items():
                source = PREVIEWS / f"mochidock-red-panda-prone-{state}-v0.4-{size}px.png"
                catalog = CATALOG / folder / f"{prefix}_{size}.imageset/{prefix}_{size}.png"
                with self.subTest(state=state, size=size):
                    self.assertEqual(sha256(source), sha256(catalog))

    def test_pet_view_does_not_brighten_the_entire_happy_frame(self) -> None:
        source = PET_VIEW.read_text()
        self.assertNotIn(".brightness(", source)
        self.assertNotIn("model.mood == .happy ? 0.025 : 0", source)


if __name__ == "__main__":
    unittest.main()
