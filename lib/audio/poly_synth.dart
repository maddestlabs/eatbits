import 'dart:math' as math;

class PolySynth {
  static const int sampleRate = 44100;

  // Convert MIDI note number to frequency (Hz)
  static double midiToFreq(int note) {
    return 440.0 * math.pow(2.0, (note - 69) / 12.0);
  }

  // Synthesize Drum & Sampler PCM Audio Buffers (Float32List)
  static List<double> generateKickBuffer({double lengthSec = 0.3}) {
    final int numSamples = (sampleRate * lengthSec).toInt();
    final buffer = List<double>.filled(numSamples, 0.0);

    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      // Exponential pitch drop from 150Hz to 40Hz
      final freq = 40.0 + 110.0 * math.exp(-t * 35.0);
      final phase = 2.0 * math.pi * freq * t;
      final env = math.exp(-t * 12.0);
      // Soft clip saturation
      final sample = math.sin(phase) * env;
      buffer[i] = (sample * 1.2).clamp(-1.0, 1.0);
    }
    return buffer;
  }

  static List<double> generateSnareBuffer({double lengthSec = 0.25}) {
    final int numSamples = (sampleRate * lengthSec).toInt();
    final buffer = List<double>.filled(numSamples, 0.0);
    final random = math.Random(42);

    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      // Tonal body 180Hz
      final body = math.sin(2.0 * math.pi * 180.0 * t) * math.exp(-t * 25.0);
      // White noise snare wires
      final noise = (random.nextDouble() * 2.0 - 1.0) * math.exp(-t * 15.0);
      buffer[i] = (body * 0.5 + noise * 0.5).clamp(-1.0, 1.0);
    }
    return buffer;
  }

  static List<double> generateHiHatBuffer({bool open = false, double lengthSec = 0.15}) {
    final dur = open ? 0.3 : 0.08;
    final int numSamples = (sampleRate * dur).toInt();
    final buffer = List<double>.filled(numSamples, 0.0);
    final random = math.Random(1234);

    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      // High-pass filtered noise
      final noise = (random.nextDouble() * 2.0 - 1.0);
      final env = math.exp(-t * (open ? 12.0 : 45.0));
      buffer[i] = (noise * env * 0.6).clamp(-1.0, 1.0);
    }
    return buffer;
  }

  static List<double> generateClapBuffer({double lengthSec = 0.22}) {
    final int numSamples = (sampleRate * lengthSec).toInt();
    final buffer = List<double>.filled(numSamples, 0.0);
    final random = math.Random(999);

    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      // Multi-burst envelope for realistic clap
      double burstEnv = 0.0;
      if (t < 0.01) burstEnv = 1.0;
      else if (t < 0.02) burstEnv = 0.8;
      else if (t < 0.035) burstEnv = 0.9;
      else burstEnv = math.exp(-(t - 0.035) * 20.0);

      final noise = (random.nextDouble() * 2.0 - 1.0);
      buffer[i] = (noise * burstEnv * 0.7).clamp(-1.0, 1.0);
    }
    return buffer;
  }

  // Synthesize Instrumental Synth Tone Buffer
  static List<double> generateSynthToneBuffer({
    required int midiNote,
    required String waveform,
    double cutoff = 3000.0,
    double attack = 0.01,
    double release = 0.3,
    double lengthSec = 0.5,
  }) {
    final double freq = midiToFreq(midiNote);
    final int numSamples = (sampleRate * lengthSec).toInt();
    final buffer = List<double>.filled(numSamples, 0.0);

    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      double raw = 0.0;
      final phase = t * freq;
      final normPhase = phase - phase.floorToDouble();

      switch (waveform) {
        case 'sine':
          raw = math.sin(2.0 * math.pi * phase);
          break;
        case 'square':
          raw = normPhase < 0.5 ? 0.7 : -0.7;
          break;
        case 'sawtooth':
        default:
          raw = 2.0 * (normPhase - 0.5);
          break;
      }

      // Envelope ADSR
      double env = 0.0;
      if (t < attack) {
        env = t / attack;
      } else {
        env = math.exp(-(t - attack) / release);
      }

      buffer[i] = (raw * env * 0.8).clamp(-1.0, 1.0);
    }
    return buffer;
  }
}
