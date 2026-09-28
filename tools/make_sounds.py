"""Synthesizes every sound effect in res://sounds/.

Nothing here is sampled: each sound is built from noise, sines and envelopes,
so the whole set can be re-tuned by editing a number and re-running

    python tools/make_sounds.py

Needs only numpy. Output is 16-bit mono 44.1 kHz WAV, peak-normalized, with
short fades on both ends so nothing clicks when it starts or stops. The seed is
fixed, so re-running without edits reproduces the same files byte for byte.
"""

import os
import wave

import numpy as np

SR = 44100
OUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "sounds")
rng = np.random.default_rng(1152)


# ---------------------------------------------------------------- building blocks

def seconds(duration):
    return np.arange(int(SR * duration)) / SR


def noise(duration):
    return rng.standard_normal(int(SR * duration))


def decay(t, tau):
    return np.exp(-t / tau)


def sweep_sine(t, freq):
    """Sine whose frequency follows the array `freq`, sample by sample."""
    return np.sin(2.0 * np.pi * np.cumsum(freq) / SR)


def biquad(x, kind, freq, q=0.707):
    """RBJ-cookbook biquad. `freq` may be a scalar or a per-sample array, which
    is how the whooshes and the crash sweep their filters."""
    freq = np.broadcast_to(np.asarray(freq, dtype=float), x.shape)
    y = np.zeros_like(x)
    x1 = x2 = y1 = y2 = 0.0
    b0 = b1 = b2 = a1 = a2 = 0.0

    for i in range(len(x)):
        if i % 16 == 0:
            w0 = 2.0 * np.pi * min(freq[i], SR * 0.45) / SR
            alpha = np.sin(w0) / (2.0 * q)
            cos_w0 = np.cos(w0)
            a0 = 1.0 + alpha
            if kind == "low":
                b0, b1, b2 = (1 - cos_w0) / 2, 1 - cos_w0, (1 - cos_w0) / 2
            elif kind == "high":
                b0, b1, b2 = (1 + cos_w0) / 2, -(1 + cos_w0), (1 + cos_w0) / 2
            else:  # band, constant peak gain
                b0, b1, b2 = alpha, 0.0, -alpha
            a1, a2 = -2 * cos_w0, 1 - alpha
            b0, b1, b2, a1, a2 = b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0

        y0 = b0 * x[i] + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
        x2, x1 = x1, x[i]
        y2, y1 = y1, y0
        y[i] = y0

    return y


def place(canvas, sound, at):
    """Mixes `sound` into `canvas` starting at `at` seconds, clipped to fit."""
    start = int(at * SR)
    end = min(len(canvas), start + len(sound))
    if start < end:
        canvas[start:end] += sound[: end - start]


def soft_clip(x, drive):
    return np.tanh(x * drive) / np.tanh(drive)


def click(duration, centre, q=0.9):
    t = seconds(duration)
    return biquad(noise(duration), "band", centre, q) * decay(t, duration / 4)


