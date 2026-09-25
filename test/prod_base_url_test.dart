import 'package:flutter_test/flutter_test.dart';
import 'package:rpd_app/core/constants/api.dart';
import 'package:rpd_app/core/constants/endpoints.dart';

/// The one address every release build talks to. A trailing slash or a stray
/// `/api` here comes back as `//api/v1` or `/api/api/v1` against the live
/// server, which is a broken build nobody sees until it ships.
void main() {
  test('production resolves to one clean API root', () {
    expect(AppEnv.prod.baseUrl, 'https://rpd-org.in/');
    expect(AppEnv.prod.origin, 'https://rpd-org.in');

    ApiConfig.use(AppEnv.prod);
    expect(ApiConfig.resolved(), 'https://rpd-org.in');
    expect('${ApiConfig.resolved()}${ApiConfig.prefix}', 'https://rpd-org.in/api/v1');
  });
}
