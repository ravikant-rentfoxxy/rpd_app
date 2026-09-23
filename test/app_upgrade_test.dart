import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rpd_app/core/translations/app_translations.dart';
import 'package:rpd_app/core/update/app_upgrade.dart';
import 'package:upgrader/upgrader.dart';

/// The update prompt has to speak the member's language, including Bhojpuri,
/// which the package has never heard of — so the copy comes from the app's own
/// translations rather than the package's.

void main() {
  setUp(() {
    Get.clearTranslations();
    Get.addTranslations(AppTranslations().keys);
  });

  test('every message key has English copy', () {
    Get.locale = const Locale('en', 'US');
    for (final key in UpgraderMessage.values) {
      final text = appUpgradeMessages.message(key);
      expect(text, isNotNull, reason: '$key has no copy');
      expect(text, isNotEmpty, reason: '$key is blank');
    }
  });

  test('the body keeps the placeholders the package substitutes', () {
    Get.locale = const Locale('en', 'US');
    final body = appUpgradeMessages.message(UpgraderMessage.body)!;
    // GetX must not eat these — upgrader fills them in after we hand them over.
    expect(body, contains('{{appName}}'));
    expect(body, contains('{{currentAppStoreVersion}}'));
    expect(body, contains('{{currentInstalledVersion}}'));
  });

  test('Hindi and Bhojpuri have their own copy, not the English', () {
    Get.locale = const Locale('en', 'US');
    final english = UpgraderMessage.values
        .map((k) => appUpgradeMessages.message(k))
        .toList();

    for (final locale in [const Locale('hi', 'IN'), const Locale('bho', 'IN')]) {
      Get.locale = locale;
      final translated = UpgraderMessage.values
          .map((k) => appUpgradeMessages.message(k))
          .toList();
      expect(translated, isNot(english), reason: '$locale falls back to English');
      for (final text in translated) {
        expect(text, isNotNull);
        expect(text, isNotEmpty);
      }
    }
  });

  test('the three locales keep the placeholders too', () {
    for (final locale in [const Locale('hi', 'IN'), const Locale('bho', 'IN')]) {
      Get.locale = locale;
      final body = appUpgradeMessages.message(UpgraderMessage.body)!;
      expect(body, contains('{{currentAppStoreVersion}}'), reason: '$locale body lost its version');
    }
  });

  testWidgets('the prompt is dismissible and does not offer Ignore', (tester) async {
    // Mounting UpgradeAlert starts the package's own store lookup, which is its
    // business, not this app's. Calling build without mounting it gets at what
    // is worth pinning: how it is configured.
    late UpgradeAlert alert;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          alert = const AppUpgradeGate(child: SizedBox()).build(context) as UpgradeAlert;
          return const SizedBox();
        },
      ),
    );
    expect(alert.barrierDismissible, isTrue, reason: 'an optional update should not feel like a wall');
    expect(alert.showIgnore, isFalse, reason: 'Ignore hides the prompt for good; Later is enough');
    expect(alert.showLater, isTrue);
  });
}
