import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/room_ws_provider.dart';

class ReactionOverlay extends ConsumerStatefulWidget {
  final String roomId;

  const ReactionOverlay({super.key, required this.roomId});

  @override
  ConsumerState<ReactionOverlay> createState() => _ReactionOverlayState();
}

class _ReactionOverlayState extends ConsumerState<ReactionOverlay>
    with TickerProviderStateMixin {
  final List<_FloatingReaction> _reactions = [];
  final _random = Random();

  @override
  void dispose() {
    for (final r in _reactions) {
      r.controller.dispose();
    }
    super.dispose();
  }

  void _spawnReaction(String emoji, String username) {
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    final x = 0.15 + _random.nextDouble() * 0.7; // 15%-85% horizontal
    final reaction = _FloatingReaction(
      emoji: emoji,
      username: username,
      startX: x,
      controller: controller,
    );

    setState(() => _reactions.add(reaction));

    controller.forward().then((_) {
      if (mounted) {
        setState(() => _reactions.remove(reaction));
      }
      controller.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      roomWsProvider(widget.roomId).select((s) => s.lastReaction),
      (previous, next) {
        if (next != null && next != previous) {
          _spawnReaction(next.emoji, next.username);
        }
      },
    );

    return IgnorePointer(
      child: Stack(
        children: _reactions.map((r) {
          return AnimatedBuilder(
            animation: r.controller,
            builder: (context, _) {
              final t = r.controller.value;
              final size = MediaQuery.of(context).size;
              final startY = size.height * 0.7;
              final endY = size.height * 0.05;
              final currentY = startY + (endY - startY) * t;
              final currentX = size.width * r.startX +
                  sin(t * pi * 2) * 20; // gentle sway
              final opacity = t < 0.7 ? 1.0 : (1.0 - (t - 0.7) / 0.3);
              final scale = t < 0.1 ? t / 0.1 : 1.0;

              return Positioned(
                left: currentX - 24,
                top: currentY,
                child: Opacity(
                  opacity: opacity.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: scale.clamp(0.0, 1.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(r.emoji, style: const TextStyle(fontSize: 32)),
                        Text(
                          r.username,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.7),
                            shadows: const [
                              Shadow(blurRadius: 4, color: Colors.black),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}

class _FloatingReaction {
  final String emoji;
  final String username;
  final double startX;
  final AnimationController controller;

  _FloatingReaction({
    required this.emoji,
    required this.username,
    required this.startX,
    required this.controller,
  });
}
