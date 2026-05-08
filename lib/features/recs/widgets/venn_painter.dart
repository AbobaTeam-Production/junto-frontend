import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Two overlapping circles for the match-screen Venn. Hue-tinted to
/// match each user's avatar, with stroke just slightly brighter than
/// fill so the curves stay legible against the dark bg.
class VennPainter extends CustomPainter {
  final int hueA;
  final int hueB;

  const VennPainter({this.hueA = 75, this.hueB = 30});

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.height / 2;
    final aCenter = Offset(radius, size.height / 2);
    final bCenter = Offset(size.width - radius, size.height / 2);

    void drawDisc(Offset c, int hue) {
      final colour = HSLColor.fromAHSL(0.45, (hue % 360).toDouble(), 0.55, 0.55).toColor();
      final stroke = HSLColor.fromAHSL(0.6, (hue % 360).toDouble(), 0.55, 0.7).toColor();
      canvas.drawCircle(c, radius, Paint()..color = colour);
      canvas.drawCircle(
        c,
        radius,
        Paint()
          ..color = stroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    drawDisc(aCenter, hueA);
    drawDisc(bCenter, hueB);
  }

  @override
  bool shouldRepaint(covariant VennPainter old) =>
      old.hueA != hueA || old.hueB != hueB;
}

/// Centred badge that floats between the two Venn circles with the
/// pair-overlap %. Amber pill on dark bg.
class VennMatchBadge extends StatelessWidget {
  final int percent;
  const VennMatchBadge({super.key, required this.percent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: const BoxDecoration(
        color: AppColors.amber,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '$percent%',
        style: const TextStyle(
          color: AppColors.amberInk,
          fontWeight: FontWeight.w700,
          fontSize: 15,
          letterSpacing: -0.3,
        ),
      ),
    );
  }
}
