import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

class DecodedAudioBuffer {
  final List<double> samples;
  final int sampleRate;
  final int channels;

  DecodedAudioBuffer({
    required this.samples,
    required this.sampleRate,
    required this.channels,
  });
}

class WaveformOverview {
  final List<double> minPeaks;
  final List<double> maxPeaks;

  WaveformOverview({
    required this.minPeaks,
    required this.maxPeaks,
  });

  static WaveformOverview generate(List<double> samples, [int points = 128]) {
    if (samples.isEmpty) {
      return WaveformOverview(
        minPeaks: List<double>.filled(points, 0.0),
        maxPeaks: List<double>.filled(points, 0.0),
      );
    }

    final minP = List<double>.filled(points, 0.0);
    final maxP = List<double>.filled(points, 0.0);
    final step = samples.length / points;

    for (int i = 0; i < points; i++) {
      final start = (i * step).floor();
      final end = math.min(((i + 1) * step).ceil(), samples.length);

      double minVal = 0.0;
      double maxVal = 0.0;

      for (int j = start; j < end; j++) {
        final val = samples[j];
        if (val < minVal) minVal = val;
        if (val > maxVal) maxVal = val;
      }

      minP[i] = minVal;
      maxP[i] = maxVal;
    }

    return WaveformOverview(minPeaks: minP, maxPeaks: maxP);
  }
}

class SamplerEngine {
  static final SamplerEngine instance = SamplerEngine._internal();
  SamplerEngine._internal();

  final Map<String, DecodedAudioBuffer> _samples = {};
  final Map<String, WaveformOverview> _overviews = {};

  Map<String, DecodedAudioBuffer> get loadedSamples => Map.unmodifiable(_samples);

  /// Registers a sample from raw bytes (WAV or PCM).
  bool registerSampleBytes(String id, Uint8List bytes) {
    try {
      final decoded = decodeWav(bytes);
      if (decoded != null) {
        _samples[id] = decoded;
        _overviews[id] = WaveformOverview.generate(decoded.samples);
        debugPrint('SamplerEngine: Registered WAV sample "$id" (${decoded.samples.length} samples)');
        return true;
      }
    } catch (e) {
      debugPrint('SamplerEngine error decoding sample $id: $e');
    }
    return false;
  }

  /// Registers a sample from a Data URI string (e.g. "data:audio/wav;base64,...").
  bool registerSampleDataUri(String id, String dataUri) {
    try {
      String base64Str = dataUri;
      if (dataUri.contains(',')) {
        base64Str = dataUri.split(',').last;
      }
      final bytes = base64.decode(base64Str.trim());
      return registerSampleBytes(id, bytes);
    } catch (e) {
      debugPrint('SamplerEngine error parsing Data URI for $id: $e');
      return false;
    }
  }

  /// Retrieves a registered sample buffer by ID or path.
  DecodedAudioBuffer? getSample(String id) {
    return _samples[id] ?? _samples[id.replaceAll('\\', '/').split('/').last];
  }

  /// Retrieves or generates a 128-point WaveformOverview for a sample ID.
  WaveformOverview? getWaveformOverview(String id) {
    final cleanId = id.replaceAll('\\', '/').split('/').last;
    final overview = _overviews[id] ?? _overviews[cleanId];
    if (overview != null) return overview;

    final buffer = getSample(id);
    if (buffer != null) {
      final ov = WaveformOverview.generate(buffer.samples);
      _overviews[id] = ov;
      return ov;
    }
    return null;
  }

  /// Resamples / Pitch-shifts sample for a specific note offset (semitones relative to root key 60 / C4).
  List<double> getPitchShiftedPcm(String id, double semitoneOffset) {
    final buffer = getSample(id);
    if (buffer == null || buffer.samples.isEmpty) return const [];

    if (semitoneOffset.abs() < 0.01) {
      return List<double>.from(buffer.samples);
    }

    final playbackRate = math.pow(2.0, semitoneOffset / 12.0).toDouble();
    final newLength = (buffer.samples.length / playbackRate).round();
    final result = List<double>.filled(newLength, 0.0);

    for (int i = 0; i < newLength; i++) {
      final srcIndex = i * playbackRate;
      final idx0 = srcIndex.floor();
      final idx1 = (idx0 + 1).clamp(0, buffer.samples.length - 1);
      final frac = srcIndex - idx0;

      if (idx0 >= buffer.samples.length - 1) {
        result[i] = buffer.samples.last;
      } else {
        result[i] = (1.0 - frac) * buffer.samples[idx0] + frac * buffer.samples[idx1];
      }
    }

    return result;
  }

