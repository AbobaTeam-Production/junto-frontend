import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

/// Pill chip with the match% — used as overlay on posters and in
/// inline rows. Backdrop is semi-translucent dark for poster overlays;
/// the `solid` variant uses the surface tone for in-row use.
class MatchBadge extends StatelessWidget {
  final int percent;
  final String? prefix;
  final bool solid;

  const MatchBadge({
    super.key,
    required this.percent,
    this.prefix,
    this.solid = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = solid
        ? AppColors.amberDim
        : AppColors.bg.withValues(alpha: 0.85);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        prefix == null ? '$percent%' : '$prefix · $percent%',
        style: AppTheme.mono(
          size: 10,
          color: AppColors.amber,
          weight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
