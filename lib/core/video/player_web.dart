import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

import '../api/server_config.dart';
import 'player_api.dart';

UnifiedVideoPlayer createPlatformPlayer() => WebVideoPlayer();

@JS('Hls')
external JSAny? get _hlsCtor;

@JS('Hls.isSupported')
external bool _hlsIsSupported();

@JS('Hls')
@staticInterop
class _Hls {
  external factory _Hls();
}

extension _HlsExt on _Hls {
  external void loadSource(String url);
  external void attachMedia(web.HTMLVideoElement video);
  external void destroy();
  external void on(String event, JSFunction callback);
  external void recoverMediaError();
  external void startLoad();
}

/// Web video player. Direct hls.js + HTMLVideoElement plumbing — no
/// `video_player_web_hls`, which has broken JS interop with hls.js >=1.4
/// (triggers `internalException` on `hlsMediaAttached` so the source is
/// never loaded). For non-HLS URLs we just set `video.src` and let the
/// browser handle it.
class WebVideoPlayer implements UnifiedVideoPlayer {
  static int _seq = 0;

  web.HTMLVideoElement? _video;
  _Hls? _hls;
  String? _viewType;
  final List<VoidCallback> _listeners = [];
  final List<StreamSubscription<web.Event>> _subs = [];
  bool _initialized = false;

  @override
  bool get isInitialized => _initialized;

  @override
  bool get isPlaying => _video != null && !_video!.paused;

  @override
  Duration get position => _toDuration(_video?.currentTime);

  @override
  Duration get duration => _toDuration(_video?.duration);

  @override
  Size get videoSize {
    final v = _video;
    if (v == null) return Size.zero;
    return Size(v.videoWidth.toDouble(), v.videoHeight.toDouble());
  }

  // hls.js + EVENT playlist (mid-transcode) reports infinite/NaN duration
  // until ffmpeg writes ENDLIST. Coerce to zero so room-sync math doesn't
  // produce NaN seek targets.
  static Duration _toDuration(num? v) {
    if (v == null || v.isNaN || v.isInfinite || v < 0) return Duration.zero;
    final us = (v * 1e6).round();
    if (us > 24 * 3600 * 1000000) return Duration.zero;
    return Duration(microseconds: us);
  }

