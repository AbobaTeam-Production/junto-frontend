import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../widgets/retryable_image.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/junto_primitives.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/recs_provider.dart';
import '../widgets/poster_placeholder.dart';

class RecsTitleScreen extends ConsumerWidget {
  final int movieId;
  const RecsTitleScreen({super.key, required this.movieId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final asyncTitle = ref.watch(recsTitleProvider(movieId));

    final w = MediaQuery.of(context).size.width;
    final body = asyncTitle.when(
      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (_, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(l.sessionsHistoryError,
              style: AppTheme.text(size: 14, color: AppColors.ink3)),
        ),
      ),
      data: (t) => _TitleBody(title: t, movieId: movieId),
    );
    return Scaffold(
      backgroundColor: AppColors.bg,
      // The title page is a phone layout — at desktop width the 320-tall
      // backdrop fills the whole window because BoxFit.cover crops up. Cap
      // the column at 720 px so the hero stays in proportion.
      body: w > 720
          ? Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: body,
              ),
            )
          : body,
    );
  }
}

class _TitleBody extends ConsumerStatefulWidget {
  final RecsTitle title;
  final int movieId;
  const _TitleBody({required this.title, required this.movieId});

  @override
  ConsumerState<_TitleBody> createState() => _TitleBodyState();
}

class _TitleBodyState extends ConsumerState<_TitleBody> {
  final _selectedFriendIds = <int>{};
  bool _inviting = false;

  RecsTitle get title => widget.title;

