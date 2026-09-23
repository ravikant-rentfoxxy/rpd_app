import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// The IRO kit: the pieces every screen is assembled from. Nothing here knows
/// about the session or the data layer, so the same card reads the same on
/// Home, Work and Community.

TextStyle iroDisplay({double size = 20, Color color = Iro.ink, FontWeight weight = FontWeight.w800}) {
  return GoogleFonts.poppins(fontSize: size, fontWeight: weight, color: color, height: 1.2);
}

TextStyle iroLabel({double size = 11, Color color = Iro.muted, FontWeight weight = FontWeight.w600}) {
  return GoogleFonts.poppins(fontSize: size, fontWeight: weight, color: color, height: 1.25, letterSpacing: 0.2);
}

/// The white card the whole app is built from: 20pt radius, hairline rule and
/// the shared two-layer shadow.
class IroCard extends StatelessWidget {
  const IroCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin = const EdgeInsets.only(bottom: 14),
    this.onTap,
    this.radius = 20,
    this.color = Iro.surface,
    this.border = Iro.line,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final double radius;
  final Color color;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: border == null ? BorderSide.none : BorderSide(color: border!),
    );
    return Padding(
      padding: margin,
      child: DecoratedBox(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(radius), boxShadow: iroCardShadow),
        child: Material(
          color: color,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: onTap == null
              ? Padding(padding: padding, child: child)
              : InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
        ),
      ),
    );
  }
}

/// A small rounded label. Used for status, distance, language and counts.
class IroChip extends StatelessWidget {
  const IroChip(
    this.label, {
    super.key,
    this.icon,
    this.fg = Iro.green,
    this.bg = Iro.wash,
    this.dot = false,
    this.size = 10.5,
    this.dense = false,
  });

