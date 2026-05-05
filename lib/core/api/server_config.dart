import 'package:flutter/foundation.dart';

/// Centralized server configuration.
///
/// On Web — derived from [Uri.base], so the app always talks to the same
/// origin that served it (no CORS, no port mismatch).
///
/// On native — uses [_lanHost] / [_lanPort] / [_scheme], overridable via
/// --dart-define=SERVER_HOST=... / SERVER_PORT=... / SERVER_SCHEME=...
class ServerConfig {
  ServerConfig._();

  static const _lanHost = String.fromEnvironment(
    'SERVER_HOST',
    defaultValue: 'junto.local',
  );

  static const _lanPort = String.fromEnvironment(
    'SERVER_PORT',
    defaultValue: '',
  );

  // http | https. Default https (prod). For local dev with nginx on :8080
  // pass --dart-define=SERVER_SCHEME=http.
  static const _scheme = String.fromEnvironment(
    'SERVER_SCHEME',
    defaultValue: 'https',
  );

  static String get _hostWithPort =>
      _lanPort.isEmpty ? _lanHost : '$_lanHost:$_lanPort';

  static String get _wsScheme => _scheme == 'http' ? 'ws' : 'wss';

  /// On Web — host/port/scheme of the page that served the app.
  /// Same origin as the frontend → no CORS issues, no port drift.
  static String get _webOrigin => Uri.base.origin;

  static String get _webWsScheme =>
      Uri.base.scheme == 'http' ? 'ws' : 'wss';

  static String get _webAuthority => Uri.base.authority;

  /// HTTP base URL for REST API.
  static String get apiBaseUrl {
    if (kIsWeb) return '$_webOrigin/api';
    return '$_scheme://$_hostWithPort/api';
  }

  /// HTTP base URL for media (HLS, etc).
  static String get mediaBaseUrl {
    if (kIsWeb) return _webOrigin;
    return '$_scheme://$_hostWithPort';
  }

  /// WebSocket base URL.
  static String get wsBaseUrl {
    if (kIsWeb) return '$_webWsScheme://$_webAuthority';
    return '$_wsScheme://$_hostWithPort';
  }
}
