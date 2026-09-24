import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app.dart';
import 'core/constants/api.dart';
import 'core/constants/endpoints.dart';
import 'core/utils/app_log.dart';
import 'data/local/hive_service.dart';
import 'data/remote/api_client.dart';
import 'core/push/push_service.dart';
import 'features/session/session_controller.dart';
import 'firebase_options.dart';

bool _crashlyticsReady = false;

/// Which backend this build talks to. Change this one line to switch:
///
///   AppEnv.local -> this Mac over Wi-Fi (see LAN_HOST in endpoints.dart)
///   AppEnv.dev   -> https://rpd-backend.vercel.app
///   AppEnv.prod  -> https://iroorg.tech/api
///
/// Comment out the `ApiConfig.use(backend)` call below to let the build decide
/// instead: `--dart-define=APP_ENV=...`, or prod for a release build and local
/// for anything else.
const backend = AppEnv.prod;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ApiConfig.use(backend);

  await _initCrashlytics();

  FlutterError.onError = (details) {
    AppLog.error(
      details.exceptionAsString(),
      error: details.exception,
      stack: details.stack,
      tag: 'FLUTTER',
    );
    if (_crashlyticsReady) {
      FirebaseCrashlytics.instance.recordFlutterError(details);
    }
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    AppLog.error('Uncaught platform error', error: error, stack: stack, tag: 'PLATFORM');
    if (_crashlyticsReady) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    }
    return true;
  };

  await Get.putAsync(() => HiveService().init());
  AppLog.info('API ${ApiConfig.env.name} -> ${ApiConfig.resolved()}', tag: 'BOOT');
  if (ApiConfig.isMisconfiguredRelease) {
    // A release build calling anything but prod would ship pointing at a
    // laptop or the staging box, which is worth more than a quiet log line.
    AppLog.error(
      'RELEASE BUILD IS ON ${ApiConfig.env.name.toUpperCase()} — set `backend` in main.dart to AppEnv.prod',
      tag: 'BOOT',
    );
  }

  await Get.putAsync(() => ApiClient().init());
  Get.put(SessionController());
  await Get.putAsync(() => PushService().init());
  runApp(const RpdApp());
}

Future<void> _initCrashlytics() async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    }
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);
    _crashlyticsReady = true;
    AppLog.info('Crashlytics ready (collection ${kDebugMode ? 'off in debug' : 'on'})', tag: 'CRASH');
  } catch (e, stack) {
    _crashlyticsReady = false;
    AppLog.error('Crashlytics init failed', error: e, stack: stack, tag: 'CRASH');
  }
}
