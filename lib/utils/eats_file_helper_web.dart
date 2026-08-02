import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

void downloadWebZipImpl(Uint8List bytes, String fileName) {
  try {
    final blob = html.Blob([bytes], 'application/zip');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final name = fileName.endsWith('.eats.zip')
        ? fileName
        : (fileName.endsWith('.zip') ? fileName : '$fileName.eats.zip');
    final anchor = html.AnchorElement()
      ..href = url
      ..download = name;
    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  } catch (e) {
    debugPrint('Web ZIP download failed: $e');
  }
}

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

void pickEatsFileWebImpl(
    Function(Uint8List? bytes, String? textContent, String fileName) onFileLoaded) {
  try {
    final uploadInput = html.InputElement()
      ..type = 'file'
      ..accept = '.eats.zip,.zip,.lua,.eats,.txt';
    uploadInput.click();

    uploadInput.onChange.listen((event) {
      final files = uploadInput.files;
      if (files != null && files.isNotEmpty) {
        final file = files.first;
        final isZip = file.name.endsWith('.zip') || file.name.endsWith('.eats.zip');
        final reader = html.FileReader();

        if (isZip) {
          reader.readAsArrayBuffer(file);
          reader.onLoadEnd.listen((e) {
            final result = reader.result;
            if (result is Uint8List) {
              onFileLoaded(result, null, file.name);
            } else if (result is ByteBuffer) {
              onFileLoaded(result.asUint8List(), null, file.name);
            }
          });
        } else {
          reader.readAsText(file);
          reader.onLoadEnd.listen((e) {
            final content = reader.result as String?;
            if (content != null && content.isNotEmpty) {
              onFileLoaded(null, content, file.name);
            }
          });
        }
      }
    });
  } catch (e) {
    debugPrint('Web file picker failed: $e');
  }
}
