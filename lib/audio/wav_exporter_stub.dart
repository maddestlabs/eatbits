import 'dart:typed_data';
import 'package:flutter/foundation.dart';

void saveWavFileImpl(Uint8List wavBytes, String filename) {
  debugPrint('WAV download not supported on non-web target');
}
