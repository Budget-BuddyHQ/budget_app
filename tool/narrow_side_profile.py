"""Narrows the side-facing villager sprites so they stop reading as fat.

THE PROBLEM, MEASURED
---------------------
"the left and right walking animations still look like the character is fat"
came back repeatedly. Measuring the sheets says exactly why:

    row            front (south)   profile (west)
    head top            40                50
    hair                70                85
    torso               70                75

The profile is *wider than the front view at the head*, which is
anatomically backwards, and its torso is only 7% narrower than face-on when
a real profile is closer to half. Nothing about the walk cycle or the legs
was ever the issue — the silhouette is simply too wide, and a too-wide
silhouette reads as fat regardless of how well the legs animate.

THE FIX
-------
Column deletion, not scaling. Squashing the sprite horizontally would blur
every outline and destroy the 5px block grid the art is drawn on. Instead
this finds the longest run of a single flat colour in each row — the middle
of the hair slab, the middle of the coat — and deletes columns from *inside*
it, then slides the remainder across. Both edges survive untouched, so the
face, the arm, the back outline and every anti-aliasing-free hard edge come
through exactly as drawn. This is the standard way to narrow pixel art.

Rows below the hip are left alone: the legs were never the problem, and
shifting them would desynchronise the walk cycle across frames.

WHY IT IS SAFE ACROSS ALL 22 SHEETS
-----------------------------------
The 11 female sheets share one alpha mask and the 11 male sheets share
another (verified), so the skins are palette swaps of two geometries. The
run-detection is per-row and per-frame rather than hardcoded coordinates, so
it adapts to both without a table of magic numbers.

USAGE
-----
    python tool/narrow_side_profile.py --preview      # contact sheet only
    python tool/narrow_side_profile.py --apply        # rewrite the sheets

Always run --preview and *look* at the result first. Three previous attempts
at this sprite shipped or nearly shipped changes that measured fine and
looked worse.
"""

from __future__ import annotations

import sys as _superseded_sys

_superseded_sys.exit('Superseded by tool/redraw_side_walk.py, which redraws the villager side rows from scratch. This script patched the old frames in place; run now it would damage the new walk cycle.')

import argparse
import glob
import os

from PIL import Image

SHEETS = "assets/self_made_skins"
CELL_W, CELL_H = 104, 162
COLS, ROWS = 8, 4

# Sheet rows: 0 south, 1 north, 2 west, 3 east.
WEST_ROW, EAST_ROW = 2, 3

# Everything below this row in a cell is legs and stays exactly where it is.
# The coat's bottom edge sits around y=115 in these sheets; below that is
# trouser, shoe and shadow, none of which reads as wide.
HIP_Y = 116

# Never shave a flat run down to nothing — leave this many columns of it so
# the shading band it belongs to is still visible after the cut.
MIN_KEEP = 6

# The art is drawn on a 5px block grid; every edit has to land on it or
# the sprite gets pixels that are visibly the wrong size.
BLOCK = 5


def _runs(px, y: int, w: int):
    """Opaque single-colour runs across one row, as (start, end, colour)."""
    out = []
    prev = None
    start = 0
    for x in range(w):
        col = px[x, y]
        if col != prev:
            if prev is not None:
                out.append((start, x - 1, prev))
            prev = col
            start = x
    out.append((start, w - 1, prev))
    return [r for r in out if r[2][3] > 8]



def _palette(src, w: int, h: int):
    """Recover this skin's outline / hair / skin colours from the cell.

    Read out of the art rather than passed in, because the 22 sheets are
    palette swaps: hardcoding colours would fix one skin and corrupt the
    other twenty-one.
    """
    counts = {}
    for y in range(h):
        for x in range(w):
            c = src[x, y]
            if c[3] > 8:
                counts[c] = counts.get(c, 0) + 1
    if not counts:
        return None

    # Outline: the darkest colour with a real presence. Threshold on count so
    # a stray antialiased pixel cannot win.
    solid = [c for c, n in counts.items() if n > 40]
    if not solid:
        return None
    outline = min(solid, key=lambda c: c[0] + c[1] + c[2])

    # Skin: whatever fills the neck, which is bare on every skin. The neck is
    # the narrow column just under the head.
    skin = None
    for y in range(46, 60):
        runs = _runs(src, y, w)
        inner = [r for r in runs if r[2] != outline]
        if len(inner) == 1 and 10 <= (inner[0][1] - inner[0][0] + 1) <= 30:
            skin = inner[0][2]
            break
    if skin is None:
        return None

    # Hair: the widest non-outline, non-skin run in the head band.
    hair, best = None, 0
    for y in range(24, 46):
        for a, b, c in _runs(src, y, w):
            if c != outline and c != skin and (b - a) > best:
                best, hair = b - a, c
    if hair is None:
        return None
    return outline, hair, skin


