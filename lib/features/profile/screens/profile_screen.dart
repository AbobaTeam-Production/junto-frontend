import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/junto_primitives.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/fcm_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../widgets/edit_profile_sheet.dart';
import '../widgets/language_picker_sheet.dart';
import '../widgets/mic_picker_sheet.dart';
import '../widgets/sessions_history_sheet.dart';
import '../../../l10n/app_localizations.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Re-pull the profile every time the screen opens so the watch-time
    // and session-count stats reflect the most recent disconnect. The
    // current user already lives in `authStateProvider`, so we just kick
    // an /auth/profile/ refresh to update those denormalised counters.
    Future.microtask(() {
      if (!mounted) return;
      ref.read(authStateProvider.notifier).refreshProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider);
    final settings = ref.watch(settingsProvider);
    final isGuest = user == null || user.isGuest;
    final displayName = isGuest ? l.profileGuestLabel : user.username;
    final handle = isGuest ? l.profileGuestHandle : '@${user.username.toLowerCase()}';
    final langCode = settings.locale?.languageCode ?? 'ru';
    final langLabel = langCode == 'en' ? l.profileLanguageEn : l.profileLanguageRu;
    final micLabel = settings.micDeviceId.isEmpty
        ? l.profileMicrophoneDefault
        // Display name resolution lives inside MicPickerSheet — for the
        // subtitle we just hint that a custom device is in use.
        : '•';

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
          children: [
            // Header — mono "Профиль" + display "Я" + settings icon
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MonoLabel(l.profileLabel,
                            color: AppColors.ink3, letterSpacing: 1.8),
                        const SizedBox(height: 4),
                        Text(l.profileTitle,
                            style: AppTheme.display(
                                size: 32, weight: FontWeight.w600, letterSpacing: -0.8)),
                      ],
                    ),
                  ),
                  // Settings shortcut on the right was decorative — this
                  // screen IS the settings page, so the icon was a dead
                  // chiclet. We keep a small badge here only when the
                  // user has incoming friend requests waiting; tapping
                  // jumps straight to the requests tab.
                  if ((user?.pendingRequestsCount ?? 0) > 0)
                    InkResponse(
                      radius: 22,
                      onTap: () => context.push('/friends'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.amber.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_add_alt_1_rounded,
                                size: 14, color: AppColors.amber),
                            const SizedBox(width: 6),
                            Text('${user!.pendingRequestsCount}',
                                style: AppTheme.text(
                                    size: 12,
                                    weight: FontWeight.w600,
                                    color: AppColors.amber)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Profile card with stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _ProfileCard(
                name: displayName,
                handle: handle,
                isGuest: isGuest,
                avatarUrl: user?.avatarUrl,
                sessionsCount: user?.sessionsCount ?? 0,
                watchHours: user?.watchHours ?? 0,
                friendsCount: user?.friendsCount ?? 0,
                onFriendsTap: isGuest ? null : () => context.push('/friends'),
                onSessionsTap: (isGuest || user.sessionsCount == 0)
                    ? null
                    : () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const SessionsHistorySheet(),
                        ),
                onEdit: isGuest
                    ? null
                    : () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const EditProfileSheet(),
                        ),
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.04, end: 0),

            const SizedBox(height: 24),

            // Settings section. Notifications row is hidden on platforms
            // where firebase_messaging has no implementation (Windows /
            // Linux) — toggling it would do nothing visible to the user.
            _SettingsSection(
              title: l.profileSettingsTitle,
              children: [
                if (fcmSupported)
                  _Row(
                    icon: Icons.notifications_none_rounded,
                    label: l.profileNotifications,
                    value: settings.notificationsEnabled
                        ? l.profileNotificationsOn
                        : l.profileNotificationsOff,
                    onTap: () => ref
                        .read(settingsProvider.notifier)
                        .setNotificationsEnabled(!settings.notificationsEnabled),
                  ),
                _Row(
                  icon: Icons.language_outlined,
                  label: l.profileLanguage,
                  value: langLabel,
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const LanguagePickerSheet(),
                  ),
                ),
                _Row(
                  icon: Icons.mic_none_rounded,
                  label: l.profileMicrophone,
                  value: micLabel,
                  isLast: true,
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const MicPickerSheet(),
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 400.ms, delay: 80.ms),

            const SizedBox(height: 24),

            _SettingsSection(
              title: l.profileAboutTitle,
              children: [
                _Row(icon: Icons.info_outline_rounded, label: l.profileVersion, value: '1.0.0'),
                _Row(
                  icon: Icons.description_outlined,
                  label: l.profileLicenses,
                  value: '',
                  onTap: () => showLicensePage(context: context),
                  isLast: true,
                ),
              ],
            ).animate().fadeIn(duration: 400.ms, delay: 140.ms),

            const SizedBox(height: 24),

            if (isGuest) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _exitGuestTo(context, ref, '/login'),
                    child: Text(l.profileLoginButton),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _exitGuestTo(context, ref, '/register'),
                    child: Text(l.profileRegisterButton),
                  ),
                ),
              ),
            ] else
              _SettingsSection(
                title: '',
                children: [
                  _Row(
                    icon: Icons.logout_rounded,
                    label: l.profileLogout,
                    value: '',
                    danger: true,
                    isLast: true,
                    onTap: () => _showLogoutDialog(context, ref),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// Guests are technically authenticated, so a bare context.go('/login')
  /// gets bounced back to /home by the router redirect. Drop the guest
  /// session first, then navigate.
  Future<void> _exitGuestTo(
      BuildContext context, WidgetRef ref, String path) async {
    await ref.read(authStateProvider.notifier).logout();
    if (context.mounted) context.go(path);
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.r2)),
        title: Text(l.profileLogoutConfirmTitle, style: AppTheme.display(size: 18, weight: FontWeight.w600)),
        content: Text(l.profileLogoutConfirmMessage,
            style: AppTheme.text(size: 14, color: AppColors.ink2, weight: FontWeight.w400)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.profileLogoutCancel)),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authStateProvider.notifier).logout();
              context.go('/login');
            },
            child: Text(l.profileLogoutConfirm, style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final String name;
  final String handle;
  final bool isGuest;
  final String? avatarUrl;
  final int sessionsCount;
  final int watchHours;
  final int friendsCount;
  final VoidCallback? onEdit;
  final VoidCallback? onFriendsTap;
  final VoidCallback? onSessionsTap;

  const _ProfileCard({
    required this.name,
    required this.handle,
    required this.isGuest,
    required this.sessionsCount,
    required this.watchHours,
    required this.friendsCount,
    this.avatarUrl,
    this.onEdit,
    this.onFriendsTap,
    this.onSessionsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.r3),
        border: Border.all(color: AppColors.hairline),
      ),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              JuntoAvatar(
                name: name,
                size: 64,
                hue: 75,
                online: !isGuest,
                imageUrl: avatarUrl,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.display(
                            size: 22, weight: FontWeight.w600, letterSpacing: -0.4)),
                    const SizedBox(height: 2),
                    Text(handle,
                        style: AppTheme.text(size: 13, color: AppColors.ink3, weight: FontWeight.w400)),
                  ],
                ),
              ),
              if (onEdit != null)
                InkResponse(
                  onTap: onEdit,
                  radius: 20,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit_outlined, color: AppColors.ink2, size: 16),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 22),
          Builder(builder: (ctx) {
            final l = AppLocalizations.of(ctx);
            return Row(
              children: [
                InkWell(
                  onTap: onSessionsTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: _Stat(
                      value: '$sessionsCount',
                      label: l.profileSessionsLabel,
                    ),
                  ),
                ),
                const SizedBox(width: 28),
                _Stat(value: '$watchHours', label: l.profileHoursLabel),
                const SizedBox(width: 28),
                InkWell(
                  onTap: onFriendsTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: _Stat(
                      value: '$friendsCount',
                      label: l.profileFriendsLabel,
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppTheme.display(
            size: 22, weight: FontWeight.w600, color: AppColors.amber, letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 2),
        MonoLabel(label, color: AppColors.ink3, size: 9, letterSpacing: 1.4),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            MonoLabel(title, color: AppColors.ink3, letterSpacing: 1.8),
            const SizedBox(height: 4),
          ],
          ...children,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool danger;
  final bool isLast;

  const _Row({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.danger = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.danger : AppColors.ink;
    final iconColor = danger ? AppColors.danger : AppColors.ink3;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(bottom: BorderSide(color: AppColors.hairline)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: AppTheme.text(size: 14, weight: FontWeight.w500, color: color)),
            ),
            if (value.isNotEmpty)
              Text(value,
                  style: AppTheme.text(size: 13, color: AppColors.ink3, weight: FontWeight.w400)),
            if (!danger) ...[
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.ink4),
            ],
          ],
        ),
      ),
    );
  }
}