  final String label;
  final IconData? icon;
  final Color fg;
  final Color bg;
  final bool dot;
  final double size;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 7 : 9, vertical: dense ? 3 : 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(width: 6, height: 6, decoration: BoxDecoration(color: fg, shape: BoxShape.circle)),
            const SizedBox(width: 5),
          ],
          if (icon != null) ...[
            Icon(icon, size: size + 2.5, color: fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: iroLabel(size: size, color: fg, weight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// A section heading with an optional quiet note on the right, the pattern the
/// whole app uses above a rail or a list.
class IroSectionHeading extends StatelessWidget {
  const IroSectionHeading(this.title, {super.key, this.trailing, this.onTrailingTap, this.leading, this.top = 6});

  final String title;
  final String? trailing;
  final VoidCallback? onTrailingTap;
  final Widget? leading;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: top, bottom: 10, left: 2, right: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 7)],
          Expanded(child: Text(title, style: iroDisplay(size: 17.5))),
          if (trailing != null)
            GestureDetector(
              onTap: onTrailingTap,
              child: Text(trailing!, style: iroLabel(size: 11.5, color: Iro.greenMid, weight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}

/// One cell of the 2×2 snapshot grid: a quiet label, a big number, a short
/// qualifier, and a tinted icon in the corner.
class IroStatTile extends StatelessWidget {
  const IroStatTile({
    super.key,
    required this.label,
    required this.value,
    required this.note,
    required this.icon,
    this.tone = Iro.green,
    this.noteTone,
    this.onTap,
  });

  final String label;
  final String value;
  final String note;
  final IconData icon;
  final Color tone;
  final Color? noteTone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IroCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
      radius: 18,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: iroLabel(size: 11.5, color: Iro.muted, weight: FontWeight.w600),
                ),
              ),
              Icon(icon, size: 16, color: tone),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: iroDisplay(size: 23, color: tone)),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  note,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: iroLabel(size: 10.5, color: noteTone ?? Iro.muted, weight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The scrolling filter row above a feed.
class IroSegmented extends StatelessWidget {
  const IroSegmented({super.key, required this.items, required this.index, required this.onChanged, this.scroll = true});

  final List<String> items;
  final int index;
  final ValueChanged<int> onChanged;
  final bool scroll;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      for (var i = 0; i < items.length; i++)
        Padding(
          padding: EdgeInsets.only(right: i == items.length - 1 ? 0 : 8),
          child: _SegChip(label: items[i], on: i == index, onTap: () => onChanged(i)),
        ),
    ];
    if (!scroll) return Row(children: [for (final chip in chips) Flexible(child: chip)]);
    return SizedBox(
      height: 36,
      child: ListView(scrollDirection: Axis.horizontal, children: chips),
    );
  }
}

class _SegChip extends StatelessWidget {
  const _SegChip({required this.label, required this.on, required this.onTap});
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: on ? Iro.forest : Iro.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(color: on ? Iro.forest : Iro.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: iroLabel(size: 12, color: on ? Colors.white : Iro.ink2, weight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}

/// The saturation dial on the duty card.
class IroRing extends StatelessWidget {
  const IroRing({super.key, required this.value, this.size = 46, this.track = const Color(0x33FFFFFF), this.fill = Iro.leaf, this.label});

  final double value;
  final double size;
  final Color track;
  final Color fill;
  final String? label;

  @override
  Widget build(BuildContext context) {
    // Clamp once: the arc and the number it is labelled with have to agree.
    final done = value.clamp(0, 1).toDouble();
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(value: done, track: track, fill: fill),
        child: Center(
          child: Text(
            label ?? '${(done * 100).round()}%',
            style: iroLabel(size: size * 0.24, color: Colors.white, weight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.value, required this.track, required this.fill});
  final double value;
  final Color track;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.1;
    final rect = Offset(stroke / 2, stroke / 2) & Size(size.width - stroke, size.height - stroke);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = fill;
    canvas.drawArc(rect, 0, math.pi * 2, false, base);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * value, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value || old.fill != fill;
}

/// A horizontal progress rule with a rounded cap.
class IroMeter extends StatelessWidget {
  const IroMeter({super.key, required this.value, this.height = 7, this.track = Iro.wash, this.fill});

  final double value;
  final double height;
  final Color track;
  final Gradient? fill;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: track)),
            FractionallySizedBox(
              widthFactor: value.clamp(0, 1).toDouble(),
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: fill ?? Iro.actionGradient),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A painted district map. The app runs offline, so the sector view is drawn
/// rather than fetched — it always renders, on any handset, with no tiles.
class IroMiniMap extends StatelessWidget {
  const IroMiniMap({super.key, required this.height, this.seed = 7, this.overlay = const [], this.radius = 16});

  final double height;
  final int seed;
  final List<Widget> overlay;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _MapPainter(seed: seed)),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x59062012), Color(0x00062012), Color(0x73062012)],
                  stops: [0, 0.45, 1],
                ),
              ),
            ),
            ...overlay,
          ],
        ),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter({required this.seed});
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed);
    final w = size.width;
    final h = size.height;

    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFCFE4D2));

    // Green belts and parks.
    final park = Paint()..color = const Color(0xFFA9CFB0);
    for (var i = 0; i < 5; i++) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(rng.nextDouble() * w * 0.8, rng.nextDouble() * h * 0.75, 40 + rng.nextDouble() * 70, 26 + rng.nextDouble() * 44),
        const Radius.circular(9),
      );
      canvas.drawRRect(rect, park);
    }

    // The river, drawn before roads so bridges read on top.
    final river = Path()
      ..moveTo(w * 0.78, -6)
      ..cubicTo(w * 0.62, h * 0.3, w * 0.9, h * 0.55, w * 0.68, h + 6);
    canvas.drawPath(
      river,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * 0.16
        ..color = const Color(0xFF9EC4D8),
    );

    // Arterial roads.
    final major = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFFFF6E2);
    canvas.drawLine(Offset(-4, h * 0.62), Offset(w + 4, h * 0.38), major);
    canvas.drawLine(Offset(w * 0.28, -4), Offset(w * 0.46, h + 4), major);

    // Lanes.
    final minor = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xCCFFFFFF);
    for (var i = 0; i < 7; i++) {
      final y = h * (0.12 + i * 0.13);
      canvas.drawLine(Offset(0, y), Offset(w * (0.35 + rng.nextDouble() * 0.5), y - 10), minor);
    }
    for (var i = 0; i < 5; i++) {
      final x = w * (0.08 + i * 0.19);
      canvas.drawLine(Offset(x, 0), Offset(x + 14, h), minor);
    }

    // Blocks.
    final block = Paint()..color = const Color(0x40FFFFFF);
    for (var i = 0; i < 16; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(rng.nextDouble() * w, rng.nextDouble() * h, 12 + rng.nextDouble() * 22, 10 + rng.nextDouble() * 16),
          const Radius.circular(3),
        ),
        block,
      );
    }

    // Plotted incidents.
    for (var i = 0; i < 8; i++) {
      final centre = Offset(w * (0.12 + rng.nextDouble() * 0.76), h * (0.18 + rng.nextDouble() * 0.66));
      canvas.drawCircle(centre, 9, Paint()..color = const Color(0x33BF3B2B));
      canvas.drawCircle(centre, 4, Paint()..color = const Color(0xFFBF3B2B));
      canvas.drawCircle(centre, 4, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(_MapPainter old) => old.seed != seed;
}

/// A photo that always has something to show. The dummy feed points at remote
/// images and the app runs offline, so every tile falls back to painted art
/// rather than a broken frame.
class IroPhoto extends StatelessWidget {
  const IroPhoto({super.key, required this.url, required this.icon, this.seed = 3, this.fit = BoxFit.cover});

  final String? url;
  final IconData icon;
  final int seed;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final src = url?.trim() ?? '';
    final fallback = _PhotoFallback(icon: icon, seed: seed);
    if (!src.startsWith('http')) return fallback;
    return Image.network(
      src,
      fit: fit,
      errorBuilder: (_, _, _) => fallback,
      loadingBuilder: (context, child, progress) => progress == null ? child : fallback,
    );
  }
}

