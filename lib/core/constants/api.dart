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

  /// 127.0.0.1 is this device. A phone on Wi‑Fi must use the Mac LAN IP.
  /// The Android emulator can use 10.0.2.2, but a real phone cannot.
  /// Keeps path/query so media URLs are not collapsed to the origin.
  static String adjustForPlatform(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return url;
    final loopback = uri.host == 'localhost' || uri.host == '127.0.0.1';
    final emulatorOnly = uri.host == '10.0.2.2';
    String? lan;
    try {
      lan = dotenv.maybeGet('API_LAN_URL')?.trim();
    } catch (_) {
      lan = null;
    }
    final onPhone = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    if (onPhone && lan != null && lan.isNotEmpty && (loopback || emulatorOnly)) {
      return _withOrigin(uri, lan);
    }
    if (!kIsWeb && Platform.isAndroid && loopback) {
      return _keepUrl(uri.replace(host: '10.0.2.2'));
    }
    return _keepUrl(uri);
  }

  static String _withOrigin(Uri from, String origin) {
    final to = Uri.tryParse(origin);
    if (to == null || to.host.isEmpty) return _keepUrl(from);
    return _keepUrl(
      from.replace(
        scheme: to.scheme,
        host: to.host,
        port: to.hasPort ? to.port : (to.scheme == 'https' ? 443 : 80),
      ),
    );
  }

  static String _keepUrl(Uri uri) {
    final text = uri.toString();
    if (uri.path.isEmpty || uri.path == '/') return _trimSlash(text);
    return text;
  }

  static String _trimSlash(String value) {
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }
}
