"""Synthesises Budget Buddy's sound effects and ambient loop.

WHY THESE ARE SYNTHESISED RATHER THAN SOURCED
---------------------------------------------
The brief asked for CS:GO's case-opening sound and Minecraft's music. Both
are copyrighted recordings owned by Valve and Mojang/C418 respectively, and
shipping them inside an app that is going to the stores is straightforward
infringement — the kind that gets a listing pulled rather than the kind
nobody notices. So this generates equivalents instead.

That turns out to be fine, because what makes a case-opening sound *work* is
not the recording, it is the **rhythm**: a ratchet of ticks that starts fast
and decelerates, so the ear extrapolates where it will stop and the last few
ticks feel agonising. That structure is not anyone's property, and it is
reproduced here exactly. Same for the reward chimes: rarity reads as
*harmonic richness plus how long the tail rings*, not as a particular melody.

Everything is written with the standard library alone — `wave`, `math`,
`struct`. No dependency, no download, no licence question.

USAGE
-----
    python tool/make_sounds.py

Writes into assets/audio/. Rerunning overwrites.
"""

from __future__ import annotations

import math
import os
import random
import struct
import wave

OUT = os.path.join("assets", "audio")

RATE = 22050  # plenty for UI effects, and a quarter the size of 44.1k


def _write(name: str, samples: list[float], peak_target: float = 0.86) -> None:
    """Normalise, de-click and write one mono 16-bit WAV.

    `peak_target` is per-file rather than one global number because these
    sounds do not want the same loudness. A reward chime is an event and
    should land; the blip under a tab switch is punctuation, and punctuation
    at the same level as an event is what makes an interface feel like it is
    shouting. The first pass normalised everything to 0.86 and the navigation
    click was as loud as an unboxing.
    """
    if not samples:
        return
    peak = max(abs(s) for s in samples) or 1.0
    gain = peak_target / peak

    # A hard start or end on a non-zero sample is an audible click, so both
    # edges get a fade — but they get *different* fades, and that asymmetry is
    # the point.
    #
    # A symmetric 10ms fade destroys short percussive sounds: `navigation.wav`
    # is 55ms long and its peak is in the first millisecond, so a 10ms ramp
    # was flattening the attack and the file came out at half its requested
    # level. 1.5ms is enough to remove the discontinuity and short enough that
    # the transient survives; the tail keeps the full 10ms, where there is
    # nothing to preserve and a real risk of cutting off mid-cycle.
    fade_in = min(int(RATE * 0.0015), len(samples) // 4)
    fade_out = min(int(RATE * 0.01), len(samples) // 2)
    frames = bytearray()
    for i, s in enumerate(samples):
        v = s * gain
        if fade_in > 0 and i < fade_in:
            v *= i / fade_in
        elif fade_out > 0 and i > len(samples) - fade_out:
            v *= (len(samples) - i) / fade_out
        frames += struct.pack("<h", int(max(-1.0, min(1.0, v)) * 32767))

    path = os.path.join(OUT, name)
    with wave.open(path, "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(bytes(frames))
    print(f"  {name:24} {len(samples) / RATE:.2f}s")


def _tone(freq: float, dur: float, *, decay=8.0, harmonics=(1.0, 0.0, 0.0)):
    """A pitched blip with an exponential decay.

    `harmonics` are the relative levels of the 1st, 2nd and 3rd partials.
    More upper partials reads as brighter and, in the reward chimes, as
    rarer — which is the whole trick those use.
    """
    out = []
    for i in range(int(RATE * dur)):
        t = i / RATE
        env = math.exp(-decay * t)
        v = 0.0
        for n, level in enumerate(harmonics, start=1):
            if level:
                v += level * math.sin(2 * math.pi * freq * n * t)
        out.append(v * env)
    return out


def _tick(dur=0.045, freq=1400.0, rng=None):
    """One ratchet click: a noise burst with a short pitched body."""
    rng = rng or random
    out = []
    for i in range(int(RATE * dur)):
        t = i / RATE
        env = math.exp(-60 * t)
        noise = (rng.random() * 2 - 1) * 0.5
        body = math.sin(2 * math.pi * freq * t) * 0.5
        out.append((noise + body) * env)
    return out


def _mix(base: list[float], add: list[float], at: int) -> None:
    """Adds `add` into `base` starting at sample `at`, growing base if needed."""
    need = at + len(add)
    if len(base) < need:
        base.extend([0.0] * (need - len(base)))
    for i, v in enumerate(add):
        base[at + i] += v


# --------------------------------------------------------------------------
# The case ratchet, locked to the reel
# --------------------------------------------------------------------------
#
# These four numbers are the contract with `customize_screen.dart`. The reel
# animates a strip of skin tiles past a marker with a decelerating curve, and
# every tick in this file is one tile crossing that marker. If any of them
# changes on one side and not the other, the sound stops being the reel and
# becomes a noise playing near it.
#
# `CASE_ROLL_ITEMS` is why the Dart side places the winning skin at a *fixed*
# index and randomises the rest of the strip around it, rather than putting
# the winner wherever it happens to sit in the catalogue: a variable distance
# would mean a variable number of tile crossings, and no pre-rendered file can
# match that.
CASE_ROLL_SECONDS = 4.2
CASE_ROLL_ITEMS = 72
CASE_ROLL_CURVE = (0.16, 0.86, 0.41, 1.0)  # Flutter Cubic(a, b, c, d)


def _cubic_bezier(a: float, b: float, c: float, d: float, t: float) -> float:
    """Flutter's `Cubic.transform`: the y of the curve at parameter x = t.

    Flutter solves for the Bezier parameter whose x equals the input, then
    returns that point's y. Bisection rather than Newton because it cannot
    diverge and 30 iterations is exact enough at audio resolution.
    """

    def bezier(p1, p2, s):
        one = 1.0 - s
        return 3 * one * one * s * p1 + 3 * one * s * s * p2 + s * s * s

    lo, hi = 0.0, 1.0
    for _ in range(30):
        mid = (lo + hi) / 2
        if bezier(a, c, mid) < t:
            lo = mid
        else:
            hi = mid
    return bezier(b, d, (lo + hi) / 2)


def _tick_times(items: int, seconds: float) -> list[float]:
    """When each tile crosses the marker, in seconds.

    The reel's *position* follows the eased curve, so the tick for tile `k`
    lands at the time whose eased progress equals `k / items`. Inverting the
    curve like this is what makes the deceleration match: the gaps stretch on
    exactly the schedule the tiles slow down on, instead of on a geometric
    approximation of it that drifts apart from the picture.
    """
    times: list[float] = []
    k = 1
    steps = 4000
    for i in range(steps + 1):
        t = i / steps
        progress = _cubic_bezier(*CASE_ROLL_CURVE, t)
        while k <= items and progress >= k / items:
            times.append(t * seconds)
            k += 1
        if k > items:
            break
    return times


def case_roll(
    seconds: float = CASE_ROLL_SECONDS,
    items: int = CASE_ROLL_ITEMS,
) -> list[float]:
    """The case ratchet: one tick per tile, decelerating with the reel.

    The deceleration is what makes this an unboxing rather than a rattle. The
    ear extrapolates where the ticks are heading, so the last two — landing
    the better part of a second apart — feel like a decision being made.
    """
    rng = random.Random(7)
    out: list[float] = []
    times = _tick_times(items, seconds)
    for i, t in enumerate(times):
        # Pitch drifts up as it slows, which reads as tension. The last few
        # ticks are also the loudest, because by then each one is a candidate
        # for being the result.
        progress = i / max(1, len(times) - 1)
        freq = 1200 + 460 * progress
        gain = 0.7 + 0.3 * progress
        tick = [v * gain for v in _tick(freq=freq, rng=rng)]
        _mix(out, tick, int(t * RATE))
    return out


def unbox(rarity: str) -> list[float]:
    """A reward chime whose richness and tail scale with rarity."""
    # Root notes climb; harmonic content and ring time climb with them.
    spec = {
        "common": (523.25, (1.0, 0.15, 0.0), 6.0, [0]),
        "rare": (659.25, (1.0, 0.45, 0.15), 3.4, [0, 4]),
        "epic": (783.99, (1.0, 0.6, 0.3), 2.4, [0, 4, 7]),
        "legendary": (1046.5, (1.0, 0.75, 0.5), 1.5, [0, 4, 7, 12]),
    }[rarity]
    root, harmonics, decay, steps = spec

    out: list[float] = []
    for i, semitones in enumerate(steps):
        freq = root * (2 ** (semitones / 12))
        note = _tone(freq, 1.6, decay=decay, harmonics=harmonics)
        # Arpeggiated rather than struck together: a rising figure reads as
        # "this is getting better" where a chord just reads as "an event".
        _mix(out, note, int(i * 0.085 * RATE))
    return out


def ui_blip(freq: float, dur: float, decay: float, harmonics=(1.0, 0.2, 0.0)):
    return _tone(freq, dur, decay=decay, harmonics=harmonics)


def ambient_loop(seconds=24.0) -> list[float]:
    """A calm, seamless pad-and-pluck loop.

    Pentatonic on purpose: with no semitone clashes, notes chosen at random
    cannot produce a sour interval, so a generated melody stays pleasant
    without anyone composing it. This is the same reason wind chimes are
    tuned that way.

    The loop is made seamless by choosing a note grid that divides the total
    length exactly and by the edge fades in [_write] — a background track
    that clicks every 24 seconds is worse than silence.
    """
    rng = random.Random(11)
    total = int(RATE * seconds)
    out = [0.0] * total

    # A slow two-chord drone underneath, so the plucks have somewhere to sit.
    for i in range(total):
        t = i / RATE
        swell = 0.5 + 0.5 * math.sin(2 * math.pi * t / seconds)
        drone = (
            math.sin(2 * math.pi * 110.0 * t) * 0.35
            + math.sin(2 * math.pi * 164.81 * t) * 0.22
        )
        out[i] += drone * 0.16 * (0.6 + 0.4 * swell)

    # Pentatonic plucks on a fixed grid.
    scale = [0, 2, 4, 7, 9, 12, 14, 16]
    step = 0.75
    n = 0
    while n * step < seconds - 1.6:
        if rng.random() < 0.62:
            semitone = scale[rng.randrange(len(scale))]
            freq = 440.0 * (2 ** (semitone / 12))
            note = _tone(freq, 1.5, decay=3.2, harmonics=(1.0, 0.25, 0.08))
            _mix(out, [v * 0.30 for v in note], int(n * step * RATE))
        n += 1

    return out[:total]


def main() -> None:
    os.makedirs(OUT, exist_ok=True)
    print(f"writing to {OUT}/")

    # The ten effects `AppSoundService` already expects.
    #
    # The peak targets are the loudness design. Roughly: navigation is
    # background texture (0.22), taps and selections are light (0.30-0.34),
    # gameplay feedback sits in the middle, and only the reward sounds are
    # allowed to be an event. A tab switch happens dozens of times a session
    # and a case opens rarely, so they cannot share a level.
    _write("tap.wav", ui_blip(880, 0.06, 46), peak_target=0.30)
    # Softer, shorter and an octave down from the old blip, with almost no
    # upper partial — the brief was "make switching tabs more subtle", and a
    # dull low thud reads as movement where a bright click reads as an alert.
    _write(
        "navigation.wav",
        ui_blip(392, 0.055, 60, harmonics=(1.0, 0.04, 0.0)),
        peak_target=0.22,
    )
    _write("selection.wav", ui_blip(1046, 0.07, 38), peak_target=0.34)
    _write("notification.wav", unbox("common"), peak_target=0.62)
    _write("success.wav", unbox("rare"), peak_target=0.70)
    _write(
        "error.wav",
        ui_blip(196, 0.26, 10, harmonics=(1.0, 0.45, 0.2)),
        peak_target=0.48,
    )
    _write("need_pickup.wav", ui_blip(1318, 0.10, 28), peak_target=0.40)
    _write(
        "want_hit.wav",
        ui_blip(294, 0.18, 15, harmonics=(1.0, 0.4, 0.2)),
        peak_target=0.46,
    )
    _write("celebration.wav", unbox("legendary"), peak_target=0.80)
    _write("shutdown.wav", ui_blip(330, 0.32, 8), peak_target=0.40)

    # Case opening. The ratchet runs for four seconds under everything else,
    # so it sits below the chime that resolves it.
    _write("case_roll.wav", case_roll(), peak_target=0.52)
    for rarity, level in (
        ("common", 0.62),
        ("rare", 0.68),
        ("epic", 0.74),
        ("legendary", 0.80),
    ):
        _write(f"unbox_{rarity}.wav", unbox(rarity), peak_target=level)

    # The quietest thing in the app by a wide margin: it is under everything
    # else for as long as the app is open.
    _write("ambient_loop.wav", ambient_loop(), peak_target=0.34)


if __name__ == "__main__":
    main()
