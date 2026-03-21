import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/room_ws_provider.dart';
import '../../rooms/providers/room_providers.dart';
import 'add_media_sheet.dart';

class QueuePanel extends ConsumerWidget {
  final String roomId;
  final bool isHost;

  const QueuePanel({super.key, required this.roomId, required this.isHost});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomAsync = ref.watch(roomDetailProvider(roomId));
    final wsState = ref.watch(roomWsProvider(roomId));
    final currentHlsUrl = wsState.player.hlsUrl;

    return roomAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(
        child: Text('Не удалось загрузить', style: TextStyle(color: AppColors.textSecondary)),
      ),
      data: (data) {
        final mediaList = (data['media'] as List?) ?? [];

        return Column(
          children: [
            if (isHost)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showAddMedia(context),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Добавить в очередь'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
            if (mediaList.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'Очередь пуста',
                    style: TextStyle(color: AppColors.textHint, fontSize: 14),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: mediaList.length,
                  itemBuilder: (context, index) {
                    final item = mediaList[index] as Map<String, dynamic>;
                    final title = item['title'] as String? ?? 'Без названия';
                    final status = item['status'] as String? ?? 'processing';
                    final hlsUrl = item['hls_url'] as String?;
                    final mediaId = item['id']?.toString() ?? '';
                    final progress = item['progress'] as int? ?? 0;
                    final sourceType = item['source_type'] as String? ?? 'upload';
                    final isPlaying = hlsUrl != null && hlsUrl == currentHlsUrl;
                    final isReady = status == 'ready';
                    final isError = status == 'error';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: isPlaying
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: isHost && isReady && !isPlaying
                              ? () => _playItem(ref, mediaId, hlsUrl!, title, sourceType)
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                // Index / status icon
                                Container(
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(
                                    color: isPlaying
                                        ? AppColors.primary.withValues(alpha: 0.2)
                                        : isError
                                            ? AppColors.error.withValues(alpha: 0.1)
                                            : AppColors.card,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: isPlaying
                                        ? const Icon(Icons.play_arrow_rounded, color: AppColors.primary, size: 20)
                                        : isError
                                            ? const Icon(Icons.error_outline, color: AppColors.error, size: 18)
                                            : !isReady
                                                ? SizedBox(
                                                    width: 16, height: 16,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      value: progress > 0 ? progress / 100 : null,
                                                      color: AppColors.primary,
                                                    ),
                                                  )
                                                : Text(
                                                    '${index + 1}',
                                                    style: const TextStyle(
                                                      color: AppColors.textSecondary,
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Title
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: TextStyle(
                                          color: isPlaying ? AppColors.primary : AppColors.textPrimary,
                                          fontWeight: isPlaying ? FontWeight.w600 : FontWeight.w500,
                                          fontSize: 13,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (!isReady && !isError)
                                        Text(
                                          'Обработка: $progress%',
                                          style: const TextStyle(color: AppColors.textHint, fontSize: 11),
                                        ),
                                      if (isError)
                                        const Text(
                                          'Ошибка',
                                          style: TextStyle(color: AppColors.error, fontSize: 11),
                                        ),
                                    ],
                                  ),
                                ),
                                // Source type icon
                                Icon(
                                  sourceType == 'torrent'
                                      ? Icons.link_rounded
                                      : sourceType == 'youtube'
                                          ? Icons.play_arrow_rounded
                                          : Icons.upload_file_rounded,
                                  size: 16,
                                  color: AppColors.textHint,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  void _playItem(WidgetRef ref, String mediaId, String hlsUrl, String title, String sourceType) {
    ref.read(roomWsProvider(roomId).notifier).sendPlayMedia(
      mediaId: mediaId,
      hlsUrl: hlsUrl,
      title: title,
      sourceType: sourceType,
    );
  }

  void _showAddMedia(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddMediaSheet(roomId: roomId),
    );
  }
}
