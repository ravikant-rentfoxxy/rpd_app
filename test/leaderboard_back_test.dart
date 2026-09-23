import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rpd_app/core/translations/app_translations.dart';
import 'package:rpd_app/core/widgets/ui.dart';

/// The leaderboard is only ever pushed, so its bar has to offer a way back.
/// This pins the behaviour of the bar it uses, either way round.

Widget _host(Widget home) {
  Get.locale = const Locale('en', 'US');
  return GetMaterialApp(
    translations: AppTranslations(),
    locale: const Locale('en', 'US'),
    fallbackLocale: const Locale('en', 'US'),
    home: home,
  );
}

Widget _pushable(Widget pushed) => Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => pushed)),
            child: const Text('go'),
          ),
        ),
      ),
    );

void main() {
  testWidgets('a pushed screen gets a back button', (tester) async {
    await tester.pumpWidget(_host(_pushable(
      const Scaffold(appBar: OrganicAppBar(title: 'Leaderboard')),
    )));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(find.text('Leaderboard'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
  });

  testWidgets('and tapping it goes back', (tester) async {
    await tester.pumpWidget(_host(_pushable(
      const Scaffold(appBar: OrganicAppBar(title: 'Leaderboard')),
    )));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Leaderboard'), findsNothing);
    expect(find.text('go'), findsOneWidget);
  });

  testWidgets('a root screen with nothing behind it gets none', (tester) async {
    await tester.pumpWidget(_host(
      const Scaffold(appBar: OrganicAppBar(title: 'Home')),
    ));
    await tester.pump();
    expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
  });
}
