import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../widgets/edit_profile_sheet.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isGuest = user == null || user.isGuest;

    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar + info
            _buildHeader(context, user)
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.03, end: 0),
            const SizedBox(height: 32),

            // Settings section
            _buildSection(
              context,
              title: 'Настройки',
              children: [
                _SettingsTile(
                  icon: Icons.notifications_outlined,
                  title: 'Уведомления',
                  trailing: Switch.adaptive(
                    value: true,
                    onChanged: (_) {},
                    activeTrackColor: AppColors.primary,
                  ),
                ),
                _SettingsTile(
                  icon: Icons.dark_mode_outlined,
                  title: 'Тёмная тема',
                  trailing: Switch.adaptive(
                    value: true,
                    onChanged: null, // always dark for now
                    activeTrackColor: AppColors.primary,
                  ),
                ),
                _SettingsTile(
                  icon: Icons.language_outlined,
                  title: 'Язык',
                  trailing: const Text(
                    'Русский',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 100.ms)
                .slideY(begin: 0.03, end: 0),
            const SizedBox(height: 20),

            // About section
            _buildSection(
              context,
              title: 'О приложении',
              children: [
                _SettingsTile(
                  icon: Icons.info_outline,
                  title: 'Версия',
                  trailing: const Text(
                    '1.0.0',
                    style: TextStyle(
                      color: AppColors.textHint,
                      fontSize: 14,
                    ),
                  ),
                ),
                _SettingsTile(
                  icon: Icons.description_outlined,
                  title: 'Лицензии',
                  trailing: const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textHint, size: 20),
                  onTap: () => showLicensePage(context: context),
                ),
              ],
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 200.ms)
                .slideY(begin: 0.03, end: 0),
            const SizedBox(height: 28),

            // Guest: sign in / register buttons
            if (isGuest) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Войти в аккаунт'),
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 300.ms),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.go('/register'),
                  child: const Text('Зарегистрироваться'),
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 350.ms),
            ],

            // Authenticated: logout button
            if (!isGuest) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showLogoutDialog(context, ref),
                  icon: const Icon(
                    Icons.logout_rounded,
                    size: 18,
                    color: AppColors.error,
                  ),
                  label: const Text('Выйти из аккаунта'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 300.ms),
            ],

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AuthUser? user) {
    final isGuest = user == null || user.isGuest;

    if (isGuest) {
      return Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              size: 44,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Гость',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Войдите или зарегистрируйтесь,\nчтобы получить доступ ко всем функциям',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      );
    }

    final initial = user.username.isNotEmpty ? user.username[0].toUpperCase() : '?';

    return Column(
      children: [
        // Avatar
        if (user.avatarUrl != null)
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 44,
              backgroundImage: NetworkImage(user.avatarUrl!),
            ),
          )
        else
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),
        Text(
          user.username,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          user.email,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 14),
        // Edit profile button
        TextButton.icon(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const EditProfileSheet(),
            );
          },
          icon: const Icon(Icons.edit_outlined, size: 16),
          label: const Text('Редактировать'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Выход'),
        content: const Text('Вы уверены, что хотите выйти?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authStateProvider.notifier).logout();
              context.go('/login');
            },
            child: const Text(
              'Выйти',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
