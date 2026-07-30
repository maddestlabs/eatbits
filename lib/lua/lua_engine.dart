import 'dart:math' as math;

class LuaParamDef {
  final String name;
  final double min;
  final double max;
  final double defaultValue;

  LuaParamDef({
    required this.name,
    required this.min,
    required this.max,
    required this.defaultValue,
  });
}

class LuaCompilationResult {
  final bool isSuccess;
  final String errorMessage;
  final int errorLine;
  final List<LuaParamDef> params;
  final String scriptType; // 'synth', 'drum', or 'effect'

  LuaCompilationResult({
    required this.isSuccess,
    this.errorMessage = '',
    this.errorLine = 0,
    required this.params,
    required this.scriptType,
  });
}

class LuaEngine {
  static double _tanh(double x) {
    if (x > 20.0) return 1.0;
    if (x < -20.0) return -1.0;
    final ex = math.exp(x);
    final enx = math.exp(-x);
    return (ex - enx) / (ex + enx);
  }

  static final RegExp _paramRegExp = RegExp(
    "Param\\.add\\(\\s*[\"']([^\"']+)[\"']\\s*,\\s*([\\d\\.-]+)\\s*,\\s*([\\d\\.-]+)\\s*,\\s*([\\d\\.-]+)\\s*\\)",
  );

  static final RegExp _v1ParamRegExp = RegExp(
    "getParam\\(\\s*[\"']([^\"']+)[\"']\\s*\\)",
  );

  static final RegExp _clipParamRegExp = RegExp(
    "registerParam\\(\\s*[\"']([^\"']+)[\"']\\s*,\\s*([\\d\\.-]+)\\s*,\\s*([\\d\\.-]+)\\s*,\\s*([\\d\\.-]+)\\s*\\)",
  );

  static LuaCompilationResult compile(String code) {
    if (code.trim().isEmpty) {
      return LuaCompilationResult(
        isSuccess: false,
        errorMessage: 'Lua script code is empty.',
        params: [],
        scriptType: 'synth',
      );
    }

    try {
      final params = <LuaParamDef>[];
      final matches = _paramRegExp.allMatches(code);
      for (final m in matches) {
        final name = m.group(1)!;
        final minVal = double.tryParse(m.group(2)!) ?? 0.0;
        final maxVal = double.tryParse(m.group(3)!) ?? 1.0;
        final defVal = double.tryParse(m.group(4)!) ?? minVal;
        params.add(LuaParamDef(
          name: name,
          min: minVal,
          max: maxVal,
          defaultValue: defVal,
        ));
      }

      // Check for clip:registerParam
      final clipMatches = _clipParamRegExp.allMatches(code);
      for (final m in clipMatches) {
        final name = m.group(1)!;
        final minVal = double.tryParse(m.group(2)!) ?? 0.0;
        final maxVal = double.tryParse(m.group(3)!) ?? 1.0;
        final defVal = double.tryParse(m.group(4)!) ?? minVal;
        if (!params.any((p) => p.name == name)) {
          params.add(LuaParamDef(
            name: name,
            min: minVal,
            max: maxVal,
            defaultValue: defVal,
          ));
        }
      }

      // Check for eatbits.v1 Param handles in Lua scripts
      final v1Matches = _v1ParamRegExp.allMatches(code);
      for (final m in v1Matches) {
        final name = m.group(1)!;
        if (!params.any((p) => p.name == name)) {
          params.add(LuaParamDef(
            name: name,
            min: 0.0,
            max: 1.0,
            defaultValue: 0.5,
          ));
        }
      }

      String scriptType = 'synth';
      if (code.contains('processSignal') || code.contains('StereoDelayFX') || code.contains('Bitcrusher')) {
        scriptType = 'effect';
      }

      // Check basic Lua syntax markers or eatbits.v1 scripts
      final isV1Script = code.contains('eatbits.v1') || code.contains('Eatbits.v1') || code.contains('eatbits');
      final hasFunctionOrLocal = code.contains('function') || code.contains('local') || code.contains('Param.add') || code.contains('--');

      if (!hasFunctionOrLocal && !isV1Script) {
        return LuaCompilationResult(
          isSuccess: false,
          errorMessage: 'Lua Syntax Error: Missing function definition or script structure.',
          errorLine: 1,
          params: [],
          scriptType: scriptType,
        );
      }

      return LuaCompilationResult(
        isSuccess: true,
        errorMessage: 'Compiled successfully (Lua Live Scripting - eatbits.v1 Target)! Active parameters: ${params.length}',
        params: params,
        scriptType: scriptType,
      );
    } catch (e) {
      return LuaCompilationResult(
        isSuccess: false,
        errorMessage: 'Lua Compilation Error: ${e.toString()}',
        params: [],
        scriptType: 'synth',
      );
    }
  }

