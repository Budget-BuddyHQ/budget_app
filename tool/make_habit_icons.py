"""Generates local art for the 16 Money Habits cards into
assets/images/money_habits/.

WHY THIS EXISTS
---------------
Asked for as: *"finishing adding the images to the daily screens."* Only 6 of
the 16 habit cards had a photo at all, and every one of those six was a
hotlinked Wikimedia URL — a coffee cup, a shopping cart, a pile of cash. Three
problems in one: ten cards had no picture, the app depended on the network for
a screen that should work offline, and the six that did load looked like stock
photos dropped into a hand-drawn pixel game.

This draws all sixteen instead, as flat pixel badges in the app's own palette
(pulled from `lib/themes_colors/app_theme.dart`, the same source
`make_ui_kit.py` uses), so a habit card looks like the rest of the app rather
than next to it, and works with no network at all.

WHY GENERATED RATHER THAN DRAWN BY HAND
----------------------------------------
Every badge is the same three layers — an outlined circle in the habit's
category colour, a soft inner ring, and a glyph — so the geometry is one
function and a palette change is one line. The *glyph* for each icon is
hand-composed below from basic shapes, because which sixteen pictures say
"skip coffee" or "wait 24 hours" is judgement, not geometry.

USAGE
-----
    python tool/make_habit_icons.py

Requires Pillow. Rerunning is safe: every file is rewritten from scratch.
"""

from __future__ import annotations

import math
import os

from PIL import Image, ImageDraw

OUT = os.path.join("assets", "images", "money_habits")
S = 144  # canvas size, native. Flutter downsizes; drawing crisp beats upscaling.

# ---------------------------------------------------------------------------
# Palette, pulled from lib/themes_colors/app_theme.dart and
# money_habit_models.dart's HabitCategory accents, so generated art cannot
# drift from the Flutter colours that sit next to it.
INK = (10, 26, 18, 255)
CREAM = (247, 255, 251, 255)
CORAL = (255, 132, 116, 255)  # HabitCategory.cutSpending
CORAL_LO = (181, 79, 68, 255)
GREEN = (75, 210, 163, 255)  # HabitCategory.saveMore
GREEN_LO = (42, 128, 100, 255)
BLUE = (105, 198, 255, 255)  # HabitCategory.smartHabits
BLUE_LO = (55, 116, 158, 255)
GOLD = (233, 196, 106, 255)

CATEGORY_COLOURS = {
    "cutSpending": (CORAL, CORAL_LO),
    "saveMore": (GREEN, GREEN_LO),
    "smartHabits": (BLUE, BLUE_LO),
}


def badge(accent, shadow):
    """The shared base every icon draws its glyph onto: an outlined circle,
    with a darker underside so it reads as a puffy button rather than a flat
    sticker — the same trick `AppTheme.getPuffyDecoration` uses in Flutter."""
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    r = S // 2 - 4
    cx = cy = S // 2
    d.ellipse((cx - r, cy - r + 5, cx + r, cy + r + 5), fill=shadow)
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=accent, outline=INK, width=5)
    inner = r - 10
    d.ellipse(
        (cx - inner, cy - inner, cx + inner, cy + inner),
        outline=(255, 255, 255, 60),
        width=2,
    )
    return img, d, cx, cy


def line(d, pts, width=7, fill=INK):
    d.line(pts, fill=fill, width=width, joint="curve")
    r = width / 2
    for x, y in (pts[0], pts[-1]):
        d.ellipse((x - r, y - r, x + r, y + r), fill=fill)


def save(name, img):
    os.makedirs(OUT, exist_ok=True)
    img.save(os.path.join(OUT, f"{name}.png"))
    print("wrote", name)


# ---------------------------------------------------------------------------
# One glyph function per habit id. Each draws onto the shared badge in CREAM
# (the glyph) with an INK outline, so it reads at a thumbnail's distance.
# ---------------------------------------------------------------------------


def skip_eating_out():
    img, d, cx, cy = badge(*CATEGORY_COLOURS["cutSpending"])
    # A plate with a fork and knife either side — "eating out", crossed by a
    # slash so it reads as "skip" rather than "here is a restaurant".
    d.ellipse((cx - 30, cy - 22, cx + 30, cy + 38), fill=CREAM, outline=INK, width=5)
    d.ellipse((cx - 16, cy - 8, cx + 16, cy + 24), outline=INK, width=4)
    line(d, [(cx - 46, cy - 30), (cx - 46, cy + 6)], width=6, fill=INK)
    line(d, [(cx - 52, cy - 30), (cx - 52, cy - 6)], width=4, fill=INK)
    line(d, [(cx - 40, cy - 30), (cx - 40, cy - 6)], width=4, fill=INK)
    line(d, [(cx + 46, cy - 30), (cx + 46, cy + 6)], width=6, fill=INK)
    line(d, [(cx - 58, cy - 44), (cx + 60, cy + 46)], width=9, fill=CORAL_LO)
    line(d, [(cx - 58, cy - 44), (cx + 60, cy + 46)], width=4, fill=CREAM)
    return img


