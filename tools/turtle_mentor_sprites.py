"""128x128 redraw of the mentor turtle — 4x the pixel density of the 64x64
pass, so curves read as curves instead of staircases.

What the extra resolution actually buys (it is not just a bigger grid):
  * rounded-rect shell and limbs instead of hard rectangles
  * three-tone body shading (highlight / base / shade) rather than two
  * outlines that are 2px on a 128 grid — visually half as thick as the
    2px outline was on the 64 grid, which is most of the "blocky" look
  * eyes with a real iris, a big catchlight and a small secondary one
  * rounded fingers on the raised hand
"""
from PIL import Image

N = 128
SCALE = 5  # -> 640x640, same output size as every other sheet

PAL = {
    'L': (176, 226, 122, 255),  # body highlight (top-lit)
    'G': (143, 209, 79, 255),   # body base
    'F': (116, 180, 60, 255),   # body shade
    'S': (78, 139, 58, 255),    # shell frame
    'T': (64, 116, 47, 255),    # shell frame shade
    'D': (22, 49, 31, 255),     # ink outline
    'C': (242, 239, 208, 255),  # shell plate
    'H': (250, 248, 228, 255),  # shell plate highlight
    'K': (208, 204, 170, 255),  # shell plate seam
    'P': (244, 155, 176, 255),  # cheek
    'R': (250, 190, 205, 255),  # cheek highlight
    'W': (255, 255, 255, 255),  # catchlight
    'B': (150, 214, 236, 255),  # sweat drop
    'N': (198, 236, 248, 255),  # sweat highlight
    '.': (0, 0, 0, 0),
}


def blank_grid():
    return [['.' for _ in range(N)] for _ in range(N)]


def ellipse_mask(cx, cy, rx, ry):
    cells = set()
    r_lo, r_hi = max(0, int(cy - ry - 2)), min(N, int(cy + ry + 3))
    c_lo, c_hi = max(0, int(cx - rx - 2)), min(N, int(cx + rx + 3))
    for row in range(r_lo, r_hi):
        for col in range(c_lo, c_hi):
            dx = (col + 0.5 - cx) / rx
            dy = (row + 0.5 - cy) / ry
            if dx * dx + dy * dy <= 1.0:
                cells.add((row, col))
    return cells


def rect_mask(r0, c0, r1, c1):
    return {(r, c) for r in range(r0, r1) for c in range(c0, c1)}


def round_rect_mask(r0, c0, r1, c1, rad):
    """Rounded rectangle as a cross plus four corner discs."""
    cells = set()
    cells |= rect_mask(r0 + rad, c0, r1 - rad, c1)
    cells |= rect_mask(r0, c0 + rad, r1, c1 - rad)
    for cr, cc in (
        (r0 + rad, c0 + rad),
        (r0 + rad, c1 - 1 - rad),
        (r1 - 1 - rad, c0 + rad),
        (r1 - 1 - rad, c1 - 1 - rad),
    ):
        cells |= ellipse_mask(cc + 0.5, cr + 0.5, rad, rad)
    return cells


def stroke(points, rad):
    """A connected line of given half-thickness through `points`.

    Stamping a disc at each vertex alone leaves gaps on any diagonal, which
    is what turns a squiggle into a row of dashes — the interpolation
    between vertices is the part that makes it read as one line.
    """
    cells = set()
    prev = None
    for r, c in points:
        cells |= ellipse_mask(c, r, rad, rad)
        if prev is not None:
            pr, pc = prev
            steps = max(int(max(abs(r - pr), abs(c - pc))) * 2, 1)
            for s in range(steps + 1):
                f = s / steps
                cells |= ellipse_mask(pc + (c - pc) * f, pr + (r - pr) * f, rad, rad)
        prev = (r, c)
    return cells


def dilate(cells, n=1):
    out = set(cells)
    for _ in range(n):
        grown = set(out)
        for r, c in out:
            grown.add((r - 1, c))
            grown.add((r + 1, c))
            grown.add((r, c - 1))
            grown.add((r, c + 1))
            grown.add((r - 1, c - 1))
            grown.add((r - 1, c + 1))
            grown.add((r + 1, c - 1))
            grown.add((r + 1, c + 1))
        out = grown
    return out


def stamp(grid, cells, key):
    for r, c in cells:
        if 0 <= r < N and 0 <= c < N:
            grid[r][c] = key


def stamp_outlined(grid, fill_cells, fill_key, ring=2):
    """Outline + fill in ONE pass. Outlining a sub-part separately re-rings
    it and eats into whatever it overlaps — union first, call this once."""
    stamp(grid, dilate(fill_cells, ring), 'D')
    stamp(grid, fill_cells, fill_key)


