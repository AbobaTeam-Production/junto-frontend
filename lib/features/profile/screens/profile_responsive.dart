import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'profile_screen.dart';
import 'web_profile_screen.dart';

class ProfileResponsive extends StatelessWidget {
  const ProfileResponsive({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (kIsWeb && width >= 900) {
      return const WebProfileScreen();
    }
    return const ProfileScreen();
  }
}
