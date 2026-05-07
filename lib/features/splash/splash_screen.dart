import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Continuation of the native splash while we restore the auth session.
///
/// Shown by the router whenever AuthStatus == unknown so the user never
/// sees /login flash before the redirect to /home on cold start.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: AppColors.amber,
          ),
        ),
      ),
    );
  }
}
