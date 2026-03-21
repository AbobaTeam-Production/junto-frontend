import 'package:flutter/foundation.dart';

/// Centralized server configuration.
///
/// For development, change [_lanHost] to your machine's local IP.
/// Alternatively, pass at build time:
///   flutter run --dart-define=SERVER_HOST=192.168.1.100
///   flutter run --dart-define=SERVER_PORT=8000
class ServerConfig {
  ServerConfig._();

  static const _lanHost = String.fromEnvironment(
    'SERVER_HOST',
    defaultValue: '192.168.0.165',
  );
  static const _lanPort = String.fromEnvironment(
    'SERVER_PORT',
    defaultValue: '8000',
  );

  /// HTTP base URL for REST API.
  static String get apiBaseUrl {
    if (kIsWeb) return 'http://localhost:$_lanPort/api';
    return 'http://$_lanHost:$_lanPort/api';
  }

  /// HTTP base URL for media (HLS, etc).
  static String get mediaBaseUrl {
    if (kIsWeb) return 'http://localhost:$_lanPort';
    return 'http://$_lanHost:$_lanPort';
  }

  /// WebSocket base URL.
  static String get wsBaseUrl {
    if (kIsWeb) return 'ws://localhost:$_lanPort';
    return 'ws://$_lanHost:$_lanPort';
  }
}
