import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'ui.dart';

class AppEmptyCard extends StatefulWidget {
  const AppEmptyCard({
    super.key,
    required this.title,
    this.sub,
    this.icon = Icons.inbox_rounded,
    this.actionLabel,
    this.onAction,
    this.compact = false,
    this.onDark = false,
  });

  final String title;
  final String? sub;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;
  final bool onDark;

  @override
  State<AppEmptyCard> createState() => _AppEmptyCardState();
}

class _AppEmptyCardState extends State<AppEmptyCard> with TickerProviderStateMixin {
  late final AnimationController _enter;
  late final AnimationController _float;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 720))..forward();
    _float = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _fade = CurvedAnimation(parent: _enter, curve: Curves.easeOut);
    _scale = CurvedAnimation(parent: _enter, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _enter.dispose();
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = widget.compact;
    final onDark = widget.onDark;
    final ink = onDark ? Colors.white : HomeColors.ink;
    final muted = onDark ? HomeColors.navyMuted : HomeColors.muted;
    final wash = onDark ? const Color(0x33FFFFFF) : HomeColors.peach2;
    final iconColor = onDark ? HomeColors.orangeSoft : HomeColors.orange;

    final content = FadeTransition(
      opacity: _fade,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: Listenable.merge([_scale, _float]),
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, (0.5 - _float.value) * (compact ? 4 : 7)),
                child: Transform.scale(scale: 0.72 + (_scale.value * 0.28), child: child),
              );
            },
            child: Container(
              width: compact ? 56 : 78,
              height: compact ? 56 : 78,
              decoration: BoxDecoration(color: wash, shape: BoxShape.circle),
              child: Icon(widget.icon, size: compact ? 26 : 36, color: iconColor),
            ),
          ),
          SizedBox(height: compact ? 12 : 16),
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: compact ? 15 : 17, height: 1.3),
          ),
          if (widget.sub != null && widget.sub!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              widget.sub!,
              textAlign: TextAlign.center,
              style: TextStyle(color: muted, fontWeight: FontWeight.w600, fontSize: compact ? 12.5 : 13.5, height: 1.4),
            ),
          ],
          if (widget.actionLabel != null && widget.onAction != null) ...[
            SizedBox(height: compact ? 12 : 16),
            PrimaryButton(widget.actionLabel!, onTap: widget.onAction),
          ],
        ],
      ),
    );

    if (onDark) return content;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 4, vertical: compact ? 0 : 8),
      child: Material(
        color: onDark ? Colors.transparent : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(compact ? 20 : 24)),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, compact ? 18 : 28, 20, compact ? 18 : 26),
          child: content,
        ),
      ),
    );
  }
}
