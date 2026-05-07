/// Paginated history of the current user's watch sessions.
///
/// Backed by `GET /api/profile/sessions/?limit=&offset=`. The notifier
/// keeps the accumulated list across loadMore() calls so the bottom
/// sheet can render an infinite scroll without losing already-fetched
/// pages.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/api_endpoints.dart';

class WatchSession {
  final int id;
  final String roomId;
  final String roomInviteCode;
  final String roomStatus; // 'active' | 'expired'
  final DateTime joinedAt;
  final int durationSec;

  const WatchSession({
    required this.id,
    required this.roomId,
    required this.roomInviteCode,
    required this.roomStatus,
    required this.joinedAt,
    required this.durationSec,
  });

  bool get isRoomActive => roomStatus == 'active';

  factory WatchSession.fromJson(Map<String, dynamic> json) {
    return WatchSession(
      id: (json['id'] as num).toInt(),
      roomId: json['room_id'].toString(),
      roomInviteCode: (json['room_invite_code'] as String?) ?? '',
      roomStatus: (json['room_status'] as String?) ?? 'expired',
      joinedAt: DateTime.parse(json['joined_at'] as String),
      durationSec: (json['duration_sec'] as num?)?.toInt() ?? 0,
    );
  }
}

class WatchHistoryState {
  final List<WatchSession> items;
  final bool loading;
  final bool hasMore;
  final Object? error;

  const WatchHistoryState({
    this.items = const [],
    this.loading = false,
    this.hasMore = true,
    this.error,
  });

  WatchHistoryState copyWith({
    List<WatchSession>? items,
    bool? loading,
    bool? hasMore,
    Object? error,
    bool clearError = false,
  }) =>
      WatchHistoryState(
        items: items ?? this.items,
        loading: loading ?? this.loading,
        hasMore: hasMore ?? this.hasMore,
        error: clearError ? null : (error ?? this.error),
      );
}

class WatchHistoryNotifier extends StateNotifier<WatchHistoryState> {
  WatchHistoryNotifier(this._ref) : super(const WatchHistoryState());

  static const _pageSize = 20;
  final Ref _ref;

  Future<void> loadFirstPage() async {
    state = const WatchHistoryState(loading: true);
    await _fetchPage(offset: 0, replace: true);
  }

  Future<void> loadMore() async {
    if (state.loading || !state.hasMore) return;
    state = state.copyWith(loading: true, clearError: true);
    await _fetchPage(offset: state.items.length, replace: false);
  }

  Future<void> _fetchPage({required int offset, required bool replace}) async {
    try {
      final dio = _ref.read(dioProvider);
      final resp = await dio.get(
        ApiEndpoints.profileSessions,
        queryParameters: {'limit': _pageSize, 'offset': offset},
      );
      final data = resp.data as Map<String, dynamic>;
      final results = (data['results'] as List? ?? [])
          .map((e) => WatchSession.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final hasMore = data['next'] != null;
      state = state.copyWith(
        items: replace ? results : [...state.items, ...results],
        loading: false,
        hasMore: hasMore,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e);
    }
  }
}

/// `autoDispose` so the notifier resets every time the bottom sheet
/// closes — we always want a fresh first page on reopen.
final watchHistoryProvider =
    StateNotifierProvider.autoDispose<WatchHistoryNotifier, WatchHistoryState>(
  (ref) => WatchHistoryNotifier(ref),
);
