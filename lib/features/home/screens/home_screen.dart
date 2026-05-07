import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/junto_primitives.dart';
import '../../rooms/providers/room_providers.dart';
import '../widgets/create_room_sheet.dart';
import '../widgets/join_room_sheet.dart';
import '../../../l10n/app_localizations.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider);
    final firstName = user == null
        ? 'друг'
        : user.isGuest
            ? l.profileGuestLabel
            : user.username.split(' ').first;
    final now = TimeOfDay.now();
    final timeLabel =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final dateLabel = 'Сегодня · $timeLabel';

    final roomsAsync = ref.watch(myRoomsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Header — date label + bell + avatar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MonoLabel(dateLabel, color: AppColors.ink3, letterSpacing: 1.8),
                        const SizedBox(height: 2),
                        Text('Junto',
                            style: AppTheme.display(size: 24, weight: FontWeight.w600, letterSpacing: -0.4)),
                      ],
                    ),
                  ),
                  _CircleIconButton(icon: Icons.notifications_none_rounded, onTap: () {}),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => context.go('/profile'),
                    child: JuntoAvatar(
                      name: firstName,
                      size: 38,
                      hue: 75,
                      imageUrl: user?.avatarUrl,
                    ),
                  ),
                ],
              ),
            ),

            // Greeting
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              child: RichText(
                text: TextSpan(
                  style: AppTheme.display(size: 36, weight: FontWeight.w500, letterSpacing: -1.0, height: 1.05),
                  children: [
                    TextSpan(text: '${l.homeGreetingPrefix(firstName)}.\n'),
                    TextSpan(
                      text: l.homeGreetingQuestion,
                      style: AppTheme.display(size: 36, weight: FontWeight.w500, color: AppColors.ink3, letterSpacing: -1.0, height: 1.05),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.04, end: 0),

            const SizedBox(height: 24),

            // Hero CTA — create room (amber, with concentric rings)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _CreateRoomHero(onTap: () => _showCreateRoom(context)),
            ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.04, end: 0),

            const SizedBox(height: 14),

            // Quiet join row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _JoinByCodeCard(onTap: () => _showJoinRoom(context)),
            ).animate().fadeIn(duration: 400.ms, delay: 180.ms),

            const SizedBox(height: 24),

            // "Сейчас смотрят друзья" rail
            _LiveRoomsRail(roomsAsync: roomsAsync),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
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

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 24,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.hairline),
        ),
        child: Icon(icon, size: 18, color: AppColors.ink2),
      ),
    );
  }
}

class _CreateRoomHero extends StatelessWidget {
  final VoidCallback onTap;
  const _CreateRoomHero({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Material(
      color: AppColors.amber,
      borderRadius: BorderRadius.circular(AppTheme.r3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.r3),
        splashColor: AppColors.amberInk.withValues(alpha: 0.1),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.r3),
          child: Stack(
            children: [
              const Positioned.fill(child: ProjectorRings()),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MonoLabel(l.homeCreateRoomLabel,
                        color: AppColors.amberInk.withValues(alpha: 0.65), letterSpacing: 2.0),
                    const SizedBox(height: 6),
                    Text(l.homeCreateRoomTitle,
                        style: AppTheme.display(
                          size: 26, weight: FontWeight.w600, letterSpacing: -0.6, color: AppColors.amberInk, height: 1.1,
                        )),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 240,
                      child: Text(
                        l.homeCreateRoomDesc,
                        style: AppTheme.text(
                          size: 13,
                          color: AppColors.amberInk.withValues(alpha: 0.78),
                          weight: FontWeight.w400,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: AppColors.amberInk,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add_rounded, color: AppColors.amber, size: 22),
                        ),
                        const SizedBox(width: 10),
                        Text(l.homeCreateRoomButton,
                            style: AppTheme.text(
                              size: 14, weight: FontWeight.w600, color: AppColors.amberInk,
                            )),
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

class _JoinByCodeCard extends StatelessWidget {
  final VoidCallback onTap;
  const _JoinByCodeCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppTheme.r2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.r2),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.r2),
            border: Border.all(color: AppColors.hairline),
          ),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.groups_2_outlined, color: AppColors.ink2, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.homeJoinCodeLabel,
                        style: AppTheme.text(size: 15, weight: FontWeight.w600, color: AppColors.ink)),
                    const SizedBox(height: 2),
                    Text(l.homeJoinCodeHint,
                        style: AppTheme.text(size: 12, color: AppColors.ink3, weight: FontWeight.w400)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.hairline, style: BorderStyle.solid),
                ),
                child: Text('______',
                    style: AppTheme.mono(
                      size: 12,
                      color: AppColors.ink3,
                      letterSpacing: 2,
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveRoomsRail extends StatelessWidget {
  final AsyncValue<List<RoomInfo>> roomsAsync;
  const _LiveRoomsRail({required this.roomsAsync});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final liveRooms = roomsAsync.maybeWhen(
      data: (rooms) => rooms.where((r) => r.isActive).toList(),
      orElse: () => <RoomInfo>[],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              MonoLabel(l.homeLiveRoomsLabel, color: AppColors.ink3, letterSpacing: 1.8),
              const Spacer(),
              Text('${liveRooms.length}',
                  style: AppTheme.text(size: 12, color: AppColors.ink3, weight: FontWeight.w400)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 174,
          child: liveRooms.isEmpty
              ? _emptyRail(context)
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: liveRooms.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (ctx, i) {
                    final r = liveRooms[i];
                    final mood = i.isEven ? PosterMood.amber : PosterMood.cool;
                    final hostHue = i.isEven ? 30 : 220;
                    return _LiveRoomCard(room: r, mood: mood, hostHue: hostHue);
                  },
                ),
        ),
      ],
    );
  }

  Widget _emptyRail(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.r2),
          border: Border.all(color: AppColors.hairline),
        ),
        padding: const EdgeInsets.all(20),
        alignment: Alignment.centerLeft,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MonoLabel(l.homeLiveRoomsEmpty, color: AppColors.ink4, letterSpacing: 2.0),
            const SizedBox(height: 8),
            Text(l.homeLiveRoomsEmptyDesc,
                style: AppTheme.text(size: 14, color: AppColors.ink2, weight: FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}

class _LiveRoomCard extends StatelessWidget {
  final RoomInfo room;
  final PosterMood mood;
  final int hostHue;
  const _LiveRoomCard({required this.room, required this.mood, required this.hostHue});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SizedBox(
      width: 200,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.r2),
        child: InkWell(
          onTap: () => context.push('/room/${room.id}'),
          borderRadius: BorderRadius.circular(AppTheme.r2),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.r2),
              border: Border.all(color: AppColors.hairline),
            ),
            padding: const EdgeInsets.all(10),
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
                        padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                        decoration: BoxDecoration(
                          color: AppColors.bgDeep.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const LiveChip(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${l.homeRoomLabel} ${room.inviteCode}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.text(size: 14, weight: FontWeight.w600, color: AppColors.ink),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    JuntoAvatar(name: room.hostName, size: 16, hue: hostHue),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '${room.hostName} · ${room.memberCount} ${l.homeRoomMembers}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.text(size: 12, color: AppColors.ink3, weight: FontWeight.w400),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
