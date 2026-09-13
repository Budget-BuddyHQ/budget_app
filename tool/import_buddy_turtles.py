# -*- coding: utf-8 -*-
"""Cuts the fifteen Budget Buddy turtles out of the character sheet.

# Why this exists

The person the app is being built for said the existing turtle skins do not
match the main turtle — the one in the Budget Buddy logo. They are right: the
four original skins are chunky pixel sprites, and the logo is a soft, outlined
illustration. The client supplied a sheet of fifteen turtles drawn in the
logo's own style (`assets/images/bb characters.png`), each with a name and a
one-line motto underneath.

# Why a script and not fifteen manual crops

The sheet is a flat RGB image on a cream background with the labels baked in.
Cropping fifteen cells by hand means fifteen chances to clip a sparkle, leave a
sliver of a name pill, or pick a slightly different background tolerance for
each one — and the result would look like fifteen different people cut them.

So the grid is **measured, not typed in**: rows and columns are found from
where ink starts and stops against the background, the art rows are separated
from the label rows by the gap between them, and each skin's accent colour is
read out of its own name pill. Replace the sheet and re-run; everything
downstream follows.

# Why flood fill rather than a colour key

A plain colour key removes every cream pixel, including the ones that belong
to the art — the Space turtle's white suit, the flower petals on Forest, the
whites of every eye. Flood-filling inward from the edge of each cell only
removes background that is *connected to the outside*, so anything enclosed by
an outline survives.

The edge pixels are then **decontaminated**: the sheet is anti-aliased, so the
ring of pixels around each outline is part cream. Leaving them opaque puts a
pale halo around every turtle on the app's dark green screens. Each edge pixel
gets an alpha from how far it is from the background colour, and its colour is
un-mixed from the cream accordingly.

Run:  python tool/import_buddy_turtles.py
"""

import os
from collections import Counter, deque

from PIL import Image

SHEET = 'assets/images/bb characters.png'
OUT = 'assets/images/turtles/buddy'
SIZE = 320          # exported square; the art is ~235px, so this is a light upscale
PAD = 0.06          # breathing room inside the square

# Order as printed on the sheet, left to right, top to bottom. The mottos are
# the client's own copy from under each turtle.
SKINS = [
    ('buddy_classic', 'Classic', 'The original money-minded turtle.'),
    ('buddy_scholar', 'Scholar', 'Learns today, builds tomorrow.'),
    ('buddy_adventurer', 'Adventurer', 'Explores. Learns. Grows.'),
    ('buddy_cool', 'Cool', 'Smart money, good vibes.'),
    ('buddy_pink_dream', 'Pink Dream', 'Big dreams, smart moves.'),
    ('buddy_ocean', 'Ocean', 'Dive into your future.'),
    ('buddy_gamer', 'Gamer', 'Level up your finances.'),
    ('buddy_space', 'Space', 'Reach your financial goals.'),
    ('buddy_forest', 'Forest', 'Save. Invest. Grow.'),
    ('buddy_beach', 'Beach', 'Good habits are always in season.'),
    ('buddy_golden', 'Golden', 'Wealth looks good on you.'),
    ('buddy_cozy', 'Cozy', 'Stay warm, keep saving.'),
    ('buddy_retro', 'Retro', 'Good money never goes out of style.'),
    ('buddy_rocket', 'Rocket', 'Small steps, big goals.'),
    ('buddy_rainbow', 'Rainbow', 'More knowledge. More freedom.'),
]

# How close to the background a pixel must be to count as background.
BG_TOLERANCE = 26
# Width of the alpha ramp used to decontaminate anti-aliased edges.
EDGE_RAMP = 70


def dist(a, b):
    return max(abs(a[0] - b[0]), abs(a[1] - b[1]), abs(a[2] - b[2]))


def background_colour(img):
    """The most common colour around the sheet's border."""
    w, h = img.size
    px = img.load()
    counts = Counter()
    for x in range(w):
        counts[px[x, 1]] += 1
        counts[px[x, h - 2]] += 1
    for y in range(h):
        counts[px[1, y]] += 1
        counts[px[w - 2, y]] += 1
    return counts.most_common(1)[0][0]


def bands(values, threshold, min_len):
    """Runs of indices whose ink count is above [threshold]."""
    out, start = [], None
    for i, v in enumerate(values):
        if v > threshold and start is None:
            start = i
        elif v <= threshold and start is not None:
            if i - start >= min_len:
                out.append((start, i))
            start = None
    if start is not None and len(values) - start >= min_len:
        out.append((start, len(values)))
    return out


