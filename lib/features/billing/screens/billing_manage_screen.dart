import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/billing_provider.dart';

class BillingManageScreen extends ConsumerStatefulWidget {
  const BillingManageScreen({super.key});

  @override
  ConsumerState<BillingManageScreen> createState() =>
      _BillingManageScreenState();
}

class _BillingManageScreenState extends ConsumerState<BillingManageScreen> {
  bool _busy = false;

  Future<void> _confirmCancel(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text(l10n.billingManageCancelConfirm,
                style: AppTheme.text(size: 16, weight: FontWeight.w600)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text('Отмена',
                    style: AppTheme.text(color: AppColors.ink2)),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.danger),
                child: Text(l10n.billingManageCancelCta,
                    style: AppTheme.text(weight: FontWeight.w600)),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok) return;
    final cancelledMsg = l10n.billingManageCancelled;
    setState(() => _busy = true);
    try {
      await runMockCancel(ref);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(cancelledMsg)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ru = Localizations.localeOf(context).languageCode == 'ru';
    final subAsync = ref.watch(currentSubscriptionProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: Text(l10n.billingManageTitle,
            style: AppTheme.text(size: 16, weight: FontWeight.w600)),
        elevation: 0,
      ),
      body: subAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.amber)),
        error: (e, _) =>
            Center(child: Text('$e', style: AppTheme.text(color: AppColors.danger))),
        data: (sub) {
          final hasActive = sub.isActive && sub.plan != null;
          if (!hasActive) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.billingPriceFree,
                      style: AppTheme.display(size: 22)),
                  const SizedBox(height: 8),
                  Text(l10n.billingPlansSubtitle,
                      style: AppTheme.text(color: AppColors.ink3)),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => context.push('/billing/plans'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.amber,
                      foregroundColor: AppColors.amberInk,
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 22),
                    ),
                    child: Text(l10n.billingCtaSubscribe,
                        style: AppTheme.text(
                            size: 14, weight: FontWeight.w600)),
                  ),
                ],
              ),
            );
          }
          final expires = sub.expiresAt;
          final formattedDate = expires == null
              ? '∞'
              : '${expires.day.toString().padLeft(2, '0')}.${expires.month.toString().padLeft(2, '0')}.${expires.year}';
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppTheme.r3),
                  border: Border.all(color: AppColors.amber, width: 1.6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sub.plan!.localisedTitle(ru),
                        style: AppTheme.display(
                            size: 22, weight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(
                      l10n.billingManageActive(formattedDate),
                      style: AppTheme.text(
                          size: 13, color: AppColors.ink3),
                    ),
                    if (sub.lastCardLast4 != null &&
                        sub.lastCardLast4!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('•••• ${sub.lastCardLast4}',
                          style: AppTheme.mono(
                              size: 11, color: AppColors.ink3)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _busy ? null : () => _confirmCancel(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.hairline),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.r3)),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              valueColor: AlwaysStoppedAnimation(
                                  AppColors.danger)),
                        )
                      : Text(l10n.billingManageCancelCta,
                          style: AppTheme.text(
                              size: 14, weight: FontWeight.w600)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