def skip_coffee():
    img, d, cx, cy = badge(*CATEGORY_COLOURS["cutSpending"])
    # A mug: taller than it is wide, with a wide rim and a handle, rather than
    # the flat wide box a bare rectangle reads as.
    d.rounded_rectangle(
        (cx - 20, cy - 8, cx + 16, cy + 32), radius=6, fill=CREAM, outline=INK, width=5
    )
    d.line((cx - 22, cy - 10, cx + 18, cy - 10), fill=INK, width=6)
    d.arc((cx + 8, cy - 2, cx + 34, cy + 22), -80, 80, fill=INK, width=6)
    for i, x in enumerate((cx - 8, cx + 2)):
        d.arc((x - 5, cy - 30 + i * 2, x + 5, cy - 18 + i * 2), 200, 340, fill=CREAM, width=4)
    return img


def no_impulse_buy():
    img, d, cx, cy = badge(*CATEGORY_COLOURS["cutSpending"])
    # A shopping trolley: basket, a push handle, and two wheels — the shape
    # a bare trapezoid does not read as on its own.
    d.polygon(
        [
            (cx - 26, cy - 8),
            (cx + 22, cy - 8),
            (cx + 16, cy + 18),
            (cx - 20, cy + 18),
        ],
        fill=CREAM,
        outline=INK,
        width=5,
    )
    d.line((cx - 26, cy - 8, cx - 34, cy - 8, cx - 30, cy - 22), fill=INK, width=5, joint="curve")
    for x in (cx - 12, cx + 6):
        d.ellipse((x - 6, cy + 22, x + 6, cy + 34), fill=INK)
    line(d, [(cx - 44, cy - 34), (cx + 42, cy + 40)], width=9, fill=CORAL_LO)
    line(d, [(cx - 44, cy - 34), (cx + 42, cy + 40)], width=4, fill=CREAM)
    return img


def cancel_unused_sub():
    img, d, cx, cy = badge(*CATEGORY_COLOURS["cutSpending"])
    d.rounded_rectangle(
        (cx - 30, cy - 22, cx + 30, cy + 22), radius=8, fill=CREAM, outline=INK, width=5
    )
    d.polygon(
        [(cx - 22, cy - 14), (cx, cy + 4), (cx + 22, cy - 14)],
        outline=INK,
        width=5,
    )
    line(d, [(cx - 40, cy + 30), (cx + 40, cy - 30)], width=9, fill=CORAL_LO)
    line(d, [(cx - 40, cy + 30), (cx + 40, cy - 30)], width=4, fill=CREAM)
    return img


def use_a_coupon():
    img, d, cx, cy = badge(*CATEGORY_COLOURS["cutSpending"])
    d.rounded_rectangle(
        (cx - 34, cy - 20, cx + 34, cy + 20), radius=10, fill=CREAM, outline=INK, width=5
    )
    for x in (cx - 34, cx + 34):
        d.ellipse((x - 8, cy - 8, x + 8, cy + 8), fill=CATEGORY_COLOURS["cutSpending"][0])
    d.line((cx - 14, cy - 12, cx - 14, cy + 12), fill=INK, width=3)
    d.line((cx + 2, cy - 12, cx + 2, cy + 12), fill=INK, width=3)
    d.line((cx + 18, cy - 12, cx + 18, cy + 12), fill=INK, width=3)
    return img


def save_pocket_change():
    img, d, cx, cy = badge(*CATEGORY_COLOURS["saveMore"])
    # A coin: a disc with a slot through the middle, plus a smaller coin
    # dropping in beside it — text does not render reliably at this size, so
    # the "$" is drawn as strokes rather than a character.
    d.ellipse((cx - 26, cy - 26, cx + 26, cy + 26), fill=GOLD, outline=INK, width=5)
    d.ellipse((cx - 17, cy - 17, cx + 17, cy + 17), outline=INK, width=3)
    d.arc((cx - 8, cy - 12, cx + 8, cy + 4), 40, 320, fill=INK, width=4)
    d.arc((cx - 8, cy - 4, cx + 8, cy + 12), 220, 140, fill=INK, width=4)
    d.line((cx, cy - 15, cx, cy + 15), fill=INK, width=3)
    d.ellipse((cx + 20, cy + 12, cx + 40, cy + 32), fill=GOLD, outline=INK, width=4)
    return img


def round_up_savings():
    img, d, cx, cy = badge(*CATEGORY_COLOURS["saveMore"])
    for i, (x, r) in enumerate([(cx - 22, 16), (cx + 22, 22)]):
        d.ellipse((x - r, cy + 18 - r, x + r, cy + 18 + r), fill=GOLD, outline=INK, width=4)
    d.line((cx - 34, cy - 6, cx + 6, cy - 30), fill=INK, width=6)
    d.line((cx - 2, cy - 34, cx + 8, cy - 30, cx + 4, cy - 20), fill=None)
    d.polygon([(cx + 8, cy - 36), (cx + 20, cy - 30), (cx + 8, cy - 20)], fill=INK)
    return img


