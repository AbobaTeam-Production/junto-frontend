import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';

const _kLocaleKey = 'app_locale';
const _kMicDeviceKey = 'mic_device_id';

class AppSettings {
  /// `null` means "system default" — usually we pick `ru` to stay consistent
  /// with our launch markets.
  final Locale? locale;

  /// Empty string means "use the OS-default microphone". Otherwise we hand
  /// this id to LiveKit's `AudioCaptureOptions.deviceId`.
  final String micDeviceId;

  const AppSettings({this.locale, this.micDeviceId = ''});

  AppSettings copyWith({Locale? locale, String? micDeviceId, bool clearLocale = false}) =>
      AppSettings(
        locale: clearLocale ? null : (locale ?? this.locale),
        micDeviceId: micDeviceId ?? this.micDeviceId,
      );
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  final SharedPreferences _prefs;

  SettingsNotifier(this._prefs)
      : super(AppSettings(
          locale: _readLocale(_prefs),
          micDeviceId: _prefs.getString(_kMicDeviceKey) ?? '',
        ));

  static Locale? _readLocale(SharedPreferences prefs) {
    final code = prefs.getString(_kLocaleKey);
    if (code == null || code.isEmpty) return const Locale('ru');
    return Locale(code);
  }

  Future<void> setLocale(Locale? locale) async {
    if (locale == null) {
      await _prefs.remove(_kLocaleKey);
    } else {
      await _prefs.setString(_kLocaleKey, locale.languageCode);
    }
    state = state.copyWith(locale: locale, clearLocale: locale == null);
  }

  Future<void> setMicDeviceId(String id) async {
    await _prefs.setString(_kMicDeviceKey, id);
    state = state.copyWith(micDeviceId: id);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(ref.watch(sharedPreferencesProvider));
});

/// Convenience selector — what `MaterialApp.locale` should read.
final localeProvider =
    Provider<Locale?>((ref) => ref.watch(settingsProvider).locale);