def rim_light(grid, fill, cx, cy, rx, ry, light='L', shade='F', depth=4):
    """Cel-shades a round body as two rim crescents around a base middle.

    Offsetting a whole second ellipse and intersecting it (the obvious
    approach) leaves a hard-edged blob floating *inside* the shape, which
    reads as a stain rather than as light. Subtracting an inset-and-shifted
    ellipse instead leaves only a crescent hugging the actual silhouette,
    which is how cel-shaded pixel art conveys a curved surface.
    """
    stamp(grid, fill, 'G')
    stamp(grid, fill - ellipse_mask(cx + depth, cy + depth + 1, rx - depth, ry - depth - 1), light)
    stamp(grid, fill - ellipse_mask(cx - depth, cy - depth - 1, rx - depth, ry - depth - 1), shade)


# ---------------------------------------------------------------- features

def draw_ears(grid):
    left = set()
    # A tapered horn: wide at the head, narrowing to a tip.
    for i, (r, half) in enumerate(
        [(14, 3), (17, 4), (20, 5), (23, 5), (26, 5), (29, 4), (32, 3)]
    ):
        cc = 30 - i
        left |= rect_mask(r, cc - half, r + 3, cc + half)
    left |= ellipse_mask(24, 15, 5, 5)
    right = {(r, N - 1 - c) for (r, c) in left}
    stamp_outlined(grid, left, 'G')
    stamp(grid, ellipse_mask(26, 22, 4, 6) & left, 'L')
    stamp_outlined(grid, right, 'G')
    stamp(grid, {(r, N - 1 - c) for (r, c) in (ellipse_mask(26, 22, 4, 6) & left)}, 'L')


def draw_head(grid):
    fill = ellipse_mask(64, 46, 38, 30)
    stamp_outlined(grid, fill, 'G')
    rim_light(grid, fill, 64, 46, 38, 30, depth=5)


def draw_eyes(grid, mode='normal'):
    if mode == 'happy':
        # A smooth closed-eye arc, drawn as a ring segment so its ends
        # taper rather than stopping square.
        for cx in (48, 80):
            outer = ellipse_mask(cx, 44, 13, 13)
            inner = ellipse_mask(cx, 44, 13, 13)
            inner = {(r, c) for (r, c) in ellipse_mask(cx, 44, 10, 10)}
            ring = outer - inner
            arc = {(r, c) for (r, c) in ring if r <= 40}
            stamp(grid, arc, 'D')
        return

    for cx in (48, 80):
        stamp(grid, ellipse_mask(cx, 42, 11, 14), 'D')
        # Big primary catchlight, small secondary — the pair is what stops
        # an eye reading as a flat hole.
        stamp(grid, ellipse_mask(cx - 4, 35, 3.6, 4.4), 'W')
        stamp(grid, ellipse_mask(cx + 5, 47, 2.0, 2.2), 'W')

    if mode == 'worried':
        # Inner ends raised, outer ends dropped — the sad/anxious brow (the
        # opposite tilt reads as angry).
        #
        # Kept inside rows 22-26: the head is an ellipse 30 tall, so it has
        # only ~19 columns of half-width by row 20, and a brow placed any
        # higher or wider pokes through the outline and reads as a crack in
        # the skull rather than as a face.
        stamp(grid, stroke([(26, 42), (22, 56)], 2.0), 'D')
        stamp(grid, stroke([(26, 86), (22, 72)], 2.0), 'D')


def draw_cheeks(grid):
    for cx in (34, 94):
        stamp(grid, ellipse_mask(cx, 57, 8, 5.5), 'P')
        stamp(grid, ellipse_mask(cx - 1, 55, 4.5, 2.6), 'R')


def draw_mouth(grid, mode='smile'):
    if mode == 'smile':
        # Ring-segment smile: even thickness, tapered ends.
        ring = ellipse_mask(64, 50, 17, 16) - ellipse_mask(64, 50, 14, 12.5)
        stamp(grid, {(r, c) for (r, c) in ring if r >= 60}, 'D')
    elif mode == 'worried':
        stamp(
            grid,
            stroke(
                [(63, 50), (58, 56), (63, 62), (58, 68), (63, 74)],
                1.9,
            ),
            'D',
        )


def draw_sweat(grid):
    # Beside the temple, below the ear. Higher up and it collides with the
    # right ear (rows 14-36, out to col ~119) and reads as an earring.
    drop = ellipse_mask(112, 52, 5, 6.5)
    drop |= {(r, c) for r in range(42, 49) for c in range(110, 115)}
    stamp_outlined(grid, drop, 'B', ring=2)
    stamp(grid, ellipse_mask(110, 50, 2, 2.6), 'N')


def draw_shell(grid):
    body = round_rect_mask(80, 30, 118, 98, 14)
    stamp_outlined(grid, body, 'S')
    stamp(grid, ellipse_mask(86, 108, 40, 26) & body, 'T')
    plate = round_rect_mask(86, 40, 112, 88, 9)
    stamp(grid, dilate(plate, 1), 'D')
    stamp(grid, plate, 'C')
    stamp(grid, ellipse_mask(58, 90, 26, 8) & plate, 'H')
    # Scute seams.
    for c in (56, 72):
        stamp(grid, rect_mask(88, c, 110, c + 2) & plate, 'K')
    stamp(grid, rect_mask(97, 42, 99, 86) & plate, 'K')


