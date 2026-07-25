class WrenPreset {
  final String id;
  final String name;
  final String category; // 'synth', 'drum', or 'effect'
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
    // 1. JC-303 Acid Bass Synth (Modelled after midilab/jc303)
    WrenPreset(
      id: 'acid_303',
      name: 'TB-303 Acid Synth (JC-303)',
      category: 'synth',
      description: 'Roland TB-303 emulation modelled after midilab/jc303 with 24dB Diode Ladder filter, Accent, Slide, EnvMod, and Overdrive.',
      code: '''
// --- JC-303 Roland TB-303 Acid Engine ---
class Acid303 {
  static init() {
    Param.add("Waveform", 0.0, 1.0, 0.0)    // 0 = Saw, 1 = Square
    Param.add("Cutoff", 100.0, 6500.0, 1600.0)
    Param.add("Resonance", 0.5, 16.0, 8.0)
    Param.add("EnvMod", 0.0, 1.0, 0.75)
    Param.add("Decay", 0.05, 1.2, 0.28)
    Param.add("Accent", 0.0, 1.0, 0.6)
    Param.add("Slide", 0.0, 1.0, 0.4)
    Param.add("Overdrive", 0.0, 1.0, 0.3)
  }

  static process(time, freq, note, params) {
    var waveType = params["Waveform"]
    var cutoff = params["Cutoff"]
    var res = params["Resonance"]
    var envMod = params["EnvMod"]
    var decay = params["Decay"]
    var accent = params["Accent"]
    var drive = params["Overdrive"]

    // JC-303 Dual Waveform: Sawtooth & Square with 303 Highpass
    var phase = time * freq
    var normPhase = phase - Math.floor(phase)
    var saw = 2.0 * normPhase - 1.0
    var sqr = normPhase < 0.5 ? 0.75 : -0.75
    var osc = waveType < 0.5 ? saw : sqr

    // Accent envelope boost
    var envBoost = 1.0 + (accent * 0.8)
    var envDecay = decay / envBoost
    var env = Math.exp(-time / envDecay)

    // 24dB 4-Pole Diode Ladder Filter simulation
    var modCutoff = cutoff + (envMod * env * 5500.0 * envBoost)
    var filtered = DSP.lowpass(osc, modCutoff, res)

    // Overdrive saturation
    if (drive > 0.05) {
      filtered = Math.tanh(filtered * (1.0 + drive * 4.0))
    }

    return filtered * env * 0.85
  }
}
''',
    ),

    // 2. Procedural Snare Drum Preset
    WrenPreset(
      id: 'procedural_snare',
      name: 'Procedural Snare Drum',
      category: 'drum',
      description: 'Synthesized snare drum combining a 180Hz tonal body oscillator and high-pass filtered noise wires.',
      code: '''
// --- Procedural Snare Drum Script ---
class ProceduralSnare {
  static init() {
    Param.add("ToneFreq", 100.0, 300.0, 185.0)
    Param.add("Snappy", 0.0, 1.0, 0.65)
    Param.add("Decay", 0.05, 0.5, 0.22)
  }

  static process(time, freq, note, params) {
    var toneFreq = params["ToneFreq"]
    var snappy = params["Snappy"]
    var decay = params["Decay"]

    // Body tone (pitch sweep)
    var sweepFreq = toneFreq * Math.exp(-time * 40.0)
    var body = Math.sin(2.0 * Math.pi * sweepFreq * time) * Math.exp(-time * 25.0)

    // Snare noise wires
    var noise = (Math.random() * 2.0 - 1.0) * Math.exp(-time / decay)
    var filteredNoise = DSP.highpass(noise, 1500.0, 1.0)

    var output = body * (1.0 - snappy) + filteredNoise * snappy
    return Math.tanh(output * 1.2)
  }
}
''',
    ),

    // 3. Procedural Hi-Hat Preset
    WrenPreset(
      id: 'procedural_hihat',
      name: 'Procedural Hi-Hat',
      category: 'drum',
      description: 'Synthesis hi-hat using a metallic square ring cluster and high-pass filtered white noise.',
      code: '''
// --- Procedural Hi-Hat Synth Script ---
class ProceduralHiHat {
  static init() {
    Param.add("Cutoff", 4000.0, 14000.0, 8500.0)
    Param.add("Decay", 0.02, 0.4, 0.09)
    Param.add("Metallic", 0.0, 1.0, 0.4)
  }

  static process(time, freq, note, params) {
    var cutoff = params["Cutoff"]
    var decay = params["Decay"]
    var metallic = params["Metallic"]

    var env = Math.exp(-time / decay)

    // Metallic ring oscillator cluster (6 square waves)
    var ring = Math.sin(2.0 * Math.pi * 800.0 * time) *
               Math.sin(2.0 * Math.pi * 1340.0 * time) *
               Math.sin(2.0 * Math.pi * 2100.0 * time)

    // White noise generator
    var noise = (Math.random() * 2.0 - 1.0)
    var filteredNoise = DSP.highpass(noise * 0.7 + ring * metallic * 0.3, cutoff, 1.2)

    return filteredNoise * env * 0.7
  }
}
''',
    ),

    // 4. Procedural Clap Preset
    WrenPreset(
      id: 'procedural_clap',
      name: 'Procedural Handclap',
      category: 'drum',
      description: 'Multi-burst noise clap synthesizer simulating human handclap reverberation.',
      code: '''
// --- Procedural Handclap Script ---
class ProceduralClap {
  static init() {
    Param.add("RoomDecay", 0.05, 0.4, 0.18)
    Param.add("Tone", 800.0, 4000.0, 2200.0)
  }

  static process(time, freq, note, params) {
    var roomDecay = params["RoomDecay"]
    var tone = params["Tone"]

    // Multi-tap burst envelope
    var burstEnv = 0.0
    if (time < 0.01) burstEnv = 1.0
    else if (time < 0.022) burstEnv = 0.75
    else if (time < 0.035) burstEnv = 0.85
    else burstEnv = Math.exp(-(time - 0.035) / roomDecay)

    var noise = (Math.random() * 2.0 - 1.0)
    var filtered = DSP.bandpass(noise, tone, 2.0)

    return filtered * burstEnv * 0.8
  }
}
''',
    ),

    // 5. Wren Stereo Delay Effect
    WrenPreset(
      id: 'wren_delay',
      name: 'Wren Stereo Delay FX',
      category: 'effect',
      description: 'Feedback delay line effect module with dampening and dry/wet mix controls.',
      code: '''
// --- Wren Stereo Feedback Delay Effect ---
class StereoDelayFX {
  static init() {
    Param.add("TimeMs", 50.0, 800.0, 250.0)
    Param.add("Feedback", 0.0, 0.9, 0.45)
    Param.add("Dampening", 1000.0, 12000.0, 4500.0)
    Param.add("Mix", 0.0, 1.0, 0.4)
  }

  static processSignal(inputSample, time, params) {
    var timeMs = params["TimeMs"]
    var fb = params["Feedback"]
    var damp = params["Dampening"]
    var mix = params["Mix"]

    // Delayed sample read from WebAudio buffer
    var delayed = DSP.delay(inputSample, timeMs, fb)
    var dampened = DSP.lowpass(delayed, damp, 1.0)

    return (inputSample * (1.0 - mix)) + (dampened * mix)
  }
}
''',
    ),

    // 6. Wren Stereo Chorus Effect
    WrenPreset(
      id: 'wren_chorus',
      name: 'Wren Stereo Chorus FX',
      category: 'effect',
      description: 'LFO modulated short delay lines creating lush stereo chorus and ensemble thickness.',
      code: '''
// --- Wren Stereo Chorus Effect ---
class StereoChorusFX {
  static init() {
    Param.add("RateHz", 0.1, 5.0, 1.2)
    Param.add("DepthMs", 1.0, 15.0, 6.0)
    Param.add("Mix", 0.0, 1.0, 0.5)
  }

  static processSignal(inputSample, time, params) {
    var rate = params["RateHz"]
    var depth = params["DepthMs"]
    var mix = params["Mix"]

    // LFO Modulation
    var lfo = Math.sin(2.0 * Math.pi * rate * time)
    var modulatedTime = 12.0 + (lfo * depth)

    var wet = DSP.delay(inputSample, modulatedTime, 0.2)
    return (inputSample * (1.0 - mix)) + (wet * mix)
  }
}
''',
    ),

    // 7. 8-Bit Retro Crusher FX
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

    // 8. Warm Tube Distortion
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
