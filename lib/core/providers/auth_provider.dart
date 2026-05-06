import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../api/server_config.dart';

class AuthUser {
  final int id;
  final String username;
  final String email;
  final String? avatarUrl;
  final int sessionsCount;
  final int watchSeconds;
  final int friendsCount;
  final int pendingRequestsCount;

  const AuthUser({
    required this.id,
    required this.username,
    required this.email,
    this.avatarUrl,
    this.sessionsCount = 0,
    this.watchSeconds = 0,
    this.friendsCount = 0,
    this.pendingRequestsCount = 0,
  });

  bool get isGuest => username.startsWith('Гость_');

  /// Display value for the "hours watched" stat: floor of watch_seconds / 3600,
  /// so a 12-minute session shows 0 (not yet noteworthy) and an hour-and-a-half
  /// session shows 1.
  int get watchHours => watchSeconds ~/ 3600;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    String? avatarUrl = json['avatar_url'] as String?;
    // Resolve relative paths to full URLs
    if (avatarUrl != null && avatarUrl.startsWith('/')) {
      avatarUrl = '${ServerConfig.mediaBaseUrl}$avatarUrl';
    }
    return AuthUser(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      avatarUrl: avatarUrl,
      sessionsCount: (json['sessions_count'] as num?)?.toInt() ?? 0,
      watchSeconds: (json['watch_seconds'] as num?)?.toInt() ?? 0,
      friendsCount: (json['friends_count'] as num?)?.toInt() ?? 0,
      pendingRequestsCount:
          (json['pending_requests_count'] as num?)?.toInt() ?? 0,
    );
  }
}

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final AuthUser? user;
  final String? error;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.error,
  });

  AuthState copyWith({AuthStatus? status, AuthUser? user, String? error}) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
    );
  }
}

final authStateProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

final currentUserProvider = Provider<AuthUser?>((ref) {
  return ref.watch(authStateProvider).user;
});

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;

  AuthNotifier(this._ref) : super(const AuthState());

  Dio get _dio => _ref.read(dioProvider);
  TokenService get _tokenService => _ref.read(tokenServiceProvider);

  Future<void> tryRestoreSession() async {
    if (!_tokenService.hasTokens) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }
    try {
      final response = await _dio.get(ApiEndpoints.profile);
      final user = AuthUser.fromJson(response.data);
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (_) {
      await _tokenService.clear();
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String email, String password) async {
    try {
      state = state.copyWith(error: null);
      final response = await _dio.post(
        ApiEndpoints.login,
        data: {'username': email, 'password': password},
      );
      await _tokenService.saveTokens(
        access: response.data['access'],
        refresh: response.data['refresh'],
      );
      // Fetch user profile
      final profileResponse = await _dio.get(ApiEndpoints.profile);
      final user = AuthUser.fromJson(profileResponse.data);
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } on DioException catch (e) {
      final message = _extractError(e);
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: message,
      );
      rethrow;
    }
  }

  Future<void> register(String username, String email, String password) async {
    try {
      state = state.copyWith(error: null);
      final response = await _dio.post(
        ApiEndpoints.register,
        data: {
          'username': username,
          'email': email,
          'password': password,
          'password_confirm': password,
        },
      );
      final tokens = response.data['tokens'];
      await _tokenService.saveTokens(
        access: tokens['access'],
        refresh: tokens['refresh'],
      );
      final user = AuthUser.fromJson(response.data['user']);
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } on DioException catch (e) {
      final message = _extractError(e);
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: message,
      );
      rethrow;
    }
  }

  Future<void> loginAsGuest() async {
    try {
      state = state.copyWith(error: null);
      final response = await _dio.post(ApiEndpoints.guest);
      final tokens = response.data['tokens'];
      await _tokenService.saveTokens(
        access: tokens['access'],
        refresh: tokens['refresh'],
      );
      final user = AuthUser.fromJson(response.data['user']);
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } on DioException catch (e) {
      final message = _extractError(e);
      state = state.copyWith(error: message);
      rethrow;
    }
  }

  /// Re-fetch /auth/profile/ to pick up server-side stat changes
  /// (sessions_count / watch_seconds). Called when entering the profile
  /// screen so the user sees up-to-date numbers without re-logging.
  Future<void> refreshProfile() async {
    if (state.status != AuthStatus.authenticated) return;
    try {
      final response = await _dio.get(ApiEndpoints.profile);
      final user = AuthUser.fromJson(response.data);
      state = state.copyWith(user: user);
    } catch (_) {
      // Silent — stats just won't update this round.
    }
  }

  Future<void> updateProfile({
    String? username,
    String? email,
    Uint8List? avatarBytes,
    String? avatarFileName,
  }) async {
    final data = <String, dynamic>{};
    if (username != null) data['username'] = username;
    if (email != null) data['email'] = email;
    if (avatarBytes != null) {
      data['avatar'] = MultipartFile.fromBytes(
        avatarBytes,
        filename: avatarFileName ?? 'avatar.jpg',
      );
    }
    if (data.isEmpty) return;

    final formData = FormData.fromMap(data);
    final response = await _dio.patch(ApiEndpoints.profile, data: formData);
    final user = AuthUser.fromJson(response.data);
    state = state.copyWith(user: user);
  }

  Future<void> logout() async {
    await _tokenService.clear();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      if (data.containsKey('detail')) return data['detail'].toString();
      // Collect field errors
      final errors = <String>[];
      data.forEach((key, value) {
        if (value is List) {
          errors.add(value.join(', '));
        } else {
          errors.add(value.toString());
        }
      });
      if (errors.isNotEmpty) return errors.join('\n');
    }
    return 'Ошибка сети. Попробуйте ещё раз.';
  }
}
