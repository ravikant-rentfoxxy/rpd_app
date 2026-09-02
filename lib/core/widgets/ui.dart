import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class PartyMark extends StatelessWidget {
  const PartyMark({super.key, this.size = 62, this.onBrand = false});
  final double size;
  final bool onBrand;

  @override
  Widget build(BuildContext context) {
    final bg = onBrand ? Colors.white.withValues(alpha: 0.16) : AppColors.brand;
    final fg = onBrand ? Colors.white : AppColors.brandOn;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(size * 0.24)),
      child: CustomPaint(painter: _BarsPainter(fg)),
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    final r = Radius.circular(size.width * 0.04);
    canvas.drawRRect(RRect.fromLTRBR(size.width * 0.26, size.height * 0.55, size.width * 0.38, size.height * 0.74, r), p);
    canvas.drawRRect(RRect.fromLTRBR(size.width * 0.44, size.height * 0.43, size.width * 0.56, size.height * 0.74, r), p);
    canvas.drawRRect(RRect.fromLTRBR(size.width * 0.62, size.height * 0.28, size.width * 0.74, size.height * 0.74, r), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.tone = CardTone.plain,
    this.onTap,
    this.margin,
  });
  final Widget child;
  final CardTone tone;
  final VoidCallback? onTap;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color border) = switch (tone) {
      CardTone.plain => (AppColors.card, AppColors.rule),
      CardTone.flat => (AppColors.sunk, Colors.transparent),
      CardTone.brand => (AppColors.brandWash, AppColors.brandLight),
      CardTone.ok => (AppColors.okBg, AppColors.ok),
      CardTone.warn => (AppColors.warnBg, AppColors.warn),
      CardTone.bad => (AppColors.badBg, AppColors.bad),
    };
    return Padding(
      padding: margin ?? const EdgeInsets.only(bottom: 12),
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpace.cardRadius),
          side: BorderSide(color: border),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpace.cardRadius),
          child: Padding(padding: const EdgeInsets.fromLTRB(11, 10, 11, 10), child: child),
        ),
      ),
    );
  }
}

enum CardTone { plain, flat, brand, ok, warn, bad }

class CardTitle extends StatelessWidget {
  const CardTitle(this.title, {super.key, this.sub});
  final String title;
  final String? sub;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, height: 1.35)),
        if (sub != null) ...[
          const SizedBox(height: 2),
          Text(sub!, style: GoogleFonts.ibmPlexMono(fontSize: 11, color: AppColors.ink3, height: 1.5)),
        ],
      ],
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton(this.label, {super.key, required this.onTap, this.enabled = true, this.ghost = false});
  final String label;
  final VoidCallback? onTap;
  final bool enabled;
  final bool ghost;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ghost
          ? OutlinedButton(
              onPressed: enabled ? onTap : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.ink2,
                side: const BorderSide(color: AppColors.rule2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpace.controlRadius)),
              ),
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            )
          : FilledButton(
              onPressed: enabled ? onTap : null,
              style: FilledButton.styleFrom(
                backgroundColor: enabled ? AppColors.brand : AppColors.rule2,
                foregroundColor: enabled ? AppColors.brandOn : AppColors.ink4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpace.controlRadius)),
              ),
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
    );
  }
}

class AppField extends StatelessWidget {
  const AppField({
    super.key,
    required this.label,
    required this.controller,
    this.keyboard,
    this.hint,
    this.mono = false,
    this.prefix,
    this.maxLength,
    this.onChanged,
  });
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboard;
  final String? hint;
  final bool mono;
  final String? prefix;
  final int? maxLength;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final textStyle = mono
        ? GoogleFonts.ibmPlexMono(fontSize: 16, color: AppColors.ink)
        : const TextStyle(fontSize: 16, color: AppColors.ink);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.rule2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.ink3)),
          TextField(
            controller: controller,
            keyboardType: keyboard,
            maxLength: maxLength,
            onChanged: onChanged,
            style: textStyle,
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              counterText: '',
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.ink4),
              prefixText: prefix,
              prefixStyle: textStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class StepBar extends StatelessWidget {
  const StepBar({super.key, required this.total, required this.current});
  final int total;
  final int current;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: List.generate(total, (i) {
          return Expanded(
            child: Container(
              height: 3,
              margin: EdgeInsets.only(right: i == total - 1 ? 0 : 3),
              decoration: BoxDecoration(
                color: i < current ? AppColors.brandLight : AppColors.rule2,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class Pill extends StatelessWidget {
  const Pill(this.label, {super.key, this.tone = PillTone.neutral});
  final String label;
  final PillTone tone;
  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (tone) {
      PillTone.ok => (AppColors.okBg, AppColors.ok),
      PillTone.warn => (AppColors.warnBg, AppColors.warn),
      PillTone.bad => (AppColors.badBg, AppColors.bad),
      PillTone.brand => (AppColors.brandWash, AppColors.brandLight),
      PillTone.neutral => (AppColors.sunk, AppColors.ink3),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

enum PillTone { ok, warn, bad, brand, neutral }

class DisplayText extends StatelessWidget {
  const DisplayText(this.text, {super.key, this.size = 19, this.color, this.center = false});
  final String text;
  final double size;
  final Color? color;
  final bool center;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: center ? TextAlign.center : TextAlign.start,
      style: GoogleFonts.bricolageGrotesque(
        fontWeight: FontWeight.w800,
        fontSize: size,
        letterSpacing: -0.6,
        color: color ?? AppColors.ink,
        height: 1.18,
      ),
    );
  }
}

class MonoText extends StatelessWidget {
  const MonoText(this.text, {super.key, this.size = 12, this.color});
  final String text;
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    return Text(text, style: GoogleFonts.ibmPlexMono(fontSize: size, color: color ?? AppColors.ink3));
  }
}

class ScoreBar extends StatelessWidget {
  const ScoreBar({super.key, required this.value, this.color = AppColors.brandLight});
  final double value;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 5,
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(color: AppColors.rule2, borderRadius: BorderRadius.circular(3)),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: value.clamp(0, 1),
        child: DecoratedBox(
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
      ),
    );
  }
}

class AvatarCircle extends StatelessWidget {
  const AvatarCircle(this.initials, {super.key, this.color, this.bg});
  final String initials;
  final Color? color;
  final Color? bg;
  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: bg ?? AppColors.brandWash,
      child: Text(
        initials,
        style: TextStyle(color: color ?? AppColors.brandLight, fontWeight: FontWeight.w700, fontSize: 11),
      ),
    );
  }
}
