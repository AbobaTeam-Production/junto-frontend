import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/friends_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/junto_primitives.dart';
import '../../rooms/providers/room_providers.dart';
import '../widgets/create_room_sheet.dart';
import '../widgets/join_room_sheet.dart';

/// Desktop-Web Home dashboard. Renders inside `WebDesktopShell` so this
/// widget contributes only the content slot (greeting + create/join hero +
/// friends-watching grid + activity).
class WebHomeScreen extends ConsumerWidget {
  const WebHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final firstName = user == null
        ? 'друг'
        : user.isGuest
            ? 'Гость'
            : user.username.split(' ').first;
    final roomsAsync = ref.watch(myRoomsProvider);
    final friendsAsync = ref.watch(friendsListProvider);
    final now = TimeOfDay.now();
    final timeLabel =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final weekday = _weekdayName(DateTime.now().weekday);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(40, 32, 40, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Greeting(
                firstName: firstName,
                meta: 'Сегодня · $timeLabel · $weekday',
              ),
              const SizedBox(height: 32),
              _HeroStrip(
                onCreate: () => _showCreateRoom(context),
                onJoin: () => _showJoinRoom(context),
              ),
              const SizedBox(height: 40),
              _FriendsWatchingRail(roomsAsync: roomsAsync),
              const SizedBox(height: 40),
              _ContinueAndActivity(
                roomsAsync: roomsAsync,
                friendsAsync: friendsAsync,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _weekdayName(int wd) {
    const names = [
      'понедельник',
      'вторник',
      'среда',
      'четверг',
      'пятница',
      'суббота',
      'воскресенье',
    ];
    return names[(wd - 1).clamp(0, 6)];
  }

  void _showCreateRoom(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreateRoomSheet(),
    );
  }

  void _showJoinRoom(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const JoinRoomSheet(),
    );
  }
}

