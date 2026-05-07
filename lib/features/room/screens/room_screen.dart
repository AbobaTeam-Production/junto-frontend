import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/fullscreen_stub.dart'
    if (dart.library.js_interop) '../../../core/utils/fullscreen_web.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/video/player_api.dart';
import '../../../core/video/player_factory.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/junto_primitives.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/server_config.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/room_ws_provider.dart';
import '../../../core/providers/voice_chat_provider.dart';
import '../../../core/utils/clock_sync.dart';
import '../../rooms/providers/room_providers.dart';
import '../widgets/chat_panel.dart';
import '../widgets/participant_list.dart';
import '../widgets/queue_panel.dart';
import '../widgets/reaction_overlay.dart';
import '../../../l10n/app_localizations.dart';

class RoomScreen extends ConsumerStatefulWidget {
  final String roomId;

  const RoomScreen({super.key, required this.roomId});

  @override
  ConsumerState<RoomScreen> createState() => _RoomScreenState();
}

enum _PlayerUIState {
  /// No URL, no progress, no controller (e.g. mediaProgress already 100 but
  /// URL not yet propagated — rare edge case, render nothing).
  idle,
  /// Waiting for the host to add content (no progress, no URL).
  waiting,
  /// Backend transcoding progress while there's no playable URL for this
  /// platform yet.
  transcoding,
  /// URL set (locally or via WS), controller initializing.
  loading,
  /// Controller has finished `open()` and is ready to play.
  ready,
}

