"""Create a brief musical impact from Arcade Pulse (numpy and soundfile)."""
from pathlib import Path

import numpy as np
import soundfile as sf

ROOT = Path(__file__).resolve().parents[1]


def main():
    source, rate = sf.read(ROOT / "audio/arcade_pulse.ogg", always_2d=True)
    duration = 0.32
    time = np.arange(round(rate * duration)) / rate
    progress = time / duration
    # A quick downward bend of the soundtrack's opening attack.
    speed = 1.0 - 0.68 * progress ** 0.55
    position = np.cumsum(speed)
    position -= position[0]
    dry = np.column_stack([
        np.interp(position, np.arange(len(source)), source[:, channel])
        for channel in range(source.shape[1])
    ])
    envelope = np.minimum(time / 0.004, 1) * (1 - progress) ** 1.4
    dry *= envelope[:, None]
    # Punchy downward sweep, distorted body and a short electronic crack.
    attack = np.minimum(time / 0.002, 1)
    release = np.minimum((duration - time) / 0.035, 1)
    phase = 2 * np.pi * (48 * time + 5.5 * (1 - np.exp(-time * 38)))
    thump = np.tanh(5.0 * np.sin(phase)) * np.exp(-time * 14)
    rng = np.random.default_rng(17)
    noise = rng.uniform(-1, 1, len(time))
    crack = (noise - np.roll(noise, 1)) * np.exp(-time * 38)
    zap_phase = 2 * np.pi * (130 * time + 11 * (1 - np.exp(-time * 45)))
    zap = np.sin(zap_phase) * np.exp(-time * 32)
    metal = (np.sin(2 * np.pi * 817 * time)
             + 0.6 * np.sin(2 * np.pi * 1237 * time)
             + 0.4 * np.sin(2 * np.pi * 2011 * time)) * np.exp(-time * 42)
    impact = (thump * 0.65 + crack * 0.48 + zap * 0.24 + metal * 0.20) * attack * release
    dry = np.tanh((dry * 0.35 + impact[:, None]) * 2.6) * 0.8
    result = np.zeros((len(dry) + round(rate * 0.11), dry.shape[1]))
    result[:len(dry)] = dry
    offset = round(rate * 0.045)
    result[offset:offset + len(dry)] += dry[:, ::-1] * 0.16
    peak = np.max(np.abs(result))
    if peak > 0:
        result *= 0.8 / peak
    sf.write(ROOT / "audio/hit.wav", result, rate, subtype="PCM_16")


if __name__ == "__main__":
    main()
