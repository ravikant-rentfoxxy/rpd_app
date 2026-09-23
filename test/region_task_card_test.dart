import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rpd_app/core/theme/app_colors.dart';
import 'package:rpd_app/core/translations/app_translations.dart';
import 'package:rpd_app/core/widgets/iro_ui.dart';
import 'package:rpd_app/features/tasks/tasks_view.dart';

/// The region task card used to be a plain white box whose column shrink-wrapped,
/// so two tasks came out different widths depending on their titles. Its meta
/// line also overflowed once a long name met a long count, which the Hindi and
/// Bhojpuri copy both make more likely.

Map<String, dynamic> task({bool started = false, bool canStart = true, int count = 0}) => {
      'id': 't1',
      'title': 'Check water connectivity in every ward of the constituency',
      'started': started,
      'canStart': canStart,
      'startedCount': count,
      'assignerName': 'Sreekala Ramachandran Nair',
    };

Widget host(Widget child, {double width = 360, Locale locale = const Locale('en', 'US')}) {
  Get.locale = locale;
  Get.addTranslations(AppTranslations().keys);
  return GetMaterialApp(
    translations: AppTranslations(),
    locale: locale,
    fallbackLocale: const Locale('en', 'US'),
    home: Scaffold(
      backgroundColor: Iro.mint,
      body: Center(
        child: SizedBox(width: width, child: SingleChildScrollView(child: child)),
      ),
    ),
  );
}

void main() {
  testWidgets('long text on a narrow phone does not overflow', (tester) async {
    for (final locale in [const Locale('en', 'US'), const Locale('hi', 'IN'), const Locale('bho', 'IN')]) {
      await tester.pumpWidget(host(
        RegionTaskCard(
          task: task(),
          sub: 'Walk every ward and note where the supply is broken, then report back with photographs.',
          starting: false,
          onStart: () {},
        ),
        width: 300,
        locale: locale,
      ));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: '$locale overflows at 300px');
    }
  });

  testWidgets('two cards in a list come out the same width', (tester) async {
    await tester.pumpWidget(host(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RegionTaskCard(task: task(), sub: 'short', starting: false, onStart: () {}),
          RegionTaskCard(
            task: task()..['title'] = 'x',
            sub: 'a much, much longer description than the other one has',
            starting: false,
            onStart: () {},
          ),
        ],
      ),
    ));
    await tester.pump();

    final widths = tester
        .widgetList<RegionTaskCard>(find.byType(RegionTaskCard))
        .map((w) => tester.getSize(find.byWidget(w)).width)
        .toSet();
    expect(widths, hasLength(1), reason: 'cards are still sizing to their own text');
  });

  testWidgets('a task not yet started offers Start', (tester) async {
    await tester.pumpWidget(host(
      RegionTaskCard(task: task(), sub: '', starting: false, onStart: () {}),
    ));
    await tester.pump();
    expect(find.byType(IroActionButton), findsOneWidget);
    expect(find.text('Nobody started yet'), findsOneWidget);
  });

  testWidgets('a started task shows the chip and drops Start', (tester) async {
    await tester.pumpWidget(host(
      RegionTaskCard(task: task(started: true, count: 4), sub: '', starting: false, onStart: () {}),
    ));
    await tester.pump();
    expect(find.byType(IroActionButton), findsNothing, reason: 'it is already running');
    expect(find.text('In progress'), findsOneWidget);
    expect(find.textContaining('4'), findsOneWidget);
  });

  testWidgets('tapping Start calls back once', (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(
      RegionTaskCard(task: task(), sub: '', starting: false, onStart: () => taps++),
    ));
    await tester.pump();
    await tester.tap(find.byType(IroActionButton));
    await tester.pump();
    expect(taps, 1);
  });
}
