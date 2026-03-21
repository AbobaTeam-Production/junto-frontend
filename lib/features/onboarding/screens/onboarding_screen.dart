import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_colors.dart';

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
      icon: Icons.play_circle_filled_rounded,
      gradient: [AppColors.primary, Color(0xFF9D7CFF)],
      title: 'Смотрите вместе',
      subtitle:
          'Совместный просмотр фильмов, сериалов\nи видео с друзьями в реальном времени',
    ),
    _PageData(
      icon: Icons.cloud_upload_rounded,
      gradient: [AppColors.secondary, Color(0xFFFFAA6B)],
      title: 'Любой источник',
      subtitle:
          'Загружайте файлы, добавляйте торренты\nили вставляйте ссылки с Rutube',
    ),
    _PageData(
      icon: Icons.headset_mic_rounded,
      gradient: [Color(0xFF4ADE80), Color(0xFF22D3EE)],
      title: 'Общайтесь голосом',
      subtitle:
          'Голосовой чат с эхоподавлением —\nможно разговаривать без наушников',
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
      _controller.nextPage(
        duration: 500.ms,
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  void _skip() => _finish();

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16, top: 8),
                child: AnimatedOpacity(
                  duration: 300.ms,
                  opacity: isLast ? 0.0 : 1.0,
                  child: TextButton(
                    onPressed: isLast ? null : _skip,
                    child: const Text(
                      'Пропустить',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
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

            // Dots + button
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
              child: Row(
                children: [
                  // Dots
                  Row(
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: 300.ms,
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.only(right: 8),
                        width: _currentPage == i ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? AppColors.primary
                              : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Next / Start button
                  AnimatedContainer(
                    duration: 300.ms,
                    width: isLast ? 140 : 56,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(isLast ? 16 : 28),
                        ),
                      ),
                      child: AnimatedSwitcher(
                        duration: 300.ms,
                        child: isLast
                            ? const Text('Начать',
                                key: ValueKey('start'))
                            : const Icon(Icons.arrow_forward_rounded,
                                key: ValueKey('arrow')),
                      ),
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

class _PageData {
  final IconData icon;
  final List<Color> gradient;
  final String title;
  final String subtitle;

  const _PageData({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.subtitle,
  });
}

class _OnboardingPage extends StatelessWidget {
  final _PageData data;

  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with glow
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: data.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(36),
              boxShadow: [
                BoxShadow(
                  color: data.gradient.first.withValues(alpha: 0.35),
                  blurRadius: 40,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Icon(data.icon, size: 64, color: Colors.white),
          )
              .animate()
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1, 1),
                duration: 600.ms,
                curve: Curves.elasticOut,
              )
              .fadeIn(duration: 400.ms),
          const SizedBox(height: 48),

          // Title
          Text(
            data.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 400.ms, delay: 150.ms).slideY(
                begin: 0.15,
                end: 0,
                duration: 400.ms,
                delay: 150.ms,
              ),
          const SizedBox(height: 16),

          // Subtitle
          Text(
            data.subtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 400.ms, delay: 300.ms).slideY(
                begin: 0.15,
                end: 0,
                duration: 400.ms,
                delay: 300.ms,
              ),
        ],
      ),
    );
  }
}
