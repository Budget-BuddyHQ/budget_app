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

    # starting or ending hard on a non-zero sample = audible click, so both
    # edges get a fade. but they get *different* fades and thats the whole
    # point.
    #
    # a symmetric 10ms fade wrecks short percussive sounds. navigation.wav is
    # 55ms long and its peak is in the first millisecond, so a 10ms ramp was
    # flattening the attack and the file came out about half as loud as asked
    # for. 1.5ms is enough to kill the discontinuity and short enough the
    # transient survives. tail keeps the full 10ms - nothing to preserve back
    # there and a real risk of chopping off mid-cycle
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


def _write_stereo(
    name: str,
    left: list[float],
    right: list[float],
    peak_target: float = 0.34,
) -> None:
    """Write one stereo 16-bit WAV, with **no edge fades**.

    Deliberately different from [_write] on exactly that point. Fades exist
    there to kill the click at the start and end of a one-shot effect. A
    seamless loop is the opposite problem: playback runs off the end of this
    file straight back into its start, so a fade at either edge is an audible
    dip in the music every 48 seconds. [ambient_loop_stereo] instead makes the
    join continuous by construction — every layer wraps — so there is nothing
    here to de-click.

    Both channels share one gain so the stereo image is not shifted by
    normalising each side independently.
    """
    if not left or not right:
        return
    peak = max(max(abs(s) for s in left), max(abs(s) for s in right)) or 1.0
    gain = peak_target / peak

    frames = bytearray()
    for l, r in zip(left, right):
        for v in (l * gain, r * gain):
            frames += struct.pack("<h", int(max(-1.0, min(1.0, v)) * 32767))

    path = os.path.join(OUT, name)
    with wave.open(path, "wb") as f:
        f.setnchannels(2)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(bytes(frames))
    print(f"  {name:24} {len(left) / RATE:.2f}s stereo")


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


# ---------------------------------------------------------------------------
# Ambient music
# ---------------------------------------------------------------------------
#
# WHAT WAS WRONG WITH THE FIRST VERSION
# -------------------------------------
# It was a fixed A-and-E drone with random pentatonic plucks sprinkled on a
# uniform 0.75s grid, 24 seconds long, in mono. Four things followed from
# that, and all four are why it wore thin:
#
#   * **The harmony never moved.** One dyad for the whole loop, forever. A
#     drone is a bed, not a piece of music, and the ear stops hearing a bed
#     within a minute and starts hearing a hum.
#   * **The melody had no phrasing.** A 62% chance of a note in *every* slot
#     is a note roughly every 1.2 seconds with no rests, which reads as
#     noodling rather than as a tune. Music needs silence to have shape.
#   * **It repeated every 24 seconds**, which is short enough to notice.
#   * **It was mono**, so it sat in the middle of your head instead of
#     around you — the single biggest reason background music feels cheap.
#
# WHAT THIS DOES INSTEAD
# ----------------------
# An eight-chord progression in A natural minor (Am F C G Am Dm F Em), six
# seconds each, 48 seconds total. Every chord is diatonic, which matters for
# a specific reason: the melody is drawn from the A-minor pentatonic (A C D
# E G), and those five notes are consonant against all six of those chords.
# So the melody can still be generated rather than composed and *cannot*
# produce a sour interval — the same safety the original relied on, but now
# over harmony that actually moves. (This is why the turnaround is Em and not
# a "stronger" E major: E major's G# clashes with the pentatonic's G.)
#
# Seamlessness is by construction rather than by fading the edges. Every
# layer is mixed with wrap-around, so the last chord's pad tail and the final
# plucks' decay ring *into the start of the file*. A fade at the boundary
# would be an audible dip every 48 seconds; this way the join is inaudible
# because there is no join.

