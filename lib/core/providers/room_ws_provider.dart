import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../api/api_client.dart';
import '../api/server_config.dart';

class ChatMessage {
  final String username;
  final String text;
  final String time;

  const ChatMessage({
    required this.username,
    required this.text,
    required this.time,
  });
}

class PlayerState {
  final String status; // 'idle', 'play', 'pause'
  final double position; // seconds
  final DateTime? timestamp;
  final String? hlsUrl;
  final String? youtubeVideoId;
  final String? sourceType; // 'upload', 'youtube'
  final String? title;
  final int? mediaProgress; // transcoding progress 0-100

  const PlayerState({
    this.status = 'idle',
    this.position = 0,
    this.timestamp,
    this.hlsUrl,
    this.youtubeVideoId,
    this.sourceType,
    this.title,
    this.mediaProgress,
  });

  PlayerState copyWith({
    String? status,
    double? position,
    DateTime? timestamp,
    String? hlsUrl,
    String? youtubeVideoId,
    String? sourceType,
    String? title,
    int? mediaProgress,
  }) {
    return PlayerState(
      status: status ?? this.status,
      position: position ?? this.position,
      timestamp: timestamp ?? this.timestamp,
      hlsUrl: hlsUrl ?? this.hlsUrl,
      youtubeVideoId: youtubeVideoId ?? this.youtubeVideoId,
      sourceType: sourceType ?? this.sourceType,
      title: title ?? this.title,
      mediaProgress: mediaProgress ?? this.mediaProgress,
    );
  }
}

class ReactionEvent {
  final String username;
  final String emoji;
  final int id; // unique per event so identical reactions are distinguishable

  const ReactionEvent({required this.username, required this.emoji, required this.id});
}

int _reactionCounter = 0;

class RoomWsState {
  final bool connected;
  final List<ChatMessage> messages;
  final Map<String, String> onlineUsers; // username -> userId
  final PlayerState player;
  final ReactionEvent? lastReaction;

  const RoomWsState({
    this.connected = false,
    this.messages = const [],
    this.onlineUsers = const {},
    this.player = const PlayerState(),
    this.lastReaction,
  });

  RoomWsState copyWith({
    bool? connected,
    List<ChatMessage>? messages,
    Map<String, String>? onlineUsers,
    PlayerState? player,
    ReactionEvent? lastReaction,
  }) {
    return RoomWsState(
      connected: connected ?? this.connected,
      messages: messages ?? this.messages,
      onlineUsers: onlineUsers ?? this.onlineUsers,
      player: player ?? this.player,
      lastReaction: lastReaction ?? this.lastReaction,
    );
  }
}

class RoomWsNotifier extends StateNotifier<RoomWsState> {
  final String roomId;
  final TokenService _tokenService;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  /// Callback for WebRTC signaling events (offer/answer/ice_candidate)
  void Function(Map<String, dynamic>)? onWebRtcSignal;

  RoomWsNotifier({
    required this.roomId,
    required TokenService tokenService,
  })  : _tokenService = tokenService,
        super(const RoomWsState()) {
    _connect();
  }

  void _connect() {
    final token = _tokenService.accessToken;
    if (token == null) return;

    final uri = Uri.parse(
        '${ServerConfig.wsBaseUrl}/ws/room/$roomId/?token=$token');

    _channel = WebSocketChannel.connect(uri);
    state = state.copyWith(connected: true);

    _subscription = _channel!.stream.listen(
      (data) {
        final event = jsonDecode(data as String) as Map<String, dynamic>;
        _handleEvent(event);
      },
      onDone: () {
        state = state.copyWith(connected: false);
      },
      onError: (_) {
        state = state.copyWith(connected: false);
      },
    );
  }