  // DSP Math & Synthesis Evaluator for Lua custom synths and drum engines
  static double evaluateSynth({
    required String code,
    required double time,
    required double freq,
    required int note,
    required Map<String, double> params,
    int? targetMidiNote,
    bool isSlide = false,
  }) {
    // 0. Procedural Kick Drum
    if (code.contains('ProceduralKick') || code.contains('StartFreq')) {
      final startF = params['StartFreq'] ?? 160.0;
      final endF = params['EndFreq'] ?? 42.0;
      final pDecay = params['PitchDecay'] ?? 0.035;
      final aDecay = params['AmpDecay'] ?? 0.35;
      final click = params['Click'] ?? 0.0;

      final curFreq = endF + (startF - endF) * math.exp(-time / pDecay.clamp(0.005, 0.5));
      final subSine = math.sin(2.0 * math.pi * curFreq * time);
      final rnd = math.Random((time * 10000).toInt() % 100000 + 77);
      final clickTransient = (rnd.nextDouble() * 2.0 - 1.0) * math.exp(-time * 150.0) * click;
      final env = math.exp(-time / aDecay.clamp(0.01, 1.5));

      final rawOutput = (subSine * 0.85 + clickTransient * 0.15) * env;

      // Smooth fade toward edge of kick duration so it doesn't clip/click at the end
      final maxDuration = aDecay.clamp(0.1, 1.5) * 1.25;
      final fadeStart = maxDuration - 0.08;
      double edgeFade = 1.0;
      if (time > fadeStart) {
        final norm = ((maxDuration - time) / 0.08).clamp(0.0, 1.0);
        edgeFade = 0.5 * (1.0 + math.cos(math.pi * (1.0 - norm)));
      }
      if (time >= maxDuration) edgeFade = 0.0;

      final output = rawOutput * edgeFade;
      return (math.exp(output * 1.3) - math.exp(-output * 1.3)) / (math.exp(output * 1.3) + math.exp(-output * 1.3));
    }

    // 1. JC-303 Acid Bass Engine (Modelled after midilab/jc303)
    if (code.contains('Acid303') || code.contains('Cutoff') || code.contains('TB303')) {
      final waveType = params['Waveform'] ?? 0.0;
      final cutoff = params['Cutoff'] ?? 1600.0;
      final res = params['Resonance'] ?? 8.0;
      final envMod = params['EnvMod'] ?? 0.75;
      final decay = params['Decay'] ?? 0.28;
      final accent = params['Accent'] ?? 0.6;
      final drive = params['Overdrive'] ?? 0.3;
      final slideParam = params['Slide'] ?? 0.0;

      if (freq <= 0) return 0.0;

      // Pitch glide / Portamento logic for simultaneous / polyphonic notes
      double currentFreq = freq;
      if (targetMidiNote != null && targetMidiNote > 0) {
        final targetFreq = 440.0 * math.pow(2.0, (targetMidiNote - 69) / 12.0);
        currentFreq = targetFreq + (freq - targetFreq) * math.exp(-time / 0.065);
      } else if (isSlide || slideParam > 0.5) {
        final targetFreq = freq * 1.5; // Default half-octave slide if target not specified
        currentFreq = targetFreq + (freq - targetFreq) * math.exp(-time / 0.065);
      }

      // Authentic 303 Oscillators: Leaky Integrator Sawtooth & Differentiated Square
      final phase = time * currentFreq;
      final normPhase = phase - phase.floorToDouble();
      final sawRaw = 2.0 * normPhase - 1.0;
      final sawHP = sawRaw - 0.85 * math.exp(-time * 15.0);
      final sqrRaw = normPhase < 0.48 ? 0.75 : -0.75;
      final osc = waveType < 0.5 ? sawHP : sqrRaw;

      // Accent boost logic & decay dynamics
      final envBoost = 1.0 + (accent * 0.8);
      final envDecay = (decay / envBoost).clamp(0.02, 2.0);
      final env = math.exp(-time / envDecay);

      // 4-Pole 24dB Diode Ladder Filter cutoff & non-linear saturation
      final modCutoff = (cutoff + (envMod * env * 5500.0 * envBoost)).clamp(40.0, 16000.0);
      final fNorm = (modCutoff / 44100.0 * math.pi * 2.0).clamp(0.005, 0.85);
      final kRes = (res / 16.0 * 3.8).clamp(0.0, 3.95);

      final feedback = kRes * _tanh(osc * 0.5);
      final inputWithRes = _tanh(osc - feedback);

      final stage1 = inputWithRes * fNorm / (1.0 + fNorm);
      final stage2 = stage1 * fNorm / (1.0 + fNorm);
      final stage3 = stage2 * fNorm / (1.0 + fNorm);
      final stage4 = stage3 * fNorm / (1.0 + fNorm);
      final filtered = stage4 * 4.0;

      // Post-VCF 150Hz High-Pass filter & overdrive saturation
      final highpassed = filtered - (filtered * math.exp(-time * 40.0));
      double saturated = highpassed;
      if (drive > 0.05) {
        final gain = 1.0 + (drive * 3.5);
        saturated = _tanh(highpassed * gain);
      }

      return (saturated * env * (1.0 + accent * 0.3)).clamp(-1.0, 1.0);
    }

    // 2. Procedural Snare Drum
    else if (code.contains('ProceduralSnare') || code.contains('Snappy')) {
      final toneFreq = params['ToneFreq'] ?? 185.0;
      final snappy = params['Snappy'] ?? 0.65;
      final decay = params['Decay'] ?? 0.1;

      final sweepFreq = toneFreq * math.exp(-time * 40.0);
      final body = math.sin(2.0 * math.pi * sweepFreq * time) * math.exp(-time * 25.0);

      final rnd = math.Random((time * 10000).toInt() % 100000 + 42);
      final noise = (rnd.nextDouble() * 2.0 - 1.0) * math.exp(-time / decay.clamp(0.01, 1.0));

      final output = body * (1.0 - snappy) + noise * snappy;
      return (math.exp(output * 1.2) - math.exp(-output * 1.2)) / (math.exp(output * 1.2) + math.exp(-output * 1.2));
    }

    // 3. Procedural Hi-Hat
    else if (code.contains('ProceduralHiHat') || code.contains('Metallic')) {
      final cutoff = params['Cutoff'] ?? 8500.0;
      final decay = params['Decay'] ?? 0.0;
      final metallic = params['Metallic'] ?? 0.4;

      final env = decay <= 0.001
          ? (time < 0.015 ? math.exp(-time / 0.015) : 0.0)
          : math.exp(-time / decay.clamp(0.001, 1.0));

      final ring = math.sin(2.0 * math.pi * 800.0 * time) *
                   math.sin(2.0 * math.pi * 1340.0 * time) *
                   math.sin(2.0 * math.pi * 2100.0 * time);

      final rnd = math.Random((time * 10000).toInt() % 100000 + 123);
      final noise = (rnd.nextDouble() * 2.0 - 1.0);
      final rawSignal = noise * 0.7 + ring * metallic * 0.3;

      // Highpass filtering
      final f = (cutoff / 44100.0 * 2.0 * math.pi).clamp(0.1, 0.9);
      final output = rawSignal * f * env * 0.7;

      return output.clamp(-1.0, 1.0);
    }

    // 4. Procedural Handclap
    else if (code.contains('ProceduralClap') || code.contains('RoomDecay')) {
      final roomDecay = params['RoomDecay'] ?? 0.18;
      final tone = params['Tone'] ?? 2200.0;

      double burstEnv = 0.0;
      if (time < 0.01) {
        burstEnv = 1.0;
      } else if (time < 0.022) {
        burstEnv = 0.75;
      } else if (time < 0.035) {
        burstEnv = 0.85;
      } else {
        burstEnv = math.exp(-(time - 0.035) / roomDecay.clamp(0.01, 1.0));
      }

      final rnd = math.Random((time * 10000).toInt() % 100000 + 999);
      final noise = (rnd.nextDouble() * 2.0 - 1.0);

      final f = (tone / 44100.0 * 2.0 * math.pi).clamp(0.05, 0.95);
      final filtered = noise * f * burstEnv * 0.8;

      return filtered.clamp(-1.0, 1.0);
    }

    // 5. Dual-Op FM Synth
    else if (code.contains('FMSynth') || code.contains('ModRatio')) {
      final ratio = params['ModRatio'] ?? 2.0;
      final index = params['ModIndex'] ?? 3.5;
      final attack = params['Attack'] ?? 0.005;
      final release = params['Release'] ?? 0.4;

      if (freq <= 0) return 0.0;

      double env = 1.0;
      if (time < attack) {
        env = time / attack;
      } else {
        env = math.exp(-(time - attack) / release);
      }

      final modFreq = freq * ratio;
      final modulator = math.sin(2.0 * math.pi * modFreq * time) * (index * env);
      final carrier = math.sin(2.0 * math.pi * freq * time + modulator);

      return (carrier * env * 0.8).clamp(-1.0, 1.0);
    }

    // Default Fallback Synth: Sawtooth + Sub Octave
    else {
      if (freq <= 0) return 0.0;

      final cutoff = params['Cutoff'] ?? 3000.0;
      final phase = time * freq;
      final saw = 2.0 * (phase - (phase + 0.5).floorToDouble());
      final sub = math.sin(2.0 * math.pi * (freq * 0.5) * time);

      final env = math.exp(-time / 0.3);
      final raw = (saw * 0.7 + sub * 0.3) * env;
      return (raw * (cutoff / 5000.0)).clamp(-1.0, 1.0);
    }
  }