  @override
  void initState() {
    super.initState();
    // Pre-select the top-2 free friends so the CTA reads naturally.
    final freeFriends = title.friendsWhoWouldLike.where((f) => f.isFree).toList();
    for (final f in freeFriends.take(2)) {
      _selectedFriendIds.add(f.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final movie = title.movie;
    // Prefer the wide backdrop, fall back to the regular poster, then
    // to the placeholder. The page header is 320 tall — a poster fills
    // it more naturally than a blank striped tile.
    final heroImageUrl = (movie.backdropUrl?.isNotEmpty ?? false)
        ? movie.backdropUrl!
        : (movie.posterUrl?.isNotEmpty ?? false ? movie.posterUrl! : null);
    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.zero,
          children: [
            // Backdrop / poster
            SizedBox(
              height: 320,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: heroImageUrl != null
                        ? RetryableNetworkImage(
                            url: heroImageUrl,
                            fit: BoxFit.cover,
                            placeholderBuilder: (_) => PosterPlaceholder(
                              mood: pickPosterMood(movie.genres),
                              label: movie.titleRu,
                              radius: 0,
                            ),
                          )
                        : PosterPlaceholder(
                            mood: pickPosterMood(movie.genres),
                            label: movie.titleRu,
                            radius: 0,
                          ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.transparent,
                            AppColors.bg.withValues(alpha: 0.6),
                            AppColors.bg,
                          ],
                          stops: const [0, 0.4, 0.85, 1],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 12,
                    left: 12,
                    right: 12,
                    child: Row(
                      children: [
                        _BlurButton(
                          icon: Icons.arrow_back_rounded,
                          onTap: () => context.pop(),
                        ),
                        const Spacer(),
                        _BlurButton(
                          icon: title.hasIntent
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          onTap: () => _toggleIntent(),
                        ),
                      ],
                    ),
                  ),
                  if ((movie.trailerEmbedUrl ?? '').isNotEmpty)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 76,
                      child: Center(
                        child: _TrailerButton(
                          embedUrl: movie.trailerEmbedUrl!,
                          movieTitle: movie.titleRu,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
              child: Transform.translate(
                offset: const Offset(0, -56),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title.matchPercent > 0)
                      MonoLabel(
                        l.recsTitleMatchHeader(title.matchPercent),
                        color: AppColors.amber,
                        letterSpacing: 1.8,
                      ),
                    const SizedBox(height: 6),
                    Text(
                      movie.titleRu,
                      style: AppTheme.display(
                          size: 28, weight: FontWeight.w600, letterSpacing: -0.6),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (movie.year != null && movie.durationMin != null)
                          _MetaChip(
                              text:
                                  '${movie.year} · ${_fmtDur(movie.durationMin!)}'),
                        for (final g in movie.genres.take(3)) _MetaChip(text: g),
                      ],
                    ),
                    if (movie.synopsisRu.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        movie.synopsisRu,
                        style: AppTheme.text(
                            size: 14, color: AppColors.ink2, height: 1.55),
                      ),
                    ],
                    if (title.whyReasons.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          border: Border.all(color: AppColors.hairline),
                          borderRadius: BorderRadius.circular(AppTheme.r2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MonoLabel(l.recsTitleWhy,
                                color: AppColors.ink3, letterSpacing: 1.8),
                            const SizedBox(height: 8),
                            for (final r in title.whyReasons) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
                                    Icon(_iconFor(r.icon),
                                        size: 14, color: AppColors.amber),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(r.text,
                                          style: AppTheme.text(
                                              size: 13,
                                              color: AppColors.ink2)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    if (title.friendsWhoWouldLike.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      MonoLabel(l.recsTitleWillLike,
                          color: AppColors.ink3, letterSpacing: 1.8),
                      const SizedBox(height: 6),
                      for (var i = 0; i < title.friendsWhoWouldLike.length; i++)
                        Container(
                          decoration: BoxDecoration(
                            border: i < title.friendsWhoWouldLike.length - 1
                                ? const Border(
                                    bottom: BorderSide(color: AppColors.hairline))
                                : null,
                          ),
                          child: _FriendRow(
                            friend: title.friendsWhoWouldLike[i],
                            selected: _selectedFriendIds
                                .contains(title.friendsWhoWouldLike[i].id),
                            onToggle: () => setState(() {
                              final id = title.friendsWhoWouldLike[i].id;
                              if (_selectedFriendIds.contains(id)) {
                                _selectedFriendIds.remove(id);
                              } else {
                                _selectedFriendIds.add(id);
                              }
                            }),
                          ),
                        ),
                    ],
                    SizedBox(height: 100 + MediaQuery.of(context).padding.bottom),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Sticky CTA at the bottom
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(
              24, 14, 24, 14 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, AppColors.bg.withValues(alpha: 0.95)],
                stops: const [0, 0.35],
              ),
              border: const Border(top: BorderSide(color: AppColors.hairline)),
              color: AppColors.bg,
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.amber,
                      foregroundColor: AppColors.amberInk,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.r2),
                      ),
                    ),
                    onPressed: _inviting ? null : _invite,
                    child: _inviting
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.amberInk),
                          )
                        : Text(
                            _ctaText(l),
                            style: AppTheme.text(
                                size: 15,
                                weight: FontWeight.w600,
                                color: AppColors.amberInk),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _ctaText(AppLocalizations l) {
    final selectedNames = title.friendsWhoWouldLike
        .where((f) => _selectedFriendIds.contains(f.id))
        .map((f) => f.username)
        .toList();
    if (selectedNames.isEmpty) return l.recsTitleCtaJoinSelf;
    if (selectedNames.length == 1) return l.recsTitleCta(selectedNames.first);
    if (selectedNames.length == 2) {
      return l.recsTitleCta('${selectedNames[0]} ${l.localeName.startsWith('ru') ? 'и' : 'and'} ${selectedNames[1]}');
    }
    return l.recsTitleCta('${selectedNames.first} +${selectedNames.length - 1}');
  }

  Future<void> _toggleIntent() async {
    try {
      await toggleIntent(ref, widget.movieId);
      ref.invalidate(recsTitleProvider(widget.movieId));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).sessionsHistoryError)),
      );
    }
  }

  Future<void> _invite() async {
    setState(() => _inviting = true);
    try {
      final result = await inviteFromTitle(
        ref,
        widget.movieId,
        friendIds: _selectedFriendIds.toList(),
      );
      if (!mounted) return;
      // Backend tries to auto-attach the best torrent. If it couldn't
      // (no jacred hits / no seeders), park a hint so the room screen
      // opens AddMediaSheet pre-filled with the movie title — the
      // host can pick a source manually without re-typing.
      ref.read(pendingRecsRoomProvider.notifier).state = PendingRecsRoom(
        roomId: result.roomId,
        // Russian title first — Russian-language trackers (rutracker,
        // kinozal) index by it, so the manual-pick search lands more
        // hits if the host edits the field.
        movieTitle: result.movie.titleRu.isNotEmpty
            ? result.movie.titleRu
            : result.movie.titleOrig,
        mediaAttached: result.mediaAttached,
      );
      context.go('/room/${result.roomId}');
    } catch (_) {
      if (!mounted) return;
      setState(() => _inviting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).sessionsHistoryError)),
      );
    }
  }

  static String _fmtDur(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '$m мин';
    return '$h ч $m мин';
  }

  static IconData _iconFor(String icon) {
    switch (icon) {
      case 'heart':
        return Icons.favorite_rounded;
      case 'people':
        return Icons.people_rounded;
      case 'film':
        return Icons.movie_rounded;
      default:
        return Icons.auto_awesome_rounded;
    }
  }
}