  @override
  Future<void> open(String url) async {
    dispose();
    _initialized = false;

    final fullUrl =
        url.startsWith('http') ? url : '${ServerConfig.mediaBaseUrl}$url';

    final video = web.HTMLVideoElement()
      ..id = 'junto-video-${++_seq}'
      ..autoplay = false
      ..controls = false
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.backgroundColor = '#000';
    video.setAttribute('playsinline', 'true');
    _video = video;

    final viewType = 'junto-video-view-$_seq';
    _viewType = viewType;
    ui_web.platformViewRegistry.registerViewFactory(
      viewType, (int _) => video);

    void notify() {
      for (final l in List<VoidCallback>.from(_listeners)) {
        try {
          l();
        } catch (_) {}
      }
    }

    // hls.js fires loadedmetadata/canplay as soon as it attaches a
    // MediaSource — even before any segment is buffered, so duration
    // and videoWidth are still 0. Treat the player as initialized only
    // when we actually have a valid duration or real video dimensions.
    void maybeMarkInitialized() {
      if (_initialized) return;
      final dur = video.duration;
      final hasDur = dur.isFinite && dur > 0.5;
      final hasFrame = video.videoWidth > 0 && video.videoHeight > 0;
      if (hasDur || hasFrame) {
        _initialized = true;
        notify();
      }
    }

    _subs
      ..add(video.onLoadedMetadata.listen((_) {
        maybeMarkInitialized();
        notify();
      }))
      ..add(video.onDurationChange.listen((_) {
        maybeMarkInitialized();
        notify();
      }))
      ..add(video.onTimeUpdate.listen((_) => notify()))
      ..add(video.onPlay.listen((_) => notify()))
      ..add(video.onPause.listen((_) => notify()))
      ..add(video.onSeeked.listen((_) => notify()))
      ..add(video.onCanPlay.listen((_) {
        maybeMarkInitialized();
        notify();
      }))
      ..add(video.onError.listen((_) {
        // Surface decode errors so they show up in the room overlay; no
        // throw — playback layer keeps state stable.
        // ignore: avoid_print
        print('JUNTO: web <video> error code=${video.error?.code} '
            'msg=${video.error?.message}');
      }));

    final isHls = fullUrl.contains('.m3u8');
    final hasHlsJs = _hlsCtor != null && _hlsIsSupported();

    // Prefer hls.js for HLS even when the browser claims native support.
    // Some Chromium builds report `canPlayType('application/vnd.apple.mpegurl')='maybe'`
    // but actually fail decoding fragmented TS, dropping into
    // DEMUXER_ERROR_COULD_NOT_PARSE the moment we hit play. hls.js routes
    // through MSE which is what those builds *do* support reliably. Native
    // path is reserved for Safari/iOS where MSE for HLS is restricted.
    final ua = web.window.navigator.userAgent;
    final isSafari = ua.contains('Safari') &&
        !ua.contains('Chrome') &&
        !ua.contains('Chromium');

    if (isHls && hasHlsJs && !isSafari) {
      final hls = _Hls();
      _hls = hls;
      // Order matters: attach BEFORE loadSource so the manifest parser
      // and MSE come up together.
      hls.attachMedia(video);
      hls.loadSource(fullUrl);

      // hls.js stalls on fatal errors unless we explicitly recover.
      // Mid-transcode the first segment can hit DEMUXER_ERROR_COULD_NOT_PARSE
      // (incomplete SPS/PPS); a recoverMediaError() restart usually fixes
      // it once the next segments arrive. networkError → startLoad() to
      // retry segment fetches.
      var mediaRetries = 0;
      var netRetries = 0;
      void recoverMedia() {
        if (mediaRetries >= 3) return;
        mediaRetries++;
        try {
          hls.recoverMediaError();
        } catch (_) {}
      }

      hls.on(
        'hlsError',
        ((JSAny _, JSObject data) {
          final fatal = (data.getProperty('fatal'.toJS) as JSBoolean?)
                  ?.toDart ??
              false;
          final type =
              (data.getProperty('type'.toJS) as JSString?)?.toDart ?? '';
          final details =
              (data.getProperty('details'.toJS) as JSString?)?.toDart ?? '';
          // ignore: avoid_print
          print('JUNTO: hls.js error fatal=$fatal type=$type details=$details');
          if (!fatal) return;
          if (type == 'mediaError') {
            recoverMedia();
          } else if (type == 'networkError' && netRetries < 5) {
            netRetries++;
            try {
              hls.startLoad();
            } catch (_) {}
          }
        }).toJS,
      );

      // Also catch the bare <video> error event: when the segment is
      // malformed enough that the SourceBuffer rejects it before hls.js
      // has a chance to flag a fatal error, the video element fires
      // MEDIA_ERR_DECODE (code=4) and we'd otherwise silently freeze.
      _subs.add(video.onError.listen((_) {
        if (video.error?.code == 4) recoverMedia();
      }));
    } else {
      // Safari (native HLS) or progressive (mp4/webm).
      video.src = fullUrl;
    }

    // Wait until we actually have valid metadata (real duration or
    // dimensions), or hit a hard error. hls.js fires loadedmetadata
    // synthetically on attach, so polling the actual values is safer
    // than trusting the events alone.
    final ready = Completer<void>();
    void resolveIfReady() {
      if (ready.isCompleted) return;
      final dur = video.duration;
      final hasDur = dur.isFinite && dur > 0.5;
      final hasFrame = video.videoWidth > 0 && video.videoHeight > 0;
      if (hasDur || hasFrame) ready.complete();
    }

    final loadedSub = video.onLoadedMetadata.listen((_) => resolveIfReady());
    final canPlaySub = video.onCanPlay.listen((_) => resolveIfReady());
    final durSub = video.onDurationChange.listen((_) => resolveIfReady());
    final errSub = video.onError.listen((_) {
      if (!ready.isCompleted) ready.complete();
    });
    try {
      await ready.future.timeout(const Duration(seconds: 12), onTimeout: () {});
    } finally {
      loadedSub.cancel();
      canPlaySub.cancel();
      durSub.cancel();
      errSub.cancel();
    }

    // Even if we timed out without metadata, mark initialized so the
    // UI shows the video element — duration will fill in via the live
    // listener subscriptions above.
    if (!_initialized) {
      _initialized = true;
      notify();
    }
  }

  @override
  Future<void> play() async {
    final v = _video;
    if (v == null) return;
    try {
      final p = v.play();
      await p.toDart;
    } catch (_) {}
  }

  @override
  Future<void> pause() async {
    _video?.pause();
  }

  @override
  Future<void> seekTo(Duration pos) async {
    final v = _video;
    if (v == null) return;
    final t = pos.inMilliseconds / 1000.0;
    if (t.isNaN || t.isInfinite || t < 0) return;
    v.currentTime = t;
  }

  @override
  Future<void> setVolume(double v) async {
    _video?.volume = v.clamp(0.0, 1.0);
  }

  @override
  void addListener(VoidCallback cb) {
    _listeners.add(cb);
  }

  @override
  void removeListener(VoidCallback cb) {
    _listeners.remove(cb);
  }

  @override
  Widget buildWidget() {
    final vt = _viewType;
    if (vt == null) return const SizedBox.shrink();
    return HtmlElementView(viewType: vt);
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    try {
      _hls?.destroy();
    } catch (_) {}
    _hls = null;
    final v = _video;
    if (v != null) {
      try {
        v.pause();
        v.removeAttribute('src');
        v.load();
      } catch (_) {}
    }
    _video = null;
    _viewType = null;
    _initialized = false;
  }
}
