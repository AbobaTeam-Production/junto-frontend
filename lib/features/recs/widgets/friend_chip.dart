import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/junto_primitives.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/recs_provider.dart';

/// Small card used in the "Свободны сейчас" strip on the recs feed.
/// Border colour signals presence — green for free, hairline otherwise.
class FriendChip extends StatelessWidget {
  final RecsFriend friend;
  final VoidCallback? onTap;
  final int hue;

  const FriendChip({
    super.key,
    required this.friend,
    this.onTap,
    this.hue = 75,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isFree = friend.isFree;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.r2),
      child: Container(
        width: 92,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.r2),
          border: Border.all(
            color: isFree ? AppColors.live : AppColors.hairline,
          ),
        ),
        child: Opacity(
          opacity: friend.presence == 'idle' ? 0.55 : 1,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              JuntoAvatar(
                name: friend.username,
                size: 36,
                hue: hue,
                online: isFree,
                imageUrl: friend.avatarUrl,
              ),
              const SizedBox(height: 6),
              Text(
                friend.username,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.text(size: 12, weight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                _presenceLabel(friend.presence, l),
                style: AppTheme.mono(
                  size: 9,
                  weight: FontWeight.w500,
                  letterSpacing: 1.2,
                  color: isFree ? AppColors.live : AppColors.ink3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _presenceLabel(String presence, AppLocalizations l) {
    switch (presence) {
      case 'free':
        return l.recsPresenceFree;
      case 'busy':
        return l.recsPresenceBusy;
      default:
        return l.recsPresenceIdle;
    }
  }
}
