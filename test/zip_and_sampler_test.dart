import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_wren_daw/audio/sampler_engine.dart';
import 'package:mobile_wren_daw/audio/wav_exporter.dart';
import 'package:mobile_wren_daw/models/daw_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SamplerEngine & .eats.zip Tests', () {
    test('SamplerEngine encodes and decodes WAV buffers correctly', () {
      final left = [0.0, 0.5, 1.0, 0.5, 0.0, -0.5, -1.0, -0.5];
      final right = [0.0, 0.5, 1.0, 0.5, 0.0, -0.5, -1.0, -0.5];

      final wavBytes = WavExporter.encodeWav(
        leftSamples: left,
        rightSamples: right,
        sampleRate: 44100,
      );

      expect(wavBytes.isNotEmpty, isTrue);

      final success = SamplerEngine.instance.registerSampleBytes('test_sample', wavBytes);
      expect(success, isTrue);

      final buffer = SamplerEngine.instance.getSample('test_sample');
      expect(buffer, isNotNull);
      expect(buffer!.samples.length, equals(8));
      expect(buffer.sampleRate, equals(44100));
    });

    test('DawState exports and imports .eats.zip archives', () {
      final dawState = DawState();
      dawState.projectName = 'iOS Test Project';

      // Export to .eats.zip
      final zipBytes = dawState.exportToEatsZip();
      expect(zipBytes.isNotEmpty, isTrue);

      final importedState = DawState();
      importedState.loadFromEatsZipOrLua(zipBytes: zipBytes);
      expect(importedState.projectName, equals('iOS Test Project'));
    });


    test('WaveformOverview generates 128 decimation peak points', () {
      final samples = List<double>.generate(1000, (i) => (i % 2 == 0) ? 0.8 : -0.8);
      final overview = WaveformOverview.generate(samples, 128);

      expect(overview.maxPeaks.length, equals(128));
      expect(overview.minPeaks.length, equals(128));
      expect(overview.maxPeaks.first, equals(0.8));
      expect(overview.minPeaks.first, equals(-0.8));
    });
  });
}

