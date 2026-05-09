import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../providers/friends_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'junto_primitives.dart';
import '../../features/home/widgets/create_room_sheet.dart';

/// Desktop chrome for the Web build: top bar (logo + search + create CTA +
/// avatar) and a 232-px left sidebar (nav + friends online + beta card).
/// Replaces the mobile bottom-nav on `kIsWeb && width > 900`. The route to
/// highlight is taken from GoRouter's current location.
class WebDesktopShell extends ConsumerWidget {
  final Widget child;
  const WebDesktopShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = GoRouterState.of(context).uri.path;
    return ColoredBox(
      color: AppColors.bg,
      child: Column(
        children: [
          _TopBar(),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Sidebar(activePath: path),
                Expanded(
                  child: ColoredBox(
                    color: AppColors.bg,
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final firstName = user == null
        ? 'Junto'
        : user.isGuest
            ? 'Гость'
            : user.username.split(' ').first;
    final handle = user == null
        ? ''
        : user.isGuest
            ? ''
            : '@${user.username.toLowerCase()}';

    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(bottom: BorderSide(color: AppColors.hairline)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Logo cluster — width matches sidebar minus the row padding so
          // the logo lines up with the nav items below.
          SizedBox(
            width: 232 - 24,
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.amber,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.amber.withValues(alpha: 0.5),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Junto',
                  style: AppTheme.display(
                    size: 19,
                    weight: FontWeight.w600,
                    letterSpacing: -0.4,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.hairline),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'V2',
                    style: AppTheme.mono(
                      size: 9,
                      letterSpacing: 1.6,
                      color: AppColors.ink4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Search — stub for now, taps go to /recs/search
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: _SearchBar(),
            ),
          ),
          const Spacer(),
          // Create room CTA
          _PillButton(
            label: 'Создать комнату',
            icon: Icons.add_rounded,
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const CreateRoomSheet(),
            ),
          ),
          const SizedBox(width: 12),
          // Bell — stub
          _CircleIconButton(
            icon: Icons.notifications_none_rounded,
            badge: (user?.pendingRequestsCount ?? 0) > 0,
            onTap: () => context.go('/profile'),
          ),
          const SizedBox(width: 14),
          // Avatar + name
          InkWell(
            onTap: () => context.go('/profile'),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  JuntoAvatar(
                    name: firstName,
                    size: 32,
                    hue: 75,
                    imageUrl: user?.avatarUrl,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        firstName,
                        style: AppTheme.text(
                          size: 13,
                          weight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                      if (handle.isNotEmpty)
                        Text(
                          handle,
                          style: AppTheme.text(
                            size: 11,
                            color: AppColors.ink3,
                            weight: FontWeight.w400,
                            height: 1.2,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        // push (not go) so the search overlay's back button can pop
        // back to whichever tab the user came from.
        onTap: () => context.push('/recs/search'),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.hairline),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, size: 16, color: AppColors.ink3),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Найти фильм или код комнаты…',
                  style: AppTheme.text(
                    size: 13,
                    color: AppColors.ink4,
                    weight: FontWeight.w400,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.hairline),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '⌘ K',
                  style: AppTheme.mono(
                    size: 10,
                    color: AppColors.ink4,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _PillButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.amber,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: AppColors.amberInk),
              const SizedBox(width: 6),
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

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool badge;
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.badge = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 22,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.hairline),
            ),
            child: Icon(icon, size: 16, color: AppColors.ink2),
          ),
          if (badge)
            Positioned(
              top: 6,
              right: 7,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.amber,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.bg, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Sidebar extends ConsumerWidget {
  final String activePath;
  const _Sidebar({required this.activePath});

  static const _navItems = <_NavSpec>[
    _NavSpec(path: '/home', label: 'Сейчас', icon: Icons.home_outlined, activeIcon: Icons.home_rounded),
    _NavSpec(path: '/recs', label: 'Подборки', icon: Icons.auto_awesome_outlined, activeIcon: Icons.auto_awesome_rounded),
    _NavSpec(path: '/rooms', label: 'Комнаты', icon: Icons.live_tv_outlined, activeIcon: Icons.live_tv_rounded),
    _NavSpec(path: '/profile', label: 'Профиль', icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded),
  ];

  bool _isActive(String tab, String currentPath) {
    if (tab == '/home' && currentPath == '/') return true;
    return currentPath == tab || currentPath.startsWith('$tab/');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(friendsListProvider);
    final friends = friendsAsync.maybeWhen(
      data: (list) => list.where((f) => f.status == 'accepted').toList(),
      orElse: () => const [],
    );
    final myRoomsActive = 0;

    return Container(
      width: 232,
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(right: BorderSide(color: AppColors.hairline)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
            child: MonoLabel('Навигация', color: AppColors.ink4, letterSpacing: 1.8, size: 9),
          ),
          for (final n in _navItems)
            _NavRow(
              spec: n,
              active: _isActive(n.path, activePath),
              badge: n.path == '/rooms' && myRoomsActive > 0 ? '$myRoomsActive' : null,
              onTap: () => context.go(n.path),
            ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
            child: MonoLabel('Друзья · сейчас', color: AppColors.ink4, letterSpacing: 1.8, size: 9),
          ),
          if (friends.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
              child: Text(
                'Никого. Добавь первого друга в профиле.',
                style: AppTheme.text(
                  size: 11,
                  color: AppColors.ink4,
                  weight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
            )
          else
            for (var i = 0; i < friends.length && i < 6; i++)
              _FriendRow(
                friendship: friends[i],
                hue: 30 + (i * 70) % 360,
              ),
          const Spacer(),
          _BetaCard(),
        ],
      ),
    );
  }
}

class _NavSpec {
  final String path;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _NavSpec({
    required this.path,
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}

class _NavRow extends StatelessWidget {
  final _NavSpec spec;
  final bool active;
  final String? badge;
  final VoidCallback onTap;

  const _NavRow({
    required this.spec,
    required this.active,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: active ? AppColors.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: active ? AppColors.hairline : Colors.transparent,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  active ? spec.activeIcon : spec.icon,
                  size: 17,
                  color: active ? AppColors.amber : AppColors.ink3,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    spec.label,
                    style: AppTheme.text(
                      size: 13,
                      weight: active ? FontWeight.w600 : FontWeight.w500,
                      color: active ? AppColors.ink : AppColors.ink2,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.liveDim,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badge!,
                      style: AppTheme.mono(
                        size: 10,
                        color: AppColors.live,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FriendRow extends StatelessWidget {
  final Friendship friendship;
  final int hue;
  const _FriendRow({required this.friendship, required this.hue});

  @override
  Widget build(BuildContext context) {
    final peer = friendship.peer;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Row(
        children: [
          JuntoAvatar(
            name: peer.username,
            size: 26,
            hue: hue,
            imageUrl: peer.avatarUrl,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  peer.username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.text(
                    size: 12,
                    weight: FontWeight.w500,
                    color: AppColors.ink,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'не в эфире',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.text(
                    size: 10,
                    color: AppColors.ink4,
                    weight: FontWeight.w400,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BetaCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.hairline,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MonoLabel('Beta', color: AppColors.amber, letterSpacing: 1.6, size: 9),
          const SizedBox(height: 4),
          Text(
            'Веб-плеер пока без AirPlay/Chromecast. Сообщить о проблеме →',
            style: AppTheme.text(
              size: 11,
              color: AppColors.ink3,
              weight: FontWeight.w400,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
