import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/billing_provider.dart';

/// Confirmation that the mock checkout went through. Pure visual —
/// no real payment was made.
class BillingSuccessScreen extends ConsumerWidget {
  final String planSlug;
  const BillingSuccessScreen({super.key, required this.planSlug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ru = Localizations.localeOf(context).languageCode == 'ru';
    final plansAsync = ref.watch(billingPlansProvider);

    final planLabel = plansAsync.when(
      data: (plans) {
        final p = plans.firstWhere(
          (e) => e.slug == planSlug,
          orElse: () => plans.first,
        );
        return p.localisedTitle(ru);
      },
      loading: () => 'Junto Pro',
      error: (_, _) => 'Junto Pro',
    );

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  color: AppColors.amberDim,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    size: 64, color: AppColors.amber),
              ),
              const SizedBox(height: 28),
              Text(l10n.billingSuccessTitle,
                  style: AppTheme.display(size: 28, weight: FontWeight.w700)),
              const SizedBox(height: 10),
              Text(
                l10n.billingSuccessBody(planLabel),
                style: AppTheme.text(
                    size: 16, color: AppColors.ink2, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 2),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.go('/home'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.amber,
                    foregroundColor: AppColors.amberInk,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.r3)),
                  ),
                  child: Text(l10n.billingSuccessCta,
                      style: AppTheme.text(size: 15, weight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
