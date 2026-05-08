import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/junto_primitives.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/recs_provider.dart';
import '../widgets/movie_card.dart';
import '../widgets/venn_painter.dart';

class RecsMatchScreen extends ConsumerWidget {
  final int friendId;
  const RecsMatchScreen({super.key, required this.friendId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final asyncMatch = ref.watch(recsMatchProvider(friendId));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: asyncMatch.when(
          loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          error: (_, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(l.sessionsHistoryError,
                  style: AppTheme.text(size: 14, color: AppColors.ink3)),
            ),
          ),
          data: (m) => _MatchBody(match: m),
        ),
      ),
    );
  }
}

class _MatchBody extends ConsumerWidget {
  final RecsMatch match;
  const _MatchBody({required this.match});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final pct = match.matchPercent;
    const hueA = 75; // self
    final hueB = match.friend.username.hashCode.abs() % 360;
    final me = ref.watch(currentUserProvider)?.username ?? '?';

    return Column(
      children: [
        // Top bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              _CircleIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => context.pop(),
              ),
              Expanded(
                child: Center(
                  child: MonoLabel(
                    l.recsMatchHeader,
                    color: AppColors.ink3,
                    letterSpacing: 1.8,
                  ),
                ),
              ),
              const SizedBox(width: 36),
            ],
          ),
        ),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
            children: [
              // Venn diagram
              Center(
                child: SizedBox(
                  width: 240,
                  height: 130,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(
                        child: CustomPaint(painter: VennPainter(hueA: hueA, hueB: hueB)),
                      ),
                      Positioned(
                        left: 14,
                        top: 50,
                        child: JuntoAvatar(
                          name: me,
                          size: 40,
                          hue: hueA,
                        ),
                      ),
                      Positioned(
                        right: 14,
                        top: 50,
                        child: JuntoAvatar(
                          name: match.friend.username,
                          size: 40,
                          hue: hueB,
                          imageUrl: match.friend.avatarUrl,
                        ),
                      ),
                      if (pct != null) VennMatchBadge(percent: pct),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: Text(
                  l.recsMatchPairLabel(match.friend.username),
                  style: AppTheme.display(size: 22, weight: FontWeight.w600, letterSpacing: -0.5),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  pct == null
                      ? l.recsMatchInsufficient
                      : l.recsMatchOverlapStat(pct, match.sharedTags.length),
                  textAlign: TextAlign.center,
                  style: AppTheme.text(size: 13, color: AppColors.ink3),
                ),
              ),

              if (match.sharedTags.isNotEmpty) ...[
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: MonoLabel(l.recsMatchSharedTags,
                      color: AppColors.ink3, letterSpacing: 1.8),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final t in match.sharedTags) _Chip(label: '✓ $t', solid: true),
                      for (final t in match.notSharedTags) _Chip(label: t),
                    ],
                  ),
                ),
              ],

              if (match.titles.isNotEmpty) ...[
                const SizedBox(height: 22),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: MonoLabel(l.recsMatchListLabel,
                      color: AppColors.ink3, letterSpacing: 1.8),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      for (var i = 0; i < match.titles.length; i++)
                        Container(
                          decoration: BoxDecoration(
                            border: i < match.titles.length - 1
                                ? const Border(bottom: BorderSide(color: AppColors.hairline))
                                : null,
                          ),
                          child: MovieRowTile(
                            movie: match.titles[i].movie,
                            matchPercent: match.titles[i].matchPercent,
                            whyText: match.titles[i].why,
                            trailing: _CircleIconButton(
                              icon: Icons.add_rounded,
                              onTap: () =>
                                  context.push('/recs/title/${match.titles[i].movie.id}'),
                              size: 36,
                              fg: AppColors.amber,
                              bg: AppColors.amberDim,
                            ),
                            onTap: () =>
                                context.push('/recs/title/${match.titles[i].movie.id}'),
                          ),
                        ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),

        // Sticky CTA
        Container(
          padding: EdgeInsets.fromLTRB(
            24, 12, 24,
            12 + MediaQuery.of(context).padding.bottom,
          ),
          decoration: const BoxDecoration(
            color: AppColors.bg,
            border: Border(top: BorderSide(color: AppColors.hairline)),
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.amber,
                foregroundColor: AppColors.amberInk,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.r2),
                ),
              ),
              onPressed: () {
                // The match screen doesn't bind to a specific movie —
                // CTA bounces user to the top recommended title.
                if (match.titles.isNotEmpty) {
                  context.push('/recs/title/${match.titles.first.movie.id}');
                }
              },
              child: Text(
                l.recsMatchCta(match.friend.username),
                style: AppTheme.text(
                    size: 15, weight: FontWeight.w600, color: AppColors.amberInk),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool solid;
  const _Chip({required this.label, this.solid = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: solid ? AppColors.amberDim : Colors.transparent,
        border: Border.all(color: solid ? Colors.transparent : AppColors.hairline),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTheme.text(
          size: 11,
          weight: FontWeight.w600,
          color: solid ? AppColors.amber : AppColors.ink2,
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final Color? bg;
  final Color? fg;
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.size = 36,
    this.bg,
    this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: size / 2 + 6,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bg ?? AppColors.surface,
          shape: BoxShape.circle,
          border: bg == null ? Border.all(color: AppColors.hairline) : null,
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: fg ?? AppColors.ink),
      ),
    );
  }
}