class _RoomScreenState extends ConsumerState<RoomScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final TabController _tabController;
  UnifiedVideoPlayer? _videoController;
  String? _currentHlsUrl;
  bool _isHost = false;
  bool _showControls = true;
  bool _videoEnded = false;
  /// True after `controller.open(url)` Future resolves successfully.
  ///
  /// On Web with a still-running HLS event playlist (no #EXT-X-ENDLIST yet)
  /// `controller.isInitialized` stays false because media_kit can't compute
  /// a duration. We treat the player as usable as soon as open() finishes,
  /// since playback / play() / seek() actually work regardless.
  bool _videoOpened = false;
  bool _isFullscreen = false;
  bool _orientationFullscreen = false;
  double _volume = 1.0;
  Timer? _hideControlsTimer;
  PlayerState? _lastAppliedPlayerState;
  void Function()? _disposeFsListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 3, vsync: this);

    // Keep Flutter state in sync when the browser exits fullscreen by
    // itself (Esc, alt-tab, OS toggle). Without this our `_isFullscreen`
    // flag stays true and the UI gets stuck in the fullscreen layout
    // while the document is back to normal — buttons covered, etc.
    if (kIsWeb) {
      _disposeFsListener = onBrowserFullscreenChange((inFs) {
        if (!mounted) return;
        if (!inFs && _isFullscreen) {
          // Re-parenting the <video> element back to the windowed layout
          // makes Chrome auto-pause the MediaSource. The DOM mutation +
          // pause happen *after* Flutter's rebuild, so a single
          // post-frame play() lands too early. Retry on a short ladder
          // until the element is actually playing again.
          final wasPlaying = _videoController?.isPlaying ?? false;
          setState(() {
            _isFullscreen = false;
            _orientationFullscreen = false;
          });
          if (wasPlaying) _resumeAfterFullscreenExit();
        }
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Force fresh fetch of room data (avoid stale cache from previous visit)
      ref.invalidate(roomDetailProvider(widget.roomId));

      // Listen for room detail data — detect host status and media from API
      ref.listenManual(
        roomDetailProvider(widget.roomId),
        (previous, next) {
          next.whenData((data) {
            // Check host status
            final currentUser = ref.read(currentUserProvider);
            final host = data['host'] as Map<String, dynamic>?;
            if (host != null && currentUser != null) {
              final hostNow = host['username'] == currentUser.username;
              if (hostNow != _isHost && mounted) {
                setState(() => _isHost = hostNow);
              }
            }

            // Check if media is already ready from API (only if WS hasn't set a URL yet)
            final wsPlayer = ref.read(roomWsProvider(widget.roomId)).player;
            final wsHasUrl =
                _pickStreamUrl(hlsUrl: wsPlayer.hlsUrl, rawUrl: wsPlayer.rawStreamUrl) != null;
            if (_currentHlsUrl == null && !wsHasUrl) {
              final mediaList = data['media'] as List?;
              if (mediaList != null && mediaList.isNotEmpty) {
                final media = mediaList.first as Map<String, dynamic>;
                if (media['status'] == 'ready') {
                  final url = _pickStreamUrl(
                    hlsUrl: media['hls_url'] as String?,
                    rawUrl: media['raw_stream_url'] as String?,
                  );
                  if (url != null) _initVideo(url);
                  // On Web, if HLS isn't ready yet, kick off lazy transcode.
                  _maybeRequestTranscode(media);
                } else if (media['status'] == 'processing') {
                  Future.delayed(const Duration(seconds: 2), () {
                    if (mounted && _currentHlsUrl == null) {
                      ref.invalidate(roomDetailProvider(widget.roomId));
                    }
                  });
                }
              }
            }
          });
        },
        fireImmediately: true,
      );

      // Voice presence is managed by LiveKit (see voice_chat_provider).
      // The room WS still emits user_joined/left for chat/seats, but voice
      // tracks are subscribed automatically via LiveKit RoomEvents.

      // When somebody joins/leaves over WS, refresh the room detail so the
      // members list (used by _buildPresenceRow / ParticipantList) catches
      // the new RoomMember row that JoinRoomView just inserted.
      ref.listenManual(
        roomWsProvider(widget.roomId).select((s) => s.onlineUsers),
        (previous, next) {
          if (previous == null) return;
          if (previous.length == next.length) return;
          ref.invalidate(roomDetailProvider(widget.roomId));
        },
      );

      // Listen for media_ready, play_media, and player sync events from WebSocket
      ref.listenManual(
        roomWsProvider(widget.roomId).select((s) => s.player),
        (previous, next) {
          // Init video when media arrives via WS (first media or play_media switch)
          final picked = _pickStreamUrl(
            hlsUrl: next.hlsUrl,
            rawUrl: next.rawStreamUrl,
          );
          if (picked != null && picked != _currentHlsUrl) {
            _initVideo(picked);
            return;
          }

          // Sync playback for non-host viewers
          if (_isHost) return;
          if (_lastAppliedPlayerState == next) return;
          if (previous == null ||
              previous.status != next.status ||
              previous.position != next.position ||
              previous.timestamp != next.timestamp) {
            _lastAppliedPlayerState = next;
            _applyPlayerSync(next);
          }
        },
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeFsListener?.call();
    _hideControlsTimer?.cancel();
    _tabController.dispose();
    _videoController?.dispose();
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([]);
    }
    super.dispose();
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    _restartHideTimer();
  }

  void _restartHideTimer() {
    _hideControlsTimer?.cancel();
    if (_showControls) {
      _hideControlsTimer = Timer(const Duration(seconds: 4), () {
        if (mounted && _showControls) {
          setState(() => _showControls = false);
        }
      });
    }
  }

  void _resumeAfterFullscreenExit() {
    // Schedule resume attempts at 50/200/600 ms — covers fast and slow
    // Esc/Alt-Tab transitions in Chrome/Firefox. Stop as soon as the
    // controller reports it's playing again.
    for (final ms in const [50, 200, 600]) {
      Future.delayed(Duration(milliseconds: ms), () {
        if (!mounted) return;
        final c = _videoController;
        if (c == null || c.isPlaying) return;
        if (_isHost) {
          // Host is the play-state source of truth; broadcast via WS so
          // everyone keeps watching together.
          _onPlayPause();
        } else {
          c.play();
        }
      });
    }
  }

  @override
  void didChangeMetrics() {
    // Auto fullscreen on landscape (mobile only)
    if (kIsWeb) return;
    final size = WidgetsBinding.instance.platformDispatcher.views.first.physicalSize;
    if (size.width == 0 || size.height == 0) return;
    final isLandscape = size.width > size.height;

    if (isLandscape && !_isFullscreen) {
      _enterFullscreen(fromOrientation: true);
    } else if (!isLandscape && _orientationFullscreen) {
      _exitFullscreen();
    }
  }

  void _enterFullscreen({bool fromOrientation = false}) {
    _toggleFullscreen(true, fromOrientation: fromOrientation);
  }

  void _exitFullscreen() {
    _toggleFullscreen(false);
  }

  void _toggleFullscreen(bool enter, {bool fromOrientation = false}) {
    final wasPlaying = _videoController?.isPlaying ?? false;
    final pos = _videoController?.position ?? Duration.zero;

    setState(() {
      _isFullscreen = enter;
      _orientationFullscreen = enter && fromOrientation;
    });

    if (kIsWeb) {
      if (enter) {
        enterBrowserFullscreen();
      } else {
        exitBrowserFullscreen();
      }
    } else {
      if (enter) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        if (!fromOrientation) {
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]);
        }
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        SystemChrome.setPreferredOrientations([]);
      }
    }

    // On web, the video element is re-attached to DOM during rebuild,
    // which pauses it. Restore after a short delay.
    if (wasPlaying) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted && _videoController != null) {
          _videoController!.seekTo(pos);
          _videoController!.play();
        }
      });
    }
  }

  void _initVideo(String streamUrl) {
    if (_currentHlsUrl == streamUrl) return;
    // Non-host: never autoPlay on init — _applyPlayerSync handles it after init
    _createController(streamUrl, autoPlay: _isHost);
  }

  bool _transcodeRequested = false;

  /// On Web, when we land on a torrent media item that has no HLS yet,
  /// poke the backend to start transcoding. Native ignores — it plays
  /// raw_stream_url directly and doesn't burn server CPU.
  void _maybeRequestTranscode(Map<String, dynamic> media) {
    if (!kIsWeb || _transcodeRequested) return;
    if (media['source_type'] != 'torrent') return;
    final hls = media['hls_url'] as String?;
    if (hls != null && hls.isNotEmpty) return;
    final id = media['id']?.toString();
    if (id == null) return;
    _transcodeRequested = true;
    ref.read(dioProvider).post(ApiEndpoints.mediaTranscode(id)).catchError((e) {
      _transcodeRequested = false; // allow retry on next room re-enter
      // ignore: avoid_print
      print('JUNTO: transcode request failed: $e');
      throw e;
    });
  }

  /// Decide which URL the local player should use.
  ///
  /// Web (browsers) can only decode H.264 in fragmented MP4/HLS, so HLS is
  /// required even when a raw torrserver stream is available. Native (libmpv
  /// via media_kit on Android/desktop) plays any container/codec from the
  /// raw URL directly — no transcode wait.
  String? _pickStreamUrl({String? hlsUrl, String? rawUrl}) {
    String? clean(String? s) {
      if (s == null || s.isEmpty) return null;
      // Host-relative URLs (e.g. /torrserver/...) are emitted by the backend
      // so the same record works no matter how the client reached us.
      if (s.startsWith('/')) return '${ServerConfig.mediaBaseUrl}$s';
      return s;
    }
    if (kIsWeb) return clean(hlsUrl);
    return clean(rawUrl) ?? clean(hlsUrl);
  }

  void _createController(String hlsUrl, {Duration startAt = Duration.zero, bool autoPlay = false}) {
    _currentHlsUrl = hlsUrl;
    _videoEnded = false;
    _videoOpened = false;

    _videoController?.dispose();
    final controller = createVideoPlayer();
    _videoController = controller;

    if (mounted) setState(() {});

    controller.addListener(() {
      // Guard: if a newer controller has replaced this one, ignore its
      // stale callbacks instead of touching a disposed player.
      if (!mounted || _videoController != controller) return;
      setState(() {});
      // Detect video end
      if (controller.isInitialized &&
          !controller.isPlaying &&
          controller.duration > Duration.zero &&
          controller.position.inMilliseconds >= controller.duration.inMilliseconds - 300) {
        if (!_videoEnded) {
          _videoEnded = true;
          if (_isHost) _autoAdvanceToNext();
        }
      }
    });

    // ignore: avoid_print
    print('JUNTO: controller.open() begin url=$hlsUrl');
    controller.open(hlsUrl).then((_) {
      // ignore: avoid_print
      print('JUNTO: controller.open() OK isInitialized=${controller.isInitialized} dur=${controller.duration}');
      if (!mounted || _videoController != controller) return;
      _videoOpened = true;
      controller.setVolume(_volume);
      if (startAt > Duration.zero) controller.seekTo(startAt);
      if (autoPlay) controller.play();
      setState(() {});
      // After init, force-sync non-host with current WS state
      if (!_isHost) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted || _videoController != controller) return;
          final ws = ref.read(roomWsProvider(widget.roomId)).player;
          _applyPlayerSync(ws);
        });
      }
    }).catchError((e, st) {
      // ignore: avoid_print
      print('JUNTO: controller.open() ERROR: $e\n$st');
    });
  }

  /// Non-host fallback for the central play button: toggle playback
  /// LOCALLY without broadcasting. Mainly exists so the user can satisfy
  /// Chrome's autoplay-on-user-gesture rule when joining a room where the
  /// host is already playing — controller.play() from _applyPlayerSync
  /// silently fails without a prior user gesture, leaving the video black.
  ///
  /// On a play-tap we re-apply sync once the controller had a moment to
  /// honor the gesture; otherwise the guest would play from 0:00 while
  /// the host is e.g. 30 min in, and no further state change ever
  /// triggers a re-sync.
  // Global keyboard shortcuts for the room: Space toggles play/pause,
  // ←/→ seek by 15s. Wrapped in a Focus(autofocus: true) so events only
  // arrive when no TextField has focus — typing in chat keeps working.
  KeyEventResult _handleKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.space) {
      if (_isHost) {
        _onPlayPause();
      } else {
        _localTogglePlayback();
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight) {
      _seekBy(key == LogicalKeyboardKey.arrowRight ? 15 : -15);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _seekBy(int seconds) {
    final c = _videoController;
    if (c == null || (!c.isInitialized && !_videoOpened)) return;
    final dur = c.duration;
    final target = c.position + Duration(seconds: seconds);
    final clamped = target < Duration.zero
        ? Duration.zero
        : (dur > Duration.zero && target > dur ? dur : target);
    c.seekTo(clamped);
    if (_isHost) {
      ref
          .read(roomWsProvider(widget.roomId).notifier)
          .sendSeek(clamped.inMilliseconds / 1000.0);
    }
  }

  void _localTogglePlayback() {
    final c = _videoController;
    // ignore: avoid_print
    print('JUNTO: localTogglePlayback c=${c != null} init=${c?.isInitialized} opened=$_videoOpened playing=${c?.isPlaying}');
    if (c == null) return;
    if (!c.isInitialized && !_videoOpened) return;
    if (c.isPlaying) {
      c.pause();
      return;
    }
    // Try muted-autoplay first: Chrome will reject c.play() with
    // NotAllowedError if there isn't a clean user-gesture chain (which is
    // brittle through media_kit's internal Promises). Muted always works.
    c.setVolume(0);
    final fut = c.play();
    // ignore: avoid_print
    print('JUNTO: localTogglePlayback called play() (muted)');
    fut.then((_) {
      // ignore: avoid_print
      print('JUNTO: c.play() resolved playing=${c.isPlaying} pos=${c.position}');
      // Restore volume after we successfully started.
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && _videoController == c) c.setVolume(_volume);
      });
    }).catchError((e) {
      // ignore: avoid_print
      print('JUNTO: c.play() rejected: $e');
    });
    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted || _videoController != c) return;
      final ws = ref.read(roomWsProvider(widget.roomId)).player;
      _applyPlayerSync(ws);
    });
  }

  void _onPlayPause() {
    if (!_isHost) return;
    final wsNotifier = ref.read(roomWsProvider(widget.roomId).notifier);

    final controller = _videoController;
    if (controller == null || !controller.isInitialized) return;

    if (controller.isPlaying) {
      final position = controller.position.inMilliseconds / 1000.0;
      controller.pause();
      wsNotifier.sendPause(position);
    } else if (_videoEnded) {
      _createController(_currentHlsUrl!, autoPlay: true);
      late void Function() onReady;
      onReady = () {
        if (_videoController?.isPlaying ?? false) {
          wsNotifier.sendPlay(0);
          _videoController?.removeListener(onReady);
        }
      };
      _videoController?.addListener(onReady);
    } else {
      final position = controller.position.inMilliseconds / 1000.0;
      controller.play();
      wsNotifier.sendPlay(position);
    }
  }

  void _onSeek(double value) {
    if (!_isHost) return;
    final wsNotifier = ref.read(roomWsProvider(widget.roomId).notifier);

    final controller = _videoController;
    if (controller == null || !controller.isInitialized) return;

    final dur = controller.duration;
    final position = Duration(milliseconds: (dur.inMilliseconds * value).toInt());
    final positionSec = position.inMilliseconds / 1000.0;

    if (_videoEnded) {
      _createController(_currentHlsUrl!, startAt: position, autoPlay: true);
      late void Function() onReady;
      onReady = () {
        if (_videoController?.isPlaying ?? false) {
          wsNotifier.sendSeek(positionSec);
          wsNotifier.sendPlay(positionSec);
          _videoController?.removeListener(onReady);
        }
      };
      _videoController?.addListener(onReady);
    } else {
      controller.seekTo(position);
      wsNotifier.sendSeek(positionSec);
    }
  }

  static const _hardSeekThresholdMs = 500;

  void _applyPlayerSync(PlayerState playerState) {
    if (_isHost) return;

    final controller = _videoController;
    if (controller == null) return;
    // _videoOpened covers the Web HLS-event case where isInitialized stays
    // false because hls.js can't compute duration before ENDLIST.
    if (!controller.isInitialized && !_videoOpened) return;

    // Skip drift seek if we don't have a real duration. On Web with a still-
    // running transcode this is the common case: hls.js doesn't know the
    // total length yet, and seeking to the host's position would land past
    // the available range — hls.js waits forever for a segment that
    // ffmpeg hasn't produced. Instead, just mirror play/pause and let the
    // viewer naturally lag the host until the transcode catches up.
    final dur = controller.duration;
    if (dur > Duration.zero) {
      final expectedSec = _expectedPosition(playerState);
      final currentSec = controller.position.inMilliseconds / 1000.0;
      final driftMs = ((currentSec - expectedSec) * 1000).round();
      if (driftMs.abs() > _hardSeekThresholdMs) {
        controller.seekTo(
          Duration(milliseconds: (expectedSec * 1000).toInt()),
        );
      }
    }

    if (playerState.status == 'play' && !controller.isPlaying) {
      controller.play();
    } else if (playerState.status == 'pause' && controller.isPlaying) {
      controller.pause();
    }
  }

  /// Expected video position right now, given the host-authored state.
  ///
  /// While playing, we add the time elapsed on the *server clock* since
  /// the host issued the event (corrected for our local-vs-server skew via
  /// [clockSyncProvider]). While paused, the position is fixed.
  double _expectedPosition(PlayerState playerState) {
    if (playerState.status != 'play' || playerState.serverTsMs == null) {
      return playerState.position;
    }
    final clock = ref.read(clockSyncProvider);
    final serverNow =
        clock?.serverNowMs ?? DateTime.now().millisecondsSinceEpoch;
    final elapsedSec = (serverNow - playerState.serverTsMs!) / 1000.0;
    if (elapsedSec < 0) return playerState.position; // clock not synced yet
    return playerState.position + elapsedSec;
  }

  void _autoAdvanceToNext() {
    final roomData = ref.read(roomDetailProvider(widget.roomId)).valueOrNull;
    if (roomData == null) return;

    final mediaList = (roomData['media'] as List?) ?? [];
    final currentUrl = _currentHlsUrl;

    bool matchesCurrent(Map<String, dynamic> item) {
      final h = item['hls_url'] as String?;
      final r = item['raw_stream_url'] as String?;
      return (h != null && h == currentUrl) || (r != null && r == currentUrl);
    }

    // Find current index
    int currentIndex = -1;
    for (var i = 0; i < mediaList.length; i++) {
      if (matchesCurrent(mediaList[i] as Map<String, dynamic>)) {
        currentIndex = i;
        break;
      }
    }

    // Find next ready item
    for (var i = currentIndex + 1; i < mediaList.length; i++) {
      final item = mediaList[i] as Map<String, dynamic>;
      if (item['status'] != 'ready') continue;
      final hls = item['hls_url'] as String? ?? '';
      final raw = item['raw_stream_url'] as String? ?? '';
      // Need at least one URL the local platform can use.
      if (_pickStreamUrl(hlsUrl: hls, rawUrl: raw) == null) continue;
      ref.read(roomWsProvider(widget.roomId).notifier).sendPlayMedia(
        mediaId: item['id'].toString(),
        hlsUrl: hls,
        rawStreamUrl: raw,
        title: item['title'] as String? ?? 'Без названия',
        sourceType: item['source_type'] as String? ?? 'upload',
      );
      return;
    }
  }

  void _playNext() {
    if (!_isHost) return;
    _autoAdvanceToNext();
  }

  void _copyInviteCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).roomCodeCopied),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Fullscreen mode — just video + overlay
    if (_isFullscreen) {
      final fsController = _videoController;
      final fsWsState = ref.watch(roomWsProvider(widget.roomId));
      final fsState = _resolvePlayerUIState(fsWsState.player, fsController);
      final fsInitialized = fsState == _PlayerUIState.ready;
      final fsPlaying = fsController?.isPlaying ?? false;
      final voiceState = ref.watch(voiceChatProvider(widget.roomId));
      final isMicActive = voiceState.isActive && !voiceState.isMuted;

      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _exitFullscreen();
        },
        child: Focus(
          autofocus: true,
          onKeyEvent: _handleKey,
          child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // Video content
              Center(child: _buildFullscreenVideo()),

              // Full-screen tap zone (covers black bars too)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _toggleControls,
                ),
              ),

              // Center play/pause button
              if (fsInitialized && _showControls)
                Center(
                  child: GestureDetector(
                    onTap: _isHost ? _onPlayPause : _localTogglePlayback,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        fsPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

              // Bottom controls bar
              if (_showControls)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: EdgeInsets.only(
                      left: 16, right: 16, top: 8,
                      bottom: MediaQuery.of(context).padding.bottom + 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (fsInitialized) _buildSeekBar(fsController),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Mic
                            IconButton(
                              onPressed: _onMicTap,
                              icon: Icon(
                                isMicActive ? Icons.mic_rounded : Icons.mic_off_rounded,
                                color: isMicActive ? AppColors.success : Colors.white70,
                              ),
                            ),
                            // Speaker (mobile + voice active)
                            if (voiceState.isActive && !kIsWeb)
                              IconButton(
                                onPressed: () => ref
                                    .read(voiceChatProvider(widget.roomId).notifier)
                                    .toggleSpeaker(),
                                icon: Icon(
                                  voiceState.speakerOn
                                      ? Icons.volume_up_rounded
                                      : Icons.hearing_rounded,
                                  color: voiceState.speakerOn
                                      ? AppColors.primary
                                      : Colors.white70,
                                ),
                              ),
                            const SizedBox(width: 16),
                            // Play/pause
                            IconButton(
                              onPressed: _isHost ? _onPlayPause : _localTogglePlayback,
                              icon: Icon(
                                fsPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            // Next (host only)
                            if (_isHost)
                              IconButton(
                                onPressed: _playNext,
                                icon: const Icon(Icons.skip_next_rounded, color: Colors.white70),
                              ),
                            const SizedBox(width: 8),
                            // Volume in fullscreen
                            Icon(
                              _volume == 0 ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                              size: 18, color: Colors.white54,
                            ),
                            SizedBox(
                              width: 80,
                              child: SliderTheme(
                                data: SliderThemeData(
                                  trackHeight: 2,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                                  activeTrackColor: Colors.white70,
                                  inactiveTrackColor: Colors.white24,
                                  thumbColor: Colors.white,
                                ),
                                child: Slider(
                                  value: _volume,
                                  onChanged: (v) {
                                    setState(() => _volume = v);
                                    _videoController?.setVolume(v);
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Reactions
                            IconButton(
                              onPressed: _showReactions,
                              icon: const Icon(Icons.emoji_emotions_outlined,
                                  color: Colors.white70),
                            ),
                            // Exit fullscreen
                            IconButton(
                              onPressed: _exitFullscreen,
                              icon: const Icon(Icons.fullscreen_exit_rounded,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              // Reactions overlay
              ReactionOverlay(roomId: widget.roomId),
            ],
          ),
        ),
        ),
      );
    }

    final roomAsync = ref.watch(roomDetailProvider(widget.roomId));
    final wsState = ref.watch(roomWsProvider(widget.roomId));
    final playerState = wsState.player;
    final isWide = MediaQuery.of(context).size.width > 800;

    final l = AppLocalizations.of(context);
    final inviteCode = roomAsync.whenOrNull(
          data: (data) => data['invite_code'] as String?,
        ) ??
        '------';
    final onlineCount = wsState.onlineUsers.length;

    return Focus(
      autofocus: true,
      onKeyEvent: _handleKey,
      child: Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(
              context,
              title: playerState.title ?? l.homeRoomLabel,
              inviteCode: inviteCode,
              onlineCount: onlineCount,
            ),
            Expanded(
              child: isWide ? _buildWideLayout() : _buildNarrowLayout(),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context, {
    required String title,
    required String inviteCode,
    required int onlineCount,
  }) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 14, 8),
      child: Row(
        children: [
          InkResponse(
            onTap: () => _showLeaveDialog(context),
            radius: 22,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.hairline),
              ),
              child: const Icon(Icons.arrow_back_rounded, size: 18, color: AppColors.ink),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: AppColors.live,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.live.withValues(alpha: 0.4),
                            blurRadius: 0,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(l.roomLiveLabel,
                        style: AppTheme.mono(
                            size: 9,
                            color: AppColors.live,
                            letterSpacing: 1.6,
                            weight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    Text('· $onlineCount ${l.roomOnlineCount}',
                        style: AppTheme.mono(
                            size: 9,
                            color: AppColors.ink3,
                            letterSpacing: 1.4,
                            weight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.text(size: 14, weight: FontWeight.w600, color: AppColors.ink),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _copyInviteCode(inviteCode),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 7, 12, 7),
              decoration: BoxDecoration(
                color: AppColors.amberDim,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    inviteCode,
                    style: AppTheme.mono(
                      size: 11,
                      color: AppColors.amber,
                      letterSpacing: 2,
                      weight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.content_copy_rounded, size: 12, color: AppColors.amber),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrowLayout() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.r2),
            child: _buildVideoPlayer(),
          ),
        ),
        AnimatedCrossFade(
          firstChild: _buildControls(),
          secondChild: const SizedBox.shrink(),
          crossFadeState:
              (_showControls && !_collapseForChatKeyboard(context))
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 200),
        ),
        _buildPresenceRow(),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppTheme.r3),
                topRight: Radius.circular(AppTheme.r3),
              ),
            ),
            padding: const EdgeInsets.only(top: 14),
            child: Column(
              children: [
                _buildTabStrip(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      ChatPanel(roomId: widget.roomId),
                      ParticipantList(roomId: widget.roomId),
                      QueuePanel(roomId: widget.roomId, isHost: _isHost),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// True when the chat tab is active AND the soft keyboard is up. We
  /// use it to collapse decorative rows above the chat (seats row,
  /// voice/reactions controls) so the chat input has room without an
  /// overflow strip — those widgets are visual noise while typing.
  bool _collapseForChatKeyboard(BuildContext ctx) {
    if (_tabController.index != 0) return false;
    return MediaQuery.of(ctx).viewInsets.bottom > 0;
  }

  Widget _buildPresenceRow() {
    if (_collapseForChatKeyboard(context)) {
      return const SizedBox(height: 4);
    }
    final l = AppLocalizations.of(context);
    final wsState = ref.watch(roomWsProvider(widget.roomId));
    final roomAsync = ref.watch(roomDetailProvider(widget.roomId));
    final currentUser = ref.watch(currentUserProvider);
    final speaking = ref.watch(voiceChatProvider(widget.roomId)).speakingPeers;

    return roomAsync.maybeWhen(
      data: (roomData) {
        final members = (roomData['members'] as List?) ?? [];
        final online = wsState.onlineUsers;

        // Build the "seats" — up to 4 visible
        final seats = <_Seat>[];
        for (final m in members.take(4)) {
          final mm = m as Map<String, dynamic>;
          final user = mm['user'] as Map<String, dynamic>;
          final name = user['username'] as String? ?? '?';
          // LiveKit identity = string-form of backend user id (set in
          // LiveKitTokenView). speakingPeers contains those identities.
          final userId = user['id']?.toString() ?? '';
          final isOnline = online.containsKey(name);
          final isYou = currentUser?.username == name;
          final rawAvatar = user['avatar_url'] as String?;
          final avatarUrl = (rawAvatar != null && rawAvatar.startsWith('/'))
              ? '${ServerConfig.mediaBaseUrl}$rawAvatar'
              : rawAvatar;
          seats.add(_Seat(
            name: isYou ? '$name (ты)' : name,
            online: isOnline,
            speaking: speaking.contains(userId),
            hue: name.hashCode.abs() % 360,
            avatarUrl: avatarUrl,
          ));
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MonoLabel(
                '${l.roomPresenceLabel} · ${online.length} / ${members.length}',
                color: AppColors.ink3,
                letterSpacing: 1.8,
              ),
              const SizedBox(height: 10),
              if (seats.isEmpty)
                _emptySeats()
              else
                Row(
                  children: [
                    for (var i = 0; i < seats.length; i++) ...[
                      Expanded(child: _buildSeat(seats[i])),
                      if (i < seats.length - 1) const SizedBox(width: 10),
                    ],
                  ],
                ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _buildSeat(_Seat seat) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.r2),
        border: Border.all(
          color: seat.speaking ? AppColors.live : AppColors.hairline,
          width: seat.speaking ? 1.5 : 1,
        ),
      ),
      child: Opacity(
        opacity: seat.online ? 1 : 0.45,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            JuntoAvatar(
              name: seat.name,
              size: 36,
              hue: seat.hue,
              imageUrl: seat.avatarUrl,
            ),
            const SizedBox(height: 6),
            Text(
              seat.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.text(
                size: 11,
                weight: FontWeight.w500,
                color: seat.online ? AppColors.ink2 : AppColors.ink4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptySeats() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.r2),
        border: Border.all(color: AppColors.hairline),
      ),
      alignment: Alignment.centerLeft,
      child: Text(AppLocalizations.of(context).roomEmptySeats,
          style: AppTheme.text(size: 12, color: AppColors.ink3, weight: FontWeight.w400)),
    );
  }

  Widget _buildTabStrip() {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TabBar(
        controller: _tabController,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: AppColors.amber, width: 2),
          insets: EdgeInsets.symmetric(horizontal: 0),
        ),
        indicatorSize: TabBarIndicatorSize.label,
        indicatorPadding: const EdgeInsets.only(bottom: 0),
        dividerColor: Colors.transparent,
        labelColor: AppColors.ink,
        unselectedLabelColor: AppColors.ink3,
        labelStyle: AppTheme.text(size: 13, weight: FontWeight.w600),
        unselectedLabelStyle: AppTheme.text(size: 13, weight: FontWeight.w500),
        labelPadding: const EdgeInsets.symmetric(horizontal: 14),
        tabAlignment: TabAlignment.start,
        isScrollable: true,
        tabs: [
          Tab(text: l.roomTabChat),
          Tab(text: l.roomTabParticipants),
          Tab(text: l.roomTabQueue),
        ],
      ),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.r2),
                    child: _buildVideoPlayer(),
                  ),
                ),
              ),
              AnimatedCrossFade(
                firstChild: _buildControls(),
                secondChild: const SizedBox.shrink(),
                crossFadeState: _showControls
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                duration: const Duration(milliseconds: 200),
              ),
            ],
          ),
        ),
        Container(width: 1, color: AppColors.hairline),
        SizedBox(
          width: 360,
          child: Container(
            color: AppColors.bg,
            child: Column(
              children: [
                const SizedBox(height: 12),
                _buildTabStrip(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      ChatPanel(roomId: widget.roomId),
                      ParticipantList(roomId: widget.roomId),
                      QueuePanel(roomId: widget.roomId, isHost: _isHost),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFullscreenVideo() {
    final wsState = ref.watch(roomWsProvider(widget.roomId));
    final controller = _videoController;
    final state = _resolvePlayerUIState(wsState.player, controller);
    if (state != _PlayerUIState.ready || controller == null) {
      return const CircularProgressIndicator(color: AppColors.primary);
    }
    final w = controller.videoSize.width;
    final h = controller.videoSize.height;
    final ratio = (w > 0 && h > 0) ? w / h : 16 / 9;
    // FittedBox+AspectRatio worked for media_kit (Texture has intrinsic
    // size) but collapses HtmlElementView (no intrinsics) to zero. Center
    // + AspectRatio fills the largest aspect-correct rect inside the
    // full-screen stack, and Positioned.fill keeps the platform view
    // tied to that rect on both web and native.
    return Center(
      child: AspectRatio(
        aspectRatio: ratio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(child: controller.buildWidget()),
          ],
        ),
      ),
    );
  }

  /// Resolves which UI state the player is in.
  ///
  /// Order of precedence: ready > transcoding > loading > waiting > idle.
  /// `transcoding` requires no playable URL yet — once a URL arrives we move
  /// straight to `loading` even if backend progress is still <100.
  _PlayerUIState _resolvePlayerUIState(PlayerState ps, UnifiedVideoPlayer? c) {
    // Treat the player as ready once open() resolved, even if media_kit's
    // duration probe hasn't completed (Web HLS event playlist case).
    final ready = c != null && (c.isInitialized || _videoOpened);
    if (ready) return _PlayerUIState.ready;
    final hasUrl = _pickStreamUrl(hlsUrl: ps.hlsUrl, rawUrl: ps.rawStreamUrl) != null
        || _currentHlsUrl != null;
    if (ps.mediaProgress != null && ps.mediaProgress! < 100 && !hasUrl) {
      return _PlayerUIState.transcoding;
    }
    if (hasUrl) return _PlayerUIState.loading;
    if (ps.mediaProgress == null) return _PlayerUIState.waiting;
    return _PlayerUIState.idle;
  }

  Widget _buildVideoPlayer() {
    final wsState = ref.watch(roomWsProvider(widget.roomId));
    final playerState = wsState.player;
    final controller = _videoController;
    final state = _resolvePlayerUIState(playerState, controller);
    final isReady = state == _PlayerUIState.ready;

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Base layer: video or backdrop.
            //
            // On Web, the platform view inside controller.buildWidget() only
            // mounts a <video> tag once Flutter assigns it a real (non-zero)
            // layout box, so we hand the player the full available area
            // directly via Positioned.fill — works on both web
            // (HtmlElementView) and native (Texture).
            Positioned.fill(
              child: isReady && controller != null
                  ? controller.buildWidget()
                  : _videoBackdrop(),
            ),

            // Transparent tap zone over video (captures taps that the
            // platform view would otherwise swallow).
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _toggleControls,
              ),
            ),

            // Status indicator for non-ready states.
            _buildPlayerStatusIndicator(state, playerState),

            // Ready-only overlays.
            if (isReady && _showControls) _buildPlayPauseOverlay(controller),
            if (isReady && _showControls) _buildFullscreenButton(),
            if (isReady) _buildSeekBarOverlay(controller),

            // Reaction overlay on video.
            Positioned.fill(
              child: ReactionOverlay(roomId: widget.roomId),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _videoBackdrop() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            AppColors.surfaceLight.withValues(alpha: 0.5),
            Colors.black,
          ],
          radius: 1.2,
        ),
      ),
    );
  }

  Widget _buildPlayerStatusIndicator(_PlayerUIState state, PlayerState ps) {
    switch (state) {
      case _PlayerUIState.idle:
      case _PlayerUIState.ready:
        return const SizedBox.shrink();
      case _PlayerUIState.waiting:
        return Text(
          AppLocalizations.of(context).roomVideoWaiting,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 14,
          ),
        );
      // Transcoding spinner only when there's no playable URL for this
      // platform yet. On native we get raw_stream_url before ffmpeg even
      // starts, so the "transcoding" spinner would be background noise —
      // _resolvePlayerUIState routes those cases to `loading` instead.
      case _PlayerUIState.transcoding:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context).roomVideoProcessing(ps.mediaProgress!),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
        );
      case _PlayerUIState.loading:
        return const CircularProgressIndicator(color: AppColors.primary);
    }
  }

  Widget _buildPlayPauseOverlay(UnifiedVideoPlayer? controller) {
    final isPlaying = controller?.isPlaying ?? false;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        // ignore: avoid_print
        print('JUNTO: center play tap (host=$_isHost)');
        _restartHideTimer();
        if (_isHost) {
          _onPlayPause();
        } else {
          _localTogglePlayback();
        }
      },
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          size: 40,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildFullscreenButton() {
    return Positioned(
      top: 8,
      right: 8,
      child: GestureDetector(
        onTap: _enterFullscreen,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.fullscreen_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildSeekBarOverlay(UnifiedVideoPlayer? controller) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        ignoring: !_showControls,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _showControls ? 1.0 : 0.0,
          child: _buildSeekBar(controller),
        ),
      ),
    );
  }

  Widget _buildSeekBar(UnifiedVideoPlayer? controller) {
    double progress = 0;
    int positionSec = 0;
    int durationSec = 0;

    if (controller != null && controller.isInitialized) {
      final duration = controller.duration;
      final position = controller.position;
      progress = duration.inMilliseconds > 0
          ? position.inMilliseconds / duration.inMilliseconds
          : 0.0;
      positionSec = position.inSeconds;
      durationSec = duration.inSeconds;
    }

    final volumeIcon = _volume == 0
        ? Icons.volume_off_rounded
        : _volume < 0.5
            ? Icons.volume_down_rounded
            : Icons.volume_up_rounded;

    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withValues(alpha: 0.2),
          ),
          child: Slider(
            value: progress.clamp(0.0, 1.0),
            onChanged: _isHost ? _onSeek : null,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
          child: Row(
            children: [
              Text(
                _formatDuration(positionSec),
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              const Spacer(),
              if (durationSec > 0)
                Text(
                  _formatDuration(durationSec),
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              // Volume mute/unmute toggle
              IconButton(
                onPressed: () {
                  final v = _volume > 0 ? 0.0 : 1.0;
                  setState(() => _volume = v);
                  _videoController?.setVolume(v);
                },
                visualDensity: VisualDensity.compact,
                icon: Icon(volumeIcon, color: Colors.white70, size: 20),
              ),
              // Next track — host only
              if (_isHost)
                IconButton(
                  onPressed: _playNext,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.skip_next_rounded,
                      color: Colors.white70, size: 22),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  void _onMicTap() {
    // ignore: avoid_print
    print('JUNTO: mic tap');
    final voiceState = ref.read(voiceChatProvider(widget.roomId));
    final voiceNotifier = ref.read(voiceChatProvider(widget.roomId).notifier);

    if (!voiceState.isActive) {
      voiceNotifier.start();
    } else {
      voiceNotifier.toggleMute();
    }
  }

  Widget _buildControls() {
    // Room-side controls only: voice/speaker/reactions. Video transport
    // controls (play/pause/next/seek/volume) live INSIDE the player overlay
    // so the bar stays uncluttered on narrow phones.
    final l = AppLocalizations.of(context);
    final voiceState = ref.watch(voiceChatProvider(widget.roomId));
    final isMicActive = voiceState.isActive && !voiceState.isMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Mic toggle (long-press to fully leave the voice room)
          _ControlButton(
            icon: isMicActive ? Icons.mic_rounded : Icons.mic_off_rounded,
            label: voiceState.isActive
                ? (voiceState.isMuted ? l.roomMicEnableLabel : l.roomMicActiveLabel)
                : l.roomMicLabel,
            isActive: isMicActive,
            activeColor: AppColors.success,
            onTap: _onMicTap,
            onLongPress: voiceState.isActive
                ? () => ref
                    .read(voiceChatProvider(widget.roomId).notifier)
                    .stop()
                : null,
            isPrimary: true,
          ),

          // Speaker toggle — only when voice is active and on mobile
          if (voiceState.isActive && !kIsWeb) ...[
            const SizedBox(width: 18),
            _ControlButton(
              icon: voiceState.speakerOn
                  ? Icons.volume_up_rounded
                  : Icons.hearing_rounded,
              label: voiceState.speakerOn ? l.roomSpeakerLabel : l.roomSpeakerAltLabel,
              isActive: voiceState.speakerOn,
              activeColor: AppColors.primary,
              onTap: () => ref
                  .read(voiceChatProvider(widget.roomId).notifier)
                  .toggleSpeaker(),
            ),
          ],
          const SizedBox(width: 18),

          // Reactions
          _ControlButton(
            icon: Icons.emoji_emotions_outlined,
            label: l.roomReactionsLabel,
            isActive: false,
            activeColor: AppColors.warning,
            onTap: _showReactions,
          ),
        ],
      ),
    );
  }

  void _showLeaveDialog(BuildContext context) {
    final l = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l.roomLeaveTitle),
        content: Text(l.roomLeaveMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.roomLeaveCancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/home');
            },
            child: Text(
              l.roomLeaveConfirm,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showReactions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).roomReactionsTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: ['😂', '❤️', '🔥', '👏', '😮', '😢', '🎉', '💯']
                  .map((emoji) => GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          ref
                              .read(roomWsProvider(widget.roomId).notifier)
                              .sendReaction(emoji);
                        },
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.center,
                          child:
                              Text(emoji, style: const TextStyle(fontSize: 28)),
                        ),
                      ))
                  .toList(),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _Seat {
  final String name;
  final bool online;
  final bool speaking;
  final int hue;
  final String? avatarUrl;
  const _Seat({
    required this.name,
    required this.online,
    required this.speaking,
    required this.hue,
    this.avatarUrl,
  });
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isPrimary;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    this.onTap,
    this.onLongPress,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Default deferToChild only registers taps on the icon's pixels;
      // opaque makes the whole label+icon column a hit target.
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isPrimary ? 56 : 48,
            height: isPrimary ? 56 : 48,
            decoration: BoxDecoration(
              color: isActive
                  ? activeColor.withValues(alpha: 0.15)
                  : AppColors.surfaceLight,
              shape: BoxShape.circle,
              border: isActive
                  ? Border.all(color: activeColor.withValues(alpha: 0.4))
                  : null,
            ),
            child: Icon(
              icon,
              color: onTap != null
                  ? (isActive ? activeColor : AppColors.textSecondary)
                  : AppColors.textHint,
              size: isPrimary ? 28 : 22,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: onTap != null
                  ? (isActive ? activeColor : AppColors.textSecondary)
                  : AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}
