import 'package:web/web.dart' as web;

bool _injected = false;

/// Injects a global CSS rule that disables pointer events on ALL video elements
/// and their platform view containers. Works regardless of shadow DOM or timing.
void disableVideoPointerEvents() {
  if (_injected) return;
  _injected = true;

  final style = web.document.createElement('style') as web.HTMLStyleElement;
  style.textContent = '''
    video,
    flt-platform-view,
    flt-platform-view * {
      pointer-events: none !important;
    }
  ''';
  web.document.head?.append(style);
}
