import 'package:flutter/foundation.dart';

/// Centralized server configuration.
///
/// For development, change [_lanHost] to your machine's local IP.
/// Alternatively, pass at build time:
///   flutter run --dart-define=SERVER_HOST=junto.local
class ServerConfig {
  ServerConfig._();

  static const _lanHost = String.fromEnvironment(
    'SERVER_HOST',
    defaultValue: 'junto.local',
  );

  /// HTTP base URL for REST API.
  static String get apiBaseUrl {
    return 'https://$_lanHost/api';
  }

  /// HTTP base URL for media (HLS, etc).
  static String get mediaBaseUrl {
    return 'https://$_lanHost';
  }

  /// WebSocket base URL.
  static String get wsBaseUrl {
    return 'wss://$_lanHost';
  }
}
