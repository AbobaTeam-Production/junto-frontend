import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

/// Striped placeholder used while a poster URL is loading or absent.
/// Matches the design's "contact-sheet" aesthetic — diagonal bands of
/// two close shades, mono-uppercase label optional.
class PosterPlaceholder extends StatelessWidget {
  final String label;
  final double? width;
  final double? height;
  final double? aspectRatio;
  final double radius;
  final PosterMood mood;

  const PosterPlaceholder({
    super.key,
    this.label = '',
    this.width,
    this.height,
    this.aspectRatio,
    this.radius = 12,
    this.mood = PosterMood.amber,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _moodColours(mood);
    final body = Container(
      width: width,
      height: aspectRatio == null ? height : null,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.base, colors.stripe, colors.base, colors.stripe],
          stops: const [0.0, 0.001, 0.002, 0.003],
          tileMode: TileMode.repeated,
        ),
        color: colors.base,
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: const Alignment(-1, -1),
          end: const Alignment(1, 1),
          tileMode: TileMode.repeated,
          colors: [colors.base, colors.base, colors.stripe, colors.stripe],
          stops: const [0.0, 0.012, 0.012, 0.024],
        ),
      ),
      alignment: Alignment.bottomLeft,
      padding: const EdgeInsets.all(10),
      child: label.isEmpty
          ? null
          : Text(
              label,
              style: AppTheme.mono(
                size: 9,
                color: AppColors.ink3,
                letterSpacing: 0.5,
                weight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
    );
    return aspectRatio == null
        ? body
        : AspectRatio(aspectRatio: aspectRatio!, child: body);
  }

  _MoodColours _moodColours(PosterMood m) {
    switch (m) {
      case PosterMood.amber:
        return const _MoodColours(Color(0xFF3A2E1F), Color(0xFF4F3E2A));
      case PosterMood.cool:
        return const _MoodColours(Color(0xFF1F2A3A), Color(0xFF2A3851));
      case PosterMood.rose:
        return const _MoodColours(Color(0xFF3A1F25), Color(0xFF4F2A33));
      case PosterMood.neutral:
        return const _MoodColours(Color(0xFF2A2A2D), Color(0xFF3A3A3E));
    }
  }
}

enum PosterMood { amber, cool, rose, neutral }

class _MoodColours {
  final Color base;
  final Color stripe;
  const _MoodColours(this.base, this.stripe);
}

/// Picks a poster mood from genre keywords — keeps the contact-sheet
/// vibe while reflecting the film's tone without a per-row prop drill.
PosterMood pickPosterMood(List<String> genres) {
  final joined = genres.join(' ').toLowerCase();
  if (joined.contains('мелодрам') || joined.contains('romance')) {
    return PosterMood.rose;
  }
  if (joined.contains('фант') ||
      joined.contains('детект') ||
      joined.contains('триллер') ||
      joined.contains('криминал')) {
    return PosterMood.cool;
  }
  if (joined.contains('драм') || joined.contains('history') || joined.contains('биограф')) {
    return PosterMood.amber;
  }
  return PosterMood.neutral;
}
