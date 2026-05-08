// "Что посмотреть вечером?" — main entry point of the recs system.
// Mirrors RecFeedScreen.jsx structure: friends-online strip → hero
// card → "friend wants to watch" row → mood grid.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/junto_primitives.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/recs_provider.dart';
import '../widgets/friend_chip.dart';
import '../widgets/match_badge.dart';
import '../widgets/movie_card.dart';
import '../widgets/poster_placeholder.dart';

class RecsFeedScreen extends ConsumerWidget {
  const RecsFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final feedAsync = ref.watch(recsFeedProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: feedAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          error: (_, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                l.sessionsHistoryError,
                textAlign: TextAlign.center,
                style: AppTheme.text(size: 14, color: AppColors.ink3),
              ),
            ),
          ),
          data: (feed) => RefreshIndicator(
            onRefresh: () async => ref.invalidate(recsFeedProvider),
            child: _FeedBody(feed: feed),
          ),
        ),
      ),
    );
  }
}

class _FeedBody extends ConsumerWidget {
  final RecsFeed feed;
  const _FeedBody({required this.feed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final now = DateTime.now();
    final dateLabel = _weekdayName(now.weekday, l);
    final timeLabel = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final freeCount = feed.friendsOnline.where((f) => f.isFree).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MonoLabel(
                      l.recsFeedDateLabel(dateLabel, timeLabel),
                      color: AppColors.ink3,
                      letterSpacing: 1.6,
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        style: AppTheme.display(
                          size: 30,
                          weight: FontWeight.w600,
                          letterSpacing: -0.7,
                        ),
                        children: [
                          TextSpan(text: '${l.recsFeedTitle}\n'),
                          TextSpan(
                            text: l.recsFeedTitleAccent,
                            style: AppTheme.display(
                              size: 30,
                              weight: FontWeight.w500,
                              color: AppColors.amber,
                            ).copyWith(fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (freeCount > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.live,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l.recsFeedFreeCount(freeCount),
                        style: AppTheme.mono(
                          size: 9,
                          letterSpacing: 1.4,
                          color: AppColors.ink3,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        // ── Friends-online strip ──
        if (feed.friendsOnline.isNotEmpty) ...[
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: MonoLabel(
              l.recsFeedFreeNow,
              color: AppColors.ink3,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 116,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: feed.friendsOnline.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (ctx, i) {
                final f = feed.friendsOnline[i];
                return FriendChip(
                  friend: f,
                  hue: (f.username.hashCode.abs() % 360),
                  onTap: () => context.push('/recs/match/${f.id}'),
                );
              },
            ),
          ),
        ],

        // ── Hero card ──
        if (feed.hero != null) ...[
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: MonoLabel(
              '★ ${l.recsFeedTopMatch}',
              color: AppColors.amber,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _HeroCard(hero: feed.hero!),
          ),
        ],

        // ── Social row "Аня хочет посмотреть" ──
        if (feed.socialRow != null && feed.socialRow!.movies.isNotEmpty) ...[
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                JuntoAvatar(
                  name: feed.socialRow!.friend.username,
                  size: 20,
                  imageUrl: feed.socialRow!.friend.avatarUrl,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: MonoLabel(
                    l.recsFeedFriendWantsToWatch(feed.socialRow!.friend.username),
                    color: AppColors.ink3,
                    letterSpacing: 1.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 260,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: feed.socialRow!.movies.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (ctx, i) {
                final movie = feed.socialRow!.movies[i];
                return MovieCardVertical(
                  movie: movie,
                  onTap: () => context.push('/recs/title/${movie.id}'),
                );
              },
            ),
          ),
        ],

        // ── Top-by-KP row — surfaces the broad catalog so the user
        // doesn't think recs == "the 4 cards on the front page".
        if (feed.topByKp.isNotEmpty) ...[
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: MonoLabel(
              l.recsFeedTopKpLabel,
              color: AppColors.ink3,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 260,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: feed.topByKp.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (ctx, i) {
                final movie = feed.topByKp[i];
                return MovieCardVertical(
                  movie: movie,
                  onTap: () => context.push('/recs/title/${movie.id}'),
                );
              },
            ),
          ),
        ],

        // ── Mood grid ──
        if (feed.moods.isNotEmpty) ...[
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: MonoLabel(
              l.recsFeedMoodsLabel,
              color: AppColors.ink3,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.6,
              children: feed.moods.map((m) {
                return _MoodTile(mood: m);
              }).toList(),
            ),
          ),
        ],

        if (feed.hero == null && feed.moods.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            child: Center(
              child: Text(
                l.recsFeedEmpty,
                textAlign: TextAlign.center,
                style: AppTheme.text(size: 14, color: AppColors.ink3),
              ),
            ),
          ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }

  static String _weekdayName(int weekday, AppLocalizations l) {
    // Cheap fallback — no full intl string. Russian short days.
    const ru = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    const en = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final isRu = l.localeName.startsWith('ru');
    final list = isRu ? ru : en;
    return list[(weekday - 1) % 7];
  }
}

class _HeroCard extends ConsumerWidget {
  final RecsHero hero;
  const _HeroCard({required this.hero});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return InkWell(
      onTap: () => context.push('/recs/title/${hero.movie.id}'),
      borderRadius: BorderRadius.circular(AppTheme.r3),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.r3),
          border: Border.all(color: AppColors.hairline),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: _HeroFallback.heroImage(hero.movie),
                ),
                if (hero.matchPercent > 0)
                  Positioned(
                    left: 14,
                    top: 14,
                    child: MatchBadge(percent: hero.matchPercent),
                  ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: Text(
                    hero.movie.titleRu,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.display(
                      size: 24,
                      weight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ).copyWith(
                      shadows: const [
                        Shadow(
                          color: Color(0xCC000000),
                          blurRadius: 12,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final tag in [
                        if (hero.movie.genres.isNotEmpty) hero.movie.genres.first,
                        if (hero.movie.year != null && hero.movie.durationMin != null)
                          '${hero.movie.year} · ${_formatDuration(hero.movie.durationMin!)}',
                      ])
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.hairline),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            tag,
                            style: AppTheme.text(
                              size: 11,
                              weight: FontWeight.w600,
                              color: AppColors.ink2,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (hero.movie.synopsisRu.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      hero.movie.synopsisRu,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.text(
                        size: 13,
                        color: AppColors.ink2,
                        height: 1.5,
                      ),
                    ),
                  ] else if (hero.why.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      hero.why,
                      style: AppTheme.text(
                        size: 13,
                        color: AppColors.ink2,
                        height: 1.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      if (hero.friends.isNotEmpty)
                        SizedBox(
                          height: 24,
                          child: Stack(
                            children: [
                              for (var i = 0; i < hero.friends.take(3).length; i++)
                                Positioned(
                                  left: i * 16.0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppColors.surface, width: 2),
                                    ),
                                    child: JuntoAvatar(
                                      name: hero.friends[i].username,
                                      size: 24,
                                      imageUrl: hero.friends[i].avatarUrl,
                                    ),
                                  ),
                                ),
                              SizedBox(width: 24.0 + (hero.friends.take(3).length - 1) * 16.0),
                            ],
                          ),
                        ),
                      const SizedBox(width: 10),
                      if (hero.friends.isNotEmpty)
                        Expanded(
                          child: Text(
                            l.recsFeedFriendsLikeIt(hero.friends.length),
                            style: AppTheme.text(size: 12, color: AppColors.ink3),
                          ),
                        )
                      else
                        const Spacer(),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.amber,
                          foregroundColor: AppColors.amberInk,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        ),
                        onPressed: () => context.push('/recs/title/${hero.movie.id}'),
                        child: Text(l.recsFeedInvite),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '$m мин';
    return '$h ч $m мин';
  }
}

class _HeroFallback {
  /// Picks the best image for the hero card with a graceful chain:
  /// backdrop → poster → striped placeholder. Previously fell back
  /// only to the placeholder, so movies without a backdrop (most of
  /// poiskkino's catalog) showed a blank tile.
  static Widget heroImage(RecsMovie movie) {
    final url = (movie.backdropUrl?.isNotEmpty ?? false)
        ? movie.backdropUrl!
        : (movie.posterUrl?.isNotEmpty ?? false ? movie.posterUrl! : null);
    final fallback = PosterPlaceholder(
      mood: pickPosterMood(movie.genres),
      label: movie.titleRu,
      radius: 0,
    );
    if (url == null) return fallback;
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}

class _MoodTile extends StatelessWidget {
  final RecsMood mood;
  const _MoodTile({required this.mood});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final hueColor = HSLColor.fromAHSL(0.18, mood.hue.toDouble(), 0.55, 0.55).toColor();
    return InkWell(
      onTap: () => context.push('/recs/mood/${mood.slug}'),
      borderRadius: BorderRadius.circular(AppTheme.r2),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.hairline),
          borderRadius: BorderRadius.circular(AppTheme.r2),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: hueColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  mood.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.display(
                    size: 16,
                    weight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l.recsFeedMoodMoviesCount(mood.count),
                  style: AppTheme.mono(
                    size: 10,
                    color: AppColors.ink3,
                    weight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
