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


def _write(name: str, samples: list[float]) -> None:
    """Normalise, de-click and write one mono 16-bit WAV."""
    if not samples:
        return
    peak = max(abs(s) for s in samples) or 1.0
    gain = 0.86 / peak

    # A hard start or end on a non-zero sample is an audible click. Ten
    # milliseconds of fade at each edge removes it and is far too short to
    # hear as a fade.
    edge = min(int(RATE * 0.01), len(samples) // 2)
    frames = bytearray()
    for i, s in enumerate(samples):
        v = s * gain
        if i < edge:
            v *= i / edge
        elif i > len(samples) - edge:
            v *= (len(samples) - i) / edge
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


def case_roll(seconds=4.2) -> list[float]:
    """The case ratchet: fast ticks that decelerate to a stop.

    The deceleration is what makes this sound like an unboxing rather than
    like a rattle. Intervals grow geometrically, so the gaps stretch in a way
    the ear can extrapolate — and the final two ticks land far enough apart
    that they feel like a decision being made.
    """
    rng = random.Random(7)
    out: list[float] = []
    t = 0.0
    gap = 0.035
    while t < seconds:
        # Pitch drifts up slightly as it slows, which reads as tension.
        freq = 1200 + 420 * (t / seconds)
        _mix(out, _tick(freq=freq, rng=rng), int(t * RATE))
        t += gap
        gap *= 1.075
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
    _write("tap.wav", ui_blip(880, 0.07, 40))
    _write("navigation.wav", ui_blip(660, 0.10, 26))
    _write("selection.wav", ui_blip(1046, 0.09, 30))
    _write("notification.wav", unbox("common"))
    _write("success.wav", unbox("rare"))
    _write("error.wav", ui_blip(196, 0.28, 9, harmonics=(1.0, 0.5, 0.25)))
    _write("need_pickup.wav", ui_blip(1318, 0.12, 24))
    _write("want_hit.wav", ui_blip(294, 0.20, 14, harmonics=(1.0, 0.4, 0.2)))
    _write("celebration.wav", unbox("legendary"))
    _write("shutdown.wav", ui_blip(330, 0.35, 7))

    # Case opening.
    _write("case_roll.wav", case_roll())
    for rarity in ("common", "rare", "epic", "legendary"):
        _write(f"unbox_{rarity}.wav", unbox(rarity))

    _write("ambient_loop.wav", ambient_loop())


if __name__ == "__main__":
    main()
