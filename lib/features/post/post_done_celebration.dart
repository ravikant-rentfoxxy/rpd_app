import 'dart:math';

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../join/join_chrome.dart';

Future<void> showPostDoneCelebration(BuildContext context, {required bool offline}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: const Color(0x99000000),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, animation, secondary) => _PostDoneCelebration(offline: offline),
    transitionBuilder: (context, animation, secondary, child) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.86, end: 1).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutBack)),
          child: child,
        ),
      );
    },
  );
}

class _PostDoneCelebration extends StatefulWidget {
  const _PostDoneCelebration({required this.offline});
  final bool offline;

  @override
  State<_PostDoneCelebration> createState() => _PostDoneCelebrationState();
}

class _PostDoneCelebrationState extends State<_PostDoneCelebration> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1700))..forward();
    Future<void>.delayed(const Duration(milliseconds: 1750), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.offline ? 'post_saved_offline'.trFallback('Saved on this phone') : 'post_done'.trFallback('Posted!');
    final sub = widget.offline
        ? 'post_saved_offline_sub'.trFallback('Your photo post is saved locally and will upload when you are online.')
        : 'post_done_sub'.trFallback('Your update is now visible in your region.');
    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final check = Curves.elasticOut.transform((_controller.value / 0.45).clamp(0.0, 1.0));
          return Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _ConfettiPainter(_controller.value))),
              Center(
                child: Container(
                  width: 260,
                  padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 28, offset: Offset(0, 12))],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.scale(
                        scale: 0.72 + (check * 0.28),
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: const BoxDecoration(color: HomeColors.orange, shape: BoxShape.circle),
                          child: const Icon(Icons.check_rounded, color: Colors.white, size: 44),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: HomeColors.ink),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        sub,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13.5, color: HomeColors.muted, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t);
  final double t;

  static const _colors = [
    Color(0xFFF07E1D),
    Color(0xFF291668),
    Color(0xFFFFC857),
    Color(0xFF2F6FED),
    Color(0xFFE85D75),
    Color(0xFF1B8A6A),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(21);
    for (var i = 0; i < 48; i++) {
      final dx = random.nextDouble() * size.width;
      final start = -40.0 - random.nextDouble() * 80;
      final fall = start + (size.height + 140) * t * (0.7 + random.nextDouble() * 0.5);
      final paint = Paint()..color = _colors[i % _colors.length].withValues(alpha: 1 - (t * 0.25));
      final w = 6.0 + random.nextDouble() * 7;
      final h = 10.0 + random.nextDouble() * 8;
      canvas.save();
      canvas.translate(dx, fall);
      canvas.rotate(t * 8 + i);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: w, height: h), const Radius.circular(2)), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => oldDelegate.t != t;
}
