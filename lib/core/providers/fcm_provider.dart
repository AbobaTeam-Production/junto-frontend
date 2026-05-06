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

class FcmController {
  FcmController(this._ref);

  final Ref _ref;
  bool _firebaseInited = false;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _messageSub;
  StreamSubscription<RemoteMessage>? _openedSub;
  int? _registeredDeviceId;
  String? _registeredToken;

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

  /// Registers the current device with the backend. Safe to call multiple
  /// times — the backend upserts on (user, fcm_token).
  Future<void> register() async {
    if (!fcmSupported) return;
    try {
      await _ensureFirebase();

      final messaging = FirebaseMessaging.instance;
      // On iOS / Web this prompts the user. Android <13 grants by default;
      // Android 13+ shows the system POST_NOTIFICATIONS dialog.
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return;
      }

      final token = await messaging.getToken(
        vapidKey: kIsWeb ? DefaultFirebaseOptions.webPushVapidKey : null,
      );
      if (token == null || token.isEmpty) return;

      await _postDevice(token);
      _attachListeners(messaging);
    } catch (e) {
      // Swallowed: missing google-services.json, no Play Services, denied
      // permission etc. App still works without push.
      debugPrint('FCM register failed: $e');
    }
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
    if (ctx != null && msg.notification != null) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(msg.notification!.body ?? msg.notification!.title ?? ''),
        ),
      );
    }
  }

  void _onTapped(RemoteMessage msg) {
    final type = msg.data['type'] as String?;
    if (type == 'friend_request' || type == 'friend_accepted') {
      _ref.read(appRouterProvider).go('/friends');
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
