import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import '../../data/local/hive_service.dart';

class ApiConfig {
  static const prefix = '/api/v1';
  static const envAsset = 'assets/env';

  static String? fromEnv() {
    final value = dotenv.maybeGet('API_BASE_URL')?.trim();
    if (value == null || value.isEmpty) return null;
    return _trimSlash(value);
  }

  static String? resolved() {
    final raw = _raw();
    if (raw == null) return null;
    return adjustForPlatform(raw);
  }

  static String? _raw() {
    final env = fromEnv();
    if (env != null) return env;
    if (Get.isRegistered<HiveService>()) {
      final stored = Get.find<HiveService>().apiBaseUrl;
      if (stored != null && stored.isNotEmpty) return _trimSlash(stored);
    }
    return null;
  }

  static String requireBaseUrl() {
    final url = resolved();
    if (url == null || url.isEmpty) {
      throw StateError('API_BASE_URL is missing. Set it in assets/env.');
    }
    return url;
  }

  /// Android emulator cannot reach the host via 127.0.0.1 — that is the emulator itself.
  static String adjustForPlatform(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return url;
    final loopback = uri.host == 'localhost' || uri.host == '127.0.0.1';
    if (!kIsWeb && Platform.isAndroid && loopback) {
      return _trimSlash(uri.replace(host: '10.0.2.2').toString());
    }
    return _trimSlash(url);
  }

  static String _trimSlash(String value) {
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }
}