class _PhotoFallback extends StatelessWidget {
  const _PhotoFallback({required this.icon, required this.seed});
  final IconData icon;
  final int seed;

  @override
  Widget build(BuildContext context) {
    final tints = [
      [Iro.wash, Iro.wash2],
      [const Color(0xFFDBEFE2), const Color(0xFFEAF6EE)],
      [const Color(0xFFE6F0DC), const Color(0xFFF2F8EC)],
    ][seed % 3];
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: tints),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final side = math.min(constraints.maxWidth, constraints.maxHeight);
          return Center(child: Icon(icon, size: (side * 0.34).clamp(18.0, 44.0), color: Iro.greenMid));
        },
      ),
    );
  }
}

/// The single filled action. Used once per screen, never twice.
class IroActionButton extends StatelessWidget {
  const IroActionButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.enabled = true,
    this.height = 50,
    this.gradient,
    this.wide = true,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool enabled;
  final double height;
  final Gradient? gradient;

  /// A wide button fills its parent; a narrow one sizes to its label, so it can
  /// sit beside another control in a row.
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient ?? Iro.actionGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(color: Color(0x3315633A), blurRadius: 16, offset: Offset(0, 8))],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: enabled ? onTap : null,
            child: SizedBox(
              height: height,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: wide ? 0 : 16),
                child: Row(
                  mainAxisSize: wide ? MainAxisSize.max : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: height < 42 ? 15 : 18, color: Colors.white),
                      const SizedBox(width: 7),
                    ],
                    Text(
                      label,
                      style: iroLabel(size: height < 42 ? 12 : 14.5, color: Colors.white, weight: FontWeight.w700),
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

/// One side of the like/dislike pair: the icon, the running count, and the tint
/// that says which side this member is on.
///
/// [onTap] null makes it read-only — the figure without the invitation, which
/// is what a member's own post shows, since voting on yourself is not a thing.
class IroVoteButton extends StatelessWidget {
  const IroVoteButton({
    super.key,
    required this.icon,
    required this.count,
    required this.on,
    required this.tone,
    this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final int count;

  /// This member has voted this way.
  final bool on;
  final Color tone;
  final VoidCallback? onTap;
  final bool enabled;

  bool get _live => onTap != null && enabled;

  @override
  Widget build(BuildContext context) {
    final fg = on ? tone : Iro.ink2;
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: fg),
        const SizedBox(width: 6),
        Text('$count', style: iroLabel(size: 12, color: fg, weight: FontWeight.w700)),
      ],
    );

    // Read-only: no box, no border — a figure, read the same way as the view
    // count beside it. A pill that looks pressable but is not would be a lie.
    if (onTap == null) {
      return Padding(padding: const EdgeInsets.symmetric(vertical: 9), child: row);
    }

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: on ? tone.withValues(alpha: 0.10) : Iro.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: on ? tone.withValues(alpha: 0.45) : Iro.line),
        ),
        child: _live
            ? InkWell(borderRadius: BorderRadius.circular(10), onTap: onTap, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9), child: row))
            : Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9), child: row),
      ),
    );
  }
}

