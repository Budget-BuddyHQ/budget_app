"""Draws the four turtle skins, as palette swaps of the mentor turtle.

WHY THIS DELEGATES INSTEAD OF DRAWING ITS OWN
---------------------------------------------
The skins were originally smooth vector cartoons at 563x750, 736x736,
3200x2400 and 1024x1024 — four rendering styles at four unrelated sizes, one
with a white background baked in — which read as clip-art beside the pixel
map and the pixel ending portraits.

Redrawing them as a *side view* was tried twice and failed twice: first as an
ASCII sprite map (which came out as a bench, because a turtle is curves and
hand-placing an arc across a 33-column grid gives a different answer every
time), then as side-view ellipses (which came out as a bean with a head
stuck on the end).

Meanwhile the front-facing mentor build in `tools/turtle_mentor_sprites.py`
was signed off as looking right. So the skins are that exact drawing with a
different palette and an optional coin on the shell. One construction, one
style, four characters — which is also what makes them read as a *set* rather
than as four unrelated pictures.

USAGE
-----
    python tool/make_turtle_skins.py
"""

from __future__ import annotations

import os
import sys

from PIL import Image

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "tools"))

from turtle_mentor_sprites import Palette, render  # noqa: E402

OUT = os.path.join("assets", "images", "turtles")
GUIDE_OUT = os.path.join("assets", "images", "turtle_guide")

# (shell, shell shadow, skin, skin shadow, coin on the shell?)
SKINS = {
    "classic": (
        (86, 150, 74, 255), (58, 110, 52, 255),
        (140, 208, 106, 255), (104, 172, 80, 255), False,
    ),
    "coin_shell": (
        (108, 156, 88, 255), (74, 116, 62, 255),
        (162, 214, 128, 255), (122, 176, 96, 255), True,
    ),
    "explorer": (
        (86, 142, 168, 255), (54, 100, 124, 255),
        (140, 198, 224, 255), (100, 156, 186, 255), False,
    ),
    "guild_runner": (
        (186, 92, 84, 255), (134, 58, 54, 255),
        (232, 158, 120, 255), (188, 118, 86, 255), True,
    ),
}


def main() -> None:
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(GUIDE_OUT, exist_ok=True)

    tiles = []
    for stem, (shell, dark, skin, skin_dark, coin) in SKINS.items():
        pal = Palette(shell, dark, skin, skin_dark)
        # `idle` for every skin: a skin tile is a portrait, and a waving arm
        # would read as one character doing something rather than as the
        # character itself.
        img = render("idle", pal=pal, coin=coin)
        path = os.path.join(OUT, f"{stem}.png")
        img.save(path)
        tiles.append(img)
        print(f"wrote {path} ({img.size[0]}x{img.size[1]})")

    # The guide turtle the in-app tutorial speaks through: the classic
    # palette, waving, so the coach mark opens with a greeting.
    guide = render("wave", pal=Palette(*SKINS["classic"][:4]))
    guide_path = os.path.join(GUIDE_OUT, "guide.png")
    guide.save(guide_path)
    print(f"wrote {guide_path} ({guide.size[0]}x{guide.size[1]})")

    sheet = Image.new(
        "RGBA",
        (sum(t.width for t in tiles) + 50, tiles[0].height + 20),
        (36, 44, 40, 255),
    )
    x = 10
    for t in tiles:
        sheet.alpha_composite(t, (x, 10))
        x += t.width + 10
    sheet.save(os.path.join(OUT, "_turtles_preview.png"))
    print("preview -> _turtles_preview.png")


if __name__ == "__main__":
    main()
