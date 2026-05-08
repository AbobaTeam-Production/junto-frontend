// Web implementation — listens for postMessage from
// firebase-messaging-sw.js with shape {type: 'fcm_navigate', path}.

import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

void subscribeFcmNavigate(void Function(String path) onNavigate) {
  web.window.navigator.serviceWorker.addEventListener(
    'message',
    ((web.MessageEvent event) {
      try {
        final raw = event.data;
        if (raw == null) return;
        final asMap = raw.dartify();
        if (asMap is! Map) return;
        if (asMap['type'] != 'fcm_navigate') return;
        final path = asMap['path'];
        if (path is String) onNavigate(path);
      } catch (e) {
        debugPrint('SW message handler failed: $e');
      }
    }).toJS,
  );
}
