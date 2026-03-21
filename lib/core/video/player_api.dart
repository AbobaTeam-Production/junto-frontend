import 'package:flutter/widgets.dart';

/// Platform-agnostic video player interface.
abstract class UnifiedVideoPlayer {
  bool get isInitialized;
  bool get isPlaying;
  Duration get position;
  Duration get duration;
  Size get videoSize;

  Future<void> open(String url);
  Future<void> play();
  Future<void> pause();
  Future<void> seekTo(Duration position);
  Future<void> setVolume(double volume); // 0.0 – 1.0
  void addListener(VoidCallback callback);
  void removeListener(VoidCallback callback);
  Widget buildWidget();
  void dispose();
}
