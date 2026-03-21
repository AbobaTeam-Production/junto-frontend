import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'room_ws_provider.dart';
import 'auth_provider.dart';
import 'voice_chat_web.dart' if (dart.library.io) 'voice_chat_stub.dart';

class VoiceChatState {
  final bool isActive;
  final bool isMuted;
  final bool speakerOn;
  final Set<String> activePeers;

  const VoiceChatState({
    this.isActive = false,
    this.isMuted = false,
    this.speakerOn = false,
    this.activePeers = const {},
  });

  VoiceChatState copyWith({
    bool? isActive,
    bool? isMuted,
    bool? speakerOn,
    Set<String>? activePeers,
  }) {
    return VoiceChatState(
      isActive: isActive ?? this.isActive,
      isMuted: isMuted ?? this.isMuted,
      speakerOn: speakerOn ?? this.speakerOn,
      activePeers: activePeers ?? this.activePeers,
    );
  }
}

class VoiceChatNotifier extends StateNotifier<VoiceChatState> {
  final String roomId;
  final RoomWsNotifier _wsNotifier;
  final RoomWsState Function() _readWsState;
  final String _myUserId;

  MediaStream? _localStream;
  final Map<String, RTCPeerConnection> _peers = {};

  static const _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
    ],
  };

  VoiceChatNotifier({
    required this.roomId,
    required RoomWsNotifier wsNotifier,
    required RoomWsState Function() readWsState,
    required String myUserId,
  })  : _wsNotifier = wsNotifier,
        _readWsState = readWsState,
        _myUserId = myUserId,
        super(const VoiceChatState()) {
    _wsNotifier.onWebRtcSignal = _onSignal;
  }

  void _safeSetState(VoiceChatState newState) {
    if (mounted) state = newState;
  }

  Future<bool> _ensureMic() async {
    if (_localStream != null) return true;
    try {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': {
          // Standard W3C constraints
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
          'channelCount': 1,
          // Chrome/WebRTC-specific — aggressive echo & noise processing
          'googEchoCancellation': true,
          'googExperimentalEchoCancellation': true,
          'googAutoGainControl': true,
          'googExperimentalAutoGainControl': true,
          'googNoiseSuppression': true,
          'googExperimentalNoiseSuppression': true,
          'googHighpassFilter': true,
          'googTypingNoiseDetection': true,
        },
        'video': false,
      });

      // On mobile: use earpiece (not loudspeaker) for proper AEC
      if (!kIsWeb) {
        await Helper.setSpeakerphoneOn(false);
      }

      _safeSetState(state.copyWith(isActive: true));
      debugPrint('[VoiceChat] Mic acquired');
      return true;
    } catch (e) {
      debugPrint('[VoiceChat] Mic error: $e');
      return false;
    }
  }

  Future<void> start() async {
    if (state.isActive) return;
    if (!await _ensureMic()) return;

    final onlineUsers = _readWsState().onlineUsers;
    for (final entry in onlineUsers.entries) {
      final userId = entry.value;
      if (userId != _myUserId) {
        await _createOffer(userId);
      }
    }
  }

  Future<void> stop() async {
    for (final pc in _peers.values) {
      try { await pc.close(); } catch (_) {}
    }
    _peers.clear();

    if (kIsWeb) await detachAllWebAudio();

    try {
      final tracks = _localStream?.getAudioTracks() ?? [];
      for (final t in tracks) { t.stop(); }
      _localStream?.dispose();
    } catch (e) {
      debugPrint('[VoiceChat] Stream cleanup error: $e');
    }
    _localStream = null;

    _safeSetState(const VoiceChatState());
  }

  void toggleMute() {
    if (_localStream == null) return;
    final muted = !state.isMuted;
    for (final track in _localStream!.getAudioTracks()) {
      track.enabled = !muted;
    }
    _safeSetState(state.copyWith(isMuted: muted));
  }

  /// Toggle speakerphone on mobile (earpiece ↔ loudspeaker).
  Future<void> toggleSpeaker() async {
    if (kIsWeb) return;
    final on = !state.speakerOn;
    await Helper.setSpeakerphoneOn(on);
    _safeSetState(state.copyWith(speakerOn: on));
  }

  Future<void> onUserJoined(String userId) async {
    if (!state.isActive || userId == _myUserId) return;
    if (_peers.containsKey(userId)) return;
    await _createOffer(userId);
  }

  Future<void> onUserLeft(String userId) async {
    final pc = _peers.remove(userId);
    if (pc != null) { await pc.close(); }
    if (kIsWeb) await detachWebAudio(userId);
    if (pc != null) {
      _safeSetState(state.copyWith(
        activePeers: {...state.activePeers}..remove(userId),
      ));
    }
  }

  // ─── Signaling ────────────────────────────────────

  void _onSignal(Map<String, dynamic> event) {
    final type = event['event'] as String?;
    final fromUser = event['from_user'] as String? ?? '';
    debugPrint('[VoiceChat] signal: $type from $fromUser');

    switch (type) {
      case 'webrtc_offer':
        final sdp = event['sdp'];
        if (sdp is Map<String, dynamic>) _handleOffer(fromUser, sdp);
      case 'webrtc_answer':
        final sdp = event['sdp'];
        if (sdp is Map<String, dynamic>) _handleAnswer(fromUser, sdp);
      case 'ice_candidate':
        final candidate = event['candidate'];
        if (candidate is Map<String, dynamic>) {
          _handleIceCandidate(fromUser, candidate);
        }
    }
  }

  /// On web: attach remote stream via renderer for audio playback.
  /// On mobile: WebRTC plays audio natively, no element needed.
  Future<void> _onRemoteStream(String userId, MediaStream stream) async {
    if (!mounted) return;

    if (kIsWeb) {
      await attachWebAudio(userId, stream);
      debugPrint('[VoiceChat] Web audio attached for $userId');
    } else {
      debugPrint('[VoiceChat] Mobile: native audio for $userId');
    }

    _safeSetState(state.copyWith(
      activePeers: {...state.activePeers, userId},
    ));
  }

  Future<RTCPeerConnection> _createFreshPeer(String userId) async {
    final old = _peers.remove(userId);
    if (old != null) { await old.close(); }
    if (kIsWeb) await detachWebAudio(userId);

    final pc = await createPeerConnection(_iceServers);
    _peers[userId] = pc;

    if (_localStream != null) {
      for (final track in _localStream!.getAudioTracks()) {
        await pc.addTrack(track, _localStream!);
      }
    }

    pc.onIceCandidate = (candidate) {
      if (!mounted) return;
      _wsNotifier.sendIceCandidate(userId, candidate.toMap());
    };

    pc.onTrack = (event) {
      debugPrint('[VoiceChat] onTrack from $userId '
          '(streams: ${event.streams.length})');
      if (event.streams.isNotEmpty) {
        _onRemoteStream(userId, event.streams[0]);
      }
    };

    // ignore: deprecated_member_use
    pc.onAddStream = (MediaStream stream) {
      debugPrint('[VoiceChat] onAddStream from $userId');
      _onRemoteStream(userId, stream);
    };

    pc.onIceConnectionState = (iceState) {
      if (!mounted) return;
      debugPrint('[VoiceChat] ICE $userId: $iceState');
      if (iceState == RTCIceConnectionState.RTCIceConnectionStateDisconnected ||
          iceState == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        _peers.remove(userId)?.close();
        _safeSetState(state.copyWith(
          activePeers: {...state.activePeers}..remove(userId),
        ));
      }
    };

    return pc;
  }

  /// Optimize Opus SDP for voice: enable DTX, set voice bitrate, mono.
  RTCSessionDescription _optimizeSdp(RTCSessionDescription sdp) {
    var s = sdp.sdp ?? '';
    // Add Opus params: DTX stops sending silence (breaks echo loop),
    // low bitrate is fine for voice, mono, enable FEC.
    s = s.replaceAllMapped(
      RegExp(r'(a=fmtp:111 .+)'),
      (m) {
        var line = m.group(1)!;
        if (!line.contains('usedtx=')) line += ';usedtx=1';
        if (!line.contains('stereo=')) line += ';stereo=0';
        if (!line.contains('sprop-stereo=')) line += ';sprop-stereo=0';
        if (!line.contains('maxaveragebitrate=')) {
          line += ';maxaveragebitrate=24000';
        }
        if (!line.contains('useinbandfec=')) line += ';useinbandfec=1';
        return line;
      },
    );
    return RTCSessionDescription(s, sdp.type);
  }

  Future<void> _createOffer(String userId) async {
    debugPrint('[VoiceChat] Creating offer for $userId');
    final pc = await _createFreshPeer(userId);
    final offer = await pc.createOffer();
    final optimized = _optimizeSdp(offer);
    await pc.setLocalDescription(optimized);
    _wsNotifier.sendWebRtcOffer(userId, optimized.toMap());
  }

  Future<void> _handleOffer(
      String fromUser, Map<String, dynamic> sdpMap) async {
    debugPrint('[VoiceChat] Handling offer from $fromUser');
    if (!await _ensureMic()) return;

    final pc = await _createFreshPeer(fromUser);
    await pc.setRemoteDescription(RTCSessionDescription(
      sdpMap['sdp'] as String?,
      sdpMap['type'] as String?,
    ));

    final answer = await pc.createAnswer();
    final optimized = _optimizeSdp(answer);
    await pc.setLocalDescription(optimized);
    debugPrint('[VoiceChat] Sending answer to $fromUser');
    _wsNotifier.sendWebRtcAnswer(fromUser, optimized.toMap());
  }

  Future<void> _handleAnswer(
      String fromUser, Map<String, dynamic> sdpMap) async {
    debugPrint('[VoiceChat] Handling answer from $fromUser');
    final pc = _peers[fromUser];
    if (pc == null) return;
    await pc.setRemoteDescription(RTCSessionDescription(
      sdpMap['sdp'] as String?,
      sdpMap['type'] as String?,
    ));
  }

  Future<void> _handleIceCandidate(
      String fromUser, Map<String, dynamic> candidateMap) async {
    final pc = _peers[fromUser];
    if (pc == null) return;
    await pc.addCandidate(RTCIceCandidate(
      candidateMap['candidate'] as String?,
      candidateMap['sdpMid'] as String?,
      candidateMap['sdpMLineIndex'] as int?,
    ));
  }

  @override
  void dispose() {
    _wsNotifier.onWebRtcSignal = null;
    _cleanupAsync();
    super.dispose();
  }

  Future<void> _cleanupAsync() async {
    for (final pc in _peers.values) {
      try { await pc.close(); } catch (_) {}
    }
    if (kIsWeb) await detachAllWebAudio();
    try {
      final tracks = _localStream?.getAudioTracks() ?? [];
      for (final t in tracks) { t.stop(); }
      _localStream?.dispose();
    } catch (_) {}
  }
}

final voiceChatProvider = StateNotifierProvider.autoDispose
    .family<VoiceChatNotifier, VoiceChatState, String>((ref, roomId) {
  final wsNotifier = ref.watch(roomWsProvider(roomId).notifier);
  final currentUser = ref.watch(currentUserProvider);
  final myUserId = currentUser != null ? '${currentUser.id}' : '';

  return VoiceChatNotifier(
    roomId: roomId,
    wsNotifier: wsNotifier,
    readWsState: () => ref.read(roomWsProvider(roomId)),
    myUserId: myUserId,
  );
});
