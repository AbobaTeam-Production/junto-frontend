import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Reusable bottom-sheet shown at points where a Free user hits a
/// Pro-only feature. Use [showProPaywall] from anywhere with a
/// `BuildContext` to surface it; pass a [title]/[body] that name the
/// specific feature being gated.
class ProPaywallSheet extends StatelessWidget {
  final String title;
  final String body;
  final String ctaLabel;

  const ProPaywallSheet({
    super.key,
    required this.title,
    required this.body,
    required this.ctaLabel,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppColors.amberDim,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.workspace_premium_rounded,
                  color: AppColors.amber, size: 30),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: AppTheme.display(size: 20, weight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(body,
                style: AppTheme.text(
                    size: 14, color: AppColors.ink2, height: 1.45)),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.push('/billing/plans?plan=pro');
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.amber,
                foregroundColor: AppColors.amberInk,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.r3)),
              ),
              child: Text(ctaLabel,
                  style: AppTheme.text(size: 15, weight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showProPaywall(
  BuildContext context, {
  required String title,
  required String body,
  required String ctaLabel,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.r3)),
    ),
    isScrollControlled: true,
    builder: (_) =>
        ProPaywallSheet(title: title, body: body, ctaLabel: ctaLabel),
  );
}