def sell_something():
    img, d, cx, cy = badge(*CATEGORY_COLOURS["saveMore"])
    d.polygon(
        [
            (cx - 30, cy - 6),
            (cx - 6, cy - 30),
            (cx + 30, cy + 6),
            (cx + 6, cy + 30),
        ],
        fill=CREAM,
        outline=INK,
        width=5,
    )
    d.ellipse((cx - 18, cy - 12, cx - 8, cy - 2), fill=INK)
    return img


def pack_lunch():
    img, d, cx, cy = badge(*CATEGORY_COLOURS["saveMore"])
    d.rounded_rectangle(
        (cx - 28, cy - 14, cx + 28, cy + 28), radius=8, fill=CREAM, outline=INK, width=5
    )
    d.arc((cx - 16, cy - 30, cx + 16, cy - 2), 200, 340, fill=INK, width=6)
    d.line((cx - 28, cy + 4, cx + 28, cy + 4), fill=INK, width=4)
    return img


def set_aside_allowance():
    img, d, cx, cy = badge(*CATEGORY_COLOURS["saveMore"])
    d.rounded_rectangle(
        (cx - 30, cy - 18, cx + 30, cy + 20), radius=8, fill=CREAM, outline=INK, width=5
    )
    d.rounded_rectangle((cx + 12, cy - 8, cx + 30, cy + 10), radius=4, outline=INK, width=4)
    d.ellipse((cx + 16, cy - 2, cx + 24, cy + 6), fill=GOLD, outline=INK, width=2)
    return img


def track_every_expense():
    img, d, cx, cy = badge(*CATEGORY_COLOURS["smartHabits"])
    d.rounded_rectangle(
        (cx - 22, cy - 32, cx + 22, cy + 32), radius=4, fill=CREAM, outline=INK, width=5
    )
    for i in range(4):
        y = cy - 18 + i * 12
        d.line((cx - 12, y, cx + 12, y), fill=INK, width=4)
    return img


def compare_prices():
    img, d, cx, cy = badge(*CATEGORY_COLOURS["smartHabits"])
    for x, tall in ((cx - 18, 20), (cx + 18, 32)):
        d.rectangle((x - 12, cy + 26 - tall, x + 12, cy + 26), fill=CREAM, outline=INK, width=5)
    d.line((cx - 30, cy + 30, cx + 30, cy + 30), fill=INK, width=5)
    return img


def make_a_budget_check():
    img, d, cx, cy = badge(*CATEGORY_COLOURS["smartHabits"])
    d.rounded_rectangle(
        (cx - 26, cy - 30, cx + 26, cy + 30), radius=6, fill=CREAM, outline=INK, width=5
    )
    d.line((cx - 14, cy + 2, cx - 4, cy + 14, cx + 16, cy - 12), fill=GREEN_LO, width=7, joint="curve")
    return img


def wait_24_hours():
    img, d, cx, cy = badge(*CATEGORY_COLOURS["smartHabits"])
    d.ellipse((cx - 28, cy - 28, cx + 28, cy + 28), fill=CREAM, outline=INK, width=5)
    d.line((cx, cy, cx, cy - 18), fill=INK, width=5)
    d.line((cx, cy, cx + 14, cy + 4), fill=INK, width=5)
    return img


def review_subscriptions():
    img, d, cx, cy = badge(*CATEGORY_COLOURS["smartHabits"])
    d.rounded_rectangle(
        (cx - 24, cy - 30, cx + 24, cy + 30), radius=4, fill=CREAM, outline=INK, width=5
    )
    for i in range(3):
        y = cy - 14 + i * 14
        d.rectangle((cx - 14, y - 4, cx - 6, y + 4), outline=INK, width=3)
        d.line((cx, y, cx + 14, y), fill=INK, width=3)
    d.line((cx - 14, cy - 18, cx - 10, cy - 14, cx - 4, cy - 22), fill=GREEN_LO, width=3)
    return img


def set_a_savings_goal():
    img, d, cx, cy = badge(*CATEGORY_COLOURS["smartHabits"])
    d.line((cx - 20, cy - 34, cx - 20, cy + 34), fill=INK, width=6)
    d.polygon([(cx - 20, cy - 32), (cx + 26, cy - 20), (cx - 20, cy - 8)], fill=GOLD, outline=INK, width=4)
    return img


ICONS = {
    "skip_eating_out": skip_eating_out,
    "skip_coffee": skip_coffee,
    "no_impulse_buy": no_impulse_buy,
    "cancel_unused_sub": cancel_unused_sub,
    "use_a_coupon": use_a_coupon,
    "save_pocket_change": save_pocket_change,
    "round_up_savings": round_up_savings,
    "sell_something": sell_something,
    "pack_lunch": pack_lunch,
    "set_aside_allowance": set_aside_allowance,
    "track_every_expense": track_every_expense,
    "compare_prices": compare_prices,
    "make_a_budget_check": make_a_budget_check,
    "wait_24_hours": wait_24_hours,
    "review_subscriptions": review_subscriptions,
    "set_a_savings_goal": set_a_savings_goal,
}

if __name__ == "__main__":
    for habit_id, fn in ICONS.items():
        save(habit_id, fn())
    print(f"done: {len(ICONS)} icons in {OUT}")
