import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/api_endpoints.dart';

/// Server-clock offset relative to the local clock.
///
/// `serverNowMs == DateTime.now().millisecondsSinceEpoch + offsetMs`
class ClockOffset {
  final int offsetMs;
  final int rttMs;
  final DateTime measuredAt;

  const ClockOffset({
    required this.offsetMs,
    required this.rttMs,
    required this.measuredAt,
  });

  int get serverNowMs => DateTime.now().millisecondsSinceEpoch + offsetMs;
}

class _Sample {
  final int offsetMs;
  final int rttMs;

  const _Sample(this.offsetMs, this.rttMs);
}

class ClockSyncNotifier extends StateNotifier<ClockOffset?> {
  static const _samplesPerRefresh = 5;
  static const _interSampleDelay = Duration(milliseconds: 50);
  static const _refreshInterval = Duration(seconds: 60);

  final Dio _dio;
  Timer? _timer;
  bool _disposed = false;

  ClockSyncNotifier(this._dio) : super(null) {
    refresh();
    _timer = Timer.periodic(_refreshInterval, (_) => refresh());
  }

  /// Sample server time several times and pick the offset from the
  /// round-trip with the lowest RTT (Cristian's algorithm). The lowest-RTT
  /// sample minimizes asymmetric-network bias compared to a median.
  Future<void> refresh() async {
    final samples = <_Sample>[];
    for (var i = 0; i < _samplesPerRefresh; i++) {
      final s = await _measureOnce();
      if (s != null) samples.add(s);
      if (i < _samplesPerRefresh - 1) {
        await Future.delayed(_interSampleDelay);
      }
      if (_disposed) return;
    }
    if (samples.isEmpty) return;
    samples.sort((a, b) => a.rttMs.compareTo(b.rttMs));
    final best = samples.first;
    state = ClockOffset(
      offsetMs: best.offsetMs,
      rttMs: best.rttMs,
      measuredAt: DateTime.now(),
    );
  }

  Future<_Sample?> _measureOnce() async {
    try {
      final t0 = DateTime.now().millisecondsSinceEpoch;
      final resp = await _dio.get(ApiEndpoints.serverTime);
      final t1 = DateTime.now().millisecondsSinceEpoch;
      final serverTs = (resp.data['server_time'] as num).toInt();
      final rtt = t1 - t0;
      // Estimate server time at the local "midpoint" of the round-trip.
      final offset = serverTs + (rtt ~/ 2) - t1;
      return _Sample(offset, rtt);
    } catch (e) {
      if (kDebugMode) debugPrint('clock_sync: measure failed: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}

final clockSyncProvider =
    StateNotifierProvider<ClockSyncNotifier, ClockOffset?>((ref) {
      return ClockSyncNotifier(ref.watch(dioProvider));
    });

/// Convenience: current server time in ms, falling back to local clock if
/// the offset hasn't been measured yet.
int serverNowMs(WidgetRef ref) {
  final clock = ref.read(clockSyncProvider);
  return clock?.serverNowMs ?? DateTime.now().millisecondsSinceEpoch;
}
