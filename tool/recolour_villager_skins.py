"""Makes new villager skins by recolouring the original sheets.

WHY RECOLOUR RATHER THAN REDRAW
-------------------------------
Four passes at redrawing these sprites procedurally each fixed a real problem
and lost something else, and the verdict landed on the original art: *that*
design, for all of them. Which is fair — it is hand-drawn, and a generator
that reproduces its look would be a generator that reproduces a person.

The 22 shipped sheets are palette swaps of one template, so a new skin is a
palette swap too. That gets new characters in exactly the original style, at
exactly the original quality, for the cost of four colours — and it means
every skin in the game is the same art, which is the part the from-scratch
generators kept breaking.

    villager_male_classic.png  --(exact colour substitution)-->  new skin

WHAT GETS SWAPPED
-----------------
The template's palette, read off the art itself:

    #F2C29A  skin           #4A3222  hair
    #4A7FBF  shirt          #345C8C  shirt shadow
    #3A3A3A  trousers       #6B4A32  hair shadow / detail
    #212823  outline        #17140F  deep shadow      (both kept as-is)
    #FF8EA3  blush                                     (kept as-is)

Outline and blush are deliberately not remapped: they are the parts that make
every skin feel like it belongs to the same set, and recolouring an outline per
character is what makes a sprite sheet look like clip art from four sources.

USAGE
-----
    python tool/recolour_villager_skins.py --preview
    python tool/recolour_villager_skins.py
"""

from __future__ import annotations

import argparse
import os

from PIL import Image

SRC_DIR = os.path.join("assets", "self_made_skins")

# The template's colours, in the roles they play.
TEMPLATE = {
    "skin": (0xF2, 0xC2, 0x9A),
    "hair": (0x4A, 0x32, 0x22),
    "hair_shadow": (0x6B, 0x4A, 0x32),
    "shirt": (0x4A, 0x7F, 0xBF),
    "shirt_shadow": (0x34, 0x5C, 0x8C),
    "trousers": (0x3A, 0x3A, 0x3A),
}


def _shade(rgb, factor):
    return tuple(min(255, int(c * factor)) for c in rgb)


def _tint(rgb, amount):
    return tuple(min(255, int(c + (255 - c) * amount)) for c in rgb)


class SkinPalette:
    """A new character's four colours, plus the two shadows derived from them.

    The shadows are derived rather than specified because the template's own
    are a fixed ratio of their base — shirt shadow is about 72% of shirt, hair
    shadow about 140% of hair. Matching those ratios is what keeps a recoloured
    sheet looking shaded rather than flat.
    """

    def __init__(self, skin, hair, shirt, trousers):
        self.skin = skin
        self.hair = hair
        self.shirt = shirt
        self.trousers = trousers

    @property
    def mapping(self):
        return {
            TEMPLATE["skin"]: self.skin,
            TEMPLATE["hair"]: self.hair,
            TEMPLATE["hair_shadow"]: _tint(self.hair, 0.22),
            TEMPLATE["shirt"]: self.shirt,
            TEMPLATE["shirt_shadow"]: _shade(self.shirt, 0.72),
            TEMPLATE["trousers"]: self.trousers,
        }


# New characters. Each is written as a person rather than a colourway: the
# palette, the name and the blurb in `avatar_skin.dart` were chosen together,
# because "Frost Auditor" being pale blue is the only thing that makes the
# pull feel like it meant something.
NEW_SKINS = {
    "copper_apprentice": SkinPalette(
        skin=(0xE8, 0xB8, 0x92), hair=(0x8A, 0x4B, 0x22),
        shirt=(0xB8, 0x6B, 0x3A), trousers=(0x3A, 0x2C, 0x24),
    ),
    "frost_auditor": SkinPalette(
        skin=(0xF2, 0xDC, 0xC8), hair=(0xBF, 0xD8, 0xE8),
        shirt=(0x7A, 0xB8, 0xD9), trousers=(0x2A, 0x3A, 0x45),
    ),
    "harvest_planner": SkinPalette(
        skin=(0xD9, 0xA8, 0x77), hair=(0x4A, 0x33, 0x1E),
        shirt=(0xE8, 0x8B, 0x3A), trousers=(0x40, 0x33, 0x22),
    ),
    "neon_daytrader": SkinPalette(
        skin=(0xC9, 0x9A, 0x74), hair=(0x1A, 0x1A, 0x22),
        shirt=(0x2A, 0xE0, 0xD0), trousers=(0x18, 0x1C, 0x24),
    ),
    "ember_founder": SkinPalette(
        skin=(0x8D, 0x5A, 0x3B), hair=(0x2A, 0x1A, 0x14),
        shirt=(0xD9, 0x4A, 0x2E), trousers=(0x33, 0x22, 0x1E),
    ),
    "jade_landlord": SkinPalette(
        skin=(0xF2, 0xC2, 0x9A), hair=(0x33, 0x2A, 0x1E),
        shirt=(0x2E, 0xA8, 0x7A), trousers=(0x22, 0x33, 0x2C),
    ),
    "royal_treasurer": SkinPalette(
        skin=(0x6B, 0x42, 0x30), hair=(0x1F, 0x1A, 0x2E),
        shirt=(0x6B, 0x3F, 0xB8), trousers=(0x2E, 0x24, 0x40),
    ),
    "solar_index": SkinPalette(
        skin=(0xF7, 0xDF, 0xC4), hair=(0xFF, 0xE9, 0xA8),
        shirt=(0xFF, 0xC9, 0x3C), trousers=(0x4A, 0x3A, 0x1E),
    ),
}


def recolour(template: Image.Image, palette: SkinPalette) -> Image.Image:
    """Exact colour substitution, pixel for pixel.

    Exact rather than a hue rotation: the template is flat-shaded with a small
    fixed set of colours, so a lookup is both faster and lossless. A hue shift
    would drag the outline and the blush along with it, which is what makes a
    recoloured sheet stop looking like the rest of the set.
    """
    mapping = {k: v for k, v in palette.mapping.items()}
    out = template.copy()
    px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            replacement = mapping.get((r, g, b))
            if replacement is not None:
                px[x, y] = (*replacement, a)
    return out


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--preview", action="store_true")
    parser.add_argument("--out", default="new_skins_preview.png")
    args = parser.parse_args()

    templates = {
        "male": Image.open(
            os.path.join(SRC_DIR, "villager_male_classic.png")
        ).convert("RGBA"),
        "female": Image.open(
            os.path.join(SRC_DIR, "villager_female_classic.png")
        ).convert("RGBA"),
    }

    if args.preview:
        cell_w, cell_h = 104, 162
        names = list(NEW_SKINS)
        out = Image.new(
            "RGBA",
            (cell_w * 2 * len(names), cell_h * 2),
            (20, 40, 30, 255),
        )
        for i, name in enumerate(names):
            sheet = recolour(templates["male"], NEW_SKINS[name])
            cell = sheet.crop((0, 0, cell_w, cell_h)).resize(
                (cell_w * 2, cell_h * 2), Image.NEAREST
            )
            out.paste(cell, (i * cell_w * 2, 0), cell)
        out.save(args.out)
        print(f"preview -> {args.out}")
        return

    for name, palette in NEW_SKINS.items():
        for gender, template in templates.items():
            path = os.path.join(SRC_DIR, f"villager_{gender}_{name}.png")
            recolour(template, palette).save(path)
            print(f"  wrote {os.path.basename(path)}")


if __name__ == "__main__":
    main()
