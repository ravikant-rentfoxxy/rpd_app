import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'app.dart';
import 'core/constants/api.dart';
import 'core/utils/app_log.dart';
import 'data/local/hive_service.dart';
import 'data/remote/api_client.dart';
import 'core/push/push_service.dart';
import 'features/session/session_controller.dart';
import 'firebase_options.dart';

bool _crashlyticsReady = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  try {
    await dotenv.load(fileName: ApiConfig.envAsset);
    AppLog.info('Loaded ${ApiConfig.envAsset} API_BASE_URL=${ApiConfig.fromEnv()}', tag: 'BOOT');
  } catch (e, stack) {
    AppLog.error('Failed to load ${ApiConfig.envAsset}', error: e, stack: stack, tag: 'BOOT');
  }

  final hive = await Get.putAsync(() => HiveService().init());
  final envUrl = ApiConfig.fromEnv();
  if (envUrl != null) {
    await hive.setApiBaseUrl(envUrl);
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
