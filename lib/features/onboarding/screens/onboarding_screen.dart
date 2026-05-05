import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/junto_primitives.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  static const _pages = [
    _PageData(
      tag: '01 — Together',
      titleStart: 'Кино — это\nповод ',
      titleAccent: 'встретиться.',
      subtitle:
          'Junto собирает друзей в одной комнате — синхронный плеер, голос без эха, реакции в реальном времени.',
    ),
    _PageData(
      tag: '02 — Any source',
      titleStart: 'Файл, торрент\nили ',
      titleAccent: 'Rutube.',
      subtitle:
          'Загружайте локальный файл, добавляйте магнет-ссылку или вставляйте URL — Junto синхронизирует поток.',
    ),
    _PageData(
      tag: '03 — Voice',
      titleStart: 'Голос без\nэха и ',
      titleAccent: 'наушников.',
      subtitle:
          'Голосовой чат с подавлением эхо: можно говорить через колонки, никто не услышит свой голос обратно.',
    ),
  ];

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
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(duration: 450.ms, curve: Curves.easeOutCubic);
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // Soft projector glow in the corner
          const Positioned(top: -120, right: -100, child: AmberGlow(size: 420)),

          SafeArea(
            child: Column(
              children: [
                // Skip
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
                      child: const Text('Пропустить'),
                    ),
                  ),
                ),

                // Pages
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _pages.length,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemBuilder: (context, index) =>
                        _OnboardingPage(data: _pages[index]),
                  ),
                ),

                // Foot — feature row + dots + amber pill CTA
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _featureRow(),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          // Dots — current is a wide bar
                          Row(
                            children: List.generate(_pages.length, (i) {
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
                                Text(isLast ? 'Начать' : 'Дальше',
                                    style: AppTheme.text(size: 15, weight: FontWeight.w600, color: AppColors.amberInk)),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded, size: 18, color: AppColors.amberInk),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureRow() {
    const items = ['FILES', 'TORRENT', 'RUTUBE', 'VOICE'];
    final children = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      children.add(MonoLabel(items[i], color: AppColors.ink3, letterSpacing: 1.6));
      if (i < items.length - 1) {
        children.add(const SizedBox(width: 8));
        children.add(Text('·', style: AppTheme.text(size: 12, color: AppColors.ink4)));
        children.add(const SizedBox(width: 8));
      }
    }
    return Row(children: children);
  }
}

class _PageData {
  final String tag;
  final String titleStart;
  final String titleAccent;
  final String subtitle;
  const _PageData({
    required this.tag,
    required this.titleStart,
    required this.titleAccent,
    required this.subtitle,
  });
}

class _OnboardingPage extends StatelessWidget {
  final _PageData data;
  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // Single amber projector disc
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
          )
              .animate()
              .scale(begin: const Offset(0.85, 0.85), end: const Offset(1, 1), duration: 500.ms, curve: Curves.easeOutCubic)
              .fadeIn(duration: 400.ms),

          const SizedBox(height: 60),

          MonoLabel(data.tag, color: AppColors.amber, letterSpacing: 2.0)
              .animate()
              .fadeIn(duration: 350.ms, delay: 80.ms),

          const SizedBox(height: 18),

          // Headline (Manrope display, italic accent in amber)
          RichText(
            text: TextSpan(
              style: AppTheme.display(size: 42, weight: FontWeight.w600, letterSpacing: -1.4, height: 1.04),
              children: [
                TextSpan(text: data.titleStart),
                TextSpan(
                  text: data.titleAccent,
                  style: AppTheme.display(
                    size: 42,
                    weight: FontWeight.w500,
                    color: AppColors.amber,
                    letterSpacing: -1.4,
                    height: 1.04,
                  ).copyWith(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 150.ms)
              .slideY(begin: 0.06, end: 0, duration: 400.ms, delay: 150.ms),

          const SizedBox(height: 18),

          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Text(
              data.subtitle,
              style: AppTheme.text(size: 16, color: AppColors.ink2, height: 1.45, weight: FontWeight.w400),
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 250.ms)
              .slideY(begin: 0.06, end: 0, duration: 400.ms, delay: 250.ms),
        ],
      ),
    );
  }
}
