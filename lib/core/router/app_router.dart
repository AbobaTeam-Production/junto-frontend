import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../api/api_client.dart';
import '../providers/auth_provider.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/rooms/screens/rooms_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/friends_screen.dart';
import '../../features/shell/screens/shell_screen.dart';
import '../../features/room/screens/room_screen.dart';
import '../../features/splash/splash_screen.dart';

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
      final path = state.uri.path;

      // While auth is still loading we park on /splash. Cold-start used to
      // briefly render /login here because tryRestoreSession() resolves
      // async — the splash route absorbs that window.
      if (status == AuthStatus.unknown) {
        return path == '/splash' ? null : '/splash';
      }

      // Auth is now resolved — bail out of /splash to the right destination.
      if (path == '/splash') {
        if (status == AuthStatus.authenticated) return '/home';
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
                  child: HomeScreen(),
                ),
              ),
            ],
          ),
          // Tab 1: Rooms
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/rooms',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: RoomsScreen(),
                ),
              ),
            ],
          ),
          // Tab 2: Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ProfileScreen(),
                ),
              ),
            ],
          ),
        ],
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