def draw_feet(grid):
    for c0 in (40, 70):
        foot = round_rect_mask(115, c0, 126, c0 + 20, 5)
        stamp_outlined(grid, foot, 'G')
        stamp(grid, ellipse_mask(c0 + 7, 118, 7, 4) & foot, 'L')
        stamp(grid, rect_mask(120, c0 + 9, 126, c0 + 11) & foot, 'F')


def draw_arm_down(grid, side):
    # Reaches well *under* the shell edge (shell spans cols 30..98) so the
    # limb reads as attached. At only a couple of columns of overlap the
    # outline ring swallows the join and both arms float as loose blobs.
    c0, c1 = (14, 38) if side == 'left' else (90, 114)
    arm = round_rect_mask(87, c0, 108, c1, 9)
    stamp_outlined(grid, arm, 'G')
    rim_light(grid, arm, (c0 + c1) / 2, 97.5, (c1 - c0) / 2, 10.5, depth=4)


_ARM_PATHS = {
    # Starts inside the shell's right edge so the shoulder is attached,
    # then out and up to beside the cheek with clear background between
    # the hand and the head.
    'chin': [(102, 92), (96, 104), (88, 111), (79, 113), (72, 112)],
    # Same shoulder, raised to about ear height and held out to the side.
    # Stops at row ~64 rather than climbing to the very top: the right ear
    # occupies rows 14-36 out to col 119, so a hand any higher lands under
    # it and the two silhouettes merge into one shape.
    'high': [(102, 92), (96, 104), (88, 112), (76, 116), (66, 116)],
}


def draw_arm_raised(grid, reach):
    """Limb as interpolated discs along a path, tapering from shoulder to
    wrist, with the hand unioned in before the single outline pass."""
    path = _ARM_PATHS[reach]
    cells = set()
    prev = None
    for i, (r, c) in enumerate(path):
        # Taper: thick at the shoulder, slimmer at the wrist, so it reads
        # as an arm rather than a length of hose.
        t0 = i / (len(path) - 1)
        rad = 8.5 - 3.0 * t0
        cells |= ellipse_mask(c, r, rad, rad)
        if prev is not None:
            pr, pc, prad = prev
            steps = int(max(abs(r - pr), abs(c - pc))) * 2
            for s in range(steps + 1):
                f = s / steps
                cells |= ellipse_mask(
                    pc + (c - pc) * f,
                    pr + (r - pr) * f,
                    prad + (rad - prad) * f,
                    prad + (rad - prad) * f,
                )
        prev = (r, c, rad)
    hand_r, hand_c = path[-1]
    hand = ellipse_mask(hand_c, hand_r, 9, 9)
    # Three finger bumps around the top arc of the palm — a mitten, which
    # at this size reads as a waving hand where a bare disc reads as a ball.
    for dc, dr in ((-6, -7), (0, -9.5), (6, -7)):
        hand |= ellipse_mask(hand_c + dc, hand_r + dr, 3.4, 3.4)
    cells |= hand
    stamp_outlined(grid, cells, 'G')
    rim_light(grid, cells, hand_c, hand_r + 14, 11, 26, depth=4)
    stamp(grid, ellipse_mask(hand_c - 2.5, hand_r - 2, 4, 4) & hand, 'L')


# ------------------------------------------------------------------ render

def render(grid, path):
    img = Image.new('RGBA', (N, N), (0, 0, 0, 0))
    px = img.load()
    for r in range(N):
        for c in range(N):
            px[c, r] = PAL[grid[r][c]]
    img = img.resize((N * SCALE, N * SCALE), Image.NEAREST)
    img.save(path)
    print('wrote', path, img.size)


def base(pose_eyes, pose_mouth):
    g = blank_grid()
    draw_shell(g)
    draw_feet(g)
    draw_ears(g)
    draw_head(g)
    draw_cheeks(g)
    draw_eyes(g, pose_eyes)
    draw_mouth(g, pose_mouth)
    return g


def pose_idle():
    g = base('normal', 'smile')
    draw_arm_down(g, 'left')
    draw_arm_down(g, 'right')
    return g


def pose_wave():
    g = base('happy', 'smile')
    draw_arm_down(g, 'left')
    draw_arm_raised(g, 'high')
    return g


def pose_thinking():
    g = base('normal', 'smile')
    draw_arm_down(g, 'left')
    draw_arm_raised(g, 'chin')
    return g


def pose_worried():
    g = base('worried', 'worried')
    draw_arm_down(g, 'left')
    draw_arm_down(g, 'right')
    draw_sweat(g)
    return g


if __name__ == '__main__':
    import sys
    out = sys.argv[1] if len(sys.argv) > 1 else '.'
    render(pose_idle(), f'{out}/turtle_mentor_idle.png')
    render(pose_wave(), f'{out}/turtle_mentor_wave.png')
    render(pose_thinking(), f'{out}/turtle_mentor_thinking.png')
    render(pose_worried(), f'{out}/turtle_mentor_worried.png')
