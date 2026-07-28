class LuaPreset {
  final String id;
  final String name;
  final String category; // 'synth', 'drum', or 'effect'
  final String description;
  final String code;

  const LuaPreset({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.code,
  });
}

class LuaPresetLibrary {
  static const List<LuaPreset> presets = [
    // 0. Eatbits.v1 Native Node & Automation API Showcase Preset
    LuaPreset(
      id: 'eatbits_v1_acid_automation',
      name: 'Eatbits.v1 Native TB-303 + Delay (v1 API)',
      category: 'synth',
      description: 'Demonstrates eatbits.v1 opaque handles (NodeHandle, ParamHandle), WebAudio graph routing, and sample-accurate parameter automation curves.',
      code: '''
-- --- Eatbits Engine API v1 Native Graph & Automation Script (Lua) ---
local EatbitsAcidPreset = {}

function EatbitsAcidPreset.onInit(config)
  -- 1. Create native instrument & effect nodes via node registry
  local synth = eatbits.v1.createNode("TB303", {
    waveform = 0,       -- 0 = Sawtooth, 1 = Square
    oversample = 2      -- 2x native Virtual Analog oversampling
  })

  local delay = eatbits.v1.createNode("StereoDelayFX", {
    timeMs = 250.0,
    feedback = 0.45,
    mix = 0.4
  })

  local master = eatbits.v1.getMasterBus()

  -- 2. Audio Graph Routing: Synth -> Delay -> Master
  synth:connect(delay)
  delay:connect(master)

  -- 3. Sample-Accurate Parameter Automation
  local cutoff = synth:getParam("Cutoff")
  local now = Scheduler.currentTime()

  -- Sweep filter cutoff over 2 bars (sample-accurate on audio thread)
  cutoff:setValueAtTime(200.0, now)
  cutoff:exponentialRampToValueAtTime(8000.0, now + Scheduler.beatsToSeconds(8.0))
end

function EatbitsAcidPreset.onTransportStart(bar, beat)
  -- Musical time lookahead scheduler NoteOn triggers
  Scheduler.scheduleNote(36, 0.95, 0.0, 2.0)  -- C2
  Scheduler.scheduleNote(48, 1.00, 2.0, 1.0)  -- C3
  Scheduler.scheduleNote(39, 0.85, 3.0, 1.0)  -- D#2
end

function EatbitsAcidPreset.getState()
  return {
    version = "v1",
    preset = "EatbitsAcidPreset",
    cutoff = 2400.0
  }
end

return EatbitsAcidPreset
''',
    ),
    // 1. JC-303 Acid Bass Synth
    LuaPreset(
      id: 'acid_303',
      name: 'TB-303 Acid Synth (JC-303)',
      category: 'synth',
      description: 'Roland TB-303 emulation modelled after midilab/jc303 with 24dB 4-Pole Diode Ladder filter, leaky integrator saw/square oscillators, Accent, Slide portamento, and Overdrive.',
      code: '''
-- --- JC-303 Roland TB-303 Acid Engine (Lua) ---
local Acid303 = {}

function Acid303.init()
  Param.add("Waveform", 0.0, 1.0, 0.0)    -- 0 = Saw, 1 = Square
  Param.add("Cutoff", 100.0, 6500.0, 1600.0)
  Param.add("Resonance", 0.5, 16.0, 8.0)
  Param.add("EnvMod", 0.0, 1.0, 0.75)
  Param.add("Decay", 0.05, 1.2, 0.28)
  Param.add("Accent", 0.0, 1.0, 0.6)
  Param.add("Slide", 0.0, 1.0, 0.4)
  Param.add("Overdrive", 0.0, 1.0, 0.3)
end

function Acid303.process(time, freq, note, params, targetNote, isSlide)
  local waveType = params["Waveform"] or 0.0
  local cutoff = params["Cutoff"] or 1600.0
  local res = params["Resonance"] or 8.0
  local envMod = params["EnvMod"] or 0.75
  local decay = params["Decay"] or 0.28
  local accent = params["Accent"] or 0.6
  local drive = params["Overdrive"] or 0.3
  local slideParam = params["Slide"] or 0.4

  -- Pitch glide / Portamento logic for simultaneous / polyphonic notes
  local currentFreq = freq
  if targetNote and targetNote > 0 then
    local targetFreq = 440.0 * (2.0 ^ ((targetNote - 69) / 12.0))
    currentFreq = targetFreq + (freq - targetFreq) * math.exp(-time / 0.065)
  elseif isSlide or slideParam > 0.5 then
    local targetFreq = freq * 1.5
    currentFreq = targetFreq + (freq - targetFreq) * math.exp(-time / 0.065)
  end

  -- JC-303 Oscillators: Leaky Integrator Sawtooth & Differentiated Square
  local phase = time * currentFreq
  local normPhase = phase - math.floor(phase)
  local sawRaw = 2.0 * normPhase - 1.0
  local sawHP = sawRaw - 0.85 * math.exp(-time * 15.0)
  local sqrRaw = normPhase < 0.48 and 0.75 or -0.75
  local osc = waveType < 0.5 and sawHP or sqrRaw

  -- Accent envelope dynamics
  local envBoost = 1.0 + (accent * 0.8)
  local envDecay = decay / envBoost
  local env = math.exp(-time / envDecay)

  -- 24dB 4-Pole Diode Ladder Filter simulation with feedback saturation
  local modCutoff = cutoff + (envMod * env * 5500.0 * envBoost)
  local filtered = DSP.lowpass(osc, modCutoff, res)

  -- Post-VCF 150Hz Highpass filter & overdrive saturation
  local highpassed = filtered - (filtered * math.exp(-time * 40.0))
  local output = highpassed
  if drive > 0.05 then
    output = math.tanh(highpassed * (1.0 + drive * 3.5))
  end

  return output * env * (1.0 + accent * 0.3)
end

return Acid303
''',
    ),

    // 2. Procedural Kick Drum Preset
    LuaPreset(
      id: 'procedural_kick',
      name: 'Procedural Kick Drum',
      category: 'drum',
      description: 'Synthesized punchy sub kick drum with exponential pitch sweep and smooth edge fade.',
      code: '''
-- --- Procedural Sub Kick Drum Script (Lua) ---
local ProceduralKick = {}

function ProceduralKick.init()
  Param.add("StartFreq", 100.0, 300.0, 160.0)
  Param.add("EndFreq", 30.0, 60.0, 42.0)
  Param.add("PitchDecay", 0.01, 0.1, 0.035)
  Param.add("AmpDecay", 0.1, 0.6, 0.35)
  Param.add("Click", 0.0, 1.0, 0.0)
end

function ProceduralKick.process(time, freq, note, params)
  local startF = params["StartFreq"] or 160.0
  local endF = params["EndFreq"] or 42.0
  local pDecay = params["PitchDecay"] or 0.035
  local aDecay = params["AmpDecay"] or 0.35
  local click = params["Click"] or 0.0

  -- Pitch sweep envelope
  local curFreq = endF + (startF - endF) * math.exp(-time / pDecay)
  local phase = 2.0 * math.pi * curFreq * time
  local subSine = math.sin(phase)

  -- Transient click
  local clickTransient = (math.random() * 2.0 - 1.0) * math.exp(-time * 150.0) * click

  local env = math.exp(-time / aDecay)
  local rawOutput = (subSine * 0.85 + clickTransient * 0.15) * env

  -- Smooth fade toward edge of kick duration to prevent clipping/pops at boundary
  local edgeFade = DSP.fadeEdge(rawOutput, time, aDecay * 1.25, 0.08)
  return math.tanh(edgeFade * 1.3)
end

return ProceduralKick
''',
    ),

    // 3. Procedural Snare Drum Preset
    LuaPreset(
      id: 'procedural_snare',
      name: 'Procedural Snare Drum',
      category: 'drum',
      description: 'Synthesized snare drum combining a 180Hz tonal body oscillator and high-pass filtered noise wires.',
      code: '''
-- --- Procedural Snare Drum Script (Lua) ---
local ProceduralSnare = {}

function ProceduralSnare.init()
  Param.add("ToneFreq", 100.0, 300.0, 185.0)
  Param.add("Snappy", 0.0, 1.0, 0.65)
  Param.add("Decay", 0.05, 0.5, 0.1)
end

function ProceduralSnare.process(time, freq, note, params)
  local toneFreq = params["ToneFreq"] or 185.0
  local snappy = params["Snappy"] or 0.65
  local decay = params["Decay"] or 0.1

  -- Body tone (pitch sweep)
  local sweepFreq = toneFreq * math.exp(-time * 40.0)
  local body = math.sin(2.0 * math.pi * sweepFreq * time) * math.exp(-time * 25.0)

  -- Snare noise wires
  local noise = (math.random() * 2.0 - 1.0) * math.exp(-time / decay)
  local filteredNoise = DSP.highpass(noise, 1500.0, 1.0)

  local output = body * (1.0 - snappy) + filteredNoise * snappy
  return math.tanh(output * 1.2)
end

return ProceduralSnare
''',
    ),

    // 4. Procedural Hi-Hat Preset
    LuaPreset(
      id: 'procedural_hihat',
      name: 'Procedural Hi-Hat',
      category: 'drum',
      description: 'Synthesis hi-hat using a metallic square ring cluster and high-pass filtered white noise.',
      code: '''
-- --- Procedural Hi-Hat Synth Script (Lua) ---
local ProceduralHiHat = {}

function ProceduralHiHat.init()
  Param.add("Cutoff", 4000.0, 14000.0, 8500.0)
  Param.add("Decay", 0.0, 0.4, 0.0)
  Param.add("Metallic", 0.0, 1.0, 0.4)
end

function ProceduralHiHat.process(time, freq, note, params)
  local cutoff = params["Cutoff"] or 8500.0
  local decay = params["Decay"] or 0.0
  local metallic = params["Metallic"] or 0.4

  local env = 0.0
  if decay <= 0.001 then
    env = time < 0.015 and math.exp(-time / 0.015) or 0.0
  else
    env = math.exp(-time / decay)
  end

  -- Metallic ring oscillator cluster (6 square waves)
  local ring = math.sin(2.0 * math.pi * 800.0 * time) *
               math.sin(2.0 * math.pi * 1340.0 * time) *
               math.sin(2.0 * math.pi * 2100.0 * time)

  -- White noise generator
  local noise = (math.random() * 2.0 - 1.0)
  local filteredNoise = DSP.highpass(noise * 0.7 + ring * metallic * 0.3, cutoff, 1.2)

  return filteredNoise * env * 0.7
end

return ProceduralHiHat
''',
    ),

    // 5. Procedural Clap Preset
    LuaPreset(
      id: 'procedural_clap',
      name: 'Procedural Handclap',
      category: 'drum',
      description: 'Multi-burst noise clap synthesizer simulating human handclap reverberation.',
      code: '''
-- --- Procedural Handclap Script (Lua) ---
local ProceduralClap = {}

function ProceduralClap.init()
  Param.add("RoomDecay", 0.05, 0.4, 0.18)
  Param.add("Tone", 800.0, 4000.0, 2200.0)
end

function ProceduralClap.process(time, freq, note, params)
  local roomDecay = params["RoomDecay"] or 0.18
  local tone = params["Tone"] or 2200.0

  -- Multi-tap burst envelope
  local burstEnv = 0.0
  if time < 0.01 then burstEnv = 1.0
  elseif time < 0.022 then burstEnv = 0.75
  elseif time < 0.035 then burstEnv = 0.85
  else burstEnv = math.exp(-(time - 0.035) / roomDecay)
  end

  local noise = (math.random() * 2.0 - 1.0)
  local filtered = DSP.bandpass(noise, tone, 2.0)

  return filtered * burstEnv * 0.8
end

return ProceduralClap
''',
    ),

    // 6. Poly Lead Synth Preset
    LuaPreset(
      id: 'poly_lead',
      name: 'Poly Lead Synth',
      category: 'synth',
      description: 'Dual oscillator sawtooth lead synthesizer with dynamic lowpass filter sweep.',
      code: '''
-- --- Poly Lead Synth Script (Lua) ---
local PolyLeadSynth = {}

function PolyLeadSynth.init()
  Param.add("Cutoff", 400.0, 12000.0, 4500.0)
  Param.add("Resonance", 0.5, 8.0, 3.0)
  Param.add("Detune", 0.0, 10.0, 3.0)
  Param.add("Attack", 0.001, 0.1, 0.01)
  Param.add("Release", 0.05, 1.0, 0.35)
end

function PolyLeadSynth.process(time, freq, note, params)
  local cutoff = params["Cutoff"] or 4500.0
  local res = params["Resonance"] or 3.0
  local detune = params["Detune"] or 3.0
  local attack = params["Attack"] or 0.01
  local release = params["Release"] or 0.35

  -- ADSR Envelope
  local env = 1.0
  if time < attack then
    env = time / attack
  else
    env = math.exp(-(time - attack) / release)
  end

  -- Dual Detuned Saw Oscillators
  local f1 = freq
  local f2 = freq + detune
  local phase1 = time * f1
  local phase2 = time * f2

  local saw1 = 2.0 * (phase1 - math.floor(phase1)) - 1.0
  local saw2 = 2.0 * (phase2 - math.floor(phase2)) - 1.0
  local rawOsc = (saw1 + saw2) * 0.5

  -- Resonant Filter
  local filtered = DSP.lowpass(rawOsc, cutoff, res)
  return filtered * env * 0.8
end

return PolyLeadSynth
''',
    ),

    // 7. Lua Stereo Delay Effect
    LuaPreset(
      id: 'lua_delay',
      name: 'Lua Stereo Delay FX',
      category: 'effect',
      description: 'Feedback delay line effect module with dampening and dry/wet mix controls.',
      code: '''
-- --- Lua Stereo Feedback Delay Effect ---
local StereoDelayFX = {}

function StereoDelayFX.init()
  Param.add("TimeMs", 50.0, 800.0, 250.0)
  Param.add("Feedback", 0.0, 0.9, 0.45)
  Param.add("Dampening", 1000.0, 12000.0, 4500.0)
  Param.add("Mix", 0.0, 1.0, 0.4)
end

function StereoDelayFX.processSignal(inputSample, time, params)
  local timeMs = params["TimeMs"] or 250.0
  local fb = params["Feedback"] or 0.45
  local damp = params["Dampening"] or 4500.0
  local mix = params["Mix"] or 0.4

  -- Delayed sample read from WebAudio buffer
  local delayed = DSP.delay(inputSample, timeMs, fb)
  local dampened = DSP.lowpass(delayed, damp, 1.0)

  return (inputSample * (1.0 - mix)) + (dampened * mix)
end

return StereoDelayFX
''',
    ),

    // 8. Lua Stereo Chorus Effect
    LuaPreset(
      id: 'lua_chorus',
      name: 'Lua Stereo Chorus FX',
      category: 'effect',
      description: 'LFO modulated short delay lines creating lush stereo chorus and ensemble thickness.',
      code: '''
-- --- Lua Stereo Chorus Effect ---
local StereoChorusFX = {}

function StereoChorusFX.init()
  Param.add("RateHz", 0.1, 5.0, 1.2)
  Param.add("DepthMs", 1.0, 15.0, 6.0)
  Param.add("Mix", 0.0, 1.0, 0.5)
end

function StereoChorusFX.processSignal(inputSample, time, params)
  local rate = params["RateHz"] or 1.2
  local depth = params["DepthMs"] or 6.0
  local mix = params["Mix"] or 0.5

  -- LFO Modulation
  local lfo = math.sin(2.0 * math.pi * rate * time)
  local modulatedTime = 12.0 + (lfo * depth)

  local wet = DSP.delay(inputSample, modulatedTime, 0.2)
  return (inputSample * (1.0 - mix)) + (wet * mix)
end

return StereoChorusFX
''',
    ),

    // 9. 8-Bit Retro Crusher FX
    LuaPreset(
      id: 'bitcrusher_fx',
      name: '8-Bit Retro Crusher FX',
      category: 'effect',
      description: 'Bit-depth and sample-rate reduction effect for lo-fi chiptune textures.',
      code: '''
-- --- 8-Bit Retro Bitcrusher Effect (Lua) ---
local BitcrusherFX = {}

function BitcrusherFX.init()
  Param.add("Bits", 2.0, 16.0, 6.0)
  Param.add("Downsample", 1.0, 16.0, 4.0)
  Param.add("Mix", 0.0, 1.0, 0.8)
end

function BitcrusherFX.processSignal(inputSample, time, params)
  local bits = params["Bits"] or 6.0
  local downsample = params["Downsample"] or 4.0
  local mix = params["Mix"] or 0.8

  -- Bit depth quantize
  local steps = math.pow(2.0, bits)
  local quantized = math.floor(inputSample * steps) / steps

  -- Sample rate reduction
  local crushed = DSP.sampleHold(quantized, downsample)

  -- Dry / Wet Mix
  return (inputSample * (1.0 - mix)) + (crushed * mix)
end

return BitcrusherFX
''',
    ),

    // 10. Warm Tube Distortion
    LuaPreset(
      id: 'tube_distortion',
      name: 'Warm Tube Distortion',
      category: 'effect',
      description: 'Non-linear soft-clipping saturation and warmth.',
      code: '''
-- --- Warm Tube Overdrive (Lua) ---
local TubeDistortion = {}

function TubeDistortion.init()
  Param.add("Drive", 1.0, 20.0, 6.0)
  Param.add("Tone", 200.0, 8000.0, 3500.0)
  Param.add("OutGain", 0.1, 1.5, 0.7)
end

function TubeDistortion.processSignal(inputSample, time, params)
  local drive = params["Drive"] or 6.0
  local tone = params["Tone"] or 3500.0
  local outGain = params["OutGain"] or 0.7

  -- Soft clipping hyperbolic tangent curve
  local driven = inputSample * drive
  local clipped = math.tanh(driven)

  -- Post tone filter
  local filtered = DSP.lowpass(clipped, tone, 1.0)
  return filtered * outGain
end

return TubeDistortion
''',
    ),
  ];
}
