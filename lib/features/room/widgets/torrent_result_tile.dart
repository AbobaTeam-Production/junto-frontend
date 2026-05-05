import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// One row in a jacred search result list.
///
/// Used by both [AddMediaSheet] and [CreateRoomSheet]; both call the same
/// `/api/media/torrent/search/` and get back identical schema, so there's
/// no reason to maintain two copies of the row layout.
class TorrentResultTile extends StatelessWidget {
  final Map<String, dynamic> result;
  final VoidCallback onTap;

  const TorrentResultTile({
    super.key,
    required this.result,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final r = result;
    final seeds = r['seeds']?.toString() ?? '0';
    final peers = r['peers']?.toString() ?? '0';
    final size = r['size']?.toString() ?? '';
    final provider = r['provider']?.toString() ?? '';
    final qualityLabel = _qualityLabel(r['quality']);
    final voice = _firstVoice(r['voices']);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              r['name']?.toString() ?? '',
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (qualityLabel != null || voice != null) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (qualityLabel != null) _Badge(qualityLabel, accent: true),
                  if (voice != null) _Badge(voice),
                ],
              ),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.arrow_upward_rounded, size: 12,
                  color: int.tryParse(seeds) != null && int.parse(seeds) > 0
                    ? AppColors.success : AppColors.textHint),
                const SizedBox(width: 2),
                Text(seeds, style: TextStyle(fontSize: 11,
                  color: int.tryParse(seeds) != null && int.parse(seeds) > 0
                    ? AppColors.success : AppColors.textHint)),
                const SizedBox(width: 10),
                const Icon(Icons.arrow_downward_rounded,
                    size: 12, color: AppColors.textSecondary),
                const SizedBox(width: 2),
                Text(peers,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(width: 10),
                const Icon(Icons.storage_rounded,
                    size: 12, color: AppColors.textSecondary),
                const SizedBox(width: 2),
                Text(size,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
                const Spacer(),
                Text(provider,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textHint)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// jacred returns `quality` as an int code. The mapping below covers the
  /// typical movie ladder; unknown values map to null so the badge is hidden.
  static String? _qualityLabel(dynamic q) {
    final n = q is num ? q.toInt() : int.tryParse('${q ?? ''}');
    if (n == null || n == 0) return null;
    return switch (n) {
      2160 => '4K',
      1080 => '1080p',
      720 => '720p',
      480 => '480p',
      360 => '360p',
      240 => '240p',
      _ => '${n}p',
    };
  }

  static String? _firstVoice(dynamic voices) {
    if (voices is List && voices.isNotEmpty) {
      final first = voices.first?.toString();
      if (first != null && first.isNotEmpty) return first;
    }
    return null;
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final bool accent;
  const _Badge(this.text, {this.accent = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: accent
            ? AppColors.primary.withValues(alpha: 0.15)
            : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: accent
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.divider,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: accent ? AppColors.primary : AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
