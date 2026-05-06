import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/fcm_provider.dart';
import 'core/providers/settings_provider.dart';
import 'l10n/app_localizations.dart';

class JuntoApp extends ConsumerStatefulWidget {
  const JuntoApp({super.key});

  @override
  ConsumerState<JuntoApp> createState() => _JuntoAppState();
}

class _JuntoAppState extends ConsumerState<JuntoApp> {
  @override
  void initState() {
    super.initState();
    // Try to restore session from saved tokens
    Future.microtask(() {
      ref.read(authStateProvider.notifier).tryRestoreSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeProvider);
    // Keep the FCM lifecycle alive for the whole app session — registers
    // / unregisters the device as auth and the notifications toggle flip.
    ref.watch(fcmLifecycleProvider);
    return MaterialApp.router(
      title: 'Junto',
      theme: AppTheme.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
    );
  }
}