def write(name, x, peak=0.89, fade_in=0.001, fade_out=0.012):
    x = x - np.mean(x)
    x = x / np.max(np.abs(x)) * peak
    n_in, n_out = int(fade_in * SR), int(fade_out * SR)
    if n_in:
        x[:n_in] *= np.linspace(0.0, 1.0, n_in)
    if n_out:
        x[-n_out:] *= np.linspace(1.0, 0.0, n_out)

    path = os.path.join(OUT_DIR, name + ".wav")
    with wave.open(path, "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(SR)
        out.writeframes((x * 32767).astype("<i2").tobytes())
    print("wrote", os.path.relpath(path), "%.2fs" % (len(x) / SR))


# ---------------------------------------------------------------- the fight

def whoosh():
    """The swing. Builds toward the end so it peaks right as the fist lands."""
    duration = 0.34
    t = seconds(duration)
    shape = np.sin(np.pi * np.clip(t / duration, 0, 1) ** 1.6) ** 2
    centre = 380 + 1700 * shape
    air = biquad(noise(duration), "band", centre, 1.1)
    body = biquad(noise(duration), "low", 500) * 0.5
    return (air + body) * shape


def hit():
    """Knuckles into plaster: a pitched-down thump under a hard snap."""
    duration = 0.6
    t = seconds(duration)
    thump = sweep_sine(t, 44 + 120 * decay(t, 0.028)) * decay(t, 0.14)
    knock = biquad(noise(duration), "low", 950) * decay(t, 0.035) * 0.9
    snap = biquad(noise(duration), "high", 2200) * decay(t, 0.006) * 0.6
    crunch = np.zeros(len(t))
    for _ in range(14):
        place(crunch, click(0.004, rng.uniform(1500, 3800)) * rng.uniform(0.2, 0.5),
              rng.exponential(0.05))
    return soft_clip(thump + knock + snap + crunch, 1.8)


def crack():
    """The wall giving a little: a brittle run of ticks that thins out."""
    duration = 0.55
    canvas = np.zeros(int(SR * duration))
    for index in range(26):
        at = rng.exponential(0.07)
        loudness = np.exp(-at / 0.12) * rng.uniform(0.4, 1.0)
        place(canvas, click(rng.uniform(0.002, 0.006), rng.uniform(1800, 4200)) * loudness, at)
        if index % 5 == 0:
            tock_t = seconds(0.03)
            tock = np.sin(2 * np.pi * rng.uniform(380, 700) * tock_t) * decay(tock_t, 0.008)
            place(canvas, tock * loudness * 0.6, at)
    return canvas


def miss():
    """Soft and a bit deflating: the punch lands on nothing much."""
    duration = 0.3
    t = seconds(duration)
    thud = sweep_sine(t, 70 + 50 * decay(t, 0.04)) * decay(t, 0.06)
    dust = biquad(noise(duration), "low", 420) * decay(t, 0.045) * 0.7
    return thud + dust


def lock():
    """A woodblock tap for committing a direction. Played higher for the
    attacker and lower for the defender, so it never says *which* way."""
    duration = 0.12
    t = seconds(duration)
    tone = np.sin(2 * np.pi * 1000 * t) * decay(t, 0.025)
    overtone = np.sin(2 * np.pi * 2710 * t) * decay(t, 0.009) * 0.45
    tap = click(0.003, 3000) * 0.5
    out = tone + overtone
    place(out, tap, 0.0)
    return out


def tick():
    """Clock tick for the last second of a turn."""
    duration = 0.06
    t = seconds(duration)
    ping = np.sin(2 * np.pi * 2300 * t) * decay(t, 0.007)
    out = ping * 0.6
    place(out, click(0.002, 4500), 0.0)
    return out


def buzzer():
    """Too slow. Two detuned saws through a lowpass, game-show cheap."""
    duration = 0.5
    t = seconds(duration)
    saw = np.zeros(len(t))
    for fundamental in (98.0, 103.5):
        for harmonic in range(1, 30):
            saw += np.sin(2 * np.pi * fundamental * harmonic * t) / harmonic
    envelope = np.clip(t / 0.01, 0, 1) * np.clip((duration - t) / 0.08, 0, 1)
    return biquad(saw, "low", 1700) * envelope


def bell():
    """One strike of a ring bell. Inharmonic partials, each paired with a
    slightly detuned twin so the tail shimmers the way brass does."""
    duration = 2.2
    t = seconds(duration)
    fundamental = 1046.0
    partials = [
        (0.56, 0.30, 1.5),
        (1.00, 1.00, 1.3),
        (1.19, 0.40, 0.9),
        (1.51, 0.45, 0.7),
        (2.00, 0.30, 0.5),
        (2.74, 0.22, 0.32),
        (3.76, 0.13, 0.2),
        (5.40, 0.08, 0.1),
    ]
    out = np.zeros(len(t))
    for ratio, amplitude, tau in partials:
        freq = fundamental * ratio
        out += amplitude * np.sin(2 * np.pi * freq * t) * decay(t, tau)
        out += amplitude * 0.3 * np.sin(2 * np.pi * (freq + 1.3) * t) * decay(t, tau)
    strike = biquad(noise(duration), "high", 3000) * decay(t, 0.004) * 0.7
    return out + strike


def rumble():
    """The wall about to go: a low swell with plaster starting to give."""
    duration = 1.1
    t = seconds(duration)
    swell = np.clip(t / 0.75, 0, 1) ** 2 * np.clip((duration - t) / 0.2, 0, 1)
    low = biquad(noise(duration), "low", 170, 1.2) * 2.2
    grit = biquad(noise(duration), "band", 900, 0.8) * 0.25
    out = (low + grit) * swell
    for _ in range(40):
        at = duration * np.sqrt(rng.uniform(0, 1))
        place(out, click(rng.uniform(0.003, 0.01), rng.uniform(900, 3000)) * rng.uniform(0.2, 0.6), at)
    return out


def crash():
    """The wall coming down, then the rubble settling."""
    duration = 1.9
    t = seconds(duration)
    boom = sweep_sine(t, 36 + 90 * decay(t, 0.05)) * decay(t, 0.35) * 1.3
    cutoff = 300 + 6000 * decay(t, 0.18)
    blast = biquad(noise(duration), "low", cutoff) * decay(t, 0.3)
    debris = np.zeros(len(t))
    for _ in range(90):
        at = 0.05 + rng.exponential(0.35)
        loudness = np.exp(-at / 0.6) * rng.uniform(0.2, 0.8)
        place(debris, click(rng.uniform(0.004, 0.02), rng.uniform(600, 3500)) * loudness, at)
    for _ in range(10):
        at = 0.1 + rng.exponential(0.3)
        thunk_t = seconds(0.06)
        thunk = np.sin(2 * np.pi * rng.uniform(140, 300) * thunk_t) * decay(thunk_t, 0.02)
        place(debris, thunk * np.exp(-at / 0.5) * 0.7, at)
    return soft_clip(boom + blast + debris, 1.5)


# ---------------------------------------------------------------- menus

def ui_move():
    duration = 0.04
    t = seconds(duration)
    out = np.sin(2 * np.pi * 1700 * t) * decay(t, 0.006)
    place(out, click(0.002, 3500) * 0.4, 0.0)
    return out


def ui_press():
    """A marker-cap pop."""
    duration = 0.14
    t = seconds(duration)
    pop = sweep_sine(t, 480 + 520 * np.clip(t / 0.04, 0, 1)) * decay(t, 0.035)
    body = np.sin(2 * np.pi * 170 * t) * decay(t, 0.03) * 0.5
    return pop + body


# ---------------------------------------------------------------- ambience

def hum():
    """The bare bulb. Exactly two seconds of whole cycles of everything, so it
    loops without a seam: 60 Hz mains, its buzzier harmonics, and a faint
    filament fizz made by giving an FFT random phases (which is periodic by
    construction)."""
    duration = 2.0
    t = seconds(duration)
    out = np.zeros(len(t))
    for harmonic, amplitude in [(1, 1.0), (2, 0.7), (3, 0.35), (4, 0.3), (5, 0.12),
                                (6, 0.14), (8, 0.08), (10, 0.05), (12, 0.035)]:
        out += amplitude * np.sin(2 * np.pi * 60 * harmonic * t + harmonic * 0.7)

    spectrum = np.zeros(len(t) // 2 + 1, dtype=complex)
    freqs = np.fft.rfftfreq(len(t), 1 / SR)
    band = (freqs > 2500) & (freqs < 7000)
    spectrum[band] = np.exp(1j * rng.uniform(0, 2 * np.pi, band.sum()))
    fizz = np.fft.irfft(spectrum, len(t))
    fizz = fizz / np.max(np.abs(fizz)) * 0.06

    wobble = 1.0 + 0.08 * np.sin(2 * np.pi * 0.5 * t) + 0.04 * np.sin(2 * np.pi * 1.5 * t)
    return (out * wobble) + fizz


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    write("whoosh", whoosh(), fade_in=0.01)
    write("hit", hit())
    write("crack", crack())
    write("miss", miss())
    write("lock", lock())
    write("tick", tick())
    write("buzzer", buzzer())
    write("bell", bell(), fade_out=0.05)
    write("rumble", rumble(), fade_in=0.02, fade_out=0.05)
    write("crash", crash(), fade_out=0.1)
    write("ui_move", ui_move())
    write("ui_press", ui_press())
    # Looping: no fades, or the seam would dip.
    write("hum", hum(), peak=0.7, fade_in=0, fade_out=0)


if __name__ == "__main__":
    main()