  /// Pure Dart RIFF/WAV PCM decoder (supports 8-bit, 16-bit, 24-bit, 32-bit float, and WAVE_FORMAT_EXTENSIBLE WAV files).
  static DecodedAudioBuffer? decodeWav(Uint8List bytes) {
    if (bytes.length < 44) return null;

    final byteData = ByteData.sublistView(bytes);

    // Check 'RIFF' magic header
    if (bytes[0] != 0x52 || bytes[1] != 0x49 || bytes[2] != 0x46 || bytes[3] != 0x46) {
      return null;
    }

    // Check 'WAVE' header
    if (bytes[8] != 0x57 || bytes[9] != 0x41 || bytes[10] != 0x56 || bytes[11] != 0x45) {
      return null;
    }

    int offset = 12;
    int audioFormat = 1;
    int channels = 1;
    int sampleRate = 44100;
    int bitsPerSample = 16;
    int dataOffset = -1;
    int dataSize = 0;

    while (offset + 8 <= bytes.length) {
      final chunkId = String.fromCharCodes(bytes.sublist(offset, offset + 4));
      final chunkSize = byteData.getUint32(offset + 4, Endian.little);

      if (chunkId == 'fmt ') {
        audioFormat = byteData.getUint16(offset + 8, Endian.little);
        channels = byteData.getUint16(offset + 10, Endian.little);
        sampleRate = byteData.getUint32(offset + 12, Endian.little);
        bitsPerSample = byteData.getUint16(offset + 22, Endian.little);

        // Handle WAVE_FORMAT_EXTENSIBLE (0xFFFE = 65534)
        if (audioFormat == 65534 && chunkSize >= 40 && offset + 34 <= bytes.length) {
          final subFormat = byteData.getUint16(offset + 32, Endian.little);
          if (subFormat == 1 || subFormat == 3) {
            audioFormat = subFormat;
          }
        }
      } else if (chunkId == 'data') {
        dataOffset = offset + 8;
        dataSize = chunkSize;
        break;
      }

      offset += 8 + chunkSize;
      if (chunkSize % 2 != 0) offset++; // Chunk padding alignment
    }


    if (dataOffset == -1 || dataOffset + dataSize > bytes.length) {
      return null;
    }

    final pcmSamples = <double>[];
    final sampleCount = dataSize ~/ (channels * (bitsPerSample ~/ 8));

    for (int i = 0; i < sampleCount; i++) {
      final bytesPerSample = bitsPerSample ~/ 8;
      final framePos = dataOffset + i * channels * bytesPerSample;

      double frameSum = 0.0;
      for (int ch = 0; ch < channels; ch++) {
        final pos = framePos + ch * bytesPerSample;
        if (pos + bytesPerSample > bytes.length) break;

        double sampleVal = 0.0;
        if (audioFormat == 3 && bitsPerSample == 32) {
          sampleVal = byteData.getFloat32(pos, Endian.little).clamp(-1.0, 1.0);
        } else if (bitsPerSample == 16) {
          final int16 = byteData.getInt16(pos, Endian.little);
          sampleVal = int16 / 32768.0;
        } else if (bitsPerSample == 8) {
          final uint8 = bytes[pos];
          sampleVal = (uint8 - 128) / 128.0;
        } else if (bitsPerSample == 24) {
          final b0 = bytes[pos];
          final b1 = bytes[pos + 1];
          final b2 = bytes[pos + 2];
          int val = (b2 << 16) | (b1 << 8) | b0;
          if ((val & 0x800000) != 0) {
            val |= 0xFF000000;
          }
          sampleVal = val / 8388608.0;
        }
        frameSum += sampleVal;
      }

      pcmSamples.add(frameSum / channels);
    }

    // Normalize sample rate to 44100 Hz if different (e.g. 48000 Hz or 22050 Hz)
    List<double> finalSamples = pcmSamples;
    if (sampleRate != 44100 && pcmSamples.isNotEmpty) {
      final rateRatio = 44100.0 / sampleRate;
      final resampledCount = (pcmSamples.length * rateRatio).round();
      final resampled = List<double>.filled(resampledCount, 0.0);

      for (int i = 0; i < resampledCount; i++) {
        final srcIdx = i / rateRatio;
        final idx0 = srcIdx.floor();
        final idx1 = (idx0 + 1).clamp(0, pcmSamples.length - 1);
        final frac = srcIdx - idx0;

        if (idx0 >= pcmSamples.length - 1) {
          resampled[i] = pcmSamples.last;
        } else {
          resampled[i] = (1.0 - frac) * pcmSamples[idx0] + frac * pcmSamples[idx1];
        }
      }
      finalSamples = resampled;
    }

    return DecodedAudioBuffer(
      samples: finalSamples,
      sampleRate: 44100,
      channels: channels,
    );
  }
}

