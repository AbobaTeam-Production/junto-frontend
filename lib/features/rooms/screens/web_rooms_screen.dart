import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/junto_primitives.dart';
import '../../home/widgets/create_room_sheet.dart';
import '../../home/widgets/join_room_sheet.dart';
import '../providers/room_providers.dart';

enum _Filter { all, live, mine, archive }

class WebRoomsScreen extends ConsumerStatefulWidget {
  const WebRoomsScreen({super.key});

  @override
  ConsumerState<WebRoomsScreen> createState() => _WebRoomsScreenState();
}

class _WebRoomsScreenState extends ConsumerState<WebRoomsScreen> {
  _Filter _filter = _Filter.all;

  List<RoomInfo> _apply(List<RoomInfo> rooms) {
    switch (_filter) {
      case _Filter.live:
        return rooms.where((r) => r.isActive).toList();
      case _Filter.archive:
        return rooms.where((r) => !r.isActive).toList();
      case _Filter.mine:
      case _Filter.all:
        return rooms;
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomsAsync = ref.watch(myRoomsProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(40, 32, 40, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(
                count: roomsAsync.maybeWhen(
                  data: (rooms) => rooms.length,
                  orElse: () => 0,
                ),
                onJoin: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const JoinRoomSheet(),
                ),
                onCreate: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const CreateRoomSheet(),
                ),
              ),
              const SizedBox(height: 24),
              roomsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.amber),
                  ),
                ),
                error: (e, _) => _ErrorBlock(
                  onRetry: () => ref.invalidate(myRoomsProvider),
                ),
                data: (rooms) {
                  final liveCount = rooms.where((r) => r.isActive).length;
                  final filtered = _apply(rooms);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _FilterRow(
                        active: _filter,
                        counts: {
                          _Filter.all: rooms.length,
                          _Filter.live: liveCount,
                          _Filter.mine: rooms.length,
                          _Filter.archive: rooms.where((r) => !r.isActive).length,
                        },
                        onChanged: (f) => setState(() => _filter = f),
                      ),
                      const SizedBox(height: 18),
                      if (filtered.isEmpty)
                        const _EmptyState()
                      else
                        _RoomsTable(rooms: filtered),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int count;
  final VoidCallback onJoin;
  final VoidCallback onCreate;

  const _Header({
    required this.count,
    required this.onJoin,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MonoLabel(
                '${count.toString().padLeft(2, '0')} / комнат',
                color: AppColors.ink3,
                letterSpacing: 2,
              ),
              const SizedBox(height: 6),
              Text(
                'Комнаты',
                style: AppTheme.display(
                  size: 44,
                  weight: FontWeight.w600,
                  letterSpacing: -1.2,
                ),
              ),
            ],
          ),
        ),
        _SecondaryPill(
          label: 'Войти по коду',
          icon: Icons.groups_2_outlined,
          onTap: onJoin,
        ),
        const SizedBox(width: 10),
        _AmberPill(
          label: 'Новая комната',
          icon: Icons.add_rounded,
          onTap: onCreate,
        ),
      ],
    );
  }
}

class _SecondaryPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _SecondaryPill({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.hairline),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: AppColors.ink2),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTheme.text(
                  size: 13,
                  color: AppColors.ink2,
                  weight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmberPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _AmberPill({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.amber,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: AppColors.amberInk),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTheme.text(
                  size: 13,
                  weight: FontWeight.w600,
                  color: AppColors.amberInk,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final _Filter active;
  final Map<_Filter, int> counts;
  final ValueChanged<_Filter> onChanged;

  const _FilterRow({
    required this.active,
    required this.counts,
    required this.onChanged,
  });

  String _label(_Filter f) {
    switch (f) {
      case _Filter.all:
        return 'Все · ${counts[f] ?? 0}';
      case _Filter.live:
        return 'Идут · ${counts[f] ?? 0}';
      case _Filter.mine:
        return 'Мои · ${counts[f] ?? 0}';
      case _Filter.archive:
        return 'Архив';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final f in _Filter.values) ...[
          _Pill(
            label: _label(f),
            on: f == active,
            onTap: () => onChanged(f),
          ),
          if (f != _Filter.values.last) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool on;
  final VoidCallback onTap;
  const _Pill({required this.label, required this.on, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: on ? AppColors.ink : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: on ? Colors.transparent : AppColors.hairline,
            ),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: AppTheme.text(
              size: 13,
              weight: FontWeight.w500,
              color: on ? AppColors.bg : AppColors.ink2,
            ),
          ),
        ),
      ),
    );
  }
}

class _RoomsTable extends StatelessWidget {
  final List<RoomInfo> rooms;
  const _RoomsTable({required this.rooms});

