import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/routes/app_pages.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'core/translations/app_translations.dart';
import 'data/local/hive_service.dart';

class RpdApp extends StatelessWidget {
  const RpdApp({super.key});

  @override
  Widget build(BuildContext context) {
    final hive = Get.find<HiveService>();
    final locale = switch (hive.locale) {
      'en' => const Locale('en', 'US'),
      'bho' => const Locale('bho', 'IN'),
      'hi' => const Locale('hi', 'IN'),
      _ => const Locale('en', 'US'),
    };
    return GetMaterialApp(
      title: 'RPD',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      translations: AppTranslations(),
      locale: hive.locale == null ? const Locale('en', 'US') : locale,
      fallbackLocale: const Locale('en', 'US'),
      initialRoute: Routes.boot,
      getPages: AppPages.pages,
    );
  }
}
