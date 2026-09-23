import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rpd_app/core/translations/app_translations.dart';
import 'package:rpd_app/data/models/broadcast.dart';
import 'package:rpd_app/features/home/home_widgets.dart';

Widget _host(Widget child, {String locale = 'en'}) => GetMaterialApp(
      translations: AppTranslations(),
      locale: Locale(locale),
      home: Scaffold(body: child),
    );

void main() {
  group('Broadcast.fromJson', () {
    test('reads the per-language payload the home endpoint sends', () {
      final item = Broadcast.fromJson({
        'id': 'a1',
        'message': {'hi': 'नमस्ते', 'en': 'Hello', 'bho': ''},
        'audioUrl': 'https://example.invalid/a.mp3',
        'sentAt': '2026-09-22T08:30:00.000Z',
      });
      expect(item, isNotNull);
      expect(item!.messages, {'hi': 'नमस्ते', 'en': 'Hello'});
      expect(item.hasAudio, isTrue);
    });

    test('is null when the author wrote no language at all', () {
      expect(Broadcast.fromJson({'id': 'a1', 'message': {'hi': '', 'en': '   '}}), isNull);
    });

    test('is null when there is no announcement on the payload', () {
      expect(Broadcast.fromJson(null), isNull);
    });

    test('falls back to another language rather than rendering blank', () {
      Get.locale = const Locale('bho');
      final item = Broadcast.fromJson({
        'id': 'a1',
        'message': {'hi': 'हिन्दी वाला', 'en': '', 'bho': ''},
      });
      // Bhojpuri was left empty by the author, so Hindi stands in.
      expect(item!.message, 'हिन्दी वाला');
      Get.locale = null;
    });
  });

  testWidgets('the card shows the message and the share action', (tester) async {
    final item = Broadcast.fromJson({
      'id': 'a1',
      'message': {'en': 'Rally on the 12th'},
      'sentAt': DateTime.now().toIso8601String(),
    })!;
    await tester.pumpWidget(_host(HomeBroadcastCard(broadcast: item)));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Rally on the 12th'), findsOneWidget);
    expect(find.text('Official message'), findsOneWidget);
    expect(find.text('Share on WhatsApp'), findsOneWidget);
    // No recording attached, so there is nothing to listen to.
    expect(find.text('Listen'), findsNothing);
  });

  testWidgets('an announcement with audio offers the listen action', (tester) async {
    final item = Broadcast.fromJson({
      'id': 'a1',
      'message': {'en': 'Rally on the 12th'},
      'audioUrl': 'https://example.invalid/a.mp3',
      'sentAt': DateTime.now().toIso8601String(),
    })!;
    await tester.pumpWidget(_host(HomeBroadcastCard(broadcast: item)));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Listen'), findsOneWidget);
  });
}
