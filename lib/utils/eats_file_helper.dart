import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'eats_file_helper_stub.dart'
    if (dart.library.html) 'eats_file_helper_web.dart';

class EatsFileHelper {
  /// Save/Download `.eats.lua` file.
  static void saveEatsLuaFile(String content, String fileName) {
    if (kIsWeb) {
      downloadWebFileImpl(content, fileName);
    } else {
      // On desktop/mobile, copy to clipboard as immediate fallback
      Clipboard.setData(ClipboardData(text: content));
    }
  }

  /// Triggers a web file input dialog for picking a `.eats.lua` file.
  static void pickEatsLuaFileWeb(Function(String content, String fileName) onFileLoaded) {
    if (kIsWeb) {
      pickEatsLuaFileWebImpl(onFileLoaded);
    }
  }
}
