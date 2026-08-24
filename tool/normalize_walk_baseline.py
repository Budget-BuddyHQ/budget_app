#!/usr/bin/env python3
"""Re-cell the villager sheets taller and clamp the walk-cycle foot dip.

WHY THIS EXISTS
----------------
Every villager sheet in ``assets/self_made_skins/`` is an 8x4 grid of
104x152 cells, drawn **head-anchored**: the head/hat/torso are
pixel-identical across all 8 frames of a walk row, and only one leg moves —
extending *below* the standing foot line. Measured across all 22 sheets:

    worst-case dip (how far a frame's feet sit below the row's own
    standing-frame feet):           15px
    worst-case headroom (blank space above the head in the original
    104x152 cell):                   2px

So in motion the head stayed nailed in place while the legs stretched and
shrank by up to 15px — the character read as an accordion, not a walker.
(The other half of the "goofy walk" complaint — stride length vs animation
speed — is a separate, already-fixed issue: see ``kTownWalkSpeed`` /
``kTownWalkStepTime`` in ``adventure_world_screen.dart``.)

A first attempt at fixing this **clamped the dip in place**, in the
original 152px-tall cell. That failed: lifting an extended frame up by
`dip - MAX_DIP` pixels needs that much clear space above the head, and the
original cell only ever had 2px. It clipped up to 6px off the top of the
hat and was reverted (see docs/CHALLENGES.md §2 for the full account).

THE FIX HERE IS TWO STEPS, IN ORDER
------------------------------------
1. **Re-cell taller first.** Every frame is recentred into a new
   104x(152+PAD_TOP) cell, pasted PAD_TOP pixels down from the top. This is
   a pure resize-and-recentre — nothing is cropped, nothing changes shape —
   so it cannot introduce a new visual bug by itself. It exists purely to
   manufacture headroom the original art never had.
2. **Then clamp the dip**, exactly as the first attempt did, but now with
   `PAD_TOP + 2` (original headroom) = enough clear space that the worst
   -case lift (15 - MAX_DIP) fits with room to spare. Verified by assertion
   before any file is written — this script refuses to touch anything if
   the arithmetic doesn't actually leave a safety margin.

`AppAssets.villagerCellHeight` / `villagerAspectRatio` must be updated to
match the new cell height after running this — see the printed reminder at
the end, and `docs/ADVENTURE_TOWN.md` §9c which documents why every call
site is safe to repoint (they all reference the named constants, never a
literal 152).

IDEMPOTENT
----------
Re-running this script against its own output is a no-op: the height check
at the top of `normalize_sheet` skips any sheet that isn't still 104x152
(i.e. one this script has already processed), and the dip clamp is an
absolute rule so a second pass over an unprocessed sheet would find nothing
left to shift.

Usage::

    python tool/normalize_walk_baseline.py            # apply
    python tool/normalize_walk_baseline.py --check     # report only, exit 1 if work pending
"""

from __future__ import annotations

import glob
import os
import sys

from PIL import Image

OLD_CW, OLD_CH = 104, 152
COLS, ROWS = 8, 4

# How much blank space to add above every frame before clamping. Combined
# with the original 2px of headroom, this gives 12px of clear space to lift
# an extended frame into.
PAD_TOP = 10
NEW_CH = OLD_CH + PAD_TOP  # 162

# A stepping foot may sit this far below the standing-foot line. Down from
# the worst-case 15px, but not all the way to 0 — some dip is what makes a
# 3/4-view walk cycle read as a walk cycle at all; 15px was too much, 0
# would look stiff.
MAX_DIP = 8

# The worst measured case across all 22 sheets (see the module docstring).
# Asserted against at import time so a future change to MAX_DIP/PAD_TOP
# that breaks the safety margin fails loudly before touching any file,
# rather than silently clipping again.
_WORST_CASE_DIP = 15
_ORIGINAL_HEADROOM = 2
_max_lift_needed = _WORST_CASE_DIP - MAX_DIP
_headroom_available = PAD_TOP + _ORIGINAL_HEADROOM
assert _max_lift_needed < _headroom_available, (
    f"PAD_TOP={PAD_TOP} / MAX_DIP={MAX_DIP} leaves only "
    f"{_headroom_available - _max_lift_needed}px of safety margin — "
    "raise PAD_TOP or MAX_DIP before running this."
)

