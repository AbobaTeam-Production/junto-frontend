import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/junto_primitives.dart';
import '../../home/widgets/create_room_sheet.dart';
import '../providers/room_providers.dart';
import '../../../l10n/app_localizations.dart';

class RoomsScreen extends ConsumerStatefulWidget {
  const RoomsScreen({super.key});

  @override
  ConsumerState<RoomsScreen> createState() => _RoomsScreenState();
}

enum _RoomsFilter { all, active, mine, archive }

class _RoomsScreenState extends ConsumerState<RoomsScreen> {
  _RoomsFilter _filter = _RoomsFilter.all;

  String _filterLabel(_RoomsFilter f, AppLocalizations l) {
    switch (f) {
      case _RoomsFilter.all:
        return l.roomsFilterAll;
      case _RoomsFilter.active:
        return l.roomsFilterActive;
      case _RoomsFilter.mine:
        return l.roomsFilterMine;
      case _RoomsFilter.archive:
        return l.roomsFilterArchive;
    }
  }

  void _confirmDelete(BuildContext context, RoomInfo room) {
    final l = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.r2)),
        title: Text(l.roomsDeleteTitle, style: AppTheme.display(size: 18, weight: FontWeight.w600)),
        content: Text(l.roomsDeleteMessage(room.inviteCode),
            style: AppTheme.text(size: 14, color: AppColors.ink2, weight: FontWeight.w400)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.roomsDeleteCancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await deleteRoom(ref, room.id);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.roomsDeleteError(e.toString()))),
                  );
                }
              }
            },
            child: Text(l.roomsDeleteConfirm, style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  void _showCreateRoom() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreateRoomSheet(),
    );
  }

  List<RoomInfo> _applyFilter(List<RoomInfo> rooms) {
    switch (_filter) {
      case _RoomsFilter.active:
        return rooms.where((r) => r.isActive).toList();
      case _RoomsFilter.archive:
        return rooms.where((r) => !r.isActive).toList();
      case _RoomsFilter.mine:
      case _RoomsFilter.all:
        return rooms;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final roomsAsync = ref.watch(myRoomsProvider);
    const filters = _RoomsFilter.values;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header — mono "04 / комнат" + display "Комнаты" + amber "Новая"
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        roomsAsync.maybeWhen(
                          data: (rooms) => MonoLabel(
                            '${rooms.length.toString().padLeft(2, '0')} / ${l.roomsCountLabel}',
                            color: AppColors.ink3,
                            letterSpacing: 1.8,
                          ),
                          orElse: () => MonoLabel('00 / ${l.roomsCountLabel}',
                              color: AppColors.ink3, letterSpacing: 1.8),
                        ),
                        const SizedBox(height: 4),
                        Text(l.roomsTitle,
                            style: AppTheme.display(
                                size: 32, weight: FontWeight.w600, letterSpacing: -0.8)),
                      ],
                    ),
                  ),
                  _NewRoomPill(onTap: _showCreateRoom),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Filter pills
            SizedBox(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: filters.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  final f = filters[i];
                  final on = f == _filter;
                  return GestureDetector(
                    onTap: () => setState(() => _filter = f),
                    child: AnimatedContainer(
                      duration: 200.ms,
                      padding: const EdgeInsets.fromLTRB(14, 7, 14, 7),
                      decoration: BoxDecoration(
                        color: on ? AppColors.ink : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: on ? Colors.transparent : AppColors.hairline,
                        ),
                      ),
                      child: Text(
                        _filterLabel(f, l),
                        style: AppTheme.text(
                          size: 12,
                          weight: FontWeight.w500,
                          color: on ? AppColors.bg : AppColors.ink2,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // List
            Expanded(
              child: roomsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator(color: AppColors.amber)),
                error: (err, _) => _ErrorBlock(onRetry: () => ref.invalidate(myRoomsProvider)),
                data: (rooms) {
                  final filtered = _applyFilter(rooms);
                  if (filtered.isEmpty) return _emptyState();
                  return RefreshIndicator(
                    color: AppColors.amber,
                    backgroundColor: AppColors.surface,
                    onRefresh: () => ref.read(myRoomsProvider.notifier).refresh(),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final room = filtered[index];
                        final mood = _moodFor(index);
                        final hue = _hueFor(index);
                        return Dismissible(
                          key: ValueKey(room.id),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) async {
                            _confirmDelete(context, room);
                            return false;
                          },
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(AppTheme.r2),
                            ),
                            child: const Icon(Icons.delete_outline_rounded,
                                color: AppColors.danger),
                          ),
                          child: _RoomRow(
                            room: room,
                            mood: mood,
                            hostHue: hue,
                            isLast: index == filtered.length - 1,
                            onTap: () => context.push('/room/${room.id}'),
                            onDelete: () => _confirmDelete(context, room),
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 350.ms, delay: (index * 60).ms)
                            .slideY(begin: 0.04, end: 0, duration: 350.ms);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  PosterMood _moodFor(int i) {
    switch (i % 4) {
      case 0:
        return PosterMood.amber;
      case 1:
        return PosterMood.cool;
      case 2:
        return PosterMood.rose;
      default:
        return PosterMood.neutral;
    }
  }

  int _hueFor(int i) {
    const palette = [30, 220, 340, 75];
    return palette[i % palette.length];
  }

  Widget _emptyState() {
    final l = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.surface2,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.hairline),
              ),
              child: const Icon(Icons.live_tv_outlined,
                  color: AppColors.ink3, size: 36),
            ),
            const SizedBox(height: 20),
            Text(l.roomsEmptyState,
                style: AppTheme.display(size: 18, weight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(l.roomsEmptyDesc,
                textAlign: TextAlign.center,
                style: AppTheme.text(size: 14, color: AppColors.ink2, weight: FontWeight.w400, height: 1.4)),
          ],
        ),
      ),
    );
  }
}