  void _handleEvent(Map<String, dynamic> event) {
    final type = event['event'] as String?;

    switch (type) {
      case 'chat':
        final msg = ChatMessage(
          username: event['username'] as String? ?? '',
          text: event['text'] as String? ?? '',
          time: _nowTime(),
        );
        state = state.copyWith(messages: [...state.messages, msg]);

      case 'user_joined':
        final name = event['username'] as String? ?? '';
        final userId = event['user_id'] as String? ?? '';
        state = state.copyWith(
          onlineUsers: {...state.onlineUsers, name: userId},
        );

      case 'user_left':
        final name = event['username'] as String? ?? '';
        final users = {...state.onlineUsers}..remove(name);
        state = state.copyWith(onlineUsers: users);

      case 'play':
        state = state.copyWith(
          player: state.player.copyWith(
            status: 'play',
            position: (event['position'] as num?)?.toDouble() ?? 0,
            timestamp: _parseTimestamp(event['timestamp']),
          ),
        );

      case 'pause':
        state = state.copyWith(
          player: state.player.copyWith(
            status: 'pause',
            position: (event['position'] as num?)?.toDouble() ?? 0,
            timestamp: _parseTimestamp(event['timestamp']),
          ),
        );

      case 'seek':
        state = state.copyWith(
          player: state.player.copyWith(
            position: (event['position'] as num?)?.toDouble() ?? 0,
            timestamp: _parseTimestamp(event['timestamp']),
          ),
        );

      case 'state_sync':
        state = state.copyWith(
          player: state.player.copyWith(
            status: event['status'] as String? ?? 'pause',
            position: (event['position'] as num?)?.toDouble() ?? 0,
            timestamp: _parseTimestamp(event['timestamp']),
          ),
        );

      case 'media_ready':
        state = state.copyWith(
          player: state.player.copyWith(
            hlsUrl: event['hls_url'] as String?,
            youtubeVideoId: event['youtube_video_id'] as String?,
            sourceType: event['source_type'] as String? ?? 'upload',
            title: event['title'] as String?,
            mediaProgress: 100,
          ),
        );

      case 'media_progress':
        state = state.copyWith(
          player: state.player.copyWith(
            mediaProgress: event['progress'] as int?,
          ),
        );

      case 'reaction':
        state = state.copyWith(
          lastReaction: ReactionEvent(
            username: event['username'] as String? ?? '',
            emoji: event['emoji'] as String? ?? '',
            id: ++_reactionCounter,
          ),
        );

      case 'webrtc_offer':
      case 'webrtc_answer':
      case 'ice_candidate':
        onWebRtcSignal?.call(event);
    }
  }

  void sendChat(String text) {
    _channel?.sink.add(jsonEncode({
      'event': 'chat',
      'text': text,
    }));
  }

  void sendReaction(String emoji) {
    _channel?.sink.add(jsonEncode({
      'event': 'reaction',
      'emoji': emoji,
    }));
  }

  void sendPlay(double position) {
    _channel?.sink.add(jsonEncode({
      'event': 'play',
      'position': position,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    }));
  }

  void sendPause(double position) {
    _channel?.sink.add(jsonEncode({
      'event': 'pause',
      'position': position,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    }));
  }

  void sendSeek(double position) {
    _channel?.sink.add(jsonEncode({
      'event': 'seek',
      'position': position,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    }));
  }

  // ─── WebRTC signaling ────────────────────────────

  void sendWebRtcOffer(String targetUserId, Map<String, dynamic> sdp) {
    _channel?.sink.add(jsonEncode({
      'event': 'webrtc_offer',
      'target': targetUserId,
      'sdp': sdp,
    }));
  }

  void sendWebRtcAnswer(String targetUserId, Map<String, dynamic> sdp) {
    _channel?.sink.add(jsonEncode({
      'event': 'webrtc_answer',
      'target': targetUserId,
      'sdp': sdp,
    }));
  }

  void sendIceCandidate(String targetUserId, Map<String, dynamic> candidate) {
    _channel?.sink.add(jsonEncode({
      'event': 'ice_candidate',
      'target': targetUserId,
      'candidate': candidate,
    }));
  }

  DateTime? _parseTimestamp(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  String _nowTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _channel?.sink.close();
    super.dispose();
  }
}

final roomWsProvider = StateNotifierProvider.autoDispose
    .family<RoomWsNotifier, RoomWsState, String>((ref, roomId) {
  final tokenService = ref.watch(tokenServiceProvider);
  return RoomWsNotifier(roomId: roomId, tokenService: tokenService);
});
