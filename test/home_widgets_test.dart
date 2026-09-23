import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rpd_app/core/translations/app_translations.dart';
import 'package:rpd_app/features/home/home_widgets.dart';

/// GetMaterialApp only adopts its `locale` while Get.locale is still unset, so
/// the locale is set here the way the running app does it.
Widget _host(Widget child, {Locale locale = const Locale('en', 'US')}) {
  Get.locale = locale;
  return GetMaterialApp(
    translations: AppTranslations(),
    locale: locale,
    fallbackLocale: const Locale('en', 'US'),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

void main() {
  testWidgets('status pill renders', (tester) async {
    await tester.pumpWidget(_host(
      const HomeStatusPill(label: 'Today', fg: Colors.orange, bg: Colors.white, icon: Icons.schedule_rounded),
    ));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Today'), findsOneWidget);
  });

  testWidgets('section header pairs English only off the English locale', (tester) async {
    await tester.pumpWidget(_host(
      HomeSectionHeader(title: 'ताज़ा ब्लॉग', titleKey: 'recent_blogs', onSeeMore: () {}),
      locale: const Locale('hi', 'IN'),
    ));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Recent blogs'), findsOneWidget);

    await tester.pumpWidget(_host(
      HomeSectionHeader(title: 'Recent blogs', titleKey: 'recent_blogs', onSeeMore: () {}),
    ));
    await tester.pump();
    expect(tester.takeException(), isNull);
    // One line on English, not the same words twice.
    expect(find.text('Recent blogs'), findsOneWidget);
  });
}
