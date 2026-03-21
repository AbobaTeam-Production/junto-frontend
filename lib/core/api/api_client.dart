import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_endpoints.dart';
import 'server_config.dart';

const _kAccessTokenKey = 'access_token';
const _kRefreshTokenKey = 'refresh_token';
const _kOnboardingSeenKey = 'onboarding_seen';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Must be overridden in ProviderScope');
});

final tokenServiceProvider = Provider<TokenService>((ref) {
  return TokenService(ref.watch(sharedPreferencesProvider));
});

class TokenService {
  final SharedPreferences _prefs;

  TokenService(this._prefs);

  String? get accessToken => _prefs.getString(_kAccessTokenKey);
  String? get refreshToken => _prefs.getString(_kRefreshTokenKey);
  bool get hasTokens => accessToken != null && refreshToken != null;

  Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    await _prefs.setString(_kAccessTokenKey, access);
    await _prefs.setString(_kRefreshTokenKey, refresh);
  }

  Future<void> clear() async {
    await _prefs.remove(_kAccessTokenKey);
    await _prefs.remove(_kRefreshTokenKey);
  }

  bool get onboardingSeen => _prefs.getBool(_kOnboardingSeenKey) ?? false;

  Future<void> markOnboardingSeen() async {
    await _prefs.setBool(_kOnboardingSeenKey, true);
  }
}

final dioProvider = Provider<Dio>((ref) {
  final tokenService = ref.watch(tokenServiceProvider);

  final baseUrl = ServerConfig.apiBaseUrl;

  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      final token = tokenService.accessToken;
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      // Let Dio set Content-Type automatically for FormData (multipart)
      if (options.data is FormData) {
        options.headers.remove('Content-Type');
      }
      handler.next(options);
    },
    onError: (error, handler) async {
      if (error.response?.statusCode == 401) {
        final refresh = tokenService.refreshToken;
        if (refresh != null) {
          try {
            final refreshDio = Dio(BaseOptions(baseUrl: baseUrl));
            final response = await refreshDio.post(
              ApiEndpoints.refresh,
              data: {'refresh': refresh},
            );
            final newAccess = response.data['access'] as String;
            await tokenService.saveTokens(
              access: newAccess,
              refresh: refresh,
            );
            // Retry the original request
            error.requestOptions.headers['Authorization'] =
                'Bearer $newAccess';
            final retryResponse = await refreshDio.fetch(error.requestOptions);
            return handler.resolve(retryResponse);
          } catch (_) {
            await tokenService.clear();
          }
        }
      }
      handler.next(error);
    },
  ));

  return dio;
});