  // DSP Math & Synthesis Evaluator for Lua custom FX
  static double evaluateEffect({
    required String code,
    required double inputSample,
    required double time,
    required Map<String, double> params,
  }) {
    if (code.contains('StereoDelayFX') || code.contains('TimeMs')) {
      final feedback = params['Feedback'] ?? 0.45;
      final mix = params['Mix'] ?? 0.4;

      final echo = inputSample * feedback;
      return (inputSample * (1.0 - mix)) + (echo * mix);
    } else if (code.contains('StereoChorusFX') || code.contains('DepthMs')) {
      final mix = params['Mix'] ?? 0.5;
      final rate = params['RateHz'] ?? 1.2;

      final lfo = math.sin(2.0 * math.pi * rate * time);
      final wet = inputSample * (0.8 + lfo * 0.2);

      return (inputSample * (1.0 - mix)) + (wet * mix);
    } else if (code.contains('Bitcrusher') || code.contains('Bits')) {
      final bits = params['Bits'] ?? 6.0;
      final downsample = params['Downsample'] ?? 4.0;
      final mix = params['Mix'] ?? 0.8;

      final steps = math.pow(2.0, bits.clamp(2.0, 16.0));
      final quantized = (inputSample * steps).floorToDouble() / steps;

      final holdSample = (time * 44100 % downsample < 1.0) ? quantized : quantized * 0.9;
      return (inputSample * (1.0 - mix)) + (holdSample * mix);
    } else if (code.contains('TubeDistortion') || code.contains('Drive')) {
      final drive = params['Drive'] ?? 6.0;
      final outGain = params['OutGain'] ?? 0.7;

      final driven = inputSample * drive;
      // Hyperbolic tangent soft clipping
      final clipped = (math.exp(driven) - math.exp(-driven)) / (math.exp(driven) + math.exp(-driven));
      return clipped * outGain;
    } else {
      return (inputSample * 1.2).clamp(-1.0, 1.0);
    }
  }
}
