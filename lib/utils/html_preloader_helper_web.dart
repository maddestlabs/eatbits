import 'dart:js_interop';

@JS('hideAppLoadingScreen')
external void _hideAppLoadingScreen();

void dismissHtmlPreloaderImpl() {
  try {
    _hideAppLoadingScreen();
  } catch (_) {}
}
