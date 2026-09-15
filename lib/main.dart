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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    AppLog.error(
      details.exceptionAsString(),
      error: details.exception,
      stack: details.stack,
      tag: 'FLUTTER',
    );
    FlutterError.presentError(details);
  };
  
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLog.error('Uncaught platform error', error: error, stack: stack, tag: 'PLATFORM');
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
