import 'dart:ui';

// Cinema Lounge palette — warm espresso dark + a single amber accent.
// Live green is reserved for "идёт сейчас" status (it is not decoration).
abstract final class AppColors {
  // Surfaces (warm, not blue-black)
  static const bg = Color(0xFF1E1A15);        // deep espresso
  static const bgDeep = Color(0xFF16120E);    // letterbox / behind-screen
  static const surface = Color(0xFF29241E);   // cards
  static const surface2 = Color(0xFF312B24);  // hover / input
  static const hairline = Color(0xFF3B342D);  // 1px lines

  // Ink
  static const ink = Color(0xFFF4F1EA);       // primary text — warm white
  static const ink2 = Color(0xFFC0B7A8);      // secondary text
  static const ink3 = Color(0xFF857C6E);      // tertiary
  static const ink4 = Color(0xFF5C5448);      // quaternary / hint

  // Accents — single amber, single signal green
  static const amber = Color(0xFFE2A155);     // projector lamp
  static const amberDim = Color(0x2EE2A155);  // 18% amber
  static const amberInk = Color(0xFF332417);  // text on amber
  static const live = Color(0xFF7DC894);
  static const liveDim = Color(0x297DC894);   // 16% live
  static const danger = Color(0xFFE15748);

  // Backwards-compatible aliases (existing code still references these)
  static const background = bg;
  static const surfaceLight = surface2;
  static const card = surface;
  static const primary = amber;
  static const primaryDark = Color(0xFFC1873E);
  static const secondary = live;
  static const textPrimary = ink;
  static const textSecondary = ink2;
  static const textHint = ink3;
  static const success = live;
  static const error = danger;
  static const warning = amber;
  static const divider = hairline;
  static const border = hairline;
  static const online = live;
}
