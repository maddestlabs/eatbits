import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

void downloadWebZipImpl(Uint8List bytes, String fileName) {
  debugPrint('Zip download not supported on VM target');
}

void downloadWebFileImpl(String content, String fileName) {
  Clipboard.setData(ClipboardData(text: content));
}

void pickEatsFileWebImpl(
    Function(Uint8List? bytes, String? textContent, String fileName) onFileLoaded) {
  debugPrint('Web file picking not supported on VM target');
}