# root, then the pad voicing above it. Voiced to keep motion small between
# neighbours rather than leaping an octave every six seconds.
_PROGRESSION = (
    ("Am", 110.00, (220.00, 261.63, 329.63)),
    ("F", 87.31, (220.00, 261.63, 349.23)),
    ("C", 130.81, (261.63, 329.63, 392.00)),
    ("G", 98.00, (246.94, 293.66, 392.00)),
    ("Am", 110.00, (220.00, 261.63, 329.63)),
    ("Dm", 146.83, (220.00, 293.66, 349.23)),
    ("F", 87.31, (220.00, 261.63, 349.23)),
    ("Em", 82.41, (246.94, 329.63, 392.00)),
)

# A minor pentatonic, mid register. Deliberately capped below ~880Hz: the
# old loop ran to C#6 and the result was tinkly over a low drone, with a
# hollow middle where the music should have been.
_PENTATONIC = (329.63, 392.00, 440.00, 523.25, 587.33, 659.25, 783.99, 880.00)


def _mix_wrap(dst: list[float], src: list[float], start: int, gain=1.0) -> None:
    """Mix `src` into `dst` at `start`, wrapping past the end back to 0.

    This is what makes the loop seamless: a note or pad tail that overhangs
    the end of the file continues at the beginning, which is exactly where
    playback goes next.
    """
    n = len(dst)
    if n == 0:
        return
    for i, v in enumerate(src):
        dst[(start + i) % n] += v * gain


def _pad_voice(freq: float, dur: float, detune_cents: float) -> list[float]:
    """One sustained pad note with a slow swell in and out.

    Two oscillators a few cents apart, because the slow beating between them
    is most of what separates a warm pad from a test tone. A quiet octave
    above adds air without brightness.
    """
    n = int(RATE * dur)
    out = [0.0] * n
    f2 = freq * (2 ** (detune_cents / 1200.0))
    attack = int(n * 0.35)
    release = int(n * 0.45)
    for i in range(n):
        t = i / RATE
        if i < attack:
            env = i / attack
        elif i > n - release:
            env = (n - i) / release
        else:
            env = 1.0
        env *= env  # squared, so the swell is gentle rather than linear
        v = (
            math.sin(2 * math.pi * freq * t)
            + 0.85 * math.sin(2 * math.pi * f2 * t)
            + 0.12 * math.sin(2 * math.pi * freq * 2 * t)
        )
        out[i] = v * env
    return out


def _bass_note(freq: float, dur: float) -> list[float]:
    """The chord root, with a soft attack so it never thumps."""
    n = int(RATE * dur)
    out = [0.0] * n
    attack = int(n * 0.25)
    release = int(n * 0.4)
    for i in range(n):
        t = i / RATE
        if i < attack:
            env = i / attack
        elif i > n - release:
            env = (n - i) / release
        else:
            env = 1.0
        out[i] = (
            math.sin(2 * math.pi * freq * t)
            + 0.18 * math.sin(2 * math.pi * freq * 2 * t)
        ) * env * env
    return out


def _lowpass_circular(samples: list[float], coeff: float) -> list[float]:
    """One-pole smoothing, run as if the signal were already looping.

    Takes the edge off the synthesised harmonics so the result reads as warm
    rather than buzzy — but the *circular* part is load-bearing, not a
    flourish. Starting a one-pole filter from zero ramps the first few
    milliseconds up from silence, and on a seamless loop that ramp lands
    exactly at the join: measured, it made the loop point a 5x-larger sample
    step than anywhere else in the file, which is a click every 48 seconds.
    Priming the filter with the state it ends in makes the response periodic,
    like the signal it is filtering.
    """
    prev = 0.0
    for s in samples:  # warm-up pass, output discarded
        prev += coeff * (s - prev)
    out = [0.0] * len(samples)
    for i, s in enumerate(samples):
        prev += coeff * (s - prev)
        out[i] = prev
    return out