/// How many people have opened this. Says nothing at zero rather than boasting
/// about it.
class IroViewCount extends StatelessWidget {
  const IroViewCount(this.views, {super.key, this.size = 11.5});
  final int views;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (views <= 0) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.visibility_outlined, size: size + 2.5, color: Iro.muted),
        const SizedBox(width: 4),
        Text('$views', style: iroLabel(size: size, weight: FontWeight.w700)),
      ],
    );
  }
}

/// A quiet outlined action, for the second choice on a card.
class IroGhostButton extends StatelessWidget {
  const IroGhostButton({super.key, required this.label, required this.onTap, this.icon, this.tone = Iro.ink2});

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Iro.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Iro.line)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 15, color: tone), const SizedBox(width: 6)],
              Text(label, style: iroLabel(size: 12, color: tone, weight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

/// The numbered progress rail on the report flow.
class IroStepRail extends StatelessWidget {
  const IroStepRail({super.key, required this.steps, required this.index, this.onStepTap});

  final List<String> steps;
  final int index;
  final ValueChanged<int>? onStepTap;

  @override
  Widget build(BuildContext context) {
    final cells = <Widget>[];
    for (var i = 0; i < steps.length; i++) {
      final done = i < index;
      final active = i == index;
      cells.add(
        Expanded(
          child: GestureDetector(
            onTap: onStepTap == null || i > index ? null : () => onStepTap!(i),
            behavior: HitTestBehavior.opaque,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? Iro.green : (active ? Iro.forest : Iro.wash),
                    border: Border.all(color: active ? Iro.forest : Colors.transparent, width: 2),
                  ),
                  child: Center(
                    child: done
                        ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
                        : Text(
                            '${i + 1}',
                            style: iroLabel(
                              size: 12,
                              color: active ? Colors.white : Iro.muted,
                              weight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  steps[i],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: iroLabel(
                    size: 10.5,
                    color: done || active ? Iro.ink : Iro.muted2,
                    weight: done || active ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      if (i != steps.length - 1) {
        cells.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Container(width: 18, height: 2, color: i < index ? Iro.green : Iro.line),
          ),
        );
      }
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: cells);
  }
}

/// A short bar of fake levels, the shape people read as "a recording exists".
class IroWaveform extends StatelessWidget {
  const IroWaveform({super.key, this.bars = 38, this.played = 0.45, this.height = 26});

  final int bars;
  final double played;
  final double height;

  @override
  Widget build(BuildContext context) {
    final rng = math.Random(11);
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var i = 0; i < bars; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Container(
                  height: height * (0.22 + rng.nextDouble() * 0.78),
                  decoration: BoxDecoration(
                    color: i / bars <= played ? Iro.greenMid : Iro.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
