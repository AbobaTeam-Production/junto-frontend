import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/junto_primitives.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/recs_provider.dart';
import '../widgets/movie_card.dart';

class RecsMoodScreen extends ConsumerWidget {
  final String slug;
  const RecsMoodScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final asyncMood = ref.watch(recsMoodProvider(slug));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: asyncMood.when(
          loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          error: (_, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(l.sessionsHistoryError,
                  style: AppTheme.text(size: 14, color: AppColors.ink3)),
            ),
          ),
          data: (m) => _MoodBody(payload: m),
        ),
      ),
    );
  }
}

class _MoodBody extends StatelessWidget {
  final RecsMoodPayload payload;
  const _MoodBody({required this.payload});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Row(
            children: [
              InkResponse(
                onTap: () => context.pop(),
                radius: 22,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.hairline),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.arrow_back_rounded,
                      size: 18, color: AppColors.ink),
                ),
              ),
              const Spacer(),
              const Icon(Icons.auto_awesome_rounded, size: 18, color: AppColors.ink2),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: MonoLabel(l.recsMoodHeader, color: AppColors.ink3, letterSpacing: 1.8),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: RichText(
            text: TextSpan(
              style: AppTheme.display(size: 30, weight: FontWeight.w600, letterSpacing: -0.7),
              children: [
                TextSpan(text: '${l.recsMoodTitle}\n'),
                TextSpan(
                  text: l.recsMoodTitleAccent(payload.mood.title.toLowerCase()),
                  style: AppTheme.display(
                    size: 30,
                    weight: FontWeight.w500,
                    color: AppColors.amber,
                  ).copyWith(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        if (payload.items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Center(
              child: Text(l.recsMoodEmpty,
                  style: AppTheme.text(size: 14, color: AppColors.ink3)),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                for (var i = 0; i < payload.items.length; i++)
                  Container(
                    decoration: BoxDecoration(
                      border: i < payload.items.length - 1
                          ? const Border(bottom: BorderSide(color: AppColors.hairline))
                          : null,
                    ),
                    child: MovieRowTile(
                      movie: payload.items[i].movie,
                      whyText: payload.items[i].whyText,
                      listIndex: i,
                      trailing: payload.items[i].movie.kpRating == null
                          ? null
                          : Text(
                              payload.items[i].movie.kpRating!.toStringAsFixed(1),
                              style: AppTheme.mono(
                                  size: 11, color: AppColors.amber, weight: FontWeight.w600),
                            ),
                      onTap: () => context.push('/recs/title/${payload.items[i].movie.id}'),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
