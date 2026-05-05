import 'dart:js_interop';

import 'package:web/web.dart' as web;

void enterBrowserFullscreen() {
  if (web.document.fullscreenElement != null) return;
  try {
    web.document.documentElement?.requestFullscreen();
  } catch (_) {}
}

void exitBrowserFullscreen() {
  // Calling exitFullscreen when not fullscreen (or after the user pressed
  // Esc / switched tab) raises "Document not active" — so guard on the
  // current fullscreen element being present, and swallow any leftover
  // races (re-entrant exit calls during transition).
  if (web.document.fullscreenElement == null) return;
  try {
    web.document.exitFullscreen();
  } catch (_) {}
}

/// Subscribes to the document's `fullscreenchange` event so the caller
/// can keep Flutter state in sync with browser-driven exits (Esc key,
/// window blur, OS-level toggle). Returns a disposer.
void Function() onBrowserFullscreenChange(void Function(bool) handler) {
  void listener(web.Event _) {
    handler(web.document.fullscreenElement != null);
  }
  final jsListener = listener.toJS;
  web.document.addEventListener('fullscreenchange', jsListener);
  return () =>
      web.document.removeEventListener('fullscreenchange', jsListener);
}
