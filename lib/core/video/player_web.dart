import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';
import '../api/server_config.dart';
import 'player_api.dart';

UnifiedVideoPlayer createPlatformPlayer() => WebVideoPlayer();

class WebVideoPlayer implements UnifiedVideoPlayer {
  VideoPlayerController? _ctrl;
  final List<VoidCallback> _listeners = [];

  @override
  bool get isInitialized => _ctrl?.value.isInitialized ?? false;
  @override
  bool get isPlaying => _ctrl?.value.isPlaying ?? false;
  @override
  Duration get position => _ctrl?.value.position ?? Duration.zero;
  @override
  Duration get duration => _ctrl?.value.duration ?? Duration.zero;
  @override
  Size get videoSize => _ctrl?.value.size ?? Size.zero;

  @override
  Future<void> open(String url) async {
    _ctrl?.dispose();
    final fullUrl = url.startsWith('http') ? url : '${ServerConfig.mediaBaseUrl}$url';
    _ctrl = VideoPlayerController.networkUrl(Uri.parse(fullUrl));
    // Re-attach listeners before initialize so first frame fires
    for (final l in _listeners) {
      _ctrl!.addListener(l);
    }
    await _ctrl!.initialize();
  }

  @override
  Future<void> play() async => _ctrl?.play();
  @override
  Future<void> pause() async => _ctrl?.pause();
  @override
  Future<void> seekTo(Duration pos) async => _ctrl?.seekTo(pos);
  @override
  Future<void> setVolume(double v) async => _ctrl?.setVolume(v);

  @override
  void addListener(VoidCallback cb) {
    _listeners.add(cb);
    _ctrl?.addListener(cb);
  }

  @override
  void removeListener(VoidCallback cb) {
    _listeners.remove(cb);
    _ctrl?.removeListener(cb);
  }

  @override
  Widget buildWidget() {
    if (_ctrl == null || !_ctrl!.value.isInitialized) return const SizedBox.shrink();
    return VideoPlayer(_ctrl!);
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    _ctrl = null;
    _listeners.clear();
  }
}
