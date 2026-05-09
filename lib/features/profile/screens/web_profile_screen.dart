import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/fcm_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/junto_primitives.dart';
import '../../../l10n/app_localizations.dart';
import '../widgets/edit_profile_sheet.dart';
import '../widgets/language_picker_sheet.dart';
import '../widgets/mic_picker_sheet.dart';
import '../widgets/sessions_history_sheet.dart';

/// Pop the existing mobile bottom-sheet as a centred dialog instead.
/// On desktop a 100%-width sheet sliding from the bottom across a
/// 1440px viewport feels wrong; reusing the same widget inside a
/// modest 480-wide dialog keeps mobile code unchanged but reads
/// natively on a wide screen.
Future<T?> _showSheetAsDialog<T>(
  BuildContext context,
  Widget sheet, {
  double maxWidth = 480,
}) {
  return showDialog<T>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        elevation: 0,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.r3),
            child: Material(
              color: AppColors.surface,
              child: sheet,
            ),
          ),
        ),
      );
    },
  );
}

/// Desktop-Web profile / settings page. Renders inside `WebDesktopShell`
/// so this widget owns only the content slot: section-nav (left, 240) +
/// main pane (identity card + grouped settings + last sessions). Each
/// row reuses the existing mobile bottom-sheets (edit / lang / mic / etc).
class WebProfileScreen extends ConsumerStatefulWidget {
  const WebProfileScreen({super.key});

  @override
  ConsumerState<WebProfileScreen> createState() => _WebProfileScreenState();
}

enum _Section { account, notifications, audioVideo, language, about }

