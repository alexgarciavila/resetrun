"""Generate the original Reset Run chiptune loop and short game cues (stdlib only)."""
from pathlib import Path
import math
import struct
import wave

RATE = 22050
ROOT = Path(__file__).resolve().parents[1] / "audio"


def save(name, samples, loop=False):
    ROOT.mkdir(exist_ok=True)
    with wave.open(str(ROOT / name), "wb") as output:
        output.setparams((1, 2, RATE, 0, "NONE", "not compressed"))
        output.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s)) * 32767)) for s in samples))


def cue(name, notes, duration, gain=0.22):
    result = []
    for index in range(round(RATE * duration)):
        time = index / RATE
        progress = time / duration
        frequency = notes[min(int(progress * len(notes)), len(notes) - 1)]
        envelope = min(time / 0.008, 1) * (1 - progress) ** 1.5
        tone = math.sin(math.tau * frequency * time) + 0.3 * math.sin(math.tau * frequency * 2 * time)
        result.append(tone * envelope * gain)
    save(name, result)


def music():
    step = 0.15
    melody = [76, 79, 83, 79, 74, 79, 81, 79, 72, 76, 79, 76, 74, 78, 81, 78,
              76, 79, 83, 86, 83, 79, 81, 79, 72, 76, 79, 83, 74, 78, 81, 78]
    bass = [40, 40, 36, 38]
    samples = []
    for index in range(round(RATE * step * len(melody))):
        time = index / RATE
        beat = int(time / step)
        local = time % step
        frequency = 440 * 2 ** ((melody[beat] - 69) / 12)
        low = 440 * 2 ** ((bass[beat // 8] - 69) / 12)
        envelope = min(local / 0.006, 1) * max(0, 1 - local / step) ** 0.65
        lead = (math.sin(math.tau * frequency * local) + math.sin(math.tau * frequency * 3 * local) / 3) * envelope * 0.11
        bass_envelope = math.sin(math.pi * (time % (step * 2)) / (step * 2))
        bottom = math.sin(math.tau * low * time) * bass_envelope * 0.14
        kick_time = time % (step * 4)
        kick = math.sin(math.tau * (60 * kick_time + 10 * (1 - math.exp(-kick_time * 30)))) * math.exp(-kick_time * 35) * 0.16
        samples.append(lead + bottom + kick)
    save("music.wav", samples)


if __name__ == "__main__":
    music()
    cue("jump.wav", [440, 554, 659, 880], 0.18)
    cue("hit.wav", [180, 130, 95, 60], 0.24, 0.3)
    cue("game_over.wav", [392, 330, 294, 220, 165], 0.8)
    cue("select.wav", [659, 880], 0.09, 0.14)
