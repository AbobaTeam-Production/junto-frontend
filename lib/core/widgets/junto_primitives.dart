import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

// Stripe poster — placeholder for any video / room artwork.
// Diagonal repeating stripes (no gradients on icons), with optional mono caption.
enum PosterMood { amber, cool, rose, neutral }

class JuntoPoster extends StatelessWidget {
  final String? label;
  final double? width;
  final double? height;
  final double? aspectRatio;
  final PosterMood mood;
  final double radius;

  const JuntoPoster({
    super.key,
    this.label,
    this.width,
    this.height,
    this.aspectRatio,
    this.mood = PosterMood.amber,
    this.radius = AppTheme.r2,
  });

  Color get _baseColor {
    switch (mood) {
      case PosterMood.amber:
        return const Color(0xFF332A1F);
      case PosterMood.cool:
        return const Color(0xFF1B2230);
      case PosterMood.rose:
        return const Color(0xFF301A22);
      case PosterMood.neutral:
        return const Color(0xFF2A2620);
    }
  }

  Color get _stripeColor {
    switch (mood) {
      case PosterMood.amber:
        return const Color(0xFF42361F);
      case PosterMood.cool:
        return const Color(0xFF263248);
      case PosterMood.rose:
        return const Color(0xFF44222F);
      case PosterMood.neutral:
        return const Color(0xFF362F26);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CustomPaint(
        painter: _StripePainter(_baseColor, _stripeColor),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: label == null || label!.isEmpty
                ? const SizedBox.shrink()
                : Text(
                    label!.toUpperCase(),
                    style: AppTheme.mono(size: 9, color: AppColors.ink3, letterSpacing: 0.6),
                  ),
          ),
        ),
      ),
    );
    if (aspectRatio != null) {
      content = AspectRatio(aspectRatio: aspectRatio!, child: content);
    }
    return SizedBox(width: width, height: height, child: content);
  }
}

class _StripePainter extends CustomPainter {
  final Color base;
  final Color stripe;
  _StripePainter(this.base, this.stripe);

  @override
  void paint(Canvas canvas, Size size) {
    final basePaint = Paint()..color = base;
    canvas.drawRect(Offset.zero & size, basePaint);

    final stripePaint = Paint()
      ..color = stripe
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // 135° diagonal stripes, ~9px apart.
    const step = 9.0;
    final diag = size.width + size.height;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (double d = -size.height; d < diag; d += step) {
      canvas.drawLine(Offset(d, 0), Offset(d + size.height, size.height), stripePaint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StripePainter old) =>
      old.base != base || old.stripe != stripe;
}

// Avatar — single letter on a solid warm-hue circle, OR a network photo
// with the initial as a fallback (used while loading or on error).
class JuntoAvatar extends StatelessWidget {
  final String name;
  final double size;
  final int hue; // 0-360, picks a warm-tinted color
  final bool online;

  /// Optional photo URL. When non-null and resolvable, replaces the
  /// initial. The colour-circle stays as a backdrop so a slow / failed
  /// load still looks like an avatar instead of a hole.
  final String? imageUrl;

  const JuntoAvatar({
    super.key,
    required this.name,
    this.size = 36,
    this.hue = 75,
    this.online = false,
    this.imageUrl,
  });

  String get _initial {
    final t = name.trim();
    if (t.isEmpty) return '?';
    return t.characters.first.toUpperCase();
  }

  Color get _bgColor {
    // approximation of oklch(0.55 0.10 hue) — pick a mid-luminance tinted swatch
    final h = hue % 360;
    final hsl = HSLColor.fromAHSL(1.0, h.toDouble(), 0.34, 0.46);
    return hsl.toColor();
  }

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    final hasImage = url != null && url.isNotEmpty;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: _bgColor,
              shape: BoxShape.circle,
              image: hasImage
                  ? DecorationImage(
                      image: NetworkImage(url),
                      fit: BoxFit.cover,
                      // onError just swallows; the initial stays visible
                      // through the transparent image area.
                      onError: (_, _) {},
                    )
                  : null,
            ),
            alignment: Alignment.center,
            child: hasImage
                ? null
                : Text(
                    _initial,
                    style: AppTheme.display(
                      size: size * 0.42,
                      color: const Color(0xFFFAF7F0),
                      weight: FontWeight.w600,
                      letterSpacing: -0.3,
                      height: 1,
                    ),
                  ),
          ),
          if (online)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: math.max(8, size * 0.28),
                height: math.max(8, size * 0.28),
                decoration: BoxDecoration(
                  color: AppColors.live,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.bg, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Tiny mono caption — uppercase, wide letterspacing, dim color by default.
class MonoLabel extends StatelessWidget {
  final String text;
  final Color? color;
  final double size;
  final double letterSpacing;
  final FontWeight weight;
  const MonoLabel(
    this.text, {
    super.key,
    this.color,
    this.size = 10,
    this.letterSpacing = 1.8,
    this.weight = FontWeight.w500,
  });
  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTheme.mono(
        size: size,
        color: color ?? AppColors.ink3,
        letterSpacing: letterSpacing,
        weight: weight,
      ),
    );
  }
}

// "● LIVE" chip — pulsing amber-green, used only when something is happening live.
class LiveChip extends StatelessWidget {
  final String label;
  final bool compact;
  const LiveChip({super.key, this.label = 'LIVE', this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 5 : 6,
          height: compact ? 5 : 6,
          decoration: const BoxDecoration(
            color: AppColors.live,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: compact ? 4 : 5),
        Text(
          label.toUpperCase(),
          style: AppTheme.mono(
            size: compact ? 9 : 10,
            color: AppColors.live,
            letterSpacing: 1.4,
            weight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// Concentric thin amber rings — used as the "projector" ornament on hero CTAs.
class ProjectorRings extends StatelessWidget {
  const ProjectorRings({super.key});
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            right: -60,
            top: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.amberInk.withValues(alpha: 0.18),
                ),
              ),
            ),
          ),
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.amberInk.withValues(alpha: 0.28),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Soft amber radial glow — the "projector lamp" in the corner of a screen.
class AmberGlow extends StatelessWidget {
  final double size;
  const AmberGlow({super.key, this.size = 420});
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AppColors.amber.withValues(alpha: 0.22),
              Colors.transparent,
            ],
            stops: const [0.0, 0.65],
          ),
        ),
      ),
    );
  }
}
