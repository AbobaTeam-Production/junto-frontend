// Three distinct onboarding screens, all in the Cinema Lounge palette
// but with different compositions so the flow doesn't feel like the
// same poster three times in a row:
//   1. Editorial      — amber projector disc, big quote-style headline.
//   2. Cinema diorama — letterboxed "screen" + projector light + seats.
//   3. Sources bento  — amber spark in the bottom-left, sources grid.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/junto_primitives.dart';
import '../../../l10n/app_localizations.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    ref.read(tokenServiceProvider).markOnboardingSeen();
    context.go('/login');
  }

  void _next() {
    if (_currentPage < 2) {
      _controller.nextPage(duration: 450.ms, curve: Curves.easeOutCubic);
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isLast = _currentPage == 2;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: AnimatedOpacity(
                duration: 250.ms,
                opacity: isLast ? 0 : 1,
                child: TextButton(
                  onPressed: isLast ? null : _finish,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.ink3,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  ),
                  child: Text(l.onboardingSkipButton),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: const [
                  _PageEditorial(),
                  _PageDiorama(),
                  _PageBento(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
              child: Row(
                children: [
                  Row(
                    children: List.generate(3, (i) {
                      final on = i == _currentPage;
                      return AnimatedContainer(
                        duration: 250.ms,
                        margin: const EdgeInsets.only(right: 6),
                        width: on ? 24 : 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: on ? AppColors.amber : AppColors.hairline,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _next,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.fromLTRB(24, 14, 22, 14),
                      shape: const StadiumBorder(),
                      backgroundColor: AppColors.amber,
                      foregroundColor: AppColors.amberInk,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isLast ? l.onboardingStartButton : l.onboardingNextButton,
                          style: AppTheme.text(
                            size: 15,
                            weight: FontWeight.w600,
                            color: AppColors.amberInk,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: AppColors.amberInk,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Page 1 — Editorial ───────────────────────────────────────────────
class _PageEditorial extends StatelessWidget {
  const _PageEditorial();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Amber projector glow — top-right corner.
        const Positioned(top: -120, right: -100, child: AmberGlow(size: 420)),

        Padding(
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.amber,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.amber.withValues(alpha: 0.55),
                      blurRadius: 80,
                      offset: const Offset(0, 30),
                      spreadRadius: -20,
                    ),
                  ],
                ),
              ).animate().scale(
                  begin: const Offset(0.85, 0.85),
                  end: const Offset(1, 1),
                  duration: 500.ms,
                  curve: Curves.easeOutCubic),
              const SizedBox(height: 56),
              MonoLabel(l.onboardingTagTogether,
                      color: AppColors.amber, letterSpacing: 2.0)
                  .animate()
                  .fadeIn(duration: 350.ms, delay: 80.ms),
              const SizedBox(height: 18),
              Text(
                l.onboardingPage1Title,
                style: AppTheme.display(
                  size: 42,
                  weight: FontWeight.w600,
                  letterSpacing: -1.4,
                  height: 1.04,
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 150.ms).slideY(
                  begin: 0.06, end: 0, duration: 400.ms, delay: 150.ms),
              const SizedBox(height: 18),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Text(
                  l.onboardingPage1Subtitle,
                  style: AppTheme.text(
                      size: 16,
                      color: AppColors.ink2,
                      height: 1.45,
                      weight: FontWeight.w400),
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 250.ms),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: MonoLabel(l.onboardingSourceTagsLine,
                    color: AppColors.ink3, letterSpacing: 1.6),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Page 2 — Cinema diorama ──────────────────────────────────────────
class _PageDiorama extends StatelessWidget {
  const _PageDiorama();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 21:9 letterboxed screen
          AspectRatio(
            aspectRatio: 21 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  // film-strip texture
                  CustomPaint(
                    size: Size.infinite,
                    painter: _FilmStripPainter(),
                  ),
                  // LIVE chip
                  Positioned(
                    top: 10, left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.bgDeep.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5, height: 5,
                            decoration: const BoxDecoration(
                              color: AppColors.live,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text('LIVE',
                              style: AppTheme.mono(
                                  size: 9,
                                  letterSpacing: 1.4,
                                  color: AppColors.live,
                                  weight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  // Faux subtitle
                  Positioned(
                    left: 0, right: 0, bottom: 12,
                    child: Center(
                      child: Text(
                        l.onboardingScreenSubtitle,
                        style: AppTheme.mono(
                            size: 11,
                            color: Colors.white,
                            weight: FontWeight.w500,
                            letterSpacing: 0.5).copyWith(
                          shadows: const [
                            Shadow(
                                color: Color(0xCC000000),
                                blurRadius: 6,
                                offset: Offset(0, 2)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 400.ms),

          // Projector light cone
          SizedBox(
            height: 36,
            child: Stack(
              children: [
                Positioned(
                  left: 0, right: 0, top: 0,
                  child: Center(
                    child: Container(
                      width: 280, height: 80,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.topCenter,
                          radius: 0.7,
                          colors: [
                            AppColors.ink.withValues(alpha: 0.10),
                            Colors.transparent,
                          ],
                          stops: const [0, 0.7],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Seats row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final seat in const [
                  _Seat(name: 'А', hue: 30),
                  _Seat(name: 'М', hue: 75),
                  _Seat(name: 'К', hue: 220),
                  _Seat(name: 'Л', hue: 340),
                ])
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      JuntoAvatar(name: seat.name, size: 36, hue: seat.hue),
                      const SizedBox(height: 6),
                      Container(
                        width: 28, height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          border: Border(top: BorderSide(color: AppColors.hairline)),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(6),
                            bottomRight: Radius.circular(6),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 150.ms),

          const SizedBox(height: 36),

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MonoLabel(l.onboardingTagOneRoom,
                    color: AppColors.amber, letterSpacing: 2.0),
                const SizedBox(height: 14),
                Text(
                  l.onboardingPage2Title,
                  style: AppTheme.display(
                    size: 36,
                    weight: FontWeight.w600,
                    letterSpacing: -1.0,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Text(
                    l.onboardingPage2Subtitle,
                    style: AppTheme.text(
                        size: 15,
                        color: AppColors.ink2,
                        height: 1.5,
                        weight: FontWeight.w400),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 250.ms),
        ],
      ),
    );
  }
}

class _Seat {
  final String name;
  final int hue;
  const _Seat({required this.name, required this.hue});
}

class _FilmStripPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()..color = const Color(0xFF231C13);
    final stripe = Paint()..color = const Color(0xFF31261B);
    canvas.drawRect(Offset.zero & size, base);
    // Diagonal stripes — like 35mm film grain.
    const angle = 0.6;
    final spacing = 11.0;
    final dx = size.width * 1.5;
    final dy = size.height * 1.5;
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(angle);
    canvas.translate(-size.width / 2, -size.height / 2);
    for (var x = -dx; x < dx; x += spacing) {
      canvas.drawRect(Rect.fromLTWH(x, -dy, 1, dy * 3), stripe);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Page 3 — Sources bento ───────────────────────────────────────────
class _PageBento extends StatelessWidget {
  const _PageBento();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Amber spark — bottom-left this time, not top-right.
        const Positioned(bottom: -120, left: -100, child: AmberGlow(size: 380)),

        Padding(
          padding: const EdgeInsets.fromLTRB(32, 8, 32, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              MonoLabel(l.onboardingTagAnySource,
                      color: AppColors.amber, letterSpacing: 2.0)
                  .animate()
                  .fadeIn(duration: 350.ms),
              const SizedBox(height: 14),
              Text(
                l.onboardingPage3Title,
                style: AppTheme.display(
                  size: 36,
                  weight: FontWeight.w600,
                  letterSpacing: -1.0,
                  height: 1.05,
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Text(
                  l.onboardingPage3Subtitle,
                  style: AppTheme.text(
                      size: 14,
                      color: AppColors.ink2,
                      height: 1.5,
                      weight: FontWeight.w400),
                ),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: _SourcesBento(l: l)
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 200.ms)
                    .slideY(begin: 0.06, end: 0),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SourcesBento extends StatelessWidget {
  final AppLocalizations l;
  const _SourcesBento({required this.l});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 14,
          child: _BigTile(
            label: l.onboardingSourceFile,
            ext: l.onboardingSourceFileExt,
            badge: l.onboardingSourceFileBadge,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 10,
          child: Column(
            children: [
              Expanded(
                child: _SmallTile(
                  icon: Icons.link_rounded,
                  label: l.onboardingSourceTorrent,
                  ext: l.onboardingSourceTorrentExt,
                  hue: 30,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _SmallTile(
                  icon: Icons.play_circle_outline_rounded,
                  label: l.onboardingSourceRutube,
                  ext: l.onboardingSourceRutubeExt,
                  hue: 220,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _SmallTile(
                  icon: Icons.cell_tower_rounded,
                  label: l.onboardingSourceStream,
                  ext: l.onboardingSourceStreamExt,
                  hue: 145,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BigTile extends StatelessWidget {
  final String label;
  final String ext;
  final String badge;
  const _BigTile({required this.label, required this.ext, required this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(AppTheme.r2),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _DiagonalStripes()),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.movie_outlined, size: 28, color: AppColors.amber),
              const SizedBox(height: 14),
              MonoLabel(badge, color: AppColors.ink3, letterSpacing: 1.4),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTheme.display(
                  size: 22, weight: FontWeight.w600, letterSpacing: -0.4),
              ),
              const Spacer(),
              Text(ext,
                  style: AppTheme.mono(
                      size: 10, color: AppColors.ink2, weight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String ext;
  final int hue;
  const _SmallTile({
    required this.icon,
    required this.label,
    required this.ext,
    required this.hue,
  });

  @override
  Widget build(BuildContext context) {
    final iconBg = HSLColor.fromAHSL(1, hue.toDouble(), 0.4, 0.30).toColor();
    final iconFg = HSLColor.fromAHSL(1, hue.toDouble(), 0.5, 0.85).toColor();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(AppTheme.r2),
      ),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 16, color: iconFg),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    style: AppTheme.text(size: 13, weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(ext,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.mono(
                        size: 9, color: AppColors.ink3, weight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DiagonalStripes extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.hairline.withValues(alpha: 0.4);
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-0.78);
    canvas.translate(-size.width, -size.height);
    for (var x = 0.0; x < size.width * 3; x += 14) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 1, size.height * 3), paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
