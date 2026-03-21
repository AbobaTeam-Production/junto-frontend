import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/api/api_client.dart';
import 'core/video/init_stub.dart'
    if (dart.library.io) 'core/video/init_native.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ensureVideoPlayerInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const JuntoApp(),
    ),
  );
}