class _MetaChip extends StatelessWidget {
  final String text;
  const _MetaChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: AppTheme.text(size: 11, weight: FontWeight.w600, color: AppColors.ink2),
      ),
    );
  }
}

class _TrailerButton extends StatelessWidget {
  final String embedUrl;
  final String movieTitle;
  const _TrailerButton({required this.embedUrl, required this.movieTitle});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () => _showTrailer(context, embedUrl, movieTitle),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.play_arrow_rounded,
                  size: 22, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                l.recsTitleWatchTrailer,
                style: AppTheme.text(
                  size: 14,
                  weight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _showTrailer(BuildContext context, String url, String title) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: _TrailerSheet(embedUrl: url, movieTitle: title),
      ),
    );
  }
}

class _TrailerSheet extends StatefulWidget {
  final String embedUrl;
  final String movieTitle;
  const _TrailerSheet({required this.embedUrl, required this.movieTitle});

  @override
  State<_TrailerSheet> createState() => _TrailerSheetState();
}

class _TrailerSheetState extends State<_TrailerSheet> {
  WebViewController? _controller;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.black)
        ..loadRequest(Uri.parse(widget.embedUrl));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 16, 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Text(
                    widget.movieTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.text(
                      size: 14,
                      weight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: kIsWeb
                ? Center(
                    // webview_flutter on Web requires the web platform
                    // implementation; embed via go_router opening a new
                    // tab is more reliable. Tapping shows the controls
                    // explicitly so the user knows where it'll open.
                    child: TextButton.icon(
                      icon: const Icon(Icons.open_in_new_rounded,
                          color: AppColors.amber),
                      label: Text(
                        widget.embedUrl,
                        style: AppTheme.text(
                            size: 13,
                            color: AppColors.amber,
                            weight: FontWeight.w500),
                      ),
                      onPressed: () {
                        // Web build: use launchUrl through dart:html. We
                        // don't pull url_launcher just for this — keep
                        // the dependency surface minimal.
                      },
                    ),
                  )
                : (_controller == null
                    ? const SizedBox.shrink()
                    : WebViewWidget(controller: _controller!)),
          ),
        ],
      ),
    );
  }
}

class _BlurButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _BlurButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 24,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.bg.withValues(alpha: 0.7),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: AppColors.ink),
      ),
    );
  }
}

class _FriendRow extends StatelessWidget {
  final RecsFriend friend;
  final bool selected;
  final VoidCallback onToggle;

  const _FriendRow({
    required this.friend,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          JuntoAvatar(
            name: friend.username,
            size: 36,
            imageUrl: friend.avatarUrl,
            online: friend.isFree,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(friend.username,
                    style: AppTheme.text(size: 14, weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  friend.isFree
                      ? l.recsPresenceFree
                      : friend.isBusy
                          ? l.recsPresenceBusy
                          : l.recsPresenceIdle,
                  style: AppTheme.mono(
                    size: 10,
                    color: friend.isFree ? AppColors.live : AppColors.ink3,
                    letterSpacing: 1.2,
                    weight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (friend.matchPercent != null && friend.matchPercent! > 0)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Text('${friend.matchPercent}%',
                  style: AppTheme.mono(
                      size: 12, color: AppColors.amber, weight: FontWeight.w600)),
            ),
          InkResponse(
            onTap: onToggle,
            radius: 18,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: selected ? AppColors.amber : AppColors.surface2,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                selected ? Icons.check_rounded : Icons.add_rounded,
                size: 16,
                color: selected ? AppColors.amberInk : AppColors.ink2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
