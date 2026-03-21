import 'package:flutter_webrtc/flutter_webrtc.dart';

/// On web: use RTCVideoRenderer to play remote audio.
/// Chrome AEC operates at the system audio level regardless of element type.
final Map<String, RTCVideoRenderer> _renderers = {};

Future<void> attachWebAudio(String peerId, MediaStream stream) async {
  await detachWebAudio(peerId);
  final renderer = RTCVideoRenderer();
  await renderer.initialize();
  renderer.srcObject = stream;
  _renderers[peerId] = renderer;
}

Future<void> detachWebAudio(String peerId) async {
  final r = _renderers.remove(peerId);
  if (r != null) {
    r.srcObject = null;
    await r.dispose();
  }
}

Future<void> detachAllWebAudio() async {
  for (final r in _renderers.values) {
    r.srcObject = null;
    await r.dispose();
  }
  _renderers.clear();
}