class _NewRoomPill extends StatelessWidget {
  final VoidCallback onTap;
  const _NewRoomPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.amber,
      shape: const StadiumBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 14, 0),
          child: SizedBox(
            height: 38,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_rounded, color: AppColors.amberInk, size: 18),
                const SizedBox(width: 4),
                Text(AppLocalizations.of(context).roomsNewButton,
                    style: AppTheme.text(
                      size: 13,
                      weight: FontWeight.w600,
                      color: AppColors.amberInk,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoomRow extends StatelessWidget {
  final RoomInfo room;
  final PosterMood mood;
  final int hostHue;
  final bool isLast;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _RoomRow({
    required this.room,
    required this.mood,
    required this.hostHue,
    required this.isLast,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return InkWell(
      onTap: onTap,
      onLongPress: onDelete,
      child: Container(
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(bottom: BorderSide(color: AppColors.hairline)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            JuntoPoster(width: 64, height: 64, mood: mood, radius: 12),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (room.isActive)
                        const LiveChip(compact: true)
                      else
                        const MonoLabel('OFFLINE', color: AppColors.ink4, size: 9, letterSpacing: 1.4),
                      const SizedBox(width: 10),
                      Text(
                        room.inviteCode,
                        style: AppTheme.mono(
                          size: 11,
                          color: AppColors.amber,
                          letterSpacing: 2,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${l.homeRoomLabel} ${room.inviteCode}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.text(size: 15, weight: FontWeight.w600, color: AppColors.ink),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      JuntoAvatar(name: room.hostName, size: 14, hue: hostHue),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '${room.hostName} · ${room.memberCount} ${l.roomsOnline}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.text(
                              size: 12, color: AppColors.ink3, weight: FontWeight.w400),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.ink3, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorBlock({required this.onRetry});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.ink3),
          const SizedBox(height: 12),
          Text(l.roomsLoadError,
              style: AppTheme.text(size: 14, color: AppColors.ink2, weight: FontWeight.w500)),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: Text(l.roomsLoadRetry)),
        ],
      ),
    );
  }
}