def add_profile_face(cell: Image.Image) -> Image.Image:
    """Give the side view an actual face: open hairline, nose, eye.

    **Why the narrowing alone was not enough.** Slimming the silhouette fixed
    "looks fat", but the profile still did not read as a person, because there
    was no face in it — just a 15px skin notch with hair covering everything
    behind it, and no nose or eye anywhere. A head with no features is a blob
    whatever width it is.

    Three edits, all in the head band:

    * **Open the hairline.** The art draws a strip of hair *in front of* the
      face on the upper rows, which is what made the skin patch read as a
      beak rather than as a forehead.
    * **A nose.** One block pushed forward past the face line, with the
      outline moved out to meet it. A profile is recognisable almost entirely
      by its nose.
    * **An eye.** A single outline-coloured block set back from the front
      edge, in the upper half of the face.

    Everything is measured off the art (see [_palette]) rather than
    hardcoded, so it applies to all 22 palette-swapped sheets.
    """
    w, h = cell.size
    out = cell.copy()
    src = out.load()

    pal = _palette(src, w, h)
    if pal is None:
        return out
    outline, hair, skin = pal

    # Find the face: rows in the head band where skin is visible, and how far
    # forward it reaches.
    face_rows = []
    for y in range(24, 50):
        runs = _runs(src, y, w)
        for a, b, c in runs:
            if c == skin:
                face_rows.append((y, a, b))
                break
    if not face_rows:
        return out

    front = min(a for _, a, _ in face_rows)
    top = min(y for y, _, _ in face_rows)
    bottom = max(y for y, _, _ in face_rows)
    # A face too short to carry features means detection latched onto
    # something that is not a face; leave the frame alone rather than
    # painting an eye into the hair.
    if bottom - top < BLOCK * 2:
        return out

    # The hairline-opening step that used to live here has been removed.
    #
    # It turned hair in front of the face line into skin, to stop the small
    # skin patch reading as a beak. On most frames it helped; on the frames
    # where the head sits at a different angle it ate the face entirely and
    # left a head of pure hair. Additive edits (a nose, an eye) cannot fail
    # that way, so only those remain: the worst case is a frame that gains
    # nothing, not a frame that loses its face.

    # 1. Nose: push one block forward, on the rows just above the mouth line.
    nose_top = top + (bottom - top) // 3
    for y in range(nose_top, min(bottom, nose_top + BLOCK)):
        for x in range(front - BLOCK, front):
            if 0 <= x < w:
                src[x, y] = skin
        for x in range(front - BLOCK * 2, front - BLOCK):
            if 0 <= x < w and src[x, y][3] > 8:
                src[x, y] = outline
        # Re-close the outline in front of the new nose tip.
        for x in range(max(0, front - BLOCK * 2), max(0, front - BLOCK)):
            src[x, y] = outline

    # 2. Eye: set back from the front edge, upper half of the face.
    eye_x = front + BLOCK
    eye_y = top + max(0, (bottom - top) // 4)
    for y in range(eye_y, min(h, eye_y + BLOCK)):
        for x in range(eye_x, min(w, eye_x + BLOCK)):
            if src[x, y] == skin:
                src[x, y] = outline

    return out


def _neck_row(src, w: int, h: int) -> int:
    """The narrowest row between the head's widest point and the shoulders.

    Found rather than hardcoded so the same pass works on both the male and
    the female geometry.

    **It has to search below the head's widest row, not from the top.** A
    first version took the minimum width anywhere in 24..70 and, on the
    female sheets, latched onto the narrow hair peak at y=24 — so the "head"
    was five rows tall, the whole face counted as body, and the female
    profiles came out untouched at 71px wide while the male ones narrowed to
    56. Anchoring the search below the widest row cannot make that mistake:
    the neck is by definition the pinch *after* the skull.
    """
    def width_at(y: int) -> int:
        runs = _runs(src, y, w)
        return (runs[-1][1] - runs[0][0] + 1) if runs else 0

    head_y, head_w = 24, 0
    for y in range(16, min(64, h)):
        wy = width_at(y)
        if wy > head_w:
            head_w, head_y = wy, y

    best_y, best_w = head_y + BLOCK, 10**9
    for y in range(head_y + BLOCK, min(head_y + 44, h)):
        wy = width_at(y)
        if 0 < wy < best_w:
            best_w, best_y = wy, y
    return best_y


def narrow_cell(cell: Image.Image, cut: int) -> Image.Image:
    """Delete columns from the body, keeping the silhouette straight.

    **The shift has to be uniform within a region.** A first version chose the
    cut per row independently, so a row whose flat run could only afford 14
    columns shifted 14 while its neighbour shifted 25 — and the back of the
    coat came out as a staircase.

    **But the head and the body are sized separately.** A single take across
    the whole sprite left the profile measuring head 66 wide against a torso
    of 56 — a head wider than its own shoulders, which is the bobblehead
    silhouette that kept reading as fat however slim the coat got. Head rows
    and body rows now each get the largest cut their own region can donate,
    computed independently, which brings the head to 51 against a 56 torso.
    Uniform *within* a region, so neither silhouette staircases.

    A `head_extra` knob was tried here and removed: the top-of-head rows are
    only ~30px wide, so they cap what the head region can give long before
    any extra is reached, and the parameter never bit. The separate per-region
    takes are what actually do the work.

    Rows below the hip are translated by half the body cut rather than left
    alone: leaving the legs where they were detached them from a coat that
    had moved. Translating every frame by one constant preserves the walk
    cycle exactly.
    """
    w, h = cell.size
    src = cell.load()
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    dst = out.load()

    neck = _neck_row(src, w, h)

    def widest_run_len(y: int) -> int:
        runs = _runs(src, y, w)
        if not runs:
            return 0
        widest = max(runs, key=lambda r: r[1] - r[0])
        return widest[1] - widest[0] + 1

    def take_for(rows) -> int:
        lens = [widest_run_len(y) for y in rows]
        lens = [n for n in lens if n > 0]
        if not lens:
            return 0
        return max(0, min(lens) - MIN_KEEP)

    body_take = min(cut, take_for(range(neck + BLOCK, min(HIP_Y, h))))
    head_take = take_for(range(BLOCK * 4, neck))
    if body_take <= 0 and head_take <= 0:
        return cell.copy()
    half = body_take // 2

    def shift_row(y: int, by: int) -> None:
        for x in range(w):
            nx = x - by
            if 0 <= nx < w:
                dst[nx, y] = src[x, y]

    for y in range(h):
        if y >= HIP_Y:
            shift_row(y, half)
            continue

        take = head_take if y < neck else body_take
        runs = _runs(src, y, w)
        if not runs or take <= 0:
            shift_row(y, half)
            continue

        # The widest flat run is the fill: the middle of the hair slab on a
        # head row, the middle of the coat on a torso row. Outlines, the face
        # and the arm are short runs and are never picked.
        widest = max(runs, key=lambda r: r[1] - r[0])
        run_len = widest[1] - widest[0] + 1
        if run_len < take + MIN_KEEP:
            # The neck and other narrow rows cannot donate this much; move
            # them by half so they stay attached above and below.
            shift_row(y, half)
            continue

        cut_start = widest[0] + (run_len - take) // 2
        out_x = 0
        for x in range(w):
            if cut_start <= x < cut_start + take:
                continue
            dst[out_x, y] = src[x, y]
            out_x += 1

    return out


def process_sheet(path: str, cut: int) -> Image.Image:
    sheet = Image.open(path).convert("RGBA")
    out = sheet.copy()
    for col in range(COLS):
        box = (col * CELL_W, WEST_ROW * CELL_H, (col + 1) * CELL_W, (WEST_ROW + 1) * CELL_H)
        west = add_profile_face(narrow_cell(sheet.crop(box), cut))
        out.paste(west, (box[0], box[1]))
        # East is a mirror of west in this art, and keeping it a mirror of the
        # *fixed* west is what stops the two facings drifting apart.
        east = west.transpose(Image.FLIP_LEFT_RIGHT)
        out.paste(east, (col * CELL_W, EAST_ROW * CELL_H))
    return out


def contact_sheet(path: str, cuts, out_path: str) -> None:
    """Before/after strip, so the change is looked at rather than assumed."""
    sheet = Image.open(path).convert("RGBA")
    variants = [("original", sheet)] + [
        (f"cut {c}", process_sheet(path, c)) for c in cuts
    ]
    frames = [1, 2, 5, 6]
    zoom = 3
    cw, ch = CELL_W * zoom, CELL_H * zoom
    grid = Image.new(
        "RGBA",
        (cw * len(frames) + 20, ch * len(variants) + 20),
        (32, 38, 34, 255),
    )
    for ri, (_, img) in enumerate(variants):
        for ci, f in enumerate(frames):
            cell = img.crop(
                (f * CELL_W, WEST_ROW * CELL_H, (f + 1) * CELL_W, (WEST_ROW + 1) * CELL_H)
            ).resize((cw, ch), Image.NEAREST)
            grid.alpha_composite(cell, (10 + ci * cw, 10 + ri * ch))
    grid.save(out_path)
    print(f"contact sheet -> {out_path}")
    for i, (name, _) in enumerate(variants):
        print(f"  row {i}: {name}")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--cut", type=int, default=20)
    ap.add_argument("--preview-out", default="side_preview.png")
    args = ap.parse_args()

    files = sorted(glob.glob(os.path.join(SHEETS, "*.png")))
    if not files:
        raise SystemExit(f"no sheets under {SHEETS}")

    if not args.apply:
        # Preview on a sheet with a strong dark outline, so ragged edges are
        # visible rather than hidden inside a pale palette.
        sample = next(
            (f for f in files if "male_classic" in f.replace("female", "")),
            files[0],
        )
        contact_sheet(sample, [16, 20, 24], args.preview_out)
        return

    for path in files:
        process_sheet(path, args.cut).save(path)
    print(f"narrowed {len(files)} sheets by {args.cut}px")


if __name__ == "__main__":
    main()