class _WebProfileScreenState extends ConsumerState<WebProfileScreen> {
  final _scroll = ScrollController();
  final _keys = {
    _Section.account: GlobalKey(),
    _Section.notifications: GlobalKey(),
    _Section.audioVideo: GlobalKey(),
    _Section.language: GlobalKey(),
    _Section.about: GlobalKey(),
  };
  _Section _active = _Section.account;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    Future.microtask(() {
      if (!mounted) return;
      ref.read(authStateProvider.notifier).refreshProfile();
    });
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  /// Highlights the section whose top is the closest-above-threshold to the
  /// scroll viewport. Threshold sits 120px below the viewport top so a
  /// section with its title peeking just under the page header is what
  /// counts as "active" — not the previous one we're scrolling away from.
  void _onScroll() {
    if (!mounted) return;
    const threshold = 120.0;
    _Section? best;
    double bestTop = -double.infinity;
    for (final entry in _keys.entries) {
      final ctx = entry.value.currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) continue;
      final top = box.localToGlobal(Offset.zero).dy;
      if (top <= threshold && top > bestTop) {
        bestTop = top;
        best = entry.key;
      }
    }
    if (best != null && best != _active) {
      setState(() => _active = best!);
    }
  }

  void _scrollTo(_Section s) {
    setState(() => _active = s);
    final ctx = _keys[s]?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      alignment: 0.02,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider);
    final settings = ref.watch(settingsProvider);
    final isGuest = user == null || user.isGuest;
    final displayName = isGuest ? l.profileGuestLabel : user.username;
    final handle = isGuest ? '@guest' : '@${user.username.toLowerCase()}';
    final email = isGuest ? '—' : user.email;
    final langCode = settings.locale?.languageCode ?? 'ru';
    final langLabel = langCode == 'en' ? l.profileLanguageEn : l.profileLanguageRu;

    return SingleChildScrollView(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(40, 32, 40, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(
                pendingRequests: user?.pendingRequestsCount ?? 0,
                onRequestsTap: () => context.push('/friends'),
              ),
              const SizedBox(height: 32),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 240,
                      child: _SectionNav(
                        active: _active,
                        onTap: _scrollTo,
                        isGuest: isGuest,
                        onLogout: () => _showLogoutDialog(context),
                      ),
                    ),
                    const SizedBox(width: 32),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _IdentityCard(
                            key: _keys[_Section.account],
                            name: displayName,
                            handle: handle,
                            email: email,
                            isGuest: isGuest,
                            avatarUrl: user?.avatarUrl,
                            sessionsCount: user?.sessionsCount ?? 0,
                            watchHours: user?.watchHours ?? 0,
                            friendsCount: user?.friendsCount ?? 0,
                            onEdit: isGuest
                                ? null
                                : () => _showSheetAsDialog(
                                      context,
                                      const EditProfileSheet(),
                                    ),
                            onFriendsTap: isGuest
                                ? null
                                : () => context.push('/friends'),
                          ),
                          if (user != null && !user.isGuest) ...[
                            const SizedBox(height: 24),
                            _SubscriptionCard(
                              isPro: user.isPro,
                              tier: user.tier,
                              onTap: () {
                                if (user.isPro) {
                                  context.push('/billing/manage');
                                } else {
                                  context.push('/billing/plans?plan=pro');
                                }
                              },
                            ),
                          ],
                          const SizedBox(height: 24),
                          _AccountSection(
                            handle: handle,
                            email: email,
                            isGuest: isGuest,
                            onEdit: isGuest
                                ? null
                                : () => _showSheetAsDialog(
                                      context,
                                      const EditProfileSheet(),
                                    ),
                          ),
                          const SizedBox(height: 24),
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: KeyedSubtree(
                                    key: _keys[_Section.notifications],
                                    child: _NotificationsSection(
                                      enabled: settings.notificationsEnabled,
                                      onToggle: () => _toggleNotifications(
                                          context, settings),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: KeyedSubtree(
                                    key: _keys[_Section.audioVideo],
                                    child: _AudioVideoSection(
                                      langLabel: langLabel,
                                      onPickLang: () => _showSheetAsDialog(
                                        context,
                                        const LanguagePickerSheet(),
                                      ),
                                      onPickMic: () => _showSheetAsDialog(
                                        context,
                                        const MicPickerSheet(),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          KeyedSubtree(
                            key: _keys[_Section.language],
                            child: _LastSessionsSection(
                              hasSessions:
                                  !isGuest && (user.sessionsCount > 0),
                              onOpen: () => _showSheetAsDialog(
                                context,
                                const SessionsHistorySheet(),
                                maxWidth: 720,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          KeyedSubtree(
                            key: _keys[_Section.about],
                            child: _AboutSection(
                              onLicenses: () =>
                                  showLicensePage(context: context),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (isGuest)
                            _GuestExitRow(onSignIn: () => _exitGuest('/login'))
                          else
                            const SizedBox.shrink(),
                        ],
                      ),
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

  Future<void> _toggleNotifications(
      BuildContext context, AppSettings settings) async {
    final l = AppLocalizations.of(context);
    final goingOn = !settings.notificationsEnabled;

    await ref
        .read(settingsProvider.notifier)
        .setNotificationsEnabled(goingOn);

    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);

    if (!goingOn) {
      await ref.read(fcmControllerProvider).unregister();
      messenger.showSnackBar(
        SnackBar(content: Text(l.profileNotificationsOff)),
      );
      return;
    }

    final status = await ref.read(fcmControllerProvider).register();
    final controller = ref.read(fcmControllerProvider);
    String text;
    switch (status) {
      case FcmRegisterStatus.ok:
        text = l.profileNotificationsOn;
        break;
      case FcmRegisterStatus.permissionDenied:
        text = l.profileFcmPermissionDenied;
        break;
      case FcmRegisterStatus.unsupported:
        text = l.profileFcmUnsupported;
        break;
      case FcmRegisterStatus.backendError:
        text = l.profileFcmBackendError(controller.lastError);
        break;
      case FcmRegisterStatus.initError:
        text = l.profileFcmInitError(controller.lastError);
        break;
    }
    messenger.showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _exitGuest(String path) async {
    await ref.read(authStateProvider.notifier).logout();
    if (mounted) context.go(path);
  }

  void _showLogoutDialog(BuildContext context) {
    final l = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.r2)),
        title: Text(l.profileLogoutConfirmTitle,
            style: AppTheme.display(size: 18, weight: FontWeight.w600)),
        content: Text(
          l.profileLogoutConfirmMessage,
          style: AppTheme.text(
              size: 14, color: AppColors.ink2, weight: FontWeight.w400),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.profileLogoutCancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authStateProvider.notifier).logout();
              context.go('/login');
            },
            child: Text(l.profileLogoutConfirm,
                style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int pendingRequests;
  final VoidCallback onRequestsTap;
  const _Header({
    required this.pendingRequests,
    required this.onRequestsTap,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MonoLabel(l.profileLabel,
                  color: AppColors.ink3, letterSpacing: 2),
              const SizedBox(height: 6),
              Text(
                l.profileTitle,
                style: AppTheme.display(
                  size: 44,
                  weight: FontWeight.w600,
                  letterSpacing: -1.2,
                ),
              ),
            ],
          ),
        ),
        if (pendingRequests > 0)
          InkWell(
            onTap: onRequestsTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.amberDim,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_add_alt_1_rounded,
                      size: 14, color: AppColors.amber),
                  const SizedBox(width: 6),
                  Text(
                    '$pendingRequests',
                    style: AppTheme.text(
                      size: 13,
                      weight: FontWeight.w600,
                      color: AppColors.amber,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _SectionNav extends StatelessWidget {
  final _Section active;
  final ValueChanged<_Section> onTap;
  final bool isGuest;
  final VoidCallback onLogout;

  const _SectionNav({
    required this.active,
    required this.onTap,
    required this.isGuest,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // Items have to be built per-frame to read l10n; the previous
    // const list hard-coded Russian which leaked through whenever
    // locale was English.
    final items = <_NavItem>[
      _NavItem(_Section.account, l.profileTabAccount,
          Icons.person_outline_rounded),
      _NavItem(_Section.notifications, l.profileNotifications,
          Icons.notifications_none_rounded),
      _NavItem(_Section.audioVideo, l.profileTabAudioVideo,
          Icons.mic_none_rounded),
      _NavItem(_Section.language, l.profileTabSessions,
          Icons.history_outlined),
      _NavItem(_Section.about, l.profileAboutTitle,
          Icons.info_outline_rounded),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final it in items)
          _NavRow(
            label: it.label,
            icon: it.icon,
            active: it.section == active,
            onTap: () => onTap(it.section),
          ),
        const SizedBox(height: 10),
        Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          color: AppColors.hairline,
        ),
        const SizedBox(height: 6),
        if (!isGuest)
          _NavRow(
            label: l.profileLogout,
            icon: Icons.logout_rounded,
            danger: true,
            active: false,
            onTap: onLogout,
          ),
      ],
    );
  }
}

class _NavItem {
  final _Section section;
  final String label;
  final IconData icon;
  const _NavItem(this.section, this.label, this.icon);
}

class _NavRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final bool danger;
  final VoidCallback onTap;
  const _NavRow({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger
        ? AppColors.danger
        : (active ? AppColors.ink : AppColors.ink2);
    final iconColor = danger
        ? AppColors.danger
        : (active ? AppColors.amber : AppColors.ink3);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: active ? AppColors.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: active ? AppColors.hairline : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: iconColor),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: AppTheme.text(
                    size: 13,
                    weight: active ? FontWeight.w600 : FontWeight.w500,
                    color: color,
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

class _IdentityCard extends StatelessWidget {
  final String name;
  final String handle;
  final String email;
  final bool isGuest;
  final String? avatarUrl;
  final int sessionsCount;
  final int watchHours;
  final int friendsCount;
  final VoidCallback? onEdit;
  final VoidCallback? onFriendsTap;

  const _IdentityCard({
    super.key,
    required this.name,
    required this.handle,
    required this.email,
    required this.isGuest,
    required this.sessionsCount,
    required this.watchHours,
    required this.friendsCount,
    this.avatarUrl,
    this.onEdit,
    this.onFriendsTap,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(AppTheme.r3),
      ),
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          JuntoAvatar(
            name: name,
            size: 88,
            hue: 75,
            online: !isGuest,
            imageUrl: avatarUrl,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTheme.display(
                    size: 28,
                    weight: FontWeight.w600,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isGuest ? handle : '$handle  ·  $email',
                  style: AppTheme.text(
                    size: 13,
                    color: AppColors.ink3,
                    weight: FontWeight.w400,
                  ),
                ),
                if (onEdit != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _MiniPill(
                        label: AppLocalizations.of(context).profileEdit,
                        icon: Icons.edit_outlined,
                        onTap: onEdit!,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Stats inline
          Row(
            children: [
              _StatBlock(
                value: '$sessionsCount',
                label: l.profileSessionsLabel,
              ),
              const SizedBox(width: 36),
              _StatBlock(
                value: '$watchHours',
                label: l.profileHoursLabel,
              ),
              const SizedBox(width: 36),
              InkWell(
                onTap: onFriendsTap,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: _StatBlock(
                    value: '$friendsCount',
                    label: l.profileFriendsLabel,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _MiniPill({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface2,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.hairline),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: AppColors.ink2),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTheme.text(
                  size: 12,
                  weight: FontWeight.w500,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String value;
  final String label;
  const _StatBlock({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: AppTheme.display(
            size: 26,
            weight: FontWeight.w600,
            color: AppColors.amber,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        MonoLabel(label, color: AppColors.ink3, letterSpacing: 1.4, size: 9),
      ],
    );
  }
}

class _GroupCard extends StatelessWidget {
  final String title;
  final List<Widget> rows;
  const _GroupCard({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MonoLabel(title, color: AppColors.ink3, letterSpacing: 2),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.hairline),
            borderRadius: BorderRadius.circular(AppTheme.r2),
          ),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                rows[i],
                if (i < rows.length - 1)
                  const Divider(height: 1, color: AppColors.hairline),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String label;
  final String? value;
  final String? action;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingRow({
    required this.label,
    this.value,
    this.action,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: AppTheme.text(
                      size: 14,
                      weight: FontWeight.w500,
                      color: AppColors.ink,
                    ),
                  ),
                  if (value != null && value!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      value!,
                      style: AppTheme.text(
                        size: 12,
                        color: AppColors.ink3,
                        weight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            ?trailing,
            if (action != null && trailing == null)
              Text(
                action!,
                style: AppTheme.text(
                  size: 12,
                  color: AppColors.amber,
                  weight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Switch extends StatelessWidget {
  final bool on;
  final VoidCallback onTap;
  const _Switch({required this.on, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 38,
        height: 22,
        decoration: BoxDecoration(
          color: on ? AppColors.amber : AppColors.surface2,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: on ? AppColors.amber : AppColors.hairline,
          ),
        ),
        alignment: on ? Alignment.centerRight : Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: on ? AppColors.amberInk : AppColors.ink3,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _AccountSection extends StatelessWidget {
  final String handle;
  final String email;
  final bool isGuest;
  final VoidCallback? onEdit;

  const _AccountSection({
    required this.handle,
    required this.email,
    required this.isGuest,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _GroupCard(
      title: l.profileTabAccount,
      rows: [
        _SettingRow(
          label: l.profileNickname,
          value: handle,
          action: isGuest ? null : l.profileEdit,
          onTap: onEdit,
        ),
        _SettingRow(
          label: l.profileEmail,
          value: email,
          action: isGuest ? null : l.profileEdit,
          onTap: onEdit,
        ),
      ],
    );
  }
}

class _NotificationsSection extends StatelessWidget {
  final bool enabled;
  final VoidCallback onToggle;

  const _NotificationsSection({
    required this.enabled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _GroupCard(
      title: l.profileNotifications,
      rows: [
        _SettingRow(
          label: enabled ? l.profilePushOn : l.profilePushOff,
          value: l.profilePushDesc,
          trailing: _Switch(on: enabled, onTap: onToggle),
        ),
      ],
    );
  }
}

class _AudioVideoSection extends StatelessWidget {
  final String langLabel;
  final VoidCallback onPickLang;
  final VoidCallback onPickMic;

  const _AudioVideoSection({
    required this.langLabel,
    required this.onPickLang,
    required this.onPickMic,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _GroupCard(
      title: l.profileAudioVideoGroup,
      rows: [
        _SettingRow(
          label: l.profileMicrophone,
          value: l.profileSystemDevice,
          action: l.profileChange,
          onTap: onPickMic,
        ),
        _SettingRow(
          label: l.profileLanguage,
          value: langLabel,
          action: l.profileChange,
          onTap: onPickLang,
        ),
      ],
    );
  }
}

class _LastSessionsSection extends StatelessWidget {
  final bool hasSessions;
  final VoidCallback onOpen;

  const _LastSessionsSection({
    required this.hasSessions,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _GroupCard(
      title: l.profileSessionsGroup,
      rows: [
        _SettingRow(
          label: hasSessions ? l.profileSessionsHistory : l.profileSessionsEmpty,
          value: hasSessions
              ? l.profileSessionsHistoryDesc
              : l.profileSessionsEmptyDesc,
          action: hasSessions ? l.profileOpen : null,
          onTap: hasSessions ? onOpen : null,
        ),
      ],
    );
  }
}

class _AboutSection extends StatelessWidget {
  final VoidCallback onLicenses;
  const _AboutSection({required this.onLicenses});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _GroupCard(
      title: l.profileAboutTitle,
      rows: [
        _SettingRow(label: l.profileVersion, value: '1.0.0'),
        _SettingRow(
          label: l.profileLicenses,
          value: l.profileLicensesDesc,
          action: l.profileOpen,
          onTap: onLicenses,
        ),
      ],
    );
  }
}

class _GuestExitRow extends StatelessWidget {
  final VoidCallback onSignIn;
  const _GuestExitRow({required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(AppTheme.r2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).profileGuestMode,
                  style: AppTheme.text(
                    size: 14,
                    weight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context).profileGuestModeDesc,
                  style: AppTheme.text(
                    size: 12,
                    color: AppColors.ink3,
                    weight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Material(
            color: AppColors.amber,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              onTap: onSignIn,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.of(context).loginSubmit,
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
          ),
        ],
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  final bool isPro;
  final String tier;
  final VoidCallback onTap;

  const _SubscriptionCard({
    required this.isPro,
    required this.tier,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.r3),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 18, 18, 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isPro
                ? [AppColors.amberDim, AppColors.surface]
                : [AppColors.amber, const Color(0xFFC1873E)],
          ),
          borderRadius: BorderRadius.circular(AppTheme.r3),
          border: Border.all(
            color: isPro ? AppColors.amber : Colors.transparent,
            width: 1.4,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isPro ? AppColors.amberDim : Colors.white24,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.workspace_premium_rounded,
                size: 24,
                color: isPro ? AppColors.amber : AppColors.amberInk,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPro ? l.profileBillingManage : l.profileBillingProCta,
                    style: AppTheme.text(
                      size: 16,
                      weight: FontWeight.w700,
                      color: isPro ? AppColors.ink : AppColors.amberInk,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isPro
                        ? tier.toUpperCase()
                        : l.profileBillingProCtaSubtitle,
                    style: AppTheme.text(
                      size: 13,
                      color: isPro
                          ? AppColors.ink3
                          : AppColors.amberInk.withValues(alpha: 0.78),
                      weight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isPro ? AppColors.ink3 : AppColors.amberInk,
            ),
          ],
        ),
      ),
    );
  }
}
