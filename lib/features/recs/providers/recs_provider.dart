/// State + DTOs for the recommendations system.
///
/// One FutureProvider.autoDispose per screen — invalidated on
/// pull-to-refresh or after a mutation (intent toggle / invite).

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/server_config.dart';

// ─── DTOs ───────────────────────────────────────────────────────────

class RecsMovie {
  final int id;
  final int kpId;
  final String titleRu;
  final String titleOrig;
  final int? year;
  final String? posterUrl;
  final String? posterPreviewUrl;
  final String? backdropUrl;
  final int? durationMin;
  final double? kpRating;
  final List<String> genres;
  final String synopsisRu;

  const RecsMovie({
    required this.id,
    required this.kpId,
    required this.titleRu,
    this.titleOrig = '',
    this.year,
    this.posterUrl,
    this.posterPreviewUrl,
    this.backdropUrl,
    this.durationMin,
    this.kpRating,
    this.genres = const [],
    this.synopsisRu = '',
  });

  factory RecsMovie.fromJson(Map<String, dynamic> j) => RecsMovie(
        id: (j['id'] as num).toInt(),
        kpId: (j['kp_id'] as num).toInt(),
        titleRu: (j['title_ru'] as String?) ?? '',
        titleOrig: (j['title_orig'] as String?) ?? '',
        year: (j['year'] as num?)?.toInt(),
        posterUrl: _emptyAsNull(j['poster_url']),
        posterPreviewUrl: _emptyAsNull(j['poster_preview_url']),
        backdropUrl: _emptyAsNull(j['backdrop_url']),
        durationMin: (j['duration_min'] as num?)?.toInt(),
        // DRF DecimalField → JSON string ("7.38"). Cast-as-num would
        // throw at runtime, so route everything through tryParse.
        kpRating: _toDouble(j['kp_rating']),
        genres: (j['genres'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        synopsisRu: (j['synopsis_ru'] as String?) ?? '',
      );
}

String? _emptyAsNull(Object? v) {
  if (v == null) return null;
  final s = v.toString();
  return s.isEmpty ? null : s;
}

double? _toDouble(Object? v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

class RecsFriend {
  final int id;
  final String username;
  final String? avatarUrl;
  final String presence; // 'free' | 'busy' | 'idle'
  final int? matchPercent;

  const RecsFriend({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.presence = 'idle',
    this.matchPercent,
  });

  bool get isFree => presence == 'free';
  bool get isBusy => presence == 'busy';

  factory RecsFriend.fromJson(Map<String, dynamic> j) => RecsFriend(
        id: (j['id'] as num).toInt(),
        username: (j['username'] as String?) ?? '',
        avatarUrl: _resolveAvatar(j['avatar_url'] as String?),
        presence: (j['presence'] as String?) ?? 'idle',
        matchPercent: (j['match_percent'] as num?)?.toInt(),
      );
}

/// Backend ships relative `/media/avatars/...` paths — promote to a
/// full URL so NetworkImage can resolve them.
String? _resolveAvatar(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  if (raw.startsWith('/')) return '${ServerConfig.mediaBaseUrl}$raw';
  return raw;
}

class RecsHero {
  final RecsMovie movie;
  final int matchPercent;
  final String why;
  final List<RecsFriend> friends;

  const RecsHero({
    required this.movie,
    required this.matchPercent,
    required this.why,
    required this.friends,
  });

  factory RecsHero.fromJson(Map<String, dynamic> j) => RecsHero(
        movie: RecsMovie.fromJson(Map<String, dynamic>.from(j['movie'] as Map)),
        matchPercent: (j['match_percent'] as num?)?.toInt() ?? 0,
        why: (j['why'] as String?) ?? '',
        friends: (j['friends'] as List?)
                ?.map((e) => RecsFriend.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const [],
      );
}

class RecsSocialRow {
  final RecsFriend friend;
  final List<RecsMovie> movies;

  const RecsSocialRow({required this.friend, required this.movies});

  factory RecsSocialRow.fromJson(Map<String, dynamic> j) => RecsSocialRow(
        friend: RecsFriend.fromJson(Map<String, dynamic>.from(j['friend'] as Map)),
        movies: (j['movies'] as List?)
                ?.map((e) => RecsMovie.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const [],
      );
}

class RecsMood {
  final int id;
  final String slug;
  final String title;
  final String subtitle;
  final int hue;
  final int count;

  const RecsMood({
    required this.id,
    required this.slug,
    required this.title,
    this.subtitle = '',
    this.hue = 75,
    this.count = 0,
  });

  factory RecsMood.fromJson(Map<String, dynamic> j) => RecsMood(
        id: (j['id'] as num).toInt(),
        slug: (j['slug'] as String?) ?? '',
        title: (j['title'] as String?) ?? '',
        subtitle: (j['subtitle'] as String?) ?? '',
        hue: (j['hue'] as num?)?.toInt() ?? 75,
        count: (j['count'] as num?)?.toInt() ?? 0,
      );
}

class RecsFeed {
  final List<RecsFriend> friendsOnline;
  final RecsHero? hero;
  final RecsSocialRow? socialRow;
  final List<RecsMovie> topByKp;
  final List<RecsMood> moods;

  const RecsFeed({
    this.friendsOnline = const [],
    this.hero,
    this.socialRow,
    this.topByKp = const [],
    this.moods = const [],
  });

  factory RecsFeed.fromJson(Map<String, dynamic> j) => RecsFeed(
        friendsOnline: (j['friends_online'] as List?)
                ?.map((e) => RecsFriend.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const [],
        hero: j['hero'] == null
            ? null
            : RecsHero.fromJson(Map<String, dynamic>.from(j['hero'] as Map)),
        socialRow: j['social_row'] == null
            ? null
            : RecsSocialRow.fromJson(Map<String, dynamic>.from(j['social_row'] as Map)),
        topByKp: (j['top_by_kp'] as List?)
                ?.map((e) => RecsMovie.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const [],
        moods: (j['moods'] as List?)
                ?.map((e) => RecsMood.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const [],
      );
}

class RecsMatchTitle {
  final RecsMovie movie;
  final int? matchPercent;
  final String why;

  const RecsMatchTitle({required this.movie, this.matchPercent, this.why = ''});

  factory RecsMatchTitle.fromJson(Map<String, dynamic> j) => RecsMatchTitle(
        movie: RecsMovie.fromJson(Map<String, dynamic>.from(j['movie'] as Map)),
        matchPercent: (j['match_percent'] as num?)?.toInt(),
        why: (j['why'] as String?) ?? '',
      );
}

class RecsMatch {
  final RecsFriend friend;
  final int? matchPercent;
  final bool insufficientData;
  final List<String> sharedTags;
  final List<String> notSharedTags;
  final List<RecsMatchTitle> titles;

  const RecsMatch({
    required this.friend,
    this.matchPercent,
    this.insufficientData = false,
    this.sharedTags = const [],
    this.notSharedTags = const [],
    this.titles = const [],
  });

  factory RecsMatch.fromJson(Map<String, dynamic> j) => RecsMatch(
        friend: RecsFriend.fromJson(Map<String, dynamic>.from(j['friend'] as Map)),
        matchPercent: (j['match_percent'] as num?)?.toInt(),
        insufficientData: j['insufficient_data'] as bool? ?? false,
        sharedTags:
            (j['shared_tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        notSharedTags:
            (j['not_shared_tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        titles: (j['titles'] as List?)
                ?.map((e) => RecsMatchTitle.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const [],
      );
}

class RecsMoodEntry {
  final int id;
  final int position;
  final String whyText;
  final RecsMovie movie;

  const RecsMoodEntry({
    required this.id,
    required this.position,
    required this.whyText,
    required this.movie,
  });

  factory RecsMoodEntry.fromJson(Map<String, dynamic> j) => RecsMoodEntry(
        id: (j['id'] as num).toInt(),
        position: (j['position'] as num?)?.toInt() ?? 0,
        whyText: (j['why_text'] as String?) ?? '',
        movie: RecsMovie.fromJson(Map<String, dynamic>.from(j['movie'] as Map)),
      );
}

class RecsMoodPayload {
  final RecsMood mood;
  final List<RecsMoodEntry> items;

  const RecsMoodPayload({required this.mood, required this.items});

  factory RecsMoodPayload.fromJson(Map<String, dynamic> j) => RecsMoodPayload(
        mood: RecsMood.fromJson(Map<String, dynamic>.from(j['mood'] as Map)),
        items: (j['items'] as List?)
                ?.map((e) => RecsMoodEntry.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const [],
      );
}

class RecsTitleReason {
  final String icon;
  final String text;

  const RecsTitleReason({required this.icon, required this.text});

  factory RecsTitleReason.fromJson(Map<String, dynamic> j) => RecsTitleReason(
        icon: (j['icon'] as String?) ?? 'sparkle',
        text: (j['text'] as String?) ?? '',
      );
}

class RecsTitle {
  final RecsMovie movie;
  final int matchPercent;
  final List<RecsTitleReason> whyReasons;
  final List<RecsFriend> friendsWhoWouldLike;
  final bool hasIntent;

  const RecsTitle({
    required this.movie,
    this.matchPercent = 0,
    this.whyReasons = const [],
    this.friendsWhoWouldLike = const [],
    this.hasIntent = false,
  });

  factory RecsTitle.fromJson(Map<String, dynamic> j) => RecsTitle(
        movie: RecsMovie.fromJson(Map<String, dynamic>.from(j['movie'] as Map)),
        matchPercent: (j['match_percent'] as num?)?.toInt() ?? 0,
        whyReasons: (j['why_reasons'] as List?)
                ?.map((e) => RecsTitleReason.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const [],
        friendsWhoWouldLike: (j['friends_who_would_like'] as List?)
                ?.map((e) => RecsFriend.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const [],
        hasIntent: j['has_intent'] as bool? ?? false,
      );
}

class RecsInviteResult {
  final String roomId;
  final String inviteCode;
  final RecsMovie movie;
  final bool mediaAttached;
  final Map<String, dynamic>? attachedTorrent;

  const RecsInviteResult({
    required this.roomId,
    required this.inviteCode,
    required this.movie,
    this.mediaAttached = false,
    this.attachedTorrent,
  });

  factory RecsInviteResult.fromJson(Map<String, dynamic> j) => RecsInviteResult(
        roomId: j['room_id'].toString(),
        inviteCode: (j['invite_code'] as String?) ?? '',
        movie: RecsMovie.fromJson(Map<String, dynamic>.from(j['movie'] as Map)),
        mediaAttached: j['media_attached'] as bool? ?? false,
        attachedTorrent: j['attached_torrent'] == null
            ? null
            : Map<String, dynamic>.from(j['attached_torrent'] as Map),
      );
}

/// State carried from a Recs invite into the room screen — when the
/// backend couldn't auto-attach a torrent, the room screen reads this
/// on first frame and opens AddMediaSheet pre-filled with the title.
class PendingRecsRoom {
  final String roomId;
  final String movieTitle;
  final bool mediaAttached;

  const PendingRecsRoom({
    required this.roomId,
    required this.movieTitle,
    required this.mediaAttached,
  });
}

final pendingRecsRoomProvider = StateProvider<PendingRecsRoom?>((_) => null);

// ─── Providers ──────────────────────────────────────────────────────

final recsFeedProvider = FutureProvider.autoDispose<RecsFeed>((ref) async {
  final dio = ref.read(dioProvider);
  final resp = await dio.get(ApiEndpoints.recsFeed);
  return RecsFeed.fromJson(Map<String, dynamic>.from(resp.data as Map));
});

final recsMatchProvider =
    FutureProvider.autoDispose.family<RecsMatch, int>((ref, friendId) async {
  final dio = ref.read(dioProvider);
  final resp = await dio.get(ApiEndpoints.recsMatch(friendId));
  return RecsMatch.fromJson(Map<String, dynamic>.from(resp.data as Map));
});

final recsMoodProvider =
    FutureProvider.autoDispose.family<RecsMoodPayload, String>((ref, slug) async {
  final dio = ref.read(dioProvider);
  final resp = await dio.get(ApiEndpoints.recsMood(slug));
  return RecsMoodPayload.fromJson(Map<String, dynamic>.from(resp.data as Map));
});

final recsTitleProvider =
    FutureProvider.autoDispose.family<RecsTitle, int>((ref, movieId) async {
  final dio = ref.read(dioProvider);
  final resp = await dio.get(ApiEndpoints.recsTitle(movieId));
  return RecsTitle.fromJson(Map<String, dynamic>.from(resp.data as Map));
});

/// Toggles WatchIntent. Caller invalidates `recsTitleProvider(movieId)`
/// after to refresh the screen.
Future<bool> toggleIntent(WidgetRef ref, int movieId) async {
  final dio = ref.read(dioProvider);
  final resp = await dio.post(ApiEndpoints.recsTitleIntent(movieId));
  return resp.data['has_intent'] as bool? ?? false;
}

/// Creates a room around a movie recommendation. The selected
/// friends get a `room_invite` push so they can tap-to-join.
Future<RecsInviteResult> inviteFromTitle(
  WidgetRef ref,
  int movieId, {
  List<int> friendIds = const [],
}) async {
  final dio = ref.read(dioProvider);
  final resp = await dio.post(
    ApiEndpoints.recsTitleInvite(movieId),
    data: {'friend_ids': friendIds},
  );
  return RecsInviteResult.fromJson(Map<String, dynamic>.from(resp.data as Map));
}
