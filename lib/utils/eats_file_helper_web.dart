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
      ..accept = '.eats.zip,.zip,.sf2,.wav,.mp3,.lua,.eats,.txt';
    uploadInput.click();

    uploadInput.onChange.listen((event) {
      final files = uploadInput.files;
      if (files != null && files.isNotEmpty) {
        final file = files.first;
        final name = file.name.toLowerCase();
        final isBinary = name.endsWith('.zip') || name.endsWith('.eats.zip') || name.endsWith('.sf2') || name.endsWith('.wav') || name.endsWith('.mp3');
        final reader = html.FileReader();

        if (isBinary) {
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

void initGlobalAudioDropImpl(Function(String fileName, Uint8List bytes) onAudioDropped) {
  try {
    html.document.body?.onDragOver.listen((event) {
      event.preventDefault();
    });

    html.document.body?.onDrop.listen((event) {
      event.preventDefault();
      final files = event.dataTransfer.files;
      if (files != null && files.isNotEmpty) {
        final file = files.first;
        final name = file.name.toLowerCase();
        if (name.endsWith('.wav') || name.endsWith('.mp3') || name.endsWith('.sf2') || name.endsWith('.ogg') || name.endsWith('.flac')) {
          final reader = html.FileReader();
          reader.readAsArrayBuffer(file);
          reader.onLoadEnd.listen((e) {
            final result = reader.result;
            if (result is Uint8List) {
              onAudioDropped(file.name, result);
            } else if (result is ByteBuffer) {
              onAudioDropped(file.name, result.asUint8List());
            }
          });
        }
      }
    });

  } catch (e) {
    debugPrint('Error setting up web file drop listener: $e');
  }
}

Future<Uint8List?> fetchUrlBytesWebImpl(String url) async {
  try {
    final req = await html.HttpRequest.request(
      url,
      responseType: 'arraybuffer',
    );
    if (req.status == 200 && req.response != null) {
      final ByteBuffer buf = req.response as ByteBuffer;
      return buf.asUint8List();
    }
  } catch (e) {
    debugPrint('Error fetching URL $url: $e');
  }
  return null;
}

