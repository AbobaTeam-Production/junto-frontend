import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../api/api_client.dart';
import '../providers/auth_provider.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/onboarding/screens/onboarding_taste_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/home/screens/home_responsive.dart';
import '../../features/rooms/screens/rooms_responsive.dart';
import '../../features/profile/screens/profile_responsive.dart';
import '../../features/profile/screens/friends_screen.dart';
import '../../features/shell/screens/shell_screen.dart';
import '../../features/room/screens/room_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/recs/screens/recs_feed_screen.dart';
import '../../features/recs/screens/recs_match_screen.dart';
import '../../features/recs/screens/recs_mood_screen.dart';
import '../../features/recs/screens/recs_search_screen.dart';
import '../../features/recs/screens/recs_title_screen.dart';
import '../../features/billing/screens/billing_plans_screen.dart';
import '../../features/billing/screens/billing_checkout_screen.dart';
import '../../features/billing/screens/billing_success_screen.dart';
import '../../features/billing/screens/billing_manage_screen.dart';

/// Bridges Riverpod → GoRouter: notifies GoRouter to re-evaluate redirects
/// whenever auth state changes, without recreating the router.
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, _) => notifyListeners());
  }
}

final _authNotifierProvider = Provider<_AuthNotifier>((ref) {
  return _AuthNotifier(ref);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.read(_authNotifierProvider);
  final tokenService = ref.read(tokenServiceProvider);
  final seenOnboarding = tokenService.onboardingSeen;

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final status = ref.read(authStateProvider).status;
      final user = ref.read(authStateProvider).user;
      final path = state.uri.path;

      // While auth is still loading we park on /splash. Cold-start used to
      // briefly render /login here because tryRestoreSession() resolves
      // async — the splash route absorbs that window.
      if (status == AuthStatus.unknown) {
        return path == '/splash' ? null : '/splash';
      }

      // Auth is now resolved — bail out of /splash to the right destination.
      if (path == '/splash') {
        if (status == AuthStatus.authenticated) {
          // Cold accounts go through taste capture first so the recs
          // feed isn't empty on their first open.
          if (user != null && !user.isGuest && !user.hasTasteSignal) {
            return '/onboarding/taste';
          }
          return '/home';
        }
        return seenOnboarding ? '/login' : '/onboarding';
      }

      final isAuthRoute =
          path == '/login' || path == '/register' || path == '/onboarding';

      // Skip onboarding if already seen
      if (path == '/onboarding' && seenOnboarding) {
        return '/login';
      }

      if (status == AuthStatus.unauthenticated && !isAuthRoute) {
        return '/login';
      }
      if (status == AuthStatus.authenticated && isAuthRoute) {
        return '/home';
      }

      // After login of a fresh account — push them through the taste
      // capture once before the empty feed. Once they submit (or skip)
      // the profile flips has_taste_signal=true and this redirect
      // stops bouncing.
      if (status == AuthStatus.authenticated &&
          user != null &&
          !user.isGuest &&
          !user.hasTasteSignal &&
          path != '/onboarding/taste') {
        return '/onboarding/taste';
      }

      return null;
    },
    routes: [
      // Splash — covers the auth-restore window. The redirect above
      // bounces away from here as soon as AuthStatus resolves.
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: SplashScreen(),
        ),
      ),

      // Cold-start taste capture — gated by `has_taste_signal` in the
      // profile. Shown once per fresh account.
      GoRoute(
        path: '/onboarding/taste',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingTasteScreen(),
          transitionsBuilder: (context, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),

      // Onboarding — first launch
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingScreen(),
          transitionsBuilder: (context, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),

      // Auth
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: (context, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const RegisterScreen(),
          transitionsBuilder: (context, animation, _, child) => SlideTransition(
            position: Tween(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        ),
      ),

      // Main shell with bottom nav
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ShellScreen(navigationShell: navigationShell),
        branches: [
          // Tab 0: Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: HomeResponsive(),
                ),
              ),
            ],
          ),
          // Tab 1: Recs (Подборки)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/recs',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: RecsFeedScreen(),
                ),
              ),
            ],
          ),
          // Tab 2: Rooms
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/rooms',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: RoomsResponsive(),
                ),
              ),
            ],
          ),
          // Tab 3: Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ProfileResponsive(),
                ),
              ),
            ],
          ),
        ],
      ),

      // Recs sub-routes — outside shell, pushed from feed
      GoRoute(
        path: '/recs/search',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const RecsSearchScreen(),
          transitionsBuilder: (context, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      GoRoute(
        path: '/recs/match/:friendId',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: RecsMatchScreen(
            friendId: int.parse(state.pathParameters['friendId']!),
          ),
          transitionsBuilder: (context, animation, _, child) => SlideTransition(
            position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        ),
      ),
      GoRoute(
        path: '/recs/mood/:slug',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: RecsMoodScreen(slug: state.pathParameters['slug']!),
          transitionsBuilder: (context, animation, _, child) => SlideTransition(
            position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        ),
      ),
      GoRoute(
        path: '/recs/title/:movieId',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: RecsTitleScreen(
            movieId: int.parse(state.pathParameters['movieId']!),
          ),
          transitionsBuilder: (context, animation, _, child) => SlideTransition(
            position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        ),
      ),

      // Friends — outside shell, pushed from Profile
      GoRoute(
        path: '/friends',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const FriendsScreen(),
          transitionsBuilder: (context, animation, _, child) =>
              SlideTransition(
            position: Tween(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        ),
      ),

      // Billing — outside shell, pushed from Profile / paywall sheets.
      GoRoute(
        path: '/billing/plans',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: BillingPlansScreen(
            highlightedSlug: state.uri.queryParameters['plan'],
          ),
          transitionsBuilder: (context, animation, _, child) => SlideTransition(
            position: Tween(begin: const Offset(0, 1), end: Offset.zero)
                .animate(CurvedAnimation(
                    parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
      ),
      GoRoute(
        path: '/billing/checkout',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: BillingCheckoutScreen(
            planSlug: state.uri.queryParameters['plan'] ?? 'pro',
            period: state.uri.queryParameters['period'] ?? 'monthly',
          ),
          transitionsBuilder: (context, animation, _, child) => SlideTransition(
            position: Tween(begin: const Offset(1, 0), end: Offset.zero)
                .animate(CurvedAnimation(
                    parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
      ),
      GoRoute(
        path: '/billing/success',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: BillingSuccessScreen(
            planSlug: state.uri.queryParameters['plan'] ?? 'pro',
          ),
          transitionsBuilder: (context, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      GoRoute(
        path: '/billing/manage',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const BillingManageScreen(),
          transitionsBuilder: (context, animation, _, child) => SlideTransition(
            position: Tween(begin: const Offset(1, 0), end: Offset.zero)
                .animate(CurvedAnimation(
                    parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
      ),

      // Room — outside shell (full screen)
      GoRoute(
        path: '/room/:roomId',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: RoomScreen(roomId: state.pathParameters['roomId']!),
          transitionsBuilder: (context, animation, _, child) =>
              SlideTransition(
            position: Tween(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        ),
      ),
    ],
  );
});