class _Greeting extends StatelessWidget {
  final String firstName;
  final String meta;
  const _Greeting({required this.firstName, required this.meta});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MonoLabel(meta, color: AppColors.ink3, letterSpacing: 2),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: AppTheme.display(
                    size: 48,
                    weight: FontWeight.w500,
                    letterSpacing: -1.4,
                    height: 1.05,
                  ),
                  children: [
                    TextSpan(text: 'Привет, $firstName. '),
                    TextSpan(
                      text: 'Что смотрим?',
                      style: AppTheme.display(
                        size: 48,
                        weight: FontWeight.w500,
                        color: AppColors.ink3,
                        letterSpacing: -1.4,
                        height: 1.05,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
            const SizedBox(width: 8),
            Text(
              'Сервер · онлайн',
              style: AppTheme.text(
                size: 12,
                color: AppColors.ink3,
                weight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroStrip extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback onJoin;
  const _HeroStrip({required this.onCreate, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    // 220 was just enough for the Create hero but the Join card with
    // its label + 6-box row + button + helper line overflowed by
    // ~24 px, jamming the button against the bottom border. 260 fits
    // both with comfortable breathing room.
    return SizedBox(
      height: 260,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 14, child: _CreateHero(onTap: onCreate)),
          const SizedBox(width: 18),
          Expanded(flex: 10, child: _JoinHero(onTap: onJoin)),
        ],
      ),
    );
  }
}

class _CreateHero extends StatelessWidget {
  final VoidCallback onTap;
  const _CreateHero({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.amber,
      borderRadius: BorderRadius.circular(AppTheme.r3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.r3),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.r3),
          child: Stack(
            children: [
              const Positioned.fill(child: ProjectorRings()),
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 28, 32, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MonoLabel(
                      'Новый сеанс',
                      color: AppColors.amberInk.withValues(alpha: 0.6),
                      letterSpacing: 2,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Создать комнату',
                      style: AppTheme.display(
                        size: 38,
                        weight: FontWeight.w600,
                        letterSpacing: -0.9,
                        color: AppColors.amberInk,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 360,
                      child: Text(
                        'Загрузите файл, вставьте magnet или ссылку. Друзья присоединятся по 6-значному коду.',
                        style: AppTheme.text(
                          size: 14,
                          color: AppColors.amberInk.withValues(alpha: 0.78),
                          weight: FontWeight.w400,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          decoration: const BoxDecoration(
                            color: AppColors.amberInk,
                            borderRadius: BorderRadius.all(Radius.circular(999)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add_rounded,
                                  color: AppColors.amber, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                'Начать сеанс',
                                style: AppTheme.text(
                                  size: 14,
                                  weight: FontWeight.w600,
                                  color: AppColors.amber,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'или перетащите .mp4 / .mkv сюда',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.text(
                              size: 12,
                              color: AppColors.amberInk.withValues(alpha: 0.7),
                              weight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JoinHero extends StatelessWidget {
  final VoidCallback onTap;
  const _JoinHero({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final placeholders = ['_', '_', '_', '_', '_', '_'];
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppTheme.r3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.r3),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.hairline),
            borderRadius: BorderRadius.circular(AppTheme.r3),
          ),
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MonoLabel(
                'Войти по коду',
                color: AppColors.ink3,
                letterSpacing: 2,
              ),
              const SizedBox(height: 6),
              Text(
                '6 символов',
                style: AppTheme.display(
                  size: 22,
                  weight: FontWeight.w600,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  for (var i = 0; i < placeholders.length; i++) ...[
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.hairline),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '',
                            style: AppTheme.mono(
                              size: 22,
                              color: AppColors.ink4,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (i < placeholders.length - 1) const SizedBox(width: 8),
                  ],
                ],
              ),
              // Spacer can collapse to 0 when the column has no
              // bounded height (e.g. card auto-sizes), which leaves
              // the Войти button glued to the code-box row. Hard
              // 22 px gap so the button always stands clear.
              const SizedBox(height: 22),
              SizedBox(
                height: 44,
                child: Material(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(999),
                    child: Center(
                      child: Text(
                        'Войти',
                        style: AppTheme.text(
                          size: 13,
                          weight: FontWeight.w600,
                          color: AppColors.bg,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Код прислал друг? Вставьте сюда.',
                textAlign: TextAlign.center,
                style: AppTheme.text(
                  size: 11,
                  color: AppColors.ink4,
                  weight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FriendsWatchingRail extends StatelessWidget {
  final AsyncValue<List<RoomInfo>> roomsAsync;
  const _FriendsWatchingRail({required this.roomsAsync});

  @override
  Widget build(BuildContext context) {
    final liveRooms = roomsAsync.maybeWhen(
      data: (rooms) => rooms.where((r) => r.isActive).toList(),
      orElse: () => const <RoomInfo>[],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            MonoLabel(
              'Сейчас смотрят друзья',
              color: AppColors.ink3,
              letterSpacing: 2,
            ),
            const Spacer(),
            InkWell(
              onTap: () => context.go('/rooms'),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Text(
                  'Все комнаты →',
                  style: AppTheme.text(
                    size: 12,
                    color: AppColors.ink3,
                    weight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (liveRooms.isEmpty)
          _EmptyRoomsState()
        else
          GridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.05,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (var i = 0; i < liveRooms.length; i++)
                _LiveRoomCard(
                  room: liveRooms[i],
                  mood: _moodFor(i),
                  hostHue: _hueFor(i),
                ),
            ],
          ),
      ],
    );
  }

  PosterMood _moodFor(int i) {
    const moods = [PosterMood.amber, PosterMood.cool, PosterMood.rose];
    return moods[i % moods.length];
  }

  int _hueFor(int i) => [30, 220, 340, 75, 160][i % 5];
}

class _LiveRoomCard extends StatelessWidget {
  final RoomInfo room;
  final PosterMood mood;
  final int hostHue;
  const _LiveRoomCard({
    required this.room,
    required this.mood,
    required this.hostHue,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppTheme.r2),
      child: InkWell(
        onTap: () => context.push('/room/${room.id}'),
        borderRadius: BorderRadius.circular(AppTheme.r2),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.hairline),
            borderRadius: BorderRadius.circular(AppTheme.r2),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  JuntoPoster(
                    label: 'POSTER · ${room.inviteCode}',
                    aspectRatio: 16 / 9,
                    mood: mood,
                    radius: 10,
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.bgDeep.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const LiveChip(),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.bgDeep.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        room.inviteCode,
                        style: AppTheme.mono(
                          size: 10,
                          color: AppColors.amber,
                          letterSpacing: 1.6,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Комната ${room.inviteCode}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.text(
                  size: 15,
                  weight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  JuntoAvatar(name: room.hostName, size: 16, hue: hostHue),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      room.hostName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.text(
                        size: 12,
                        color: AppColors.ink3,
                        weight: FontWeight.w400,
                      ),
                    ),
                  ),
                  Text(
                    ' · ',
                    style: AppTheme.text(
                      size: 12,
                      color: AppColors.ink4,
                      weight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    '${room.memberCount} в эфире',
                    style: AppTheme.text(
                      size: 12,
                      color: AppColors.ink3,
                      weight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyRoomsState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(AppTheme.r2),
        color: AppColors.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MonoLabel('Тихо', color: AppColors.ink4, letterSpacing: 2),
          const SizedBox(height: 8),
          Text(
            'Никто сейчас не смотрит. Создай комнату — друзья получат пуш.',
            style: AppTheme.text(
              size: 14,
              color: AppColors.ink2,
              weight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinueAndActivity extends StatelessWidget {
  final AsyncValue<List<RoomInfo>> roomsAsync;
  final AsyncValue<List<Friendship>> friendsAsync;
  const _ContinueAndActivity({
    required this.roomsAsync,
    required this.friendsAsync,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 14, child: _ContinueColumn()),
          const SizedBox(width: 24),
          Expanded(flex: 10, child: _ActivityColumn(friendsAsync: friendsAsync)),
        ],
      ),
    );
  }
}

class _ContinueColumn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MonoLabel('Продолжить', color: AppColors.ink3, letterSpacing: 2),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.hairline),
            borderRadius: BorderRadius.circular(AppTheme.r2),
            color: AppColors.surface,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Историю просмотра сюда',
                style: AppTheme.text(
                  size: 14,
                  color: AppColors.ink2,
                  weight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Скоро: продолжить с того места, где остановились.',
                style: AppTheme.text(
                  size: 12,
                  color: AppColors.ink4,
                  weight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActivityColumn extends StatelessWidget {
  final AsyncValue<List<Friendship>> friendsAsync;
  const _ActivityColumn({required this.friendsAsync});

  @override
  Widget build(BuildContext context) {
    final friends = friendsAsync.maybeWhen(
      data: (list) => list.where((f) => f.status == 'accepted').toList(),
      orElse: () => const <Friendship>[],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MonoLabel('Лента активности', color: AppColors.ink3, letterSpacing: 2),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.hairline),
            borderRadius: BorderRadius.circular(AppTheme.r2),
            color: AppColors.surface,
          ),
          child: friends.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'Пока тихо. Когда друг создаст комнату — событие появится здесь.',
                    style: AppTheme.text(
                      size: 13,
                      color: AppColors.ink3,
                      weight: FontWeight.w400,
                      height: 1.5,
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < friends.length && i < 5; i++)
                      _ActivityRow(
                        peer: friends[i].peer,
                        hue: [30, 220, 340, 75, 160][i % 5],
                        last: i == friends.length - 1 || i == 4,
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final FriendPeer peer;
  final int hue;
  final bool last;
  const _ActivityRow({
    required this.peer,
    required this.hue,
    required this.last,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: AppColors.hairline)),
      ),
      child: Row(
        children: [
          JuntoAvatar(
            name: peer.username,
            size: 26,
            hue: hue,
            imageUrl: peer.avatarUrl,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTheme.text(
                  size: 12,
                  color: AppColors.ink2,
                  weight: FontWeight.w400,
                  height: 1.45,
                ),
                children: [
                  TextSpan(
                    text: peer.username,
                    style: AppTheme.text(
                      size: 12,
                      color: AppColors.ink,
                      weight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(text: ' добавлен в друзей'),
                ],
              ),
            ),
          ),
          Text(
            'недавно',
            style: AppTheme.mono(
              size: 10,
              color: AppColors.ink4,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
