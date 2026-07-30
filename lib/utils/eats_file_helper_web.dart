import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

void downloadWebFileImpl(String content, String fileName) {
  try {
    final bytes = utf8.encode(content);
    final blob = html.Blob([bytes], 'text/x-lua;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement()
      ..href = url
      ..download = fileName.endsWith('.eats.lua') ? fileName : '$fileName.eats.lua';
    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  } catch (e) {
    debugPrint('Web download failed: $e');
  }
}

void pickEatsLuaFileWebImpl(Function(String content, String fileName) onFileLoaded) {
  try {
    final uploadInput = html.InputElement()
      ..type = 'file'
      ..accept = '.lua,.eats,.txt';
    uploadInput.click();

    uploadInput.onChange.listen((event) {
      final files = uploadInput.files;
      if (files != null && files.isNotEmpty) {
        final file = files.first;
        final reader = html.FileReader();
        reader.readAsText(file);
        reader.onLoadEnd.listen((e) {
          final content = reader.result as String?;
          if (content != null && content.isNotEmpty) {
            onFileLoaded(content, file.name);
          }
        });
      }
    });
  } catch (e) {
    debugPrint('Web file picker failed: $e');
  }
}
