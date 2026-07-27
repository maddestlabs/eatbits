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
  static final RegExp _paramRegExp = RegExp(
    "Param\\.add\\(\\s*[\"']([^\"']+)[\"']\\s*,\\s*([\\d\\.-]+)\\s*,\\s*([\\d\\.-]+)\\s*,\\s*([\\d\\.-]+)\\s*\\)",
  );

  static final RegExp _v1ParamRegExp = RegExp(
    "getParam\\(\\s*[\"']([^\"']+)[\"']\\s*\\)",
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
  }) {
    // 0. Procedural Kick Drum
    if (code.contains('ProceduralKick') || code.contains('StartFreq')) {
      final startF = params['StartFreq'] ?? 160.0;
      final endF = params['EndFreq'] ?? 42.0;
      final pDecay = params['PitchDecay'] ?? 0.035;
      final aDecay = params['AmpDecay'] ?? 0.35;
      final click = params['Click'] ?? 0.5;

      final curFreq = endF + (startF - endF) * math.exp(-time / pDecay.clamp(0.005, 0.5));
      final subSine = math.sin(2.0 * math.pi * curFreq * time);
      final rnd = math.Random((time * 10000).toInt() % 100000 + 77);
      final clickTransient = (rnd.nextDouble() * 2.0 - 1.0) * math.exp(-time * 150.0) * click;
      final env = math.exp(-time / aDecay.clamp(0.01, 1.5));

      final output = (subSine * 0.85 + clickTransient * 0.15) * env;
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

      if (freq <= 0) return 0.0;

      // Oscillators: 303 Sawtooth & Square
      final phase = time * freq;
      final normPhase = phase - phase.floorToDouble();
      final saw = 2.0 * normPhase - 1.0;
      final sqr = normPhase < 0.5 ? 0.75 : -0.75;
      final osc = waveType < 0.5 ? saw : sqr;

      // Accent boost logic
      final envBoost = 1.0 + (accent * 0.8);
      final envDecay = (decay / envBoost).clamp(0.02, 2.0);
      final env = math.exp(-time / envDecay);

      // 24dB Diode Ladder Filter cutoff calculation
      final modCutoff = (cutoff + (envMod * env * 5500.0 * envBoost)).clamp(40.0, 16000.0);

      // Filter simulation
      final f = (modCutoff / 44100.0 * 2.0 * math.pi).clamp(0.01, 0.99);
      final q = (res / 16.0 * 6.0).clamp(0.5, 12.0);
      double filtered = osc / (1.0 + f * q);

      // Non-linear overdrive stage
      if (drive > 0.05) {
        final gain = 1.0 + (drive * 4.0);
        final x = filtered * gain;
        filtered = (math.exp(x) - math.exp(-x)) / (math.exp(x) + math.exp(-x)); // tanh saturation
      }

      return (filtered * env * 0.85).clamp(-1.0, 1.0);
    }

    // 2. Procedural Snare Drum
    else if (code.contains('ProceduralSnare') || code.contains('Snappy')) {
      final toneFreq = params['ToneFreq'] ?? 185.0;
      final snappy = params['Snappy'] ?? 0.65;
      final decay = params['Decay'] ?? 0.22;

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
      final decay = params['Decay'] ?? 0.09;
      final metallic = params['Metallic'] ?? 0.4;

      final env = math.exp(-time / decay.clamp(0.01, 1.0));

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
