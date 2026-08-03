import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_wren_daw/audio/soundfont_decoder.dart';
import 'package:mobile_wren_daw/audio/soundfont_engine.dart';
import 'package:mobile_wren_daw/models/daw_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SoundFont 2 (.sf2) Decoder & Engine Tests', () {
    test('SoundFontDecoder gracefully rejects non-RIFF binary data', () {
      final invalidBytes = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]);
      final result = SoundFontDecoder.decode(invalidBytes);
      expect(result, isNull);
    });

    test('DawState handles .sf2 drag and drop auto track creation', () {
      final dawState = DawState();
      final dummySf2Bytes = Uint8List(100);

      final initialTrackCount = dawState.activePattern.tracks.length;
      dawState.addSampleTrackFromFile(fileName: 'vintage_piano.sf2', fileBytes: dummySf2Bytes);

      expect(dawState.activePattern.tracks.length, equals(initialTrackCount + 1));
      final newTrack = dawState.activePattern.tracks.last;
      expect(newTrack.name, equals('vintage_piano'));
      expect(newTrack.sampleName, equals('vintage_piano.sf2'));
    });
  });
}
