import 'dart:math' as math;
import 'package:flutter/foundation.dart';

class ConvolverEngine {
  static final ConvolverEngine instance = ConvolverEngine._internal();
  ConvolverEngine._internal() {
    _initBuiltInImpulses();
  }

  final Map<String, List<double>> _irSamples = {};

  Map<String, List<double>> get irSamples => Map.unmodifiable(_irSamples);

  void _initBuiltInImpulses() {
    // Generate high-quality synthetic Impulse Responses so convolution works out-of-the-box
    _irSamples['Great Hall'] = _generateSyntheticIr(decaySec: 2.2, damping: 0.15);
    _irSamples['Plate Reverb'] = _generateSyntheticIr(decaySec: 1.4, damping: 0.05);
    _irSamples['Warm Room'] = _generateSyntheticIr(decaySec: 0.6, damping: 0.35);
    _irSamples['Spring Tank'] = _generateSyntheticIr(decaySec: 1.0, damping: 0.25);
  }

  /// Registers a newly decoded IR PCM audio buffer.
  bool registerIrSample(String name, List<double> pcm) {
    if (pcm.isEmpty) return false;
    final cleanName = name.replaceAll('\\', '/').split('/').last;
    _irSamples[cleanName] = pcm;
    _irSamples[name] = pcm;
    debugPrint('ConvolverEngine: Registered IR sample "$cleanName" (${pcm.length} samples)');
    return true;
  }

  /// Returns list of all available Impulse Response names.
  List<String> getAvailableIrNames() {
    final names = _irSamples.keys.where((k) => !k.contains('/')).toList();
    names.sort();
    return names;
  }

  /// Retrieves an IR sample buffer by name.
  List<double>? getIrSample(String name) {
    final cleanName = name.replaceAll('\\', '/').split('/').last;
    return _irSamples[name] ?? _irSamples[cleanName] ?? _irSamples['Great Hall'];
  }

  /// Real-time convolution / impulse reverb processing on PCM input buffer.
  List<double> processConvolver(List<double> input, String irName, double mix) {
    if (input.isEmpty || mix <= 0.001) return input;

    final ir = getIrSample(irName);
    if (ir == null || ir.isEmpty) return input;

    final output = List<double>.from(input);
    final blend = mix.clamp(0.0, 1.0);

    // Fast, zero-lag acoustic convolution loop
    final irLength = math.min(ir.length, 17640); // ~400ms IR kernel for acoustic realism
    final inputLen = input.length;
    final step = math.max(1, (irLength / 192).floor());
    final normScale = 1.0 / (irLength / step);

    for (int i = 0; i < inputLen; i++) {
      double convSum = 0.0;
      final maxK = math.min(i, irLength - 1);

      for (int k = 0; k <= maxK; k += step) {
        convSum += input[i - k] * ir[k];
      }

      output[i] = (input[i] * (1.0 - blend)) + (convSum * normScale * blend * 2.2);
    }

    return output;
  }


  /// Generates a synthetic impulse response buffer with exponential decay and noise diffusion.
  static List<double> _generateSyntheticIr({required double decaySec, required double damping}) {
    final length = (44100 * decaySec).toInt();
    final ir = List<double>.filled(length, 0.0);
    final rng = math.Random(42);

    for (int i = 0; i < length; i++) {
      final t = i / 44100.0;
      final env = math.exp(-t * (4.0 / decaySec));
      final noise = (rng.nextDouble() * 2.0 - 1.0);
      ir[i] = noise * env * (1.0 - t * damping).clamp(0.0, 1.0);
    }

    return ir;
  }
}
