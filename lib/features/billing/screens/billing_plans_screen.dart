import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/billing_provider.dart';

/// Side-by-side comparison of all subscription plans.
///
/// Free | Pro | Cinema, with the amber CTA on the active recommendation
/// (Pro by default; whichever the user opened the screen with via
/// `?plan=` query parameter).
class BillingPlansScreen extends ConsumerStatefulWidget {
  /// Plan slug pre-selected from a deeplink (`?plan=pro`).
  final String? highlightedSlug;
  const BillingPlansScreen({super.key, this.highlightedSlug});

  @override
  ConsumerState<BillingPlansScreen> createState() => _BillingPlansScreenState();
}

class _BillingPlansScreenState extends ConsumerState<BillingPlansScreen> {
  String _period = 'monthly'; // monthly | yearly

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ru = Localizations.localeOf(context).languageCode == 'ru';
    final plansAsync = ref.watch(billingPlansProvider);
    final subAsync = ref.watch(currentSubscriptionProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: Text(l10n.billingPlansTitle, style: AppTheme.text(size: 16, weight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => context.canPop() ? context.pop() : context.go('/profile'),
        ),
        elevation: 0,
      ),
      body: plansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.amber)),
        error: (e, _) => Center(child: Text('$e', style: AppTheme.text(color: AppColors.danger))),
        data: (plans) {
          final currentSlug = subAsync.maybeWhen(
            data: (s) => s.plan?.slug ?? 'free',
            orElse: () => 'free',
          );
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Text(l10n.billingPlansSubtitle,
                  style: AppTheme.display(size: 22, height: 1.2)),
              const SizedBox(height: 18),
              _PeriodToggle(
                period: _period,
                onChanged: (v) => setState(() => _period = v),
              ),
              const SizedBox(height: 22),
              for (final plan in plans) ...[
                _PlanCard(
                  plan: plan,
                  ru: ru,
                  period: _period,
                  isCurrent: plan.slug == currentSlug,
                  isHighlighted: plan.slug == widget.highlightedSlug,
                  onSubscribe: plan.isFree
                      ? null
                      : () => context.push(
                          '/billing/checkout?plan=${plan.slug}&period=$_period'),
                ),
                const SizedBox(height: 14),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _PeriodToggle extends StatelessWidget {
  final String period;
  final ValueChanged<String> onChanged;
  const _PeriodToggle({required this.period, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget seg(String value, String label) {
      final selected = period == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(value),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.amber : Colors.transparent,
              borderRadius: BorderRadius.circular(AppTheme.r3),
            ),
            child: Text(
              label,
              style: AppTheme.text(
                size: 13,
                weight: FontWeight.w600,
                color: selected ? AppColors.amberInk : AppColors.ink2,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.r3),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        children: [
          seg('monthly', l10n.billingPeriodMonthly),
          seg('yearly', l10n.billingPeriodYearly),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final BillingPlan plan;
  final bool ru;
  final String period;
  final bool isCurrent;
  final bool isHighlighted;
  final VoidCallback? onSubscribe;

  const _PlanCard({
    required this.plan,
    required this.ru,
    required this.period,
    required this.isCurrent,
    required this.isHighlighted,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final accent = isHighlighted || plan.slug == 'pro';

    String priceText() {
      if (plan.isFree) return l10n.billingPriceFree;
      if (ru) {
        final amount = period == 'yearly'
            ? plan.priceRubYearly
            : plan.priceRubMonthly;
        return period == 'yearly'
            ? l10n.billingPriceYearly(amount.toString())
            : l10n.billingPriceMonthly(amount.toString());
      }
      final cents = period == 'yearly'
          ? plan.priceUsdYearlyCents
          : plan.priceUsdMonthlyCents;
      final formatted = (cents / 100).toStringAsFixed(2);
      return period == 'yearly'
          ? l10n.billingPriceYearly(formatted)
          : l10n.billingPriceMonthly(formatted);
    }

    final ctaLabel = isCurrent ? l10n.billingCtaCurrent : l10n.billingCtaSubscribe;
    final canTapCta = !plan.isFree && !isCurrent && onSubscribe != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.r3),
        border: Border.all(
          color: accent ? AppColors.amber : AppColors.hairline,
          width: accent ? 1.6 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(plan.localisedTitle(ru),
                  style: AppTheme.display(size: 20, weight: FontWeight.w600)),
              const SizedBox(width: 10),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.liveDim,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l10n.billingCtaCurrent,
                    style: AppTheme.mono(
                        size: 9,
                        color: AppColors.live,
                        weight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(plan.localisedSubtitle(ru),
              style: AppTheme.text(size: 13, color: AppColors.ink3)),
          const SizedBox(height: 14),
          Text(priceText(), style: AppTheme.display(size: 26, weight: FontWeight.w700)),
          const SizedBox(height: 14),
          for (final f in plan.localisedFeatures(ru))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_rounded,
                      size: 16, color: AppColors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(f,
                        style: AppTheme.text(
                            size: 13, color: AppColors.ink2, height: 1.35)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: canTapCta ? onSubscribe : null,
              style: FilledButton.styleFrom(
                backgroundColor:
                    accent ? AppColors.amber : AppColors.surface2,
                foregroundColor:
                    accent ? AppColors.amberInk : AppColors.ink,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.r3)),
                disabledBackgroundColor: AppColors.surface2,
                disabledForegroundColor: AppColors.ink3,
              ),
              child: Text(ctaLabel,
                  style: AppTheme.text(size: 14, weight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
