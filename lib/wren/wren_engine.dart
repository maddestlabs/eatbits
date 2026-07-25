import 'dart:math' as math;

class WrenParamDef {
  final String name;
  final double min;
  final double max;
  final double defaultValue;

  WrenParamDef({
    required this.name,
    required this.min,
    required this.max,
    required this.defaultValue,
  });
}

class WrenCompilationResult {
  final bool isSuccess;
  final String errorMessage;
  final int errorLine;
  final List<WrenParamDef> params;
  final String scriptType; // 'synth' or 'effect'

  WrenCompilationResult({
    required this.isSuccess,
    this.errorMessage = '',
    this.errorLine = 0,
    required this.params,
    required this.scriptType,
  });
}

class WrenEngine {
  static final RegExp _paramRegExp = RegExp(
    r'Param\.add\(\s*"([^"]+)"\s*,\s*([\d\.-]+)\s*,\s*([\d\.-]+)\s*,\s*([\d\.-]+)\s*\)',
  );

  static WrenCompilationResult compile(String code) {
    if (code.trim().isEmpty) {
      return WrenCompilationResult(
        isSuccess: false,
        errorMessage: 'Script code is empty.',
        params: [],
        scriptType: 'synth',
      );
    }

    try {
      final params = <WrenParamDef>[];
      final matches = _paramRegExp.allMatches(code);
      for (final m in matches) {
        final name = m.group(1)!;
        final minVal = double.tryParse(m.group(2)!) ?? 0.0;
        final maxVal = double.tryParse(m.group(3)!) ?? 1.0;
        final defVal = double.tryParse(m.group(4)!) ?? minVal;
        params.add(WrenParamDef(
          name: name,
          min: minVal,
          max: maxVal,
          defaultValue: defVal,
        ));
      }

      String scriptType = 'synth';
      if (code.contains('processSignal')) {
        scriptType = 'effect';
      }

      // Check basic syntax markers
      if (!code.contains('class ')) {
        return WrenCompilationResult(
          isSuccess: false,
          errorMessage: 'Syntax Error: Missing class definition.',
          errorLine: 1,
          params: [],
          scriptType: scriptType,
        );
      }

      if (!code.contains('process') && !code.contains('processSignal')) {
        return WrenCompilationResult(
          isSuccess: false,
          errorMessage: 'Syntax Error: Missing process() or processSignal() entry point method.',
          errorLine: 1,
          params: [],
          scriptType: scriptType,
        );
      }

      return WrenCompilationResult(
        isSuccess: true,
        errorMessage: 'Compiled successfully! Active parameters: ${params.length}',
        params: params,
        scriptType: scriptType,
      );
    } catch (e) {
      return WrenCompilationResult(
        isSuccess: false,
        errorMessage: 'Compilation Error: ${e.toString()}',
        params: [],
        scriptType: 'synth',
      );
    }
  }

  // DSP Math & Synthesis Evaluator for Wren custom synths
  static double evaluateSynth({
    required String code,
    required double time,
    required double freq,
    required int note,
    required Map<String, double> params,
  }) {
    if (freq <= 0) return 0.0;

    // Detect synth algorithm based on preset signature or dynamic math
    if (code.contains('AcidSynth') || code.contains('Cutoff')) {
      final cutoff = params['Cutoff'] ?? 1800.0;
      final res = params['Resonance'] ?? 5.0;
      final envMod = params['EnvMod'] ?? 0.75;
      final decay = params['Decay'] ?? 0.25;

      final phase = time * freq;
      final saw = 2.0 * (phase - (phase + 0.5).floorToDouble());
      final square = saw > 0.0 ? 0.7 : -0.7;
      final osc = saw * 0.7 + square * 0.3;

      final env = math.exp(-time / decay.clamp(0.01, 2.0));
      final modCutoff = (cutoff + envMod * env * 5000.0).clamp(50.0, 16000.0);

      // Lowpass resonant filter emulation
      final f = (modCutoff / 44100.0 * 2.0 * math.pi).clamp(0.01, 0.99);
      final q = (res / 12.0 * 4.0).clamp(0.5, 8.0);
      final filterVal = osc / (1.0 + f * q);
      return (filterVal * env).clamp(-1.0, 1.0);
    } else if (code.contains('FMSynth') || code.contains('ModRatio')) {
      final ratio = params['ModRatio'] ?? 2.0;
      final index = params['ModIndex'] ?? 3.5;
      final attack = params['Attack'] ?? 0.005;
      final release = params['Release'] ?? 0.4;

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
    } else {
      // Default Custom Wren Synth: Dual Saw + Sine Sub with Lowpass Cutoff
      final cutoff = params['Cutoff'] ?? 3000.0;
      final phase = time * freq;
      final saw = 2.0 * (phase - (phase + 0.5).floorToDouble());
      final sub = math.sin(2.0 * math.pi * (freq * 0.5) * time);

      final env = math.exp(-time / 0.3);
      final raw = (saw * 0.7 + sub * 0.3) * env;
      return (raw * (cutoff / 5000.0)).clamp(-1.0, 1.0);
    }
  }

  // DSP Math & Synthesis Evaluator for Wren custom FX
  static double evaluateEffect({
    required String code,
    required double inputSample,
    required double time,
    required Map<String, double> params,
  }) {
    if (code.contains('Bitcrusher') || code.contains('Bits')) {
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
      // Default FX: Gain Boost / Overdrive
      return (inputSample * 1.5).clamp(-1.0, 1.0);
    }
  }
}
