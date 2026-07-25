class WrenPreset {
  final String id;
  final String name;
  final String category; // 'synth' or 'effect'
  final String description;
  final String code;

  const WrenPreset({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.code,
  });
}

class WrenPresetLibrary {
  static const List<WrenPreset> presets = [
    WrenPreset(
      id: 'acid_303',
      name: 'Acid 303 Bass Synth',
      category: 'synth',
      description: 'Classic analog resonant filter sweep synthesizer inspired by the Roland TB-303.',
      code: '''
// --- Acid 303 Bass Synth Script ---
class AcidSynth {
  static init() {
    Param.add("Cutoff", 100.0, 8000.0, 1800.0)
    Param.add("Resonance", 0.5, 12.0, 5.0)
    Param.add("EnvMod", 0.0, 1.0, 0.75)
    Param.add("Decay", 0.05, 1.0, 0.25)
    Param.add("Accent", 0.0, 1.0, 0.5)
  }

  static process(time, freq, note, params) {
    var cutoff = params["Cutoff"]
    var res = params["Resonance"]
    var envMod = params["EnvMod"]
    var decay = params["Decay"]

    // Sawtooth + Square morph oscillator
    var phase = time * freq
    var saw = 2.0 * (phase - Math.floor(phase + 0.5))
    var square = saw > 0.0 ? 0.7 : -0.7
    var rawOsc = saw * 0.7 + square * 0.3

    // Envelope modulation
    var env = Math.exp(-time / decay)
    var modCutoff = cutoff + (envMod * env * 5000.0)
    
    // Resonant Filter Simulation
    var filtered = DSP.lowpass(rawOsc, modCutoff, res)
    return filtered * env
  }
}
''',
    ),
    WrenPreset(
      id: 'fm_synth',
      name: 'Dual-Op FM Synth',
      category: 'synth',
      description: 'Frequency Modulation synthesizer producing glassy metallic keys and punchy electronic tones.',
      code: '''
// --- FM Metallic Keys & Bass Synth ---
class FMSynth {
  static init() {
    Param.add("ModRatio", 0.5, 8.0, 2.0)
    Param.add("ModIndex", 0.0, 10.0, 3.5)
    Param.add("Attack", 0.001, 0.1, 0.005)
    Param.add("Release", 0.05, 2.0, 0.4)
  }

  static process(time, freq, note, params) {
    var ratio = params["ModRatio"]
    var index = params["ModIndex"]
    var attack = params["Attack"]
    var release = params["Release"]

    // ADSR Envelope
    var env = DSP.envelope(time, attack, release)

    // Modulator Oscillator
    var modFreq = freq * ratio
    var modulator = Math.sin(2.0 * Math.pi * modFreq * time) * (index * env)

    // Carrier Oscillator with Frequency Modulation
    var carrier = Math.sin(2.0 * Math.pi * freq * time + modulator)

    return carrier * env * 0.8
  }
}
''',
    ),
    WrenPreset(
      id: 'bitcrusher_fx',
      name: '8-Bit Retro Crusher FX',
      category: 'effect',
      description: 'Bit-depth and sample-rate reduction effect for lo-fi chiptune textures.',
      code: '''
// --- 8-Bit Retro Bitcrusher Effect ---
class BitcrusherFX {
  static init() {
    Param.add("Bits", 2.0, 16.0, 6.0)
    Param.add("Downsample", 1.0, 16.0, 4.0)
    Param.add("Mix", 0.0, 1.0, 0.8)
  }

  static processSignal(inputSample, time, params) {
    var bits = params["Bits"]
    var downsample = params["Downsample"]
    var mix = params["Mix"]

    // Bit depth quantize
    var steps = Math.pow(2.0, bits)
    var quantized = Math.floor(inputSample * steps) / steps

    // Sample rate reduction
    var crushed = DSP.sampleHold(quantized, downsample)

    // Dry / Wet Mix
    return (inputSample * (1.0 - mix)) + (crushed * mix)
  }
}
''',
    ),
    WrenPreset(
      id: 'tube_distortion',
      name: 'Warm Tube Distortion',
      category: 'effect',
      description: 'Non-linear soft-clipping saturation and warmth.',
      code: '''
// --- Warm Tube Overdrive ---
class TubeDistortion {
  static init() {
    Param.add("Drive", 1.0, 20.0, 6.0)
    Param.add("Tone", 200.0, 8000.0, 3500.0)
    Param.add("OutGain", 0.1, 1.5, 0.7)
  }

  static processSignal(inputSample, time, params) {
    var drive = params["Drive"]
    var tone = params["Tone"]
    var outGain = params["OutGain"]

    // Soft clipping hyperbolic tangent curve
    var driven = inputSample * drive
    var clipped = Math.tanh(driven)

    // Post tone filter
    var filtered = DSP.lowpass(clipped, tone, 1.0)
    return filtered * outGain
  }
}
''',
    ),
  ];
}
