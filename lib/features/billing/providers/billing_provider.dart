import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/providers/auth_provider.dart';

/// One subscription tier as advertised by `/api/billing/plans/`.
class BillingPlan {
  final String slug; // free | pro | cinema
  final String titleRu;
  final String titleEn;
  final String subtitleRu;
  final String subtitleEn;
  final int priceRubMonthly;
  final int priceRubYearly;
  final int priceUsdMonthlyCents;
  final int priceUsdYearlyCents;
  final List<String> featuresRu;
  final List<String> featuresEn;
  final int maxRoomGuests;
  final bool includesAds;
  final int? maxHistoryDays;
  final int position;

  const BillingPlan({
    required this.slug,
    required this.titleRu,
    required this.titleEn,
    required this.subtitleRu,
    required this.subtitleEn,
    required this.priceRubMonthly,
    required this.priceRubYearly,
    required this.priceUsdMonthlyCents,
    required this.priceUsdYearlyCents,
    required this.featuresRu,
    required this.featuresEn,
    required this.maxRoomGuests,
    required this.includesAds,
    required this.maxHistoryDays,
    required this.position,
  });

  bool get isFree => slug == 'free';

  factory BillingPlan.fromJson(Map<String, dynamic> j) => BillingPlan(
        slug: j['slug'] as String,
        titleRu: j['title_ru'] as String? ?? '',
        titleEn: j['title_en'] as String? ?? '',
        subtitleRu: j['subtitle_ru'] as String? ?? '',
        subtitleEn: j['subtitle_en'] as String? ?? '',
        priceRubMonthly: (j['price_rub_monthly'] as num?)?.toInt() ?? 0,
        priceRubYearly: (j['price_rub_yearly'] as num?)?.toInt() ?? 0,
        priceUsdMonthlyCents:
            (j['price_usd_monthly_cents'] as num?)?.toInt() ?? 0,
        priceUsdYearlyCents:
            (j['price_usd_yearly_cents'] as num?)?.toInt() ?? 0,
        featuresRu: List<String>.from(j['features_ru'] as List? ?? const []),
        featuresEn: List<String>.from(j['features_en'] as List? ?? const []),
        maxRoomGuests: (j['max_room_guests'] as num?)?.toInt() ?? 2,
        includesAds: j['includes_ads'] as bool? ?? true,
        maxHistoryDays: (j['max_history_days'] as num?)?.toInt(),
        position: (j['position'] as num?)?.toInt() ?? 0,
      );

  String localisedTitle(bool ru) => ru ? titleRu : titleEn;
  String localisedSubtitle(bool ru) => ru ? subtitleRu : subtitleEn;
  List<String> localisedFeatures(bool ru) => ru ? featuresRu : featuresEn;
}

class BillingSubscription {
  final BillingPlan? plan;
  final String status; // active | cancelled | expired | free
  final String billingPeriod;
  final DateTime? activatedAt;
  final DateTime? expiresAt;
  final String? lastCardLast4;
  final bool isActive;

  const BillingSubscription({
    this.plan,
    required this.status,
    this.billingPeriod = 'monthly',
    this.activatedAt,
    this.expiresAt,
    this.lastCardLast4,
    this.isActive = false,
  });

  factory BillingSubscription.fromJson(Map<String, dynamic> j) {
    final planJson = j['plan'];
    DateTime? parse(Object? v) {
      final s = v as String?;
      if (s == null || s.isEmpty) return null;
      return DateTime.tryParse(s);
    }

    return BillingSubscription(
      plan: planJson is Map<String, dynamic>
          ? BillingPlan.fromJson(planJson)
          : null,
      status: (j['status'] as String?) ?? 'free',
      billingPeriod: (j['billing_period'] as String?) ?? 'monthly',
      activatedAt: parse(j['activated_at']),
      expiresAt: parse(j['expires_at']),
      lastCardLast4: j['last_card_last4'] as String?,
      isActive: j['is_active'] as bool? ?? false,
    );
  }

  static const free = BillingSubscription(status: 'free');
}

final billingPlansProvider =
    FutureProvider.autoDispose<List<BillingPlan>>((ref) async {
  final dio = ref.read(dioProvider);
  final resp = await dio.get<List<dynamic>>(ApiEndpoints.billingPlans);
  final list = resp.data ?? const [];
  return list
      .map((e) => BillingPlan.fromJson(e as Map<String, dynamic>))
      .toList()
    ..sort((a, b) => a.position.compareTo(b.position));
});

final currentSubscriptionProvider =
    FutureProvider.autoDispose<BillingSubscription>((ref) async {
  final dio = ref.read(dioProvider);
  final resp = await dio.get<Map<String, dynamic>>(
      ApiEndpoints.billingSubscription);
  return BillingSubscription.fromJson(resp.data ?? const {});
});

class BillingApi {
  final Dio _dio;
  BillingApi(this._dio);

  Future<int> createCheckout({
    required String planSlug,
    required String billingPeriod,
  }) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.billingCheckout,
      data: {'plan_slug': planSlug, 'billing_period': billingPeriod},
    );
    return (resp.data?['id'] as num).toInt();
  }

  Future<void> completeCheckout({
    required int sessionId,
    required String cardLast4,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.billingCheckoutComplete(sessionId),
      data: {'card_last4': cardLast4},
    );
  }

  Future<void> cancel() async {
    await _dio.post<Map<String, dynamic>>(ApiEndpoints.billingCancel);
  }
}

final billingApiProvider = Provider<BillingApi>((ref) {
  return BillingApi(ref.read(dioProvider));
});

/// Convenience — kicks off checkout + complete + refreshes auth profile so
/// the rest of the UI sees the new tier without restart.
Future<void> runMockCheckout({
  required WidgetRef ref,
  required String planSlug,
  required String billingPeriod,
  required String cardLast4,
}) async {
  final api = ref.read(billingApiProvider);
  final sessionId = await api.createCheckout(
    planSlug: planSlug,
    billingPeriod: billingPeriod,
  );
  // Tiny delay so the spinner visibly does something — UX, not logic.
  await Future<void>.delayed(const Duration(milliseconds: 800));
  await api.completeCheckout(
    sessionId: sessionId,
    cardLast4: cardLast4,
  );
  ref.invalidate(currentSubscriptionProvider);
  await ref.read(authStateProvider.notifier).refreshProfile();
}

Future<void> runMockCancel(WidgetRef ref) async {
  await ref.read(billingApiProvider).cancel();
  ref.invalidate(currentSubscriptionProvider);
  await ref.read(authStateProvider.notifier).refreshProfile();
}