def ambient_loop_stereo(chord_seconds=6.0) -> tuple[list[float], list[float]]:
    """The 48-second stereo music bed. Returns (left, right)."""
    rng = random.Random(7)
    total = int(RATE * chord_seconds * len(_PROGRESSION))
    left = [0.0] * total
    right = [0.0] * total

    # Chords overlap their neighbour so the harmony crossfades instead of
    # pulsing; the overlap on the *last* chord wraps into the first.
    overlap = chord_seconds * 0.5
    voice_dur = chord_seconds + overlap

    for index, (_name, root, voicing) in enumerate(_PROGRESSION):
        start = int(index * chord_seconds * RATE)

        # Bass stays centred — low frequencies carry no useful directional
        # information and a panned bass just sounds lopsided. Its level is
        # kept modest because a loud centred layer is also the thing that
        # drags the stereo image back to mono.
        bass = _bass_note(root, voice_dur)
        _mix_wrap(left, bass, start, 0.24)
        _mix_wrap(right, bass, start, 0.24)

        # Each pad voice sits at a different point in the stereo field, is
        # detuned differently, and reaches the two ears a few milliseconds
        # apart. That last one is the Haas effect and it is doing most of the
        # work: amplitude panning alone left the mix 95% correlated, which is
        # very nearly mono, and a few ms of inter-channel delay widens it far
        # more convincingly than turning the pan knob further would.
        for v, freq in enumerate(voicing):
            pan = -0.8 + 1.6 * (v / max(1, len(voicing) - 1))
            detune = (-7.0, 4.0, 9.0)[v % 3]
            voice = _pad_voice(freq, voice_dur, detune)
            haas = int(RATE * 0.006 * pan)  # ±6ms, following the pan
            _mix_wrap(left, voice, start, 0.13 * (1.0 - max(0.0, pan) * 0.75))
            _mix_wrap(
                right,
                voice,
                start + haas,
                0.13 * (1.0 + min(0.0, pan) * 0.75),
            )

    # Melody, phrased. Each chord gets a short run of notes and then a rest,
    # which is the difference between a tune and a note generator.
    for index in range(len(_PROGRESSION)):
        chord_start = index * chord_seconds
        # Rest entirely on some chords — the space is what makes the phrases
        # that do play read as deliberate.
        if rng.random() < 0.22:
            continue
        note_count = rng.choice((2, 3, 3, 4))
        cursor = chord_start + rng.uniform(0.0, 0.6)
        for _ in range(note_count):
            freq = _PENTATONIC[rng.randrange(len(_PENTATONIC))]
            note = _tone(freq, 2.2, decay=2.6, harmonics=(1.0, 0.22, 0.06))
            pan = rng.uniform(-0.5, 0.5)
            level = rng.uniform(0.16, 0.26)
            at = int(cursor * RATE)
            _mix_wrap(left, note, at, level * (1.0 - max(0.0, pan)))
            _mix_wrap(right, note, at, level * (1.0 + min(0.0, pan)))
            cursor += rng.choice((0.5, 0.75, 0.75, 1.0, 1.5))
            if cursor > chord_start + chord_seconds - 0.4:
                break

    # Cross-panned echoes. Four fixed taps rather than a feedback loop,
    # because taps can be wrapped around the loop point and a feedback line
    # cannot — and an echo that dies at the seam is the seam becoming
    # audible.
    echo_l = [0.0] * total
    echo_r = [0.0] * total
    tap = int(0.42 * RATE)
    gain = 0.34
    for n in range(1, 5):
        offset = tap * n
        g = gain ** n
        # Swap sides each tap so the repeats bounce across the field.
        src_l, src_r = (right, left) if n % 2 else (left, right)
        for i in range(total):
            j = (i + offset) % total
            echo_l[j] += src_l[i] * g
            echo_r[j] += src_r[i] * g

    for i in range(total):
        left[i] += echo_l[i]
        right[i] += echo_r[i]

    return _lowpass_circular(left, 0.42), _lowpass_circular(right, 0.42)


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
    # else for as long as the app is open. Written last because it is also by
    # far the slowest to synthesise.
    music_l, music_r = ambient_loop_stereo()
    _write_stereo("ambient_loop.wav", music_l, music_r, peak_target=0.34)


if __name__ == "__main__":
    main()
