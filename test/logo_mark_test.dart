import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpd_app/core/theme/app_colors.dart';
import 'package:rpd_app/core/widgets/iro_header.dart';

/// The mark's artwork has to reach the edge of its disc all the way round.
///
/// It did not. With a border on the Container's *background* decoration, the
/// artwork was inset by the border's width, so the square logo was laid out
/// smaller than the circle clipping it and the disc's own fill showed through
/// at the top, bottom and sides. The border is gone now, but the trap is not —
/// re-adding one the same way brings the gaps straight back.

const size = 42.0;
const ratio = 12.0;

void main() {
  testWidgets('the artwork reaches the edge all the way round', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          backgroundColor: Iro.mint,
          body: Center(child: RepaintBoundary(child: IroMark(size: size))),
        ),
      ),
    );
    await tester.runAsync(() async {
      await tester.pumpAndSettle();
      // The asset has to decode before there is anything to read back.
      await Future<void>.delayed(const Duration(milliseconds: 400));
    });
    await tester.pumpAndSettle();

    final boundary = tester.renderObject<RenderRepaintBoundary>(find.byType(RepaintBoundary).last);
    late ui.Image image;
    late ByteData data;
    await tester.runAsync(() async {
      image = await boundary.toImage(pixelRatio: ratio);
      data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    });

    final bytes = data.buffer.asUint8List();
    final w = image.width;
    (int, int, int, int) at(int x, int y) {
      final i = (y * w + x) * 4;
      return (bytes[i], bytes[i + 1], bytes[i + 2], bytes[i + 3]);
    }

    // The disc's fill, which is only meant to show when the asset fails.
    bool isWash((int, int, int, int) c) =>
        (c.$1 - (Iro.wash.r * 255).round()).abs() < 12 &&
        (c.$2 - (Iro.wash.g * 255).round()).abs() < 12 &&
        (c.$3 - (Iro.wash.b * 255).round()).abs() < 12;

    final centre = w / 2;
    // One logical pixel inside the edge — where an inset artwork falls short.
    final radius = centre - ratio;

    for (final degrees in [0, 45, 90, 135, 180, 225, 270, 315]) {
      final a = degrees * math.pi / 180;
      final x = (centre + radius * math.cos(a)).round();
      final y = (centre + radius * math.sin(a)).round();
      final colour = at(x, y);
      expect(
        isWash(colour),
        isFalse,
        reason: 'at $degrees° the disc shows through instead of the logo — the '
            'artwork is inset again, which a background border would do. Got $colour',
      );
      expect(colour.$4, greaterThan(230), reason: 'at $degrees° nothing is painted at all');
    }
  });

  testWidgets('no ring is drawn around the mark', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          backgroundColor: Iro.mint,
          body: Center(child: RepaintBoundary(child: IroMark(size: size))),
        ),
      ),
    );
    await tester.runAsync(() async {
      await tester.pumpAndSettle();
      await Future<void>.delayed(const Duration(milliseconds: 400));
    });
    await tester.pumpAndSettle();

    final boundary = tester.renderObject<RenderRepaintBoundary>(find.byType(RepaintBoundary).last);
    late ui.Image image;
    late ByteData data;
    await tester.runAsync(() async {
      image = await boundary.toImage(pixelRatio: ratio);
      data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    });
    final bytes = data.buffer.asUint8List();
    final w = image.width;

    var leaf = 0;
    for (var i = 0; i < bytes.length; i += 4) {
      if (bytes[i + 3] < 200) continue;
      if ((bytes[i] - (Iro.leaf.r * 255).round()).abs() < 30 &&
          (bytes[i + 1] - (Iro.leaf.g * 255).round()).abs() < 30 &&
          (bytes[i + 2] - (Iro.leaf.b * 255).round()).abs() < 30) {
        leaf++;
      }
    }
    // The logo's own art is orange and navy, so any run of leaf green is a ring.
    expect(leaf, lessThan(w), reason: 'a green ring is being drawn around the mark again ($leaf px)');
  });

  testWidgets('the mark still draws when the asset is missing', (tester) async {
    // The errorBuilder keeps a broken asset from taking the header down.
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Center(child: IroMark(size: size)))),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
