import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/room_providers.dart';

class RoomsScreen extends ConsumerWidget {
  const RoomsScreen({super.key});

  void _confirmDelete(BuildContext context, WidgetRef ref, RoomInfo room) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Удалить комнату?'),
        content: Text('Комната ${room.inviteCode} будет закрыта.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await deleteRoom(ref, room.id);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка: $e')),
                  );
                }
              }
            },
            child: const Text('Удалить', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(myRoomsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Комнаты')),
      body: roomsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.textHint),
              const SizedBox(height: 12),
              Text(
                'Не удалось загрузить комнаты',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => ref.invalidate(myRoomsProvider),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
        data: (rooms) {
          if (rooms.isEmpty) return _buildEmptyState(context);
          return RefreshIndicator(
            onRefresh: () => ref.read(myRoomsProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: rooms.length,
              itemBuilder: (context, index) {
                final room = rooms[index];
                return Dismissible(
                  key: ValueKey(room.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) async {
                    _confirmDelete(context, ref, room);
                    return false; // dialog handles deletion
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.delete_outline, color: AppColors.error),
                  ),
                  child: _RoomCard(
                    room: room,
                    onDelete: () => _confirmDelete(context, ref, room),
                  ),
                ).animate()
                    .fadeIn(duration: 400.ms, delay: (index * 80).ms)
                    .slideY(begin: 0.05, end: 0, duration: 400.ms);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.videocam_off_outlined,
                size: 36,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Нет активных комнат',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Создайте комнату или присоединитесь\nпо коду приглашения',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        )
            .animate()
            .fadeIn(duration: 500.ms)
            .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final RoomInfo room;
  final VoidCallback? onDelete;

  const _RoomCard({required this.room, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/room/${room.id}'),
          onLongPress: onDelete,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Status indicator + icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: room.isActive
                        ? AppColors.success.withValues(alpha: 0.12)
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    room.isActive
                        ? Icons.videocam_rounded
                        : Icons.videocam_off_outlined,
                    color: room.isActive
                        ? AppColors.success
                        : AppColors.textHint,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Комната ${room.inviteCode}',
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 14,
                            color: AppColors.textHint,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${room.memberCount} участник${_pluralize(room.memberCount)}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Хост: ${room.hostName}',
                            style: const TextStyle(
                              color: AppColors.textHint,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Code chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    room.inviteCode,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),

                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textHint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _pluralize(int n) {
    if (n == 1) return '';
    if (n >= 2 && n <= 4) return 'а';
    return 'ов';
  }
}
