import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rpd_app/core/translations/app_translations.dart';

void main() {
  test('englishLabel is silent on English and pairs on Hindi/Bhojpuri', () {
    Get.locale = const Locale('en', 'US');
    expect(englishLabel('recent_blogs'), isNull);

    Get.locale = const Locale('hi', 'IN');
    expect(englishLabel('recent_blogs'), 'Recent blogs');

    Get.locale = const Locale('bho', 'IN');
    expect(englishLabel('recent_videos'), 'Recent videos');

    // A key with no English entry must not render an empty second line.
    expect(englishLabel('no_such_key_at_all'), isNull);
  });
}
