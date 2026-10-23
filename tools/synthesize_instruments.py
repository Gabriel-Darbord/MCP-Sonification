"""Synthesize the instruments sound bank: short instrument notes as 48 kHz mono 16-bit WAV files.

Usage: python3 tools/synthesize_instruments.py [output-directory]
Default output: banks/instruments next to this script's parent directory.
Only the Python standard library is used, so it runs on macOS, Windows, and Linux.
"""

import math
import random
import struct
import sys
import wave
from pathlib import Path

RATE = 48000
NOTE_NAMES = {'c': 0, 'd': 2, 'e': 4, 'f': 5, 'g': 7, 'a': 9, 'b': 11}


def frequency(note):
    """'a4' -> 440.0, 'c5' -> 523.25..."""
    midi = 12 * (int(note[1:]) + 1) + NOTE_NAMES[note[0]]
    return 440.0 * 2 ** ((midi - 69) / 12)


def fade_out(samples, milliseconds=40):
    count = int(RATE * milliseconds / 1000)
    for i in range(count):
        samples[-count + i] *= 1 - i / count
    return samples


def normalize(samples, peak=0.7):
    loudest = max(abs(s) for s in samples) or 1.0
    return [s * peak / loudest for s in samples]


def pluck(freq, seconds=1.2):
    """Karplus-Strong plucked string."""
    rng = random.Random(int(freq * 100))
    period = int(RATE / freq)
    ring = [rng.uniform(-1, 1) for _ in range(period)]
    samples = []
    for i in range(int(RATE * seconds)):
        current = ring[i % period]
        following = ring[(i + 1) % period]
        ring[i % period] = 0.996 * 0.5 * (current + following)
        samples.append(current)
    return fade_out(samples)


def partials(freq, seconds, ratios, amplitudes, decays, attack=0.002):
    """Additive synthesis: each partial is a decaying sine."""
    samples = []
    for i in range(int(RATE * seconds)):
        t = i / RATE
        value = sum(
            amplitude * math.exp(-t / decay) * math.sin(2 * math.pi * freq * ratio * t)
            for ratio, amplitude, decay in zip(ratios, amplitudes, decays))
        samples.append(value * min(1.0, t / attack))
    return fade_out(samples)


def marimba(freq):
    return partials(freq, 1.0, [1, 3.93, 10.2], [1, 0.35, 0.08], [0.35, 0.08, 0.02])


def bell(freq):
    return partials(freq, 2.0, [1, 2.0, 2.76, 5.4, 8.93], [1, 0.5, 0.4, 0.25, 0.15], [1.6, 1.0, 0.8, 0.5, 0.3])


def low(freq):
    return partials(freq, 1.0, [1, 2, 3], [1, 0.3, 0.1], [0.5, 0.3, 0.2], attack=0.01)


INSTRUMENTS = {
    'pluck': (pluck, ['c4', 'e4', 'g4', 'c5', 'd5', 'e5', 'g5', 'a5', 'c6']),
    'marimba': (marimba, ['c3', 'c4', 'd4', 'e4', 'g4', 'a4', 'c5']),
    'bell': (bell, ['a4', 'c5', 'e5', 'g5', 'c6']),
    'low': (low, ['b2', 'c3', 'f3']),
}


def write_wave(path, samples):
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), 'wb') as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes(b''.join(struct.pack('<h', int(s * 32767)) for s in samples))


def main():
    default = Path(__file__).resolve().parent.parent / 'banks' / 'instruments'
    target = Path(sys.argv[1]) if len(sys.argv) > 1 else default
    for instrument, (synthesize, notes) in INSTRUMENTS.items():
        for note in notes:
            write_wave(target / instrument / f'{note}.wav', normalize(synthesize(frequency(note))))
            print(f'{instrument}/{note}')


if __name__ == '__main__':
    main()
