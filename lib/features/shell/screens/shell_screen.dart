import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

class ShellScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ShellScreen({super.key, required this.navigationShell});

  static const _items = [
    _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Сейчас'),
    _NavItem(icon: Icons.live_tv_outlined, activeIcon: Icons.live_tv_rounded, label: 'Комнаты'),
    _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Я'),
  ];

  @override
  Widget build(BuildContext context) {
    final current = navigationShell.currentIndex;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.bg,
            border: Border(
              top: BorderSide(color: AppColors.hairline, width: 1),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 14),
          child: Row(
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final selected = i == current;
              return Expanded(
                child: InkResponse(
                  onTap: () => navigationShell.goBranch(i, initialLocation: i == current),
                  radius: 36,
                  highlightShape: BoxShape.circle,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          selected ? item.activeIcon : item.icon,
                          size: 22,
                          color: selected ? AppColors.ink : AppColors.ink3,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: AppTheme.text(
                            size: 10,
                            weight: selected ? FontWeight.w600 : FontWeight.w500,
                            color: selected ? AppColors.ink : AppColors.ink3,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}
