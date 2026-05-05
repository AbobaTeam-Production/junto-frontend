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
  /// Server-side ms epoch when the host issued this state. Used together
  /// with [clockSyncProvider] to compute the expected current position.
  final int? serverTsMs;
  /// Transcoded HLS playlist — required for browsers, optional for native.
  final String? hlsUrl;
  /// Direct stream URL (e.g. torrserver). Native libmpv plays any container
  /// from this directly; browsers can't.
  final String? rawStreamUrl;
  final String? youtubeVideoId;
  final String? sourceType; // 'upload', 'youtube'
  final String? title;
  final int? mediaProgress; // transcoding progress 0-100
  final String? mediaId;

  const PlayerState({
    this.status = 'idle',
    this.position = 0,
    this.timestamp,
    this.serverTsMs,
    this.hlsUrl,
    this.rawStreamUrl,
    this.youtubeVideoId,
    this.sourceType,
    this.title,
    this.mediaProgress,
    this.mediaId,
  });

  PlayerState copyWith({
    String? status,
    double? position,
    DateTime? timestamp,
    int? serverTsMs,
    String? hlsUrl,
    String? rawStreamUrl,
    String? youtubeVideoId,
    String? sourceType,
    String? title,
    int? mediaProgress,
    String? mediaId,
  }) {
    return PlayerState(
      status: status ?? this.status,
      position: position ?? this.position,
      timestamp: timestamp ?? this.timestamp,
      serverTsMs: serverTsMs ?? this.serverTsMs,
      hlsUrl: hlsUrl ?? this.hlsUrl,
      rawStreamUrl: rawStreamUrl ?? this.rawStreamUrl,
      youtubeVideoId: youtubeVideoId ?? this.youtubeVideoId,
      sourceType: sourceType ?? this.sourceType,
      title: title ?? this.title,
      mediaProgress: mediaProgress ?? this.mediaProgress,
      mediaId: mediaId ?? this.mediaId,
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

  RoomWsNotifier({
    required this.roomId,
    required TokenService tokenService,
  })  : _tokenService = tokenService,
        super(const RoomWsState()) {
    _connect();
  }

  void _connect() {
    final token = _tokenService.accessToken;
    if (token == null) {
      // ignore: avoid_print
      print('JUNTO: room WS skip connect — no access token');
      return;
    }

    final uri = Uri.parse(
        '${ServerConfig.wsBaseUrl}/ws/room/$roomId/?token=$token');
    // ignore: avoid_print
    print('JUNTO: room WS connect → ${uri.toString().replaceFirst(RegExp(r'token=[^&]+'), 'token=…')}');

    _channel = WebSocketChannel.connect(uri);
    state = state.copyWith(connected: true);

    _subscription = _channel!.stream.listen(
      (data) {
        final event = jsonDecode(data as String) as Map<String, dynamic>;
        // ignore: avoid_print
        print('JUNTO: room WS recv: ${event['event']}');
        _handleEvent(event);
      },
      onDone: () {
        // ignore: avoid_print
        print('JUNTO: room WS closed (close=${_channel?.closeCode}, reason=${_channel?.closeReason})');
        state = state.copyWith(connected: false);
      },
      onError: (e) {
        // ignore: avoid_print
        print('JUNTO: room WS error: $e');
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
            serverTsMs: (event['server_ts'] as num?)?.toInt(),
          ),
        );

      case 'pause':
        state = state.copyWith(
          player: state.player.copyWith(
            status: 'pause',
            position: (event['position'] as num?)?.toDouble() ?? 0,
            timestamp: _parseTimestamp(event['timestamp']),
            serverTsMs: (event['server_ts'] as num?)?.toInt(),
          ),
        );

      case 'seek':
        state = state.copyWith(
          player: state.player.copyWith(
            position: (event['position'] as num?)?.toDouble() ?? 0,
            timestamp: _parseTimestamp(event['timestamp']),
            serverTsMs: (event['server_ts'] as num?)?.toInt(),
          ),
        );

      case 'state_sync':
        state = state.copyWith(
          player: state.player.copyWith(
            status: event['status'] as String? ?? 'pause',
            position: (event['position'] as num?)?.toDouble() ?? 0,
            timestamp: _parseTimestamp(event['timestamp']),
            serverTsMs: (event['server_ts'] as num?)?.toInt(),
          ),
        );

      case 'online_users':
        // Backend sends {userId: username}, frontend stores {username: userId}
        final usersRaw = event['users'] as Map<String, dynamic>? ?? {};
        final users = <String, String>{};
        for (final entry in usersRaw.entries) {
          users[entry.value.toString()] = entry.key;
        }
        state = state.copyWith(onlineUsers: users);

      case 'media_ready':
        // Hybrid streaming: torrents broadcast media_ready twice — first with
        // raw_stream_url only (native can play), then again with hls_url
        // populated once transcoding is done (web can play).
        // Always merge whichever URL fields are non-empty without nuking
        // existing ones, so a Web client stays "waiting" until HLS arrives.
        final newHls = _nonEmpty(event['hls_url']);
        final newRaw = _nonEmpty(event['raw_stream_url']);
        final newYt = _nonEmpty(event['youtube_video_id']);
        final hasAnyExisting = state.player.hlsUrl != null ||
            state.player.rawStreamUrl != null ||
            state.player.youtubeVideoId != null;
        // Preserve whatever's already there; merge in new non-empty fields.
        state = state.copyWith(
          player: state.player.copyWith(
            hlsUrl: newHls ?? state.player.hlsUrl,
            rawStreamUrl: newRaw ?? state.player.rawStreamUrl,
            youtubeVideoId: newYt ?? state.player.youtubeVideoId,
            sourceType: hasAnyExisting
                ? state.player.sourceType
                : (event['source_type'] as String? ?? 'upload'),
            title: hasAnyExisting
                ? state.player.title
                : (event['title'] as String?),
            mediaProgress: 100,
            mediaId: hasAnyExisting
                ? state.player.mediaId
                : (event['media_id'] as String?),
          ),
        );

      case 'play_media':
        state = state.copyWith(
          player: PlayerState(
            status: 'pause',
            position: 0,
            hlsUrl: _nonEmpty(event['hls_url']),
            rawStreamUrl: _nonEmpty(event['raw_stream_url']),
            sourceType: event['source_type'] as String? ?? 'upload',
            title: event['title'] as String?,
            mediaId: event['media_id'] as String?,
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
    }
  }

  void sendChat(String text) {
    // ignore: avoid_print
    print('JUNTO: room WS send chat (channel=${_channel != null}, connected=${state.connected})');
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

  void sendPlayMedia({
    required String mediaId,
    required String hlsUrl,
    String rawStreamUrl = '',
    required String title,
    String sourceType = 'upload',
  }) {
    _channel?.sink.add(jsonEncode({
      'event': 'play_media',
      'media_id': mediaId,
      'hls_url': hlsUrl,
      'raw_stream_url': rawStreamUrl,
      'title': title,
      'source_type': sourceType,
    }));
  }

  String? _nonEmpty(dynamic v) {
    if (v is String && v.isNotEmpty) return v;
    return null;
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
