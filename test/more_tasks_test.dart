import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rpd_app/core/translations/app_translations.dart';

/// The More screen gained a way into My tasks. The screen itself needs a live
/// session to build, so what is pinned here is the copy it leans on — a missing
/// key would render the key name to a member.

void main() {
  final keys = AppTranslations().keys;

  test('every locale has the My tasks copy', () {
    for (final locale in ['en_US', 'hi_IN', 'bho_IN']) {
      final map = keys[locale]!;
      expect(map['my_tasks'], isNotNull, reason: '$locale is missing my_tasks');
      expect(map['my_tasks']!.trim(), isNotEmpty, reason: '$locale my_tasks is blank');
      expect(map['my_tasks_sub'], isNotNull, reason: '$locale is missing my_tasks_sub');
      expect(map['my_tasks_sub']!.trim(), isNotEmpty, reason: '$locale my_tasks_sub is blank');
    }
  });

  test('the three locales do not share one string', () {
    final titles = ['en_US', 'hi_IN', 'bho_IN'].map((l) => keys[l]!['my_tasks']).toSet();
    expect(titles.length, 3, reason: 'a locale is falling back to another');
  });

  test('the label resolves rather than coming back as the key', () {
    // GetX resolves `.tr` against whatever is registered at the moment it is
    // read, so the translations go in first — building a GetMaterialApp around
    // it would be too late.
    Get.addTranslations(keys);
    for (final locale in [const Locale('en', 'US'), const Locale('hi', 'IN'), const Locale('bho', 'IN')]) {
      Get.locale = locale;
      expect('my_tasks'.tr, isNot('my_tasks'), reason: '$locale comes back as the raw key');
      expect('my_tasks_sub'.tr, isNot('my_tasks_sub'), reason: '$locale sub comes back as the raw key');
    }
  });
}
