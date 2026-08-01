import 'package:flutter/foundation.dart';
import 'html_preloader_helper_stub.dart'
    if (dart.library.js_interop) 'html_preloader_helper_web.dart';

class HtmlPreloaderHelper {
  static void dismissHtmlPreloader() {
    if (kIsWeb) {
      dismissHtmlPreloaderImpl();
    }
  }
}
