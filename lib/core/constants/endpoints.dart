import 'package:flutter/foundation.dart';

/// Every hardcoded address the app uses, in one place. Nothing is read from a
/// file that ships beside the build, so what a build talks to is fixed when it
/// is compiled and cannot drift between machines.

/// Where the API lives. One of three, chosen at build time.
enum AppEnv {
  /// The backend running on this Mac, reached over Wi-Fi so a real phone on the
  /// same network can see it. Override after switching network with
  /// `--dart-define=LAN_HOST=http://192.168.x.x:4000`.
  local(_lanHost),

  /// The shared staging deploy.
  dev('https://rpd-backend.vercel.app'),

  /// Live.
  prod('https://iroorg.tech/api');

  const AppEnv(this.baseUrl);

  /// As written. [origin] is what actually gets called.
  final String baseUrl;

  /// The base with any trailing `/api` taken off, because the client appends
  /// `/api/v1` — left in, prod would resolve to `https://iroorg.tech/api/api/v1`.
  String get origin {
    final trimmed = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    return trimmed.endsWith('/api') ? trimmed.substring(0, trimmed.length - 4) : trimmed;
  }
}

const _lanHost = String.fromEnvironment('LAN_HOST', defaultValue: 'http://192.168.1.2:4000');
const _selectedEnv = String.fromEnvironment('APP_ENV');

/// `--dart-define=APP_ENV=local|dev|prod` decides. Without one, a release build
/// goes to prod and everything else to the machine on Wi-Fi, so a shipped build
/// can never quietly point at a laptop.
AppEnv get appEnv {
  for (final value in AppEnv.values) {
    if (value.name == _selectedEnv.trim().toLowerCase()) return value;
  }
  return kReleaseMode ? AppEnv.prod : AppEnv.local;
}

/// Bunny CDN. The same for every environment — media is served from one place
/// whichever backend wrote the row.
class Media {
  /// Images and audio uploaded through the portal or the app.
  static const storageCdn = 'https://rentfoxxy-media.b-cdn.net';

  /// Video pull zone: HLS playlists and poster frames.
  static const streamCdn = 'https://vz-8625e1d3-3b3.b-cdn.net';

  /// Bunny's own iframe player, which is what plays an uploaded video.
  static const streamEmbed = 'https://iframe.mediadelivery.net';
  static const streamLibraryId = '750289';
}

/// OpenStreetMap raster tiles for the district map.
class MapTiles {
  static const url = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// OSM's tile usage policy asks every client to identify itself.
  static const userAgent = 'com.rpd.app';
  static const attribution = '© OpenStreetMap';
}

/// Links the app hands to another app or the browser. Templates rather than
/// settings, but they are addresses, so they live here with the rest.
class ExternalLinks {
  /// Drops a pin in whatever maps app the phone has.
  static String mapsSearch(String query) =>
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}';

  /// Share a post summary.
  static String shareOnX(String text) => 'https://x.com/intent/post?text=${Uri.encodeComponent(text)}';
}
