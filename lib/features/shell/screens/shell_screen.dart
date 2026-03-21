import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class ShellScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ShellScreen({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.divider, width: 0.5),
          ),
        ),
        child: NavigationBar(
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primary.withValues(alpha: 0.15),
          surfaceTintColor: Colors.transparent,
          height: 64,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, color: AppColors.textSecondary),
              selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
              label: 'Главная',
            ),
            NavigationDestination(
              icon: Icon(Icons.videocam_outlined, color: AppColors.textSecondary),
              selectedIcon: Icon(Icons.videocam_rounded, color: AppColors.primary),
              label: 'Комнаты',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline, color: AppColors.textSecondary),
              selectedIcon: Icon(Icons.person_rounded, color: AppColors.primary),
              label: 'Профиль',
            ),
          ],
        ),
      ),
    );
  }
}
