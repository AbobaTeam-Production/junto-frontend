// Cold-start taste-capture screen.
//
// Shown once, right after the very first login of an account that
// has zero WatchIntent + zero MovieView. Renders 12 diverse-genre
// posters; the user taps the ones they like; we POST those ids to
// /api/recs/onboarding/taste/ which seeds WatchIntent so match% and
// why-reasons start working from day one. Tapping "Готово" or "Пропустить"
// returns to / which the router resolves to /home (or /onboarding/taste
// stays as a no-op if the user wants to come back).

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/junto_primitives.dart';
import '../../../l10n/app_localizations.dart';
import '../../recs/providers/recs_provider.dart';
import '../../recs/widgets/poster_placeholder.dart';

class OnboardingTasteScreen extends ConsumerStatefulWidget {
  const OnboardingTasteScreen({super.key});

  @override
  ConsumerState<OnboardingTasteScreen> createState() =>
      _OnboardingTasteScreenState();
}

class _OnboardingTasteScreenState extends ConsumerState<OnboardingTasteScreen> {
  final _selectedIds = <int>{};
  bool _submitting = false;

  Future<void> _submit({required List<int> ids}) async {
    setState(() => _submitting = true);
    try {
      await submitTasteSignals(ref, ids);
      // Refresh profile so router sees has_taste_signal=true and
      // the redirect rule stops bouncing us back here.
      await ref.read(authStateProvider.notifier).refreshProfile();
      if (!mounted) return;
      context.go('/home');
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).sessionsHistoryError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final asyncMovies = ref.watch(tasteOnboardingProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: asyncMovies.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          error: (_, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(l.sessionsHistoryError,
                  style: AppTheme.text(size: 14, color: AppColors.ink3)),
            ),
          ),
          data: (movies) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Row(
                  children: [
                    const Spacer(),
                    TextButton(
                      onPressed: _submitting ? null : () => _submit(ids: const []),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.ink3,
                      ),
                      child: Text(l.tasteOnboardingSkip),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MonoLabel('TASTE', color: AppColors.amber, letterSpacing: 2.0),
                    const SizedBox(height: 8),
                    Text(
                      l.tasteOnboardingTitle,
                      style: AppTheme.display(
                        size: 32,
                        weight: FontWeight.w600,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l.tasteOnboardingSubtitle,
                      style: AppTheme.text(
                          size: 14, color: AppColors.ink2, height: 1.45),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.66, // 2/3 poster ratio
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: movies.length,
                  itemBuilder: (ctx, i) {
                    final movie = movies[i];
                    final selected = _selectedIds.contains(movie.id);
                    return _TasteCard(
                      movie: movie,
                      selected: selected,
                      onTap: () => setState(() {
                        if (selected) {
                          _selectedIds.remove(movie.id);
                        } else {
                          _selectedIds.add(movie.id);
                        }
                      }),
                    );
                  },
                ).animate().fadeIn(duration: 350.ms),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                    24, 8, 24, 16 + MediaQuery.of(context).padding.bottom),
                child: Row(
                  children: [
                    Text(
                      l.tasteOnboardingHint(_selectedIds.length),
                      style: AppTheme.mono(
                          size: 11,
                          color: AppColors.ink3,
                          letterSpacing: 1.4,
                          weight: FontWeight.w500),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.amber,
                        foregroundColor: AppColors.amberInk,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                        shape: const StadiumBorder(),
                      ),
                      onPressed: _submitting
                          ? null
                          : () => _submit(ids: _selectedIds.toList()),
                      child: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.amberInk),
                            )
                          : Text(
                              l.tasteOnboardingCta,
                              style: AppTheme.text(
                                size: 15,
                                weight: FontWeight.w600,
                                color: AppColors.amberInk,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TasteCard extends StatelessWidget {
  final RecsMovie movie;
  final bool selected;
  final VoidCallback onTap;
  const _TasteCard({
    required this.movie,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final url = movie.posterPreviewUrl ?? movie.posterUrl;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.amber : Colors.transparent,
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: url != null && url.isNotEmpty
                    ? Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => PosterPlaceholder(
                          mood: pickPosterMood(movie.genres),
                          label: movie.titleRu,
                        ),
                      )
                    : PosterPlaceholder(
                        mood: pickPosterMood(movie.genres),
                        label: movie.titleRu,
                      ),
              ),
            ),
            // Title strip at the bottom for posters whose artwork
            // doesn't carry the title.
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(10)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.85),
                    ],
                  ),
                ),
                child: Text(
                  movie.titleRu,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.text(
                      size: 11,
                      weight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.2),
                ),
              ),
            ),
            if (selected)
              Positioned(
                top: 6, right: 6,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: AppColors.amber,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.check_rounded,
                      size: 16, color: AppColors.amberInk),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
