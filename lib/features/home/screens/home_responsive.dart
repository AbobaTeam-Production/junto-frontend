import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'web_home_screen.dart';

/// Mobile vs. desktop dispatcher for the Home tab. The router always
/// points at this widget so window resizes flip between the two layouts
/// without router churn.
class HomeResponsive extends StatelessWidget {
  const HomeResponsive({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (kIsWeb && width >= 900) {
      return const WebHomeScreen();
    }
    return const HomeScreen();
  }
}
