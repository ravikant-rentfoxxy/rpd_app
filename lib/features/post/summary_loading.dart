import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:rpd_app/features/join/join_chrome.dart';
import '../../core/theme/app_colors.dart';

const aiGradientColors = [HomeColors.navyMid, Color(0xFF7B5CF0), HomeColors.orange];

/// Sparkle icon used on "Summary by AI" buttons. Twinkles while [animating].
class AiSparkleIcon extends StatefulWidget {
  const AiSparkleIcon({super.key, this.size = 18, this.animating = false});
  final double size;
  final bool animating;

  @override
  State<AiSparkleIcon> createState() => _AiSparkleIconState();
}

class _AiSparkleIconState extends State<AiSparkleIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void initState() {
    super.initState();
    if (widget.animating) _c.repeat();
  }

  @override
  void didUpdateWidget(AiSparkleIcon old) {
    super.didUpdateWidget(old);
    if (widget.animating && !_c.isAnimating) {
      _c.repeat();
    } else if (!widget.animating && _c.isAnimating) {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value;
        final pulse = widget.animating ? 0.82 + 0.18 * math.sin(t * 2 * math.pi).abs() : 1.0;
        return Transform.rotate(
          angle: widget.animating ? math.sin(t * 2 * math.pi) * 0.18 : 0,
          child: Transform.scale(
            scale: pulse,
            child: ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (rect) => SweepGradient(
                colors: const [...aiGradientColors, HomeColors.navyMid],
                transform: GradientRotation(t * 2 * math.pi),
              ).createShader(rect),
              child: Icon(Icons.auto_awesome_rounded, size: widget.size),
            ),
          ),
        );
      },
    );
  }
}

/// Large animated AI orb: rotating gradient ring, pulsing glow and sparkle.
class AiThinkingOrb extends StatefulWidget {
  const AiThinkingOrb({super.key, this.size = 84});
  final double size;

  @override
  State<AiThinkingOrb> createState() => _AiThinkingOrbState();
}

class _AiThinkingOrbState extends State<AiThinkingOrb> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        final wave = 0.5 + 0.5 * math.sin(t * 4 * math.pi);
        return SizedBox(
          width: s,
          height: s,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: s * (0.78 + 0.12 * wave),
                height: s * (0.78 + 0.12 * wave),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7B5CF0).withValues(alpha: 0.18 + 0.2 * wave),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              Transform.rotate(
                angle: t * 2 * math.pi,
                child: Container(
                  width: s * 0.82,
                  height: s * 0.82,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(colors: [...aiGradientColors, HomeColors.navyMid]),
                  ),
                ),
              ),
              Container(
                width: s * 0.82 - 6,
                height: s * 0.82 - 6,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
              ),
              Transform.scale(
                scale: 0.9 + 0.15 * wave,
                child: ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (rect) => const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: aiGradientColors,
                  ).createShader(rect),
                  child: Icon(Icons.auto_awesome_rounded, size: s * 0.36),
                ),
              ),
              for (var i = 0; i < 3; i++) _orbitDot(s, t, i),
            ],
          ),
        );
      },
    );
  }

  Widget _orbitDot(double s, double t, int i) {
    final angle = -t * 2 * math.pi + i * 2 * math.pi / 3;
    final r = s * 0.47;
    final phase = 0.5 + 0.5 * math.sin((t * 3 + i / 3) * 2 * math.pi);
    return Transform.translate(
      offset: Offset(math.cos(angle) * r, math.sin(angle) * r),
      child: Opacity(
        opacity: 0.35 + 0.65 * phase,
        child: Icon(Icons.auto_awesome, size: 7 + 5 * phase, color: aiGradientColors[i]),
      ),
    );
  }
}

class _AiLoadingDialog extends StatefulWidget {
  const _AiLoadingDialog();

  @override
  State<_AiLoadingDialog> createState() => _AiLoadingDialogState();
}

class _AiLoadingDialogState extends State<_AiLoadingDialog> {
  late final List<String> _steps = [
    'summary_step_read'.trFallback('Reading the grievance…'),
    'summary_step_dept'.trFallback('Finding responsible departments…'),
    'summary_step_write'.trFallback('Writing your summary…'),
  ];
  var _step = 0;
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1800), (_) {
      if (mounted) setState(() => _step = (_step + 1) % _steps.length);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Material(
            color: Colors.white,
            borderRadius: const BorderRadius.all(Radius.circular(24)),
            child: SizedBox(
              width: 280,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AiThinkingOrb(),
                    const SizedBox(height: 18),
                    ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (rect) => const LinearGradient(colors: aiGradientColors).createShader(rect),
                      child: Text(
                        'summary_loading'.trFallback('AI is thinking'),
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
                      ),
                    ),
                    const SizedBox(height: 6),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween(begin: const Offset(0, 0.35), end: Offset.zero).animate(anim),
                          child: child,
                        ),
                      ),
                      child: Text(
                        _steps[_step],
                        key: ValueKey(_step),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: HomeColors.muted, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: const LinearProgressIndicator(
                        minHeight: 4,
                        backgroundColor: Color(0xFFEDE8F8),
                        valueColor: AlwaysStoppedAnimation(Color(0xFF7B5CF0)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<T> runWithSummaryLoading<T>(BuildContext context, Future<T> Function() action) async {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: HomeColors.navyDeep.withValues(alpha: 0.55),
    builder: (_) => const _AiLoadingDialog(),
  );
  try {
    return await action();
  } finally {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}
