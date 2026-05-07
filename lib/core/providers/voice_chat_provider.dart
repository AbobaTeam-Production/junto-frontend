import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:permission_handler/permission_handler.dart';

import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import 'settings_provider.dart';

class VoiceChatState {
  final bool isActive;
  final bool isMuted;
  final bool speakerOn;
  final Set<String> activePeers; // LiveKit identities — equal to backend user IDs
  /// Subset of activePeers (plus optionally local identity) that are
  /// currently speaking, per LiveKit's ActiveSpeakersChangedEvent.
  final Set<String> speakingPeers;

  const VoiceChatState({
    this.isActive = false,
    this.isMuted = false,
    this.speakerOn = false,
    this.activePeers = const {},
    this.speakingPeers = const {},
  });

  VoiceChatState copyWith({
    bool? isActive,
    bool? isMuted,
    bool? speakerOn,
    Set<String>? activePeers,
    Set<String>? speakingPeers,
  }) {
    return VoiceChatState(
      isActive: isActive ?? this.isActive,
      isMuted: isMuted ?? this.isMuted,
      speakerOn: speakerOn ?? this.speakerOn,
      activePeers: activePeers ?? this.activePeers,
      speakingPeers: speakingPeers ?? this.speakingPeers,
    );
  }
}

class VoiceChatNotifier extends StateNotifier<VoiceChatState> {
  final String roomId;
  final Ref _ref;

  lk.Room? _room;
  lk.EventsListener<lk.RoomEvent>? _listener;
  bool _starting = false;

  VoiceChatNotifier({required this.roomId, required Ref ref})
      : _ref = ref,
        super(const VoiceChatState());

  /// Build capture options that honour the user's saved mic-device pick
  /// (`settingsProvider.micDeviceId`). Empty string = OS default.
  lk.AudioCaptureOptions _buildAudioCaptureOptions() {
    final id = _ref.read(settingsProvider).micDeviceId;
    return lk.AudioCaptureOptions(
      deviceId: id.isEmpty ? null : id,
      echoCancellation: true,
      noiseSuppression: true,
      autoGainControl: true,
      highPassFilter: true,
    );
  }

  Future<void> start() async {
    if (state.isActive || _starting) return;
    _starting = true;

    // ignore: avoid_print
    print('JUNTO: voice.start() begin');

    // Native: ask for RECORD_AUDIO before LiveKit tries to capture. The
    // plugin doesn't surface a system prompt itself, so without this the
    // first start() on a fresh install silently fails with a denied mic.
    // On Web getUserMedia handles its own prompt, so we skip there.
    if (!kIsWeb) {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        // ignore: avoid_print
        print('JUNTO: voice.start() mic permission denied: $status');
        _starting = false;
        return;
      }
    }

    // Force-register connectivity_plus before LiveKit transitively touches
    // it. dart2js tree-shaker drops the plugin from the bundle on Web if
    // our app code doesn't reference it directly, even though
    // .flutter-plugins-dependencies declares it. Without this call we get
    // MissingPluginException(... dev.fluttercommunity.plus/connectivity).
    if (kIsWeb) {
      try {
        await Connectivity().checkConnectivity();
      } catch (_) {
        // safe to ignore — only used to keep the plugin alive in the bundle
      }
    }

    final dio = _ref.read(dioProvider);

    final String wsUrl;
    final String token;
    try {
      final resp = await dio.get(ApiEndpoints.roomLivekitToken(roomId));
      wsUrl = resp.data['url'] as String;
      token = resp.data['token'] as String;
      // ignore: avoid_print
      print('JUNTO: voice.start() got token, ws=$wsUrl');
    } catch (e) {
      // ignore: avoid_print
      print('JUNTO: voice.start() token fetch FAIL: $e');
      _starting = false;
      return;
    }

    final captureOpts = _buildAudioCaptureOptions();
    final room = lk.Room(
      roomOptions: lk.RoomOptions(
        adaptiveStream: false,
        dynacast: false,
        defaultAudioCaptureOptions: captureOpts,
      ),
    );
    _room = room;
    _listener = room.createListener();
    _wireEvents(_listener!);

    try {
      await room.connect(wsUrl, token);
      // ignore: avoid_print
      print('JUNTO: voice.start() connected to LiveKit');
      await room.localParticipant?.setMicrophoneEnabled(
        true,
        audioCaptureOptions: captureOpts,
      );
      // ignore: avoid_print
      print('JUNTO: voice.start() mic enabled');
    } catch (e, st) {
      // ignore: avoid_print
      print('JUNTO: voice.start() connect/mic FAIL: $e\n$st');
      await _teardown();
      _starting = false;
      return;
    }

    if (!mounted) {
      await _teardown();
      _starting = false;
      return;
    }

    final peers = room.remoteParticipants.values
        .map((p) => p.identity)
        .toSet();
    state = state.copyWith(
      isActive: true,
      isMuted: false,
      activePeers: peers,
    );
    _starting = false;
  }

  Future<void> stop() async {
    if (!state.isActive && _room == null) return;
    await _teardown();
    if (mounted) state = const VoiceChatState();
  }

  Future<void> toggleMute() async {
    final lp = _room?.localParticipant;
    if (lp == null) return;
    final next = !state.isMuted;
    await lp.setMicrophoneEnabled(!next,
        audioCaptureOptions: _buildAudioCaptureOptions());
    if (mounted) state = state.copyWith(isMuted: next);
  }

  /// Toggle earpiece (default) / loudspeaker on Android. No-op on Web/Desktop.
  Future<void> toggleSpeaker() async {
    if (kIsWeb) return;
    final on = !state.speakerOn;
    try {
      await lk.Hardware.instance.setSpeakerphoneOn(on);
      if (mounted) state = state.copyWith(speakerOn: on);
    } catch (e) {
      debugPrint('[VoiceChat] setSpeakerphoneOn failed: $e');
    }
  }

  /// Kept for compatibility with existing room_screen presence listener.
  /// LiveKit tracks participants itself — these are now no-ops.
  Future<void> onUserJoined(String userId) async {}
  Future<void> onUserLeft(String userId) async {}

  void _wireEvents(lk.EventsListener<lk.RoomEvent> listener) {
    listener.on<lk.ParticipantConnectedEvent>((event) {
      if (!mounted) return;
      state = state.copyWith(
        activePeers: {...state.activePeers, event.participant.identity},
      );
    });
    listener.on<lk.ParticipantDisconnectedEvent>((event) {
      if (!mounted) return;
      state = state.copyWith(
        activePeers: {...state.activePeers}..remove(event.participant.identity),
      );
    });
    listener.on<lk.ActiveSpeakersChangedEvent>((event) {
      if (!mounted) return;
      state = state.copyWith(
        speakingPeers: event.speakers.map((p) => p.identity).toSet(),
      );
    });
    listener.on<lk.RoomDisconnectedEvent>((_) {
      if (!mounted) return;
      state = const VoiceChatState();
    });
  }

  Future<void> _teardown() async {
    final listener = _listener;
    final room = _room;
    _listener = null;
    _room = null;
    try {
      await listener?.dispose();
    } catch (_) {}
    try {
      await room?.disconnect();
    } catch (_) {}
    try {
      await room?.dispose();
    } catch (_) {}
  }

  @override
  void dispose() {
    _teardown();
    super.dispose();
  }
}

final voiceChatProvider = StateNotifierProvider.autoDispose
    .family<VoiceChatNotifier, VoiceChatState, String>((ref, roomId) {
  return VoiceChatNotifier(roomId: roomId, ref: ref);
});
