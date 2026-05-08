/// FCM lifecycle wired to auth state.
///
/// Idle until the user signs in; on `authenticated` we initialise Firebase
/// (if not already), request permission, fetch a token, POST it to
/// `/api/users/devices/`. On logout we DELETE the last registered device
/// so the server stops blasting pushes to a token nobody owns anymore.
///
/// Platform support: Android, iOS, Web. Windows / Linux are guarded out
/// — `firebase_messaging` has no plugin implementation there and would
/// throw `MissingPluginException` at every call. The `Notifications`
/// row in the profile is hidden on those platforms.
library;

import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'fcm_sw_navigation_stub.dart'
    if (dart.library.js_interop) 'fcm_sw_navigation_web.dart' as sw_nav;

import '../../firebase_options.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../router/app_router.dart';
import 'auth_provider.dart';
import 'friends_provider.dart';
import 'settings_provider.dart';

/// True on platforms where firebase_messaging has a real implementation.
/// Used both to gate every call here and to hide the UI toggle.
bool get fcmSupported {
  if (kIsWeb) return true;
  try {
    return Platform.isAndroid || Platform.isIOS;
  } catch (_) {
    // Platform throws on web — already handled by kIsWeb above. This
    // catch covers any future runtime where Platform isn't usable.
    return false;
  }
}

/// Result of an explicit register request — used by the Profile toggle
/// to give the user a clear "what happened?" SnackBar.
enum FcmRegisterStatus {
  /// Successful register (or already registered). UserDevice exists.
  ok,
  /// Browser / OS denied the permission prompt.
  permissionDenied,
  /// Platform doesn't support FCM (Windows / Linux native).
  unsupported,
  /// Got a token but the POST to /api/users/devices/ failed.
  backendError,
  /// Unexpected — Firebase init or getToken threw.
  initError,
}

class FcmController {
  FcmController(this._ref);

  final Ref _ref;
  bool _firebaseInited = false;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _messageSub;
  StreamSubscription<RemoteMessage>? _openedSub;
  int? _registeredDeviceId;
  String? _registeredToken;
  String? _lastError;
  String get lastError => _lastError ?? '';
  bool _initialMessageConsumed = false;