SHEET_GLOB = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "assets",
    "self_made_skins",
    "*.png",
)


def recell_and_normalize(path: str, apply: bool) -> tuple[bool, int]:
    """Returns (would_change, frames_shifted)."""
    im = Image.open(path).convert("RGBA")
    if im.size != (COLS * OLD_CW, ROWS * OLD_CH):
        if im.size == (COLS * OLD_CW, ROWS * NEW_CH):
            return False, 0  # already processed
        print(f"  !! {os.path.basename(path)}: unexpected size {im.size}, skipped")
        return False, 0

    # Step 1: recentre every frame into a taller, blank canvas. Pure
    # resize-and-recentre — cannot clip anything, since PAD_TOP is only
    # ever added, never subtracted.
    tall = Image.new("RGBA", (COLS * OLD_CW, ROWS * NEW_CH), (0, 0, 0, 0))
    for row in range(ROWS):
        for col in range(COLS):
            cell = im.crop(
                (col * OLD_CW, row * OLD_CH, (col + 1) * OLD_CW, (row + 1) * OLD_CH)
            )
            tall.paste(cell, (col * OLD_CW, row * NEW_CH + PAD_TOP), cell)

    # Step 2: clamp the dip within the new, roomier cells.
    shifted = 0
    for row in range(ROWS):
        cells = []
        for col in range(COLS):
            box = (col * OLD_CW, row * NEW_CH, (col + 1) * OLD_CW, (row + 1) * NEW_CH)
            cell = tall.crop(box)
            bbox = cell.getbbox()
            cells.append((col, cell, bbox, box))

        feet = [b[3] for _, _, b, _ in cells if b is not None]
        if not feet:
            continue
        stand_y = min(feet)

        for col, cell, bbox, box in cells:
            if bbox is None:
                continue
            dip = bbox[3] - stand_y
            if dip <= MAX_DIP:
                continue
            lift = dip - MAX_DIP
            # Safety check per-frame, not just the worst-case assertion
            # above: refuse to write anything that would clip.
            if bbox[1] - lift < 0:
                raise RuntimeError(
                    f"{os.path.basename(path)} row {row} col {col}: lifting "
                    f"{lift}px would clip the top (head at y={bbox[1]}). "
                    "This should be impossible given the module-level "
                    "assertion — stopping without writing anything."
                )
            shifted += 1
            if apply:
                moved = Image.new("RGBA", (OLD_CW, NEW_CH), (0, 0, 0, 0))
                moved.paste(cell, (0, -lift))
                tall.paste(moved, (box[0], box[1]))

    if apply and shifted:
        tall.save(path)
    elif apply:
        # No frames needed shifting, but the re-cell itself still changed
        # the file (taller canvas) — always save once re-celled.
        tall.save(path)
    return True, shifted


def main() -> int:
    check_only = "--check" in sys.argv
    sheets = sorted(glob.glob(SHEET_GLOB))
    if not sheets:
        print(f"No sheets found at {SHEET_GLOB}")
        return 1

    print(
        f"PAD_TOP={PAD_TOP} MAX_DIP={MAX_DIP} -> new cell {OLD_CW}x{NEW_CH}, "
        f"safety margin {_headroom_available - _max_lift_needed}px\n"
    )

    total_changed = 0
    total_shifted = 0
    for path in sheets:
        changed, shifted = recell_and_normalize(path, apply=not check_only)
        if changed:
            total_changed += 1
            total_shifted += shifted
            verb = "would re-cell" if check_only else "re-celled"
            print(f"  {os.path.basename(path)}: {verb}, {shifted} frames shifted")

    if total_changed == 0:
        print(f"All {len(sheets)} sheets already at {OLD_CW}x{NEW_CH}. Nothing to do.")
        return 0

    print(
        f"\n{'Pending' if check_only else 'Done'}: {total_changed} sheets "
        f"({total_shifted} frames shifted total)."
    )
    if not check_only:
        print(
            "\nNext: update AppAssets.villagerCellHeight to "
            f"{NEW_CH} in lib/constants/app_assets.dart, then run "
            "`flutter test test/assets_test.dart test/avatar_sprite_test.dart`."
        )
    return 1 if check_only else 0


if __name__ == "__main__":
    raise SystemExit(main())
