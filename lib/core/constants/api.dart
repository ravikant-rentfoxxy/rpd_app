import 'dart:io';

import 'package:flutter/foundation.dart';
import 'endpoints.dart';

class ApiConfig {
  static const prefix = '/api/v1';

  static AppEnv? _chosen;

  /// Pick the backend by hand, from `main()`. Whatever is set here wins over
  /// the build-time default, so switching environment is a one-line edit rather
  /// than a different build command.
  ///
  /// Called with null, the choice goes back to `--dart-define=APP_ENV`, and
  /// failing that to prod for a release build and local for anything else.
  static void use(AppEnv? env) => _chosen = env;

  /// Where this build talks to: what [use] was given, else [appEnv].
  static AppEnv get env => _chosen ?? appEnv;

  /// True when a release build has been pointed somewhere other than prod —
  /// worth saying out loud, since it means a shipped app calling a laptop or a
  /// staging box.
  static bool get isMisconfiguredRelease => kReleaseMode && env != AppEnv.prod;

  static String? resolved() {
    final raw = _raw();
    if (raw == null) return null;
    return adjustForPlatform(raw);
  }

  /// The environment decides, and nothing else. Nothing is stored on the device,
  /// so a build always calls where it was built to call.
  static String? _raw() {
    final origin = env.origin.trim();
    return origin.isEmpty ? null : _trimSlash(origin);
  }

  static String requireBaseUrl() {
    final url = resolved();
    if (url == null || url.isEmpty) {
      throw StateError('No API base URL for ${env.name}. Build with --dart-define=APP_ENV=local|dev|prod.');
    }
    return url;
  }

  /// 127.0.0.1 is this device, which a phone cannot reach. [AppEnv.local] holds
  /// the Wi-Fi address already, so this only catches a LAN_HOST built as
  /// loopback by mistake. Keeps path and query so media URLs are not collapsed
  /// to the origin.
  static String adjustForPlatform(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return url;
    final loopback = uri.host == 'localhost' || uri.host == '127.0.0.1';
    final onPhone = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    if (onPhone && loopback) {
      // The emulator can reach the host on 10.0.2.2; a real handset cannot, so
      // fall back to the Wi-Fi address the local environment is built around.
      final lan = Uri.tryParse(AppEnv.local.origin);
      if (Platform.isAndroid && (lan == null || lan.host.isEmpty)) {
        return _keepUrl(uri.replace(host: '10.0.2.2'));
      }
      if (lan != null && lan.host.isNotEmpty) return _withOrigin(uri, AppEnv.local.origin);
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
