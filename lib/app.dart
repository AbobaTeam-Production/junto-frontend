import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_colors.dart';
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
      builder: _webPhoneFrame,
      // Flutter's default ScrollBehavior on Web doesn't accept mouse-drag —
      // horizontal carousels in /recs become un-scrollable on desktop.
      scrollBehavior: const _AppScrollBehavior(),
    );
  }

  /// On Web we have two layout modes:
  /// - **Desktop** (`width >= 900`): full-width — the shell renders its
  ///   own top bar + sidebar via `WebDesktopShell`, and standalone routes
  ///   (auth / onboarding / room / billing) want the whole viewport too.
  ///   We add a soft 480-px cap only for the auth/onboarding forms so they
  ///   don't stretch into illegible single-line buttons.
  /// - **Narrow** (`width < 900`): clamp everything to a 480-px column
  ///   so the mobile-designed UI keeps its proportions in a browser.
  /// Native builds fall through unchanged.
  Widget _webPhoneFrame(BuildContext context, Widget? child) {
    final c = child ?? const SizedBox.shrink();
    if (!kIsWeb) return c;
    final w = MediaQuery.of(context).size.width;
    if (w < 900) {
      if (w <= 600) return c;
      return ColoredBox(
        color: AppColors.bg,
        child: Center(child: SizedBox(width: 480, child: c)),
      );
    }

    final router = ref.read(appRouterProvider);
    return ListenableBuilder(
      listenable: router.routeInformationProvider,
      builder: (ctx, _) {
        final path =
            router.routerDelegate.currentConfiguration.uri.path;
        // Auth + onboarding forms still look better as a 480-px column on
        // a wide viewport — the form fields don't benefit from extra width.
        const formRoutes = ['/login', '/register', '/onboarding', '/splash'];
        if (formRoutes.any((r) => path == r || path.startsWith('$r/'))) {
          return ColoredBox(
            color: AppColors.bg,
            child: Center(child: SizedBox(width: 480, child: c)),
          );
        }
        return c;
      },
    );
  }
}

/// Lets the user drag-scroll lists with a mouse on desktop Web. The
/// default Material behavior only enables touch + trackpad, so on a
/// desktop browser horizontal carousels look stuck.
class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
      };
}
