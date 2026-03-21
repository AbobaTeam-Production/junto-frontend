import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/api/server_config.dart';
import '../../../core/providers/room_ws_provider.dart';
import '../../../core/providers/voice_chat_provider.dart';
import '../../rooms/providers/room_providers.dart';
import '../widgets/chat_panel.dart';
import '../widgets/participant_list.dart';
import '../widgets/reaction_overlay.dart';

class RoomScreen extends ConsumerStatefulWidget {
  final String roomId;

  const RoomScreen({super.key, required this.roomId});

  @override
  ConsumerState<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends ConsumerState<RoomScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final TabController _tabController;
  VideoPlayerController? _videoController;
  String? _currentHlsUrl;
  bool _isHost = false;
  bool _showControls = true;
  bool _videoEnded = false;
  bool _isFullscreen = false;
  bool _orientationFullscreen = false;
  Timer? _hideControlsTimer;
  PlayerState? _lastAppliedPlayerState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 2, vsync: this);

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

            // Check if media is already ready from API
            if (_currentHlsUrl == null) {
              final mediaList = data['media'] as List?;
              if (mediaList != null && mediaList.isNotEmpty) {
                final media = mediaList.first as Map<String, dynamic>;
                if (media['status'] == 'ready') {
                  final hlsUrl = media['hls_url'] as String?;
                  if (hlsUrl != null) _initVideo(hlsUrl);
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

      // Listen for user join/leave to manage voice chat peer connections
      ref.listenManual(
        roomWsProvider(widget.roomId).select((s) => s.onlineUsers),
        (previous, next) {
          if (previous == null) return;
          final voiceNotifier =
              ref.read(voiceChatProvider(widget.roomId).notifier);
          // New users
          for (final userId in next.values) {
            if (!previous.values.contains(userId)) {
              voiceNotifier.onUserJoined(userId);
            }
          }
          // Left users
          for (final userId in previous.values) {
            if (!next.values.contains(userId)) {
              voiceNotifier.onUserLeft(userId);
            }
          }
        },
      );

      // Listen for media_ready and player sync events from WebSocket
      ref.listenManual(
        roomWsProvider(widget.roomId).select((s) => s.player),
        (previous, next) {
          // Init video when media arrives via WS
          if (_currentHlsUrl == null && next.hlsUrl != null) {
            _initVideo(next.hlsUrl!);
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
    setState(() {
      _isFullscreen = true;
      _orientationFullscreen = fromOrientation;
    });
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    if (!fromOrientation) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  void _exitFullscreen() {
    setState(() {
      _isFullscreen = false;
      _orientationFullscreen = false;
    });
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([]);
  }

  void _initVideo(String hlsUrl) {
    if (_currentHlsUrl == hlsUrl) return;
    _createController(hlsUrl);
  }

  void _createController(String hlsUrl, {Duration startAt = Duration.zero, bool autoPlay = false}) {
    _currentHlsUrl = hlsUrl;
    _videoEnded = false;

    final fullUrl = hlsUrl.startsWith('http')
        ? hlsUrl
        : '${ServerConfig.mediaBaseUrl}$hlsUrl';

    _videoController?.dispose();
    final controller = VideoPlayerController.networkUrl(Uri.parse(fullUrl));
    _videoController = controller;

    if (mounted) setState(() {});

    controller.initialize().then((_) {
      if (!mounted) return;
      if (startAt > Duration.zero) controller.seekTo(startAt);
      if (autoPlay) controller.play();
      setState(() {});
    }).catchError((e) {
      debugPrint('Video init error: $e');
    });

    controller.addListener(() {
      if (!mounted) return;
      setState(() {});
      // Detect video end reliably via listener
      final v = controller.value;
      if (v.isInitialized &&
          !v.isPlaying &&
          v.duration > Duration.zero &&
          v.position.inMilliseconds >= v.duration.inMilliseconds - 300) {
        _videoEnded = true;
      }
    });
  }

  void _onPlayPause() {
    if (!_isHost) return;
    final wsNotifier = ref.read(roomWsProvider(widget.roomId).notifier);

    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) return;

    if (controller.value.isPlaying) {
      final position = controller.value.position.inMilliseconds / 1000.0;
      controller.pause();
      wsNotifier.sendPause(position);
    } else if (_videoEnded) {
      _createController(_currentHlsUrl!, autoPlay: true);
      late void Function() onReady;
      onReady = () {
        if (_videoController?.value.isPlaying ?? false) {
          wsNotifier.sendPlay(0);
          _videoController?.removeListener(onReady);
        }
      };
      _videoController?.addListener(onReady);
    } else {
      final position = controller.value.position.inMilliseconds / 1000.0;
      controller.play();
      wsNotifier.sendPlay(position);
    }
  }

  void _onSeek(double value) {
    if (!_isHost) return;
    final wsNotifier = ref.read(roomWsProvider(widget.roomId).notifier);

    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) return;

    final duration = controller.value.duration;
    final position = duration * value;
    final positionSec = position.inMilliseconds / 1000.0;

    if (_videoEnded) {
      _createController(_currentHlsUrl!, startAt: position, autoPlay: true);
      late void Function() onReady;
      onReady = () {
        if (_videoController?.value.isPlaying ?? false) {
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

  void _applyPlayerSync(PlayerState playerState) {
    if (_isHost) return;
    final targetSec = playerState.position;

    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) return;

    final targetPos = Duration(milliseconds: (targetSec * 1000).toInt());
    if (playerState.timestamp != null) {
      final delay = DateTime.now().toUtc().difference(playerState.timestamp!);
      controller.seekTo(targetPos + delay);
    } else {
      controller.seekTo(targetPos);
    }

    if (playerState.status == 'play' && !controller.value.isPlaying) {
      controller.play();
    } else if (playerState.status == 'pause' && controller.value.isPlaying) {
      controller.pause();
    }
  }

  void _copyInviteCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Код скопирован'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Fullscreen mode — just video + overlay
    if (_isFullscreen) {
      final fsController = _videoController;
      final fsInitialized = fsController != null && fsController.value.isInitialized;
      final fsPlaying = fsController?.value.isPlaying ?? false;
      final voiceState = ref.watch(voiceChatProvider(widget.roomId));
      final isMicActive = voiceState.isActive && !voiceState.isMuted;

      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _exitFullscreen();
        },
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
                    onTap: _isHost ? _onPlayPause : null,
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
                              onPressed: _isHost ? _onPlayPause : null,
                              icon: Icon(
                                fsPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
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
      );
    }

    final roomAsync = ref.watch(roomDetailProvider(widget.roomId));
    final wsState = ref.watch(roomWsProvider(widget.roomId));
    final playerState = wsState.player;
    final isWide = MediaQuery.of(context).size.width > 800;

    final inviteCode = roomAsync.whenOrNull(
          data: (data) => data['invite_code'] as String?,
        ) ??
        '------';
    final memberCount = roomAsync.whenOrNull(
          data: (data) => data['member_count'] as int?,
        ) ??
        0;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => _showLeaveDialog(context),
        ),
        title: Text(playerState.title ?? 'Комната'),
        actions: [
          // Invite code chip
          GestureDetector(
            onTap: () => _copyInviteCode(inviteCode),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.copy_rounded,
                      size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    inviteCode,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Participants count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people_outline,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '$memberCount',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: isWide ? _buildWideLayout() : _buildNarrowLayout(),
    );
  }

  Widget _buildNarrowLayout() {
    return Column(
      children: [
        _buildVideoPlayer(),
        AnimatedCrossFade(
          firstChild: _buildControls(),
          secondChild: const SizedBox.shrink(),
          crossFadeState: _showControls
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 200),
        ),
        Container(
          color: AppColors.surface,
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primary,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textSecondary,
            dividerColor: AppColors.divider,
            tabs: const [
              Tab(text: 'Чат'),
              Tab(text: 'Участники'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              ChatPanel(roomId: widget.roomId),
              ParticipantList(roomId: widget.roomId),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            children: [
              Expanded(child: _buildVideoPlayer()),
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
        Container(width: 1, color: AppColors.divider),
        SizedBox(
          width: 360,
          child: Column(
            children: [
              Container(
                color: AppColors.surface,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primary,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelColor: AppColors.textPrimary,
                  unselectedLabelColor: AppColors.textSecondary,
                  dividerColor: AppColors.divider,
                  tabs: const [
                    Tab(text: 'Чат'),
                    Tab(text: 'Участники'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    ChatPanel(roomId: widget.roomId),
                    ParticipantList(roomId: widget.roomId),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFullscreenVideo() {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) {
      return const CircularProgressIndicator(color: AppColors.primary);
    }
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    final wsState = ref.watch(roomWsProvider(widget.roomId));
    final playerState = wsState.player;
    final controller = _videoController;
    final isInitialized = controller != null && controller.value.isInitialized;
    final isPlaying = controller?.value.isPlaying ?? false;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleControls,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.black,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Video or placeholder
              if (isInitialized)
                SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: controller.value.size.width,
                      height: controller.value.size.height,
                      child: VideoPlayer(controller),
                    ),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        AppColors.surfaceLight.withValues(alpha: 0.5),
                        Colors.black,
                      ],
                      radius: 1.2,
                    ),
                  ),
                ),

              // Transcoding progress
              if (!isInitialized && playerState.mediaProgress != null && playerState.mediaProgress! < 100)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: AppColors.primary),
                    const SizedBox(height: 12),
                    Text(
                      'Обработка видео: ${playerState.mediaProgress}%',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),

              // Waiting for content
              if (!isInitialized && playerState.hlsUrl == null && _currentHlsUrl == null && playerState.mediaProgress == null)
                Text(
                  'Ожидание контента...',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                ),

              // Loading spinner when media URL set but not yet initialized
              if (!isInitialized && (playerState.hlsUrl != null || _currentHlsUrl != null) && (playerState.mediaProgress == null || playerState.mediaProgress == 100))
                const CircularProgressIndicator(color: AppColors.primary),

              // Play/pause overlay
              if (isInitialized && _showControls)
                GestureDetector(
                  onTap: _isHost ? () { _onPlayPause(); _restartHideTimer(); } : null,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),

            // Fullscreen button (top-right)
            if (isInitialized && _showControls)
              Positioned(
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
              ),

            // Progress bar
            if (isInitialized)
              Positioned(
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
              ),

            // Reaction overlay on video
            Positioned.fill(
              child: ReactionOverlay(roomId: widget.roomId),
            ),
          ],
        ),
      ),
    )).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildSeekBar(VideoPlayerController? controller) {
    double progress = 0;
    int positionSec = 0;
    int durationSec = 0;

    if (controller != null && controller.value.isInitialized) {
      final duration = controller.value.duration;
      final position = controller.value.position;
      progress = duration.inMilliseconds > 0
          ? position.inMilliseconds / duration.inMilliseconds
          : 0.0;
      positionSec = position.inSeconds;
      durationSec = duration.inSeconds;
    }

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
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(positionSec),
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              if (durationSec > 0)
                Text(
                  _formatDuration(durationSec),
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  void _onMicTap() {
    final voiceState = ref.read(voiceChatProvider(widget.roomId));
    final voiceNotifier = ref.read(voiceChatProvider(widget.roomId).notifier);

    if (!voiceState.isActive) {
      voiceNotifier.start();
    } else {
      voiceNotifier.toggleMute();
    }
  }

  Widget _buildControls() {
    final controller = _videoController;
    final isPlaying = controller?.value.isPlaying ?? false;
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
          // Mic toggle (tap = start/mute, long press = disconnect)
          _ControlButton(
            icon: isMicActive ? Icons.mic_rounded : Icons.mic_off_rounded,
            label: voiceState.isActive
                ? (voiceState.isMuted ? 'Вкл. микрофон' : 'Микрофон')
                : 'Голос. чат',
            isActive: isMicActive,
            activeColor: AppColors.success,
            onTap: _onMicTap,
            onLongPress: voiceState.isActive
                ? () => ref
                    .read(voiceChatProvider(widget.roomId).notifier)
                    .stop()
                : null,
          ),

          // Speaker toggle (mobile only, visible when voice active)
          if (voiceState.isActive && !kIsWeb) ...[
            const SizedBox(width: 12),
            _ControlButton(
              icon: voiceState.speakerOn
                  ? Icons.volume_up_rounded
                  : Icons.hearing_rounded,
              label: voiceState.speakerOn ? 'Динамик' : 'Разговорный',
              isActive: voiceState.speakerOn,
              activeColor: AppColors.primary,
              onTap: () => ref
                  .read(voiceChatProvider(widget.roomId).notifier)
                  .toggleSpeaker(),
            ),
          ],
          const SizedBox(width: 12),

          // Play/pause (host only)
          _ControlButton(
            icon: isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            label: isPlaying ? 'Пауза' : 'Играть',
            isActive: isPlaying,
            activeColor: AppColors.primary,
            onTap: _isHost ? _onPlayPause : null,
            isPrimary: true,
          ),
          const SizedBox(width: 16),

          // Reactions
          _ControlButton(
            icon: Icons.emoji_emotions_outlined,
            label: 'Реакция',
            isActive: false,
            activeColor: AppColors.warning,
            onTap: _showReactions,
          ),
        ],
      ),
    );
  }

  void _showLeaveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Покинуть комнату?'),
        content: const Text('Вы уверены, что хотите выйти из комнаты?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Остаться'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/home');
            },
            child: const Text(
              'Выйти',
              style: TextStyle(color: AppColors.error),
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
              'Реакции',
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
