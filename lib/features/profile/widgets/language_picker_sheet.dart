import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/settings_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

class LanguagePickerSheet extends ConsumerWidget {
  const LanguagePickerSheet({super.key});

  static const _options = [
    ('ru', 'Русский'),
    ('en', 'English'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final current = ref.watch(settingsProvider).locale?.languageCode ?? 'ru';

    return SettingsSheetShell(
      title: l.profileLanguage,
      children: [
        for (final (code, name) in _options)
          SettingsSheetOption(
            label: name,
            selected: current == code,
            onTap: () async {
              await ref
                  .read(settingsProvider.notifier)
                  .setLocale(Locale(code));
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
      ],
    );
  }
}

/// Bottom-sheet chrome shared between language and microphone pickers:
/// the rounded card, drag handle, title, and content list. Public so other
/// settings sheets in `lib/features/profile/widgets/` can reuse it without
/// reimplementing the same shell.
class SettingsSheetShell extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const SettingsSheetShell({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.r3)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.ink4,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(title,
                style: AppTheme.display(size: 18, weight: FontWeight.w600)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class SettingsSheetOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? subtitle;

  const SettingsSheetOption({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.r2),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.text(size: 15, weight: FontWeight.w500)),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.text(
                            size: 12, color: AppColors.ink3, weight: FontWeight.w400)),
                  ],
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_rounded, size: 20, color: AppColors.amber),
          ],
        ),
      ),
    );
  }
}
