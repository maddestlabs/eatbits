import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

void downloadWebFileImpl(String content, String fileName) {
  Clipboard.setData(ClipboardData(text: content));
}

void pickEatsLuaFileWebImpl(Function(String content, String fileName) onFileLoaded) {
  debugPrint('Web file picking not supported on VM target');
}
