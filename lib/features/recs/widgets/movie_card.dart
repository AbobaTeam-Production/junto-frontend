import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/recs_provider.dart';
import 'match_badge.dart';
import 'poster_placeholder.dart';
import 'retryable_image.dart';

/// Vertical poster + title card used in the "Friend wants to watch" row.
/// Tap to open `/recs/title/<id>`.
class MovieCardVertical extends StatelessWidget {
  final RecsMovie movie;
  final int? matchPercent;
  final double posterWidth;
  final VoidCallback? onTap;

  const MovieCardVertical({
    super.key,
    required this.movie,
    this.matchPercent,
    this.posterWidth = 132,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.r2),
      child: SizedBox(
        width: posterWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 2 / 3,
                    child: _Poster(
                      url: movie.posterPreviewUrl ?? movie.posterUrl,
                      mood: pickPosterMood(movie.genres),
                      label: movie.titleRu,
                    ),
                  ),
                  if (matchPercent != null && matchPercent! > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: MatchBadge(percent: matchPercent!),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              movie.titleRu,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.text(
                  size: 13, weight: FontWeight.w600, height: 1.2),
            ),
            const SizedBox(height: 2),
            Text(
              movie.year?.toString() ?? '',
              style: AppTheme.mono(
                  size: 10, color: AppColors.ink3, weight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal row used in match / mood lists.
class MovieRowTile extends StatelessWidget {
  final RecsMovie movie;
  final String? whyText;
  final int? matchPercent;
  final int? listIndex; // for mood "01-04"
  final Widget? trailing;
  final VoidCallback? onTap;

  const MovieRowTile({
    super.key,
    required this.movie,
    this.whyText,
    this.matchPercent,
    this.listIndex,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final mood = pickPosterMood(movie.genres);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (listIndex != null)
              SizedBox(
                width: 42,
                child: Text(
                  (listIndex! + 1).toString().padLeft(2, '0'),
                  textAlign: TextAlign.right,
                  softWrap: false,
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                  style: AppTheme.display(
                      size: 26,
                      weight: FontWeight.w600,
                      color: AppColors.ink4,
                      letterSpacing: -1),
                ),
              ),
            if (listIndex != null) const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 56,
                height: 80,
                child: _Poster(
                  url: movie.posterPreviewUrl ?? movie.posterUrl,
                  mood: mood,
                  label: '',
                  fitToBox: true,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (matchPercent != null && matchPercent! > 0) ...[
                    Row(
                      children: [
                        Text(
                          '$matchPercent%',
                          style: AppTheme.mono(
                              size: 11, color: AppColors.amber, weight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                        if (movie.year != null)
                          Text(
                            movie.year.toString(),
                            style: AppTheme.mono(
                                size: 10, color: AppColors.ink4, weight: FontWeight.w500),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    movie.titleRu,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.text(
                            size: 15, weight: FontWeight.w600, height: 1.2)
                        .copyWith(letterSpacing: -0.2),
                  ),
                  if (whyText != null && whyText!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      whyText!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.text(
                          size: 12, color: AppColors.ink3, height: 1.35),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 10),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

class _Poster extends StatelessWidget {
  final String? url;
  final PosterMood mood;
  final String label;
  final bool fitToBox;
  const _Poster({
    required this.url,
    required this.mood,
    required this.label,
    this.fitToBox = false,
  });

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return RetryableNetworkImage(
        url: url!,
        fit: BoxFit.cover,
        placeholderBuilder: (_) => PosterPlaceholder(mood: mood, label: label),
      );
    }
    if (fitToBox) {
      return PosterPlaceholder(mood: mood, label: label);
    }
    return AspectRatio(
      aspectRatio: 2 / 3,
      child: PosterPlaceholder(mood: mood, label: label),
    );
  }
}