  Future<void> _ensureFirebase() async {
    if (_firebaseInited) return;
    if (kIsWeb) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.web);
    } else {
      // Android reads google-services.json via the Gradle plugin; iOS reads
      // GoogleService-Info.plist (not bundled yet — that lands when iOS
      // builds are wired up).
      await Firebase.initializeApp();
    }
    _firebaseInited = true;
  }

  /// Registers the current device with the backend. Safe to call
  /// multiple times — the backend upserts on (user, fcm_token).
  ///
  /// Returns a structured result so a UI caller (the Profile toggle)
  /// can surface "permission denied" / "no Play Services" etc as a
  /// SnackBar. Internal callers (lifecycle) ignore the result.
  Future<FcmRegisterStatus> register() async {
    if (!fcmSupported) {
      _lastError = 'platform unsupported';
      return FcmRegisterStatus.unsupported;
    }
    try {
      await _ensureFirebase();
    } catch (e) {
      debugPrint('FCM ensureFirebase failed: $e');
      _lastError = 'init: $e';
      return FcmRegisterStatus.initError;
    }

    final messaging = FirebaseMessaging.instance;
    NotificationSettings settings;
    try {
      // On iOS / Web this prompts the user. Android <13 grants by
      // default; Android 13+ shows the system POST_NOTIFICATIONS
      // dialog. On Web, the prompt only shows if the call has a
      // user-gesture chain — otherwise some browsers silently return
      // 'default' / 'denied' without UI. The Profile toggle's onTap
      // is the gesture root for explicit calls.
      settings = await messaging.requestPermission();
    } catch (e) {
      debugPrint('FCM requestPermission threw: $e');
      _lastError = 'permission: $e';
      return FcmRegisterStatus.initError;
    }

    debugPrint('FCM permission status: ${settings.authorizationStatus}');
    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      _lastError = 'permission ${settings.authorizationStatus.name}';
      return FcmRegisterStatus.permissionDenied;
    }

    String? token;
    try {
      token = await messaging.getToken(
        vapidKey: kIsWeb ? DefaultFirebaseOptions.webPushVapidKey : null,
      );
    } catch (e) {
      debugPrint('FCM getToken threw: $e');
      _lastError = 'getToken: $e';
      return FcmRegisterStatus.initError;
    }
    if (token == null || token.isEmpty) {
      _lastError = 'getToken returned empty';
      return FcmRegisterStatus.initError;
    }
    debugPrint('FCM token length: ${token.length}');

    try {
      await _postDevice(token);
    } catch (e) {
      debugPrint('FCM _postDevice failed: $e');
      _lastError = 'backend: $e';
      return FcmRegisterStatus.backendError;
    }

    _attachListeners(messaging);
    _lastError = null;
    return FcmRegisterStatus.ok;
  }

  Future<void> _postDevice(String token) async {
    if (_registeredToken == token && _registeredDeviceId != null) {
      return; // nothing changed
    }
    final dio = _ref.read(dioProvider);
    final platform = kIsWeb
        ? 'web'
        : (Platform.isAndroid ? 'android' : 'ios');
    final resp = await dio.post(
      ApiEndpoints.userDevices,
      data: {'fcm_token': token, 'platform': platform},
    );
    _registeredDeviceId = resp.data['id'] as int?;
    _registeredToken = token;
  }

  void _attachListeners(FirebaseMessaging messaging) {
    _tokenRefreshSub ??= messaging.onTokenRefresh.listen((newToken) async {
      try {
        await _postDevice(newToken);
      } catch (e) {
        debugPrint('FCM token refresh upsert failed: $e');
      }
    });
    _messageSub ??= FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    _openedSub ??= FirebaseMessaging.onMessageOpenedApp.listen(_onTapped);

    // Cold-start case — when the app was terminated and Android
    // launched it from a notification tap, onMessageOpenedApp does
    // NOT fire. Instead the launch RemoteMessage hides in
    // getInitialMessage() and we have to apply it manually. Without
    // this hook the user landed on /home instead of /room/<id>.
    _consumeInitialMessage(messaging);

    if (kIsWeb) {
      // The Web SW posts {type: 'fcm_navigate', path} on
      // notificationclick because firebase_messaging's
      // onMessageOpenedApp is unreliable on Web (only fires from a
      // closed-tab scenario). We subscribe to those SW messages and
      // route via go_router.
      sw_nav.subscribeFcmNavigate((path) {
        if (path.startsWith('/')) {
          _ref.read(appRouterProvider).push(path);
        }
      });
    }
  }

  void _onForegroundMessage(RemoteMessage msg) {
    final type = msg.data['type'] as String?;
    if (type == 'friend_request') {
      _ref.invalidate(friendRequestsProvider);
    } else if (type == 'friend_accepted') {
      _ref.invalidate(friendsListProvider);
    }

    final ctx = _ref.read(appRouterProvider).routerDelegate.navigatorKey
        .currentContext;
    if (ctx == null || msg.notification == null) return;

    final body = msg.notification!.body ?? msg.notification!.title ?? '';
    if (type == 'room_invite') {
      // Actionable SnackBar — tap «Зайти» to jump straight in. The
      // backend payload carries room_id; we route to it.
      final roomId = msg.data['room_id'] as String?;
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(body),
          duration: const Duration(seconds: 6),
          action: roomId == null
              ? null
              : SnackBarAction(
                  label: 'Зайти',
                  onPressed: () =>
                      _ref.read(appRouterProvider).push('/room/$roomId'),
                ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(body)));
  }

  void _onTapped(RemoteMessage msg) {
    final type = msg.data['type'] as String?;
    if (type == 'friend_request' || type == 'friend_accepted') {
      _ref.read(appRouterProvider).go('/friends');
    } else if (type == 'room_invite') {
      final roomId = msg.data['room_id'] as String?;
      if (roomId != null) _ref.read(appRouterProvider).push('/room/$roomId');
    }
  }

  /// One-shot read of the message that launched the app from the
  /// notification tray (terminated → tap). Defers actual routing
  /// until after auth resolves so go_router doesn't bounce us back
  /// to /splash → /login mid-flight.
  Future<void> _consumeInitialMessage(FirebaseMessaging messaging) async {
    if (_initialMessageConsumed) return;
    _initialMessageConsumed = true;
    try {
      final msg = await messaging.getInitialMessage();
      if (msg == null) return;
      // Wait until auth is resolved — on cold start AuthStatus
      // starts as `unknown`; routing to /room before
      // tryRestoreSession completes would be eaten by the splash
      // redirect.
      await _waitForAuthResolved();
      if (_ref.read(authStateProvider).status != AuthStatus.authenticated) {
        return;
      }
      _onTapped(msg);
    } catch (e) {
      debugPrint('FCM getInitialMessage failed: $e');
    }
  }

  Future<void> _waitForAuthResolved() async {
    final auth = _ref.read(authStateProvider);
    if (auth.status != AuthStatus.unknown) return;
    final completer = Completer<void>();
    final sub = _ref.listen<AuthState>(
      authStateProvider,
      (_, next) {
        if (next.status != AuthStatus.unknown && !completer.isCompleted) {
          completer.complete();
        }
      },
    );
    try {
      await completer.future.timeout(const Duration(seconds: 8),
          onTimeout: () {});
    } finally {
      sub.close();
    }
  }

  /// Removes this device from the backend so the server stops pushing to
  /// it. Called on logout / when the user disables notifications.
  Future<void> unregister() async {
    final id = _registeredDeviceId;
    if (id == null) return;
    try {
      final dio = _ref.read(dioProvider);
      await dio.delete(ApiEndpoints.userDeviceDelete(id));
    } catch (e) {
      debugPrint('FCM device delete failed: $e');
    } finally {
      _registeredDeviceId = null;
      _registeredToken = null;
    }
  }

  void dispose() {
    _tokenRefreshSub?.cancel();
    _messageSub?.cancel();
    _openedSub?.cancel();
  }
}

final fcmControllerProvider = Provider<FcmController>((ref) {
  final controller = FcmController(ref);
  ref.onDispose(controller.dispose);
  return controller;
});

/// Watches auth + notifications-toggle state and registers / unregisters
/// the device accordingly. Imported (via `ref.watch(fcmLifecycleProvider)`)
/// once near the app root so it stays alive for the whole session.
final fcmLifecycleProvider = Provider<void>((ref) {
  final controller = ref.watch(fcmControllerProvider);

  void resync() {
    final auth = ref.read(authStateProvider);
    final notifsOn = ref.read(settingsProvider).notificationsEnabled;
    final isUser = auth.status == AuthStatus.authenticated &&
        auth.user != null &&
        !auth.user!.isGuest;
    if (isUser && notifsOn) {
      controller.register();
    } else {
      controller.unregister();
    }
  }

  ref.listen<AuthState>(authStateProvider, (prev, next) {
    if (prev?.status == next.status &&
        prev?.user?.isGuest == next.user?.isGuest) {
      return;
    }
    resync();
  }, fireImmediately: true);

  ref.listen<AppSettings>(settingsProvider, (prev, next) {
    if (prev?.notificationsEnabled == next.notificationsEnabled) return;
    resync();
  });
});
