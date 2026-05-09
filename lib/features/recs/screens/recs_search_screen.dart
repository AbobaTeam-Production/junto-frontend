// Catalog search. Hits /api/recs/search/ which checks local titles
// first and falls back to TMDb if the local catalog has <6 hits.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/junto_primitives.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/recs_provider.dart';
import '../widgets/movie_card.dart';

class RecsSearchScreen extends ConsumerStatefulWidget {
  const RecsSearchScreen({super.key});

  @override
  ConsumerState<RecsSearchScreen> createState() => _RecsSearchScreenState();
}

class _RecsSearchScreenState extends ConsumerState<RecsSearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _query = text.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final canSearch = _query.length >= 2;
    final asyncResults =
        canSearch ? ref.watch(recsSearchProvider(_query)) : null;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: AppColors.ink,
                    // Cold-load (deep-link or browser refresh) leaves
                    // the navigator without a previous page, so
                    // `pop()` would do nothing — fall back to /home.
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go('/home'),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      onChanged: _onChanged,
                      style: AppTheme.text(size: 16, color: AppColors.ink),
                      decoration: InputDecoration(
                        hintText: l.recsSearchPlaceholder,
                        hintStyle: AppTheme.text(
                            size: 16, color: AppColors.ink4),
                        border: InputBorder.none,
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: AppColors.ink3),
                        suffixIcon: _controller.text.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close_rounded,
                                    color: AppColors.ink3),
                                onPressed: () {
                                  _controller.clear();
                                  setState(() => _query = '');
                                },
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.hairline),
            Expanded(
              child: !canSearch
                  ? _CenteredHint(text: l.recsSearchHint)
                  : asyncResults!.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      error: (_, _) => _CenteredHint(text: l.sessionsHistoryError),
                      data: (movies) => movies.isEmpty
                          ? _CenteredHint(text: l.recsSearchNoResults)
                          : LayoutBuilder(
                              builder: (ctx, cons) {
                                // Target a poster ~140 px wide on mobile,
                                // ~160 px on desktop. With max-extent
                                // grid the column count auto-scales
                                // with the viewport — 3 cols at 360 px,
                                // 8 at 1440 px — instead of stretching
                                // 3 huge tiles across the screen.
                                final w = cons.maxWidth;
                                final maxExtent = w < 600 ? 160.0 : 200.0;
                                return GridView.builder(
                                  padding: const EdgeInsets.all(16),
                                  gridDelegate:
                                      SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: maxExtent,
                                    // 2:3 poster + 2 lines title + year =
                                    // ~0.50 aspect.
                                    childAspectRatio: 0.50,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 16,
                                  ),
                                  itemCount: movies.length,
                                  itemBuilder: (ctx, i) {
                                    final m = movies[i];
                                    return MovieCardVertical(
                                      movie: m,
                                      posterWidth: double.infinity,
                                      onTap: () =>
                                          context.push('/recs/title/${m.id}'),
                                    );
                                  },
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenteredHint extends StatelessWidget {
  final String text;
  const _CenteredHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_rounded, size: 36, color: AppColors.ink4),
            const SizedBox(height: 12),
            MonoLabel(
              text,
              color: AppColors.ink3,
              letterSpacing: 1.4,
            ),
          ],
        ),
      ),
    );
  }
}
