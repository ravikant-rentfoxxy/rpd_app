import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rpd_app/core/theme/app_colors.dart';
import 'package:rpd_app/core/translations/app_translations.dart';
import 'package:rpd_app/core/widgets/iro_ui.dart';
import 'package:rpd_app/features/leaderboard/leaderboard_view.dart';
import 'package:rpd_app/features/members/members_view.dart';

/// My recruits used to print the status twice — once as "· verified" under the
/// name, once as a pill beside it — because the booth code it meant to show was
/// empty. The board's rows were plain boxes with no way to find yourself.

Widget host(Widget child, {double width = 360, Locale locale = const Locale('en', 'US')}) {
  Get.locale = locale;
  Get.addTranslations(AppTranslations().keys);
  return GetMaterialApp(
    translations: AppTranslations(),
    locale: locale,
    fallbackLocale: const Locale('en', 'US'),
    home: Scaffold(
      backgroundColor: Iro.mint,
      body: Center(child: SizedBox(width: width, child: SingleChildScrollView(child: child))),
    ),
  );
}

void main() {
  group('a recruit', () {
    testWidgets('shows its status once, not twice', (tester) async {
      await tester.pumpWidget(host(const RecruitCard(
        member: {'fullName': 'jbshefe', 'status': 'VERIFIED', 'membershipNumber': 'RPD-BR-58'},
      )));
      await tester.pump();
      // The chip says it once; the line under the name must not repeat it.
      // Lower case on purpose — the same word the counts above use.
      expect(find.text('verified'), findsOneWidget);
      expect(find.textContaining('· verified'), findsNothing);
      expect(find.text('RPD-BR-58'), findsOneWidget);
    });

    testWidgets('falls back to the place when there is no number yet', (tester) async {
      await tester.pumpWidget(host(const RecruitCard(
        member: {'fullName': 'Asha Devi', 'status': 'PENDING', 'districtName': 'Banka'},
      )));
      await tester.pump();
      expect(find.text('Banka'), findsOneWidget);
      expect(find.text('pending'), findsOneWidget);
    });

    testWidgets('a nameless row still renders', (tester) async {
      await tester.pumpWidget(host(const RecruitCard(member: {'status': 'REJECTED'})));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('rejected'), findsOneWidget);
    });

    testWidgets('a long name does not overflow a narrow phone', (tester) async {
      await tester.pumpWidget(host(
        const RecruitCard(member: {
          'fullName': 'Ramachandran Venkataraman Subramanian',
          'status': 'VERIFIED',
          'membershipNumber': 'RPD-UP-1234567',
        }),
        width: 300,
      ));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('a board row', () {
    testWidgets('the top three carry a medal instead of a number', (tester) async {
      for (final rank in [1, 2, 3]) {
        await tester.pumpWidget(host(RankRow(row: {'rank': rank, 'fullName': 'A', 'points': 5})));
        await tester.pump();
        expect(find.byIcon(Icons.workspace_premium_rounded), findsOneWidget, reason: 'rank $rank');
        expect(find.text('$rank'), findsNothing, reason: 'rank $rank should show a medal, not a numeral');
      }
    });

    testWidgets('fourth place onwards shows the number', (tester) async {
      await tester.pumpWidget(host(RankRow(row: {'rank': 4, 'fullName': 'A', 'points': 0})));
      await tester.pump();
      expect(find.byIcon(Icons.workspace_premium_rounded), findsNothing);
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('your own row is marked and tinted so you can find it', (tester) async {
      await tester.pumpWidget(host(RankRow(row: {'rank': 9, 'fullName': 'ravi', 'isMe': true})));
      await tester.pump();
      expect(find.textContaining('(you)'), findsOneWidget);
      final card = tester.widget<IroCard>(find.byType(IroCard));
      expect(card.color, Iro.wash, reason: 'your own row should stand out from the rest');
      expect(card.border, Iro.leaf);
    });

    testWidgets("someone else's row is plain", (tester) async {
      await tester.pumpWidget(host(RankRow(row: {'rank': 9, 'fullName': 'Pankaj Yadav'})));
      await tester.pump();
      expect(find.textContaining('(you)'), findsNothing);
      final card = tester.widget<IroCard>(find.byType(IroCard));
      expect(card.color, Iro.surface);
    });

    testWidgets('tasks and points both show', (tester) async {
      await tester.pumpWidget(host(RankRow(row: {'rank': 2, 'fullName': 'A', 'tasksDone': 7, 'points': 40})));
      await tester.pump();
      expect(find.text('7'), findsOneWidget);
      expect(find.text('40'), findsOneWidget);
    });
  });
}
