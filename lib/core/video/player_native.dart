import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart' as mkv;
import '../api/server_config.dart';
import 'player_api.dart';

UnifiedVideoPlayer createPlatformPlayer() => NativeVideoPlayer();

class NativeVideoPlayer implements UnifiedVideoPlayer {
  late final Player _player;
  late final mkv.VideoController _videoController;
  final List<VoidCallback> _listeners = [];
  final List<StreamSubscription> _subs = [];
  bool _initialized = false;

  NativeVideoPlayer() {
    _player = Player();
    _videoController = mkv.VideoController(_player);

    // Forward state changes to listeners
    _subs.add(_player.stream.playing.listen((_) => _notify()));
    _subs.add(_player.stream.position.listen((_) => _notify()));
    _subs.add(_player.stream.duration.listen((_) => _notify()));
    _subs.add(_player.stream.completed.listen((_) => _notify()));
    _subs.add(_player.stream.width.listen((_) => _notify()));
  }

  void _notify() {
    for (final l in _listeners) {
      l();
    }
  }

  @override
  bool get isInitialized => _initialized && _player.state.duration > Duration.zero;
  @override
  bool get isPlaying => _player.state.playing;
  @override
  Duration get position => _player.state.position;
  @override
  Duration get duration => _player.state.duration;
  @override
  Size get videoSize {
    final w = _player.state.width;
    final h = _player.state.height;
    if (w != null && h != null && w > 0 && h > 0) {
      return Size(w.toDouble(), h.toDouble());
    }
    return const Size(1920, 1080); // fallback
  }

  @override
  Future<void> open(String url) async {
    final fullUrl = url.startsWith('http') ? url : '${ServerConfig.mediaBaseUrl}$url';
    await _player.open(Media(fullUrl));
    _initialized = true;
    _notify();
  }

  @override
  Future<void> play() async => _player.play();
  @override
  Future<void> pause() async => _player.pause();
  @override
  Future<void> seekTo(Duration pos) async => _player.seek(pos);
  @override
  Future<void> setVolume(double v) async => _player.setVolume(v * 100); // media_kit: 0-100

  @override
  void addListener(VoidCallback cb) => _listeners.add(cb);
  @override
  void removeListener(VoidCallback cb) => _listeners.remove(cb);

  @override
  Widget buildWidget() {
    // We render our own controls in room_screen — disable media_kit's default
    // material overlay (red seekbar / fullscreen button) so it doesn't paint
    // on top of the app UI.
    return mkv.Video(
      controller: _videoController,
      controls: mkv.NoVideoControls,
    );
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    _listeners.clear();
    _player.dispose();
  }
}