def measure_grid(img, bg):
    """Finds the five columns and the three art rows.

    Every row of the sheet is art, then a name pill, then a two-line motto.
    Ink bands come out in that order, so the art rows are the tallest band in
    each group — which avoids hard-coding pixel offsets that would break the
    moment the sheet is re-exported at a different size.
    """
    w, h = img.size
    px = img.load()
    rows = [sum(dist(px[x, y], bg) > BG_TOLERANCE for x in range(0, w, 2))
            for y in range(h)]
    cols = [sum(dist(px[x, y], bg) > BG_TOLERANCE for y in range(0, h, 2))
            for x in range(w)]

    row_bands = bands(rows, 3, 6)
    col_bands = bands(cols, 3, 6)

    # Art bands are the tall ones; name pills and mottos are all under ~50px.
    art_rows = [b for b in row_bands if b[1] - b[0] > 120]
    assert len(art_rows) == 3, 'expected 3 art rows, found %r' % (art_rows,)
    assert len(col_bands) == 5, 'expected 5 columns, found %r' % (col_bands,)

    # The pill is the first band below each art row.
    pill_rows = []
    for top, bottom in art_rows:
        below = [b for b in row_bands if b[0] > bottom]
        pill_rows.append(below[0])
    return art_rows, col_bands, pill_rows


def cut_out(cell, bg):
    """Background removed by flood fill from the cell edge, edges decontaminated."""
    cell = cell.convert('RGBA')
    w, h = cell.size
    px = cell.load()

    outside = [[False] * w for _ in range(h)]
    queue = deque()
    for x in range(w):
        queue.append((x, 0))
        queue.append((x, h - 1))
    for y in range(h):
        queue.append((0, y))
        queue.append((w - 1, y))

    while queue:
        x, y = queue.popleft()
        if x < 0 or y < 0 or x >= w or y >= h or outside[y][x]:
            continue
        if dist(px[x, y], bg) > BG_TOLERANCE:
            continue
        outside[y][x] = True
        queue.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))

    for y in range(h):
        for x in range(w):
            if outside[y][x]:
                px[x, y] = (0, 0, 0, 0)
                continue
            touches = any(
                0 <= x + dx < w and 0 <= y + dy < h and outside[y + dy][x + dx]
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))
            )
            if not touches:
                continue
            r, g, b, _ = px[x, y]
            d = dist((r, g, b), bg)
            alpha = min(1.0, d / EDGE_RAMP)
            if alpha <= 0.02:
                px[x, y] = (0, 0, 0, 0)
                continue
            # Un-mix the cream: observed = art * a + bg * (1 - a).
            un = [
                max(0, min(255, round((c - k * (1 - alpha)) / alpha)))
                for c, k in zip((r, g, b), bg)
            ]
            px[x, y] = (un[0], un[1], un[2], round(alpha * 255))
    return cell


def framed(art):
    """Trimmed, then centred on a transparent square, feet on the floor."""
    box = art.getbbox()
    art = art.crop(box)
    inner = int(SIZE * (1 - 2 * PAD))
    scale = min(inner / art.width, inner / art.height)
    art = art.resize(
        (max(1, round(art.width * scale)), max(1, round(art.height * scale))),
        Image.LANCZOS,
    )
    square = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    square.alpha_composite(
        art, ((SIZE - art.width) // 2, SIZE - int(SIZE * PAD) - art.height)
    )
    return square


def main():
    sheet = Image.open(SHEET).convert('RGB')
    bg = background_colour(sheet)
    art_rows, col_bands, pill_rows = measure_grid(sheet, bg)
    os.makedirs(OUT, exist_ok=True)

    spx = sheet.load()
    results = []
    for index, (skin_id, name, motto) in enumerate(SKINS):
        row, col = divmod(index, 5)
        (x0, x1), (y0, y1) = col_bands[col], art_rows[row]
        cell = sheet.crop((max(0, x0 - 6), max(0, y0 - 6), x1 + 6, y1 + 6))
        art = framed(cut_out(cell, bg))
        path = '%s/%s.png' % (OUT, skin_id)
        art.save(path)

        # Accent from the middle of the name pill, left of the text.
        py = (pill_rows[row][0] + pill_rows[row][1]) // 2
        px_ = x0 + (x1 - x0) // 6
        accent = spx[px_, py]
        results.append((skin_id, name, motto, accent))
        print('%-18s %-11s #%02X%02X%02X  %s'
              % (skin_id, name, accent[0], accent[1], accent[2], path))

    contact = os.environ.get('CONTACT_SHEET')
    if contact:
        tile = 150
        board = Image.new('RGBA', (tile * 5, tile * 6), (0, 0, 0, 0))
        dark = Image.new('RGBA', (tile * 5, tile * 3), (18, 48, 34, 255))
        light = Image.new('RGBA', (tile * 5, tile * 3), (240, 244, 238, 255))
        board.alpha_composite(dark, (0, 0))
        board.alpha_composite(light, (0, tile * 3))
        for index, (skin_id, *_rest) in enumerate(results):
            row, col = divmod(index, 5)
            art = Image.open('%s/%s.png' % (OUT, skin_id)).resize(
                (tile - 10, tile - 10), Image.LANCZOS)
            board.alpha_composite(art, (col * tile + 5, row * tile + 5))
            board.alpha_composite(art, (col * tile + 5, (row + 3) * tile + 5))
        board.save(contact)
        print('contact sheet -> ' + contact)


if __name__ == '__main__':
    main()
