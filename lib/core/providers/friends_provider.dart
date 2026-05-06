import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../api/server_config.dart';
import 'auth_provider.dart';

/// Compact "other side" of a friendship as the backend serialises it.
class FriendPeer {
  final int id;
  final String username;
  final String? avatarUrl;

  const FriendPeer({
    required this.id,
    required this.username,
    this.avatarUrl,
  });

  factory FriendPeer.fromJson(Map<String, dynamic> json) {
    String? url = json['avatar_url'] as String?;
    if (url != null && url.startsWith('/')) {
      url = '${ServerConfig.mediaBaseUrl}$url';
    }
    return FriendPeer(
      id: json['id'] as int,
      username: json['username'] as String,
      avatarUrl: url,
    );
  }
}

class Friendship {
  final int id;
  final String status; // 'pending' | 'accepted'
  final String direction; // 'incoming' | 'outgoing'
  final FriendPeer peer;

  const Friendship({
    required this.id,
    required this.status,
    required this.direction,
    required this.peer,
  });

  factory Friendship.fromJson(Map<String, dynamic> json) => Friendship(
        id: json['id'] as int,
        status: json['status'] as String,
        direction: json['direction'] as String,
        peer: FriendPeer.fromJson(json['peer'] as Map<String, dynamic>),
      );
}

/// Used in the user-search results — adds the current viewer's relation
/// to the searched user so the UI can render the right action.
enum PeerRelation { none, pendingOutgoing, pendingIncoming, accepted }

PeerRelation _parseRelation(String s) {
  switch (s) {
    case 'accepted':
      return PeerRelation.accepted;
    case 'pending_outgoing':
      return PeerRelation.pendingOutgoing;
    case 'pending_incoming':
      return PeerRelation.pendingIncoming;
  }
  return PeerRelation.none;
}

class UserSearchHit {
  final FriendPeer peer;
  final PeerRelation relation;

  const UserSearchHit({required this.peer, required this.relation});

  factory UserSearchHit.fromJson(Map<String, dynamic> json) => UserSearchHit(
        peer: FriendPeer.fromJson(json),
        relation: _parseRelation(json['relation'] as String? ?? 'none'),
      );
}

/// Accepted friends list. Refresh by calling `ref.invalidate(friendsListProvider)`.
final friendsListProvider =
    FutureProvider.autoDispose<List<Friendship>>((ref) async {
  final dio = ref.watch(dioProvider);
  final r = await dio.get(ApiEndpoints.friends);
  final raw = r.data is List ? r.data : (r.data['results'] ?? []);
  return [for (final j in raw) Friendship.fromJson(j as Map<String, dynamic>)];
});

/// Incoming pending requests inbox.
final friendRequestsProvider =
    FutureProvider.autoDispose<List<Friendship>>((ref) async {
  final dio = ref.watch(dioProvider);
  final r = await dio.get(ApiEndpoints.friendRequests);
  final raw = r.data is List ? r.data : (r.data['results'] ?? []);
  return [for (final j in raw) Friendship.fromJson(j as Map<String, dynamic>)];
});

/// Searches the user directory. Empty query → empty list (no spammy
/// "list all users" call). Family by query string so multiple in-flight
/// searches don't fight each other.
final userSearchProvider =
    FutureProvider.autoDispose.family<List<UserSearchHit>, String>(
        (ref, query) async {
  final q = query.trim();
  if (q.isEmpty) return const [];
  final dio = ref.watch(dioProvider);
  final r = await dio.get(
    ApiEndpoints.userSearch,
    queryParameters: {'q': q, 'limit': 20},
  );
  final raw = r.data is List ? r.data : (r.data['results'] ?? []);
  return [for (final j in raw) UserSearchHit.fromJson(j as Map<String, dynamic>)];
});

/// Mutating actions — backed by Dio. After each, invalidate the affected
/// providers so screens re-fetch and the profile counts refresh.
class FriendActions {
  final Ref _ref;
  FriendActions(this._ref);

  Dio get _dio => _ref.read(dioProvider);

  Future<void> _afterChange() async {
    _ref.invalidate(friendsListProvider);
    _ref.invalidate(friendRequestsProvider);
    // Refresh profile counts (friends_count + pending_requests_count).
    await _ref.read(authStateProvider.notifier).refreshProfile();
  }

  Future<void> sendRequest(int userId) async {
    await _dio.post(ApiEndpoints.friendRequestSend, data: {'user_id': userId});
    await _afterChange();
  }

  Future<void> accept(int friendshipId) async {
    await _dio.post(ApiEndpoints.friendAccept(friendshipId));
    await _afterChange();
  }

  Future<void> remove(int friendshipId) async {
    await _dio.delete(ApiEndpoints.friendDelete(friendshipId));
    await _afterChange();
  }
}

final friendActionsProvider =
    Provider<FriendActions>((ref) => FriendActions(ref));
