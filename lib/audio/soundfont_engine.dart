import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'sampler_engine.dart';
import 'soundfont_decoder.dart';

class SoundFontEngine {
  static final SoundFontEngine instance = SoundFontEngine._internal();
  SoundFontEngine._internal();

  final Map<String, SoundFontData> _loadedFonts = {};

  Map<String, SoundFontData> get loadedFonts => Map.unmodifiable(_loadedFonts);

  /// Registers a `.sf2` SoundFont binary buffer.
  bool registerSoundFont(String fontId, Uint8List sf2Bytes) {
    try {
      final decoded = SoundFontDecoder.decode(sf2Bytes);
      if (decoded != null && decoded.sampleHeaders.isNotEmpty) {
        _loadedFonts[fontId] = decoded;
        _loadedFonts[fontId.replaceAll('\\', '/').split('/').last] = decoded;

        // Also register sample overview for visual waveform rendering
        if (decoded.pcmData.isNotEmpty) {
          final ov = WaveformOverview.generate(decoded.pcmData.sublist(
            0,
            math.min(44100 * 2, decoded.pcmData.length),
          ));

          SamplerEngine.instance.registerSampleBytes(
            fontId,
            Uint8List(0),
          );
        }

        debugPrint('SoundFontEngine: Loaded SF2 bank "$fontId" with ${decoded.presets.length} presets & ${decoded.sampleHeaders.length} samples.');
        return true;
      }
    } catch (e) {
      debugPrint('SoundFontEngine error decoding $fontId: $e');
    }
    return false;
  }

  /// Retrieves a loaded SoundFont by ID or path.
  SoundFontData? getSoundFont(String fontId) {
    final cleanId = fontId.replaceAll('\\', '/').split('/').last;
    return _loadedFonts[fontId] ?? _loadedFonts[cleanId];
  }

  /// Resamples and pitch-shifts matching SoundFont key-zone for a given MIDI note & preset.
  List<double> getPitchShiftedBuffer({
    required String fontId,
    required int presetNum,
    required int midiNote,
    double velocity = 0.9,
  }) {
    final font = getSoundFont(fontId);
    if (font == null || font.pcmData.isEmpty || font.presets.isEmpty) {
      return const [];
    }

    final preset = font.findPreset(presetNum);
    if (preset == null) return const [];

    final zone = font.findZone(preset, midiNote, (velocity * 127).round());
    if (zone == null) return const [];

    if (zone.sampleHeaderIdx < 0 || zone.sampleHeaderIdx >= font.sampleHeaders.length) {
      return const [];
    }

    final sampleHeader = font.sampleHeaders[zone.sampleHeaderIdx];
    final startIdx = sampleHeader.startSample.clamp(0, font.pcmData.length - 1);
    final endIdx = sampleHeader.endSample.clamp(startIdx, font.pcmData.length);

    if (startIdx >= endIdx) return const [];

    final rawSlice = font.pcmData.sublist(startIdx, endIdx);
    final rootKey = zone.rootKeyOverride ?? (sampleHeader.originalPitch > 0 ? sampleHeader.originalPitch : 60);
    final semitoneOffset = (midiNote - rootKey).toDouble();

    if (semitoneOffset.abs() < 0.01) {
      return List<double>.from(rawSlice);
    }

    final playbackRate = math.pow(2.0, semitoneOffset / 12.0).toDouble();
    final newLength = (rawSlice.length / playbackRate).round();
    final result = List<double>.filled(newLength, 0.0);

    for (int i = 0; i < newLength; i++) {
      final srcIndex = i * playbackRate;
      final idx0 = srcIndex.floor();
      final idx1 = (idx0 + 1).clamp(0, rawSlice.length - 1);
      final frac = srcIndex - idx0;

      if (idx0 >= rawSlice.length - 1) {
        result[i] = rawSlice.last;
      } else {
        result[i] = (1.0 - frac) * rawSlice[idx0] + frac * rawSlice[idx1];
      }
    }

    return result;
  }
}
