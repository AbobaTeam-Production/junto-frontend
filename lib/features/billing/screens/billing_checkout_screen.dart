import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/billing_provider.dart';

/// Mock card-input + "pay" flow.
///
/// No real tokenisation — we accept any 16 digits, any MM/YY, any 3-digit
/// CVC. After tap on the CTA we briefly show a spinner, then call the
/// backend's mock checkout/complete pair, and finally navigate to the
/// success screen.
class BillingCheckoutScreen extends ConsumerStatefulWidget {
  final String planSlug;
  final String period;
  const BillingCheckoutScreen({
    super.key,
    required this.planSlug,
    required this.period,
  });

  @override
  ConsumerState<BillingCheckoutScreen> createState() =>
      _BillingCheckoutScreenState();
}

class _BillingCheckoutScreenState extends ConsumerState<BillingCheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardController = TextEditingController(text: '4242 4242 4242 4242');
  final _expiryController = TextEditingController(text: '12 / 28');
  final _cvcController = TextEditingController(text: '123');
  bool _processing = false;

  @override
  void dispose() {
    _cardController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    super.dispose();
  }

  Future<void> _pay(BillingPlan plan) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _processing = true);
    try {
      final cardLast4 = _cardController.text
          .replaceAll(' ', '')
          .padLeft(4, '0')
          .substring(_cardController.text.replaceAll(' ', '').length - 4);
      await runMockCheckout(
        ref: ref,
        planSlug: widget.planSlug,
        billingPeriod: widget.period,
        cardLast4: cardLast4,
      );
      if (!mounted) return;
      context.go('/billing/success?plan=${widget.planSlug}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
      setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ru = Localizations.localeOf(context).languageCode == 'ru';
    final plansAsync = ref.watch(billingPlansProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: Text(l10n.billingCheckoutTitle,
            style: AppTheme.text(size: 16, weight: FontWeight.w600)),
        elevation: 0,
      ),
      body: plansAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.amber)),
        error: (e, _) =>
            Center(child: Text('$e', style: AppTheme.text(color: AppColors.danger))),
        data: (plans) {
          final plan = plans.firstWhere(
            (p) => p.slug == widget.planSlug,
            orElse: () => plans.first,
          );
          final priceLabel = ru
              ? '${widget.period == 'yearly' ? plan.priceRubYearly : plan.priceRubMonthly}'
              : ((widget.period == 'yearly'
                          ? plan.priceUsdYearlyCents
                          : plan.priceUsdMonthlyCents) /
                      100)
                  .toStringAsFixed(2);
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                _Summary(plan: plan, period: widget.period, ru: ru),
                const SizedBox(height: 24),
                _CardField(
                  label: l10n.billingCheckoutCardNumber,
                  controller: _cardController,
                  keyboardType: TextInputType.number,
                  formatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(16),
                    _CardNumberFormatter(),
                  ],
                  validator: (v) {
                    final digits = v?.replaceAll(' ', '') ?? '';
                    if (digits.length < 12) return '';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _CardField(
                        label: l10n.billingCheckoutCardExpiry,
                        controller: _expiryController,
                        keyboardType: TextInputType.number,
                        formatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                          _ExpiryFormatter(),
                        ],
                        validator: (v) {
                          final digits =
                              v?.replaceAll(RegExp(r'\D'), '') ?? '';
                          if (digits.length < 4) return '';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 110,
                      child: _CardField(
                        label: l10n.billingCheckoutCardCvc,
                        controller: _cvcController,
                        keyboardType: TextInputType.number,
                        formatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        obscure: true,
                        validator: (v) =>
                            (v == null || v.length < 3) ? '' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(l10n.billingCheckoutDisclaimer,
                    style: AppTheme.text(
                        size: 12, color: AppColors.ink3, height: 1.4)),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _processing ? null : () => _pay(plan),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.amber,
                      foregroundColor: AppColors.amberInk,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.r3)),
                    ),
                    child: _processing
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation(
                                    AppColors.amberInk)),
                          )
                        : Text(
                            l10n.billingCheckoutPayCta(priceLabel),
                            style: AppTheme.text(
                                size: 15, weight: FontWeight.w600),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final BillingPlan plan;
  final String period;
  final bool ru;
  const _Summary({required this.plan, required this.period, required this.ru});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final periodLabel = period == 'yearly'
        ? l10n.billingPeriodYearly
        : l10n.billingPeriodMonthly;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.r3),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.amberDim,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.workspace_premium_rounded,
                color: AppColors.amber, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plan.localisedTitle(ru),
                    style: AppTheme.text(size: 16, weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(periodLabel,
                    style: AppTheme.text(size: 12, color: AppColors.ink3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final List<TextInputFormatter> formatters;
  final String? Function(String?)? validator;
  final bool obscure;

  const _CardField({
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.formatters = const [],
    this.validator,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      obscureText: obscure,
      style: AppTheme.text(size: 15, weight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTheme.text(size: 12, color: AppColors.ink3),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.r2),
          borderSide: const BorderSide(color: AppColors.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.r2),
          borderSide: const BorderSide(color: AppColors.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.r2),
          borderSide: const BorderSide(color: AppColors.amber, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.r2),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        errorStyle: const TextStyle(height: 0, fontSize: 0),
      ),
      validator: validator,
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(' ', '');
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    final out = buf.toString();
    return TextEditingValue(
      text: out,
      selection: TextSelection.collapsed(offset: out.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    String out;
    if (digits.length < 3) {
      out = digits;
    } else {
      out = '${digits.substring(0, 2)} / ${digits.substring(2, digits.length.clamp(0, 4))}';
    }
    return TextEditingValue(
      text: out,
      selection: TextSelection.collapsed(offset: out.length),
    );
  }
}
