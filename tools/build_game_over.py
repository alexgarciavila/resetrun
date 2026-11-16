"""Build a musical defeat sting from the game's actual soundtrack.

Requires numpy and soundfile. Keeps the source Ogg untouched.
"""
from pathlib import Path

import numpy as np
import soundfile as sf

ROOT = Path(__file__).resolve().parents[1]


def main():
    source, rate = sf.read(ROOT / "audio/arcade_pulse.ogg", always_2d=True)
    # Two beats of the original arrangement, then a tape-stop descent.
    # The measured pulse is approximately 147 BPM.
    beat = 60 / 147
    duration = beat * 6
    time = np.arange(round(duration * rate)) / rate
    brake_start = beat * 2
    progress = np.clip((time - brake_start) / (duration - brake_start), 0, 1)
    speed = 1 - 0.94 * progress ** 0.75
    position = np.cumsum(speed)
    position -= position[0]
    coordinates = np.arange(len(source))
    dry = np.column_stack([
        np.interp(position, coordinates, source[:, channel])
        for channel in range(source.shape[1])
    ])
    envelope = np.minimum(time / 0.009, 1) * (1 - progress) ** 0.7
    dry *= envelope[:, None]
    result = np.zeros((len(dry) + round(rate * 0.8), dry.shape[1]))
    result[:len(dry)] = dry
    # Alternating stereo echoes leave a short musical tail after the slowdown.
    for delay, gain in [(beat / 2, 0.22), (beat, 0.12), (beat * 1.5, 0.06)]:
        offset = round(delay * rate)
        result[offset:offset + len(dry)] += dry[:, ::-1] * gain
    result[-round(rate * 0.15):] *= np.linspace(1, 0, round(rate * 0.15))[:, None]
    peak = np.max(np.abs(result))
    if peak > 0.9:
        result *= 0.9 / peak
    sf.write(ROOT / "audio/game_over.wav", result, rate, subtype="PCM_16")


if __name__ == "__main__":
    main()