  static const _columns = [
    _Col('', 88),
    _Col('Название · код', null),
    _Col('Хост', 160),
    _Col('Источник', 130),
    _Col('Запущена', 110),
    _Col('Пинг', 60, alignRight: true),
    _Col('', 36),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(AppTheme.r2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.r2),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.hairline)),
              ),
              child: Row(
                children: [
                  for (final c in _columns) _colSlot(c, _headerText(c.label)),
                ],
              ),
            ),
            for (var i = 0; i < rooms.length; i++)
              _RoomTableRow(
                room: rooms[i],
                mood: _moodFor(i),
                hostHue: _hueFor(i),
                isLast: i == rooms.length - 1,
                onTap: () => context.push('/room/${rooms[i].id}'),
              ),
          ],
        ),
      ),
    );
  }

  static Widget _headerText(String label) {
    if (label.isEmpty) return const SizedBox.shrink();
    return MonoLabel(label, color: AppColors.ink4, letterSpacing: 1.6, size: 9);
  }

  static Widget _colSlot(_Col c, Widget child) {
    if (c.width == null) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Align(
            alignment: c.alignRight ? Alignment.centerRight : Alignment.centerLeft,
            child: child,
          ),
        ),
      );
    }
    return SizedBox(
      width: c.width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Align(
          alignment: c.alignRight ? Alignment.centerRight : Alignment.centerLeft,
          child: child,
        ),
      ),
    );
  }

  PosterMood _moodFor(int i) {
    const moods = [
      PosterMood.amber,
      PosterMood.cool,
      PosterMood.rose,
      PosterMood.neutral,
    ];
    return moods[i % moods.length];
  }

  int _hueFor(int i) {
    const palette = [30, 220, 340, 75];
    return palette[i % palette.length];
  }
}

class _Col {
  final String label;
  final double? width;
  final bool alignRight;
  const _Col(this.label, this.width, {this.alignRight = false});
}

class _RoomTableRow extends StatelessWidget {
  final RoomInfo room;
  final PosterMood mood;
  final int hostHue;
  final bool isLast;
  final VoidCallback onTap;

  const _RoomTableRow({
    required this.room,
    required this.mood,
    required this.hostHue,
    required this.isLast,
    required this.onTap,
  });

  String _started() {
    final delta = DateTime.now().difference(room.expiresAt.subtract(
        const Duration(hours: 12))); // expires_at sits 12h after creation
    if (!room.isActive) return '—';
    final m = delta.inMinutes;
    if (m < 1) return 'только что';
    if (m < 60) return '$m мин назад';
    final h = delta.inHours;
    if (h < 24) return '$h ч назад';
    return '${delta.inDays} дн назад';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : const Border(bottom: BorderSide(color: AppColors.hairline)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 88,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: JuntoPoster(
                    width: 64,
                    height: 64,
                    mood: mood,
                    radius: 10,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          if (room.isActive)
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppColors.live,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'LIVE · ${room.memberCount} в эфире',
                                  style: AppTheme.mono(
                                    size: 9,
                                    color: AppColors.live,
                                    letterSpacing: 1.4,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          else
                            const MonoLabel(
                              'OFFLINE',
                              color: AppColors.ink4,
                              size: 9,
                              letterSpacing: 1.4,
                            ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.amberDim,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              room.inviteCode,
                              style: AppTheme.mono(
                                size: 11,
                                color: AppColors.amber,
                                letterSpacing: 2,
                                weight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Комната ${room.inviteCode}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.text(
                          size: 15,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: 160,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      JuntoAvatar(name: room.hostName, size: 22, hue: hostHue),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          room.hostName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.text(
                            size: 13,
                            color: AppColors.ink2,
                            weight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: 130,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'WATCHPARTY',
                    style: AppTheme.mono(
                      size: 11,
                      color: AppColors.ink3,
                      letterSpacing: 1.2,
                      weight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 110,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    _started(),
                    style: AppTheme.text(
                      size: 12,
                      color: AppColors.ink3,
                      weight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 60,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      room.isActive ? '—' : '—',
                      style: AppTheme.mono(
                        size: 12,
                        color: AppColors.ink4,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(
                width: 36,
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.ink3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(AppTheme.r2),
      ),
      child: Center(
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
              child: const Icon(
                Icons.live_tv_outlined,
                color: AppColors.ink3,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Пока нет комнат',
              style: AppTheme.display(size: 18, weight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Создай свою или войди по коду от друга.',
              textAlign: TextAlign.center,
              style: AppTheme.text(
                size: 14,
                color: AppColors.ink2,
                weight: FontWeight.w400,
              ),
            ),
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
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(AppTheme.r2),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.ink3,
            ),
            const SizedBox(height: 12),
            Text(
              'Не удалось загрузить комнаты',
              style: AppTheme.text(
                size: 14,
                color: AppColors.ink2,
                weight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('Попробовать снова')),
          ],
        ),
      ),
    );
  }
}
