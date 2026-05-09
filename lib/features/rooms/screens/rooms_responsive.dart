import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'rooms_screen.dart';
import 'web_rooms_screen.dart';

class RoomsResponsive extends StatelessWidget {
  const RoomsResponsive({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (kIsWeb && width >= 900) {
      return const WebRoomsScreen();
    }
    return const RoomsScreen();
  }
}
