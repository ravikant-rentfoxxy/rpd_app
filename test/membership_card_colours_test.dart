import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rpd_app/core/theme/app_colors.dart';
import 'package:rpd_app/core/translations/app_translations.dart';
import 'package:rpd_app/features/card/membership_card_view.dart';

/// The membership card is a printed object, so it kept its purple and orange
/// when the rest of the app went green. The back was drawn with the shared
/// VerifyColors names, which the retint pointed at the greens — so the two
/// sides stopped matching. Both sides are checked here, because the bug was
/// only ever visible by comparing them.

/// The card's own palette, repeated here on purpose: the constants are private
/// to the view, and a test that imported them could not catch them changing.
const cardPurple = Color(0xFF4A1878);
const cardOrange = Color(0xFFE88224);

const member = <String, dynamic>{
  'fullName': 'Pankaj Yadav',
  'membershipNumber': 'RPD-UP-57',
  'mobile': '+918076473811',
  'stateName': 'Uttar Pradesh',
  'districtName': 'Agra',
  'assemblyName': 'Agra Cantt',
  'validTo': '2028-03-31',
  'rowId': 57,
  'stateCode': 'UP',
};

Future<Set<int>> paint(WidgetTester tester, Widget card) async {
  tester.view.physicalSize = const Size(900, 700);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  Get.locale = const Locale('en', 'US');
  Get.addTranslations(AppTranslations().keys);

  await tester.pumpWidget(GetMaterialApp(
    translations: AppTranslations(),
    locale: const Locale('en', 'US'),
    home: Scaffold(body: Center(child: RepaintBoundary(child: card))),
  ));
  await tester.pump(const Duration(milliseconds: 250));

  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byType(RepaintBoundary).last);
  late ByteData data;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  });

  final bytes = data.buffer.asUint8List();
  final seen = <int>{};
  for (var i = 0; i < bytes.length; i += 4) {
    if (bytes[i + 3] < 250) continue;
    seen.add((bytes[i] << 16) | (bytes[i + 1] << 8) | bytes[i + 2]);
  }
  return seen;
}

int rgb(Color c) =>
    ((c.r * 255).round() << 16) | ((c.g * 255).round() << 8) | (c.b * 255).round();

void main() {
  testWidgets('the front is the card purple and orange', (tester) async {
    final seen = await paint(tester, const MembershipCardFace(member: member));
    expect(seen, contains(rgb(cardPurple)));
    expect(seen, contains(rgb(cardOrange)));
  });

  testWidgets('the back is the same, not the app green', (tester) async {
    final seen = await paint(tester, const MembershipCardBack(member: member));
    expect(seen, contains(rgb(cardOrange)), reason: 'the back lost the card orange');
    // Purple only appears as the first stop of the header gradient, under a
    // rounded corner, so the exact value does not survive — the hue does.
    final purples = seen.where((c) {
      final r = (c >> 16) & 0xFF, g = (c >> 8) & 0xFF, b = c & 0xFF;
      return b > g + 40 && r > g + 20;
    });
    expect(purples, isNotEmpty, reason: 'the back has no purple in it at all');

    // The retint is what broke this the first time.
    for (final green in [Iro.green, Iro.greenMid, Iro.bright, Iro.leaf, Iro.forest]) {
      expect(
        seen,
        isNot(contains(rgb(green))),
        reason: 'the back is painting an app green again — the card keeps its own palette',
      );
    }
  });
}
