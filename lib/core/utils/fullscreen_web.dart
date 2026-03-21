import 'package:web/web.dart' as web;

void enterBrowserFullscreen() {
  web.document.documentElement?.requestFullscreen();
}

void exitBrowserFullscreen() {
  web.document.exitFullscreen();
}
