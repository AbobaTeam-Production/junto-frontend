import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Stub for mobile — WebRTC handles audio natively.
Future<void> attachWebAudio(String peerId, MediaStream stream) async {}
Future<void> detachWebAudio(String peerId) async {}
Future<void> detachAllWebAudio() async {}
