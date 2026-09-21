import 'package:get/get.dart';
import '../../data/remote/api_client.dart';

/// Activity health for the district the signed-in member belongs to.
Future<Map<String, dynamic>> fetchDistrictHealth({int? days}) async {
  final res = await Get.find<ApiClient>().get(
    '/districts/health',
    query: days == null ? null : {'days': days},
  );
  return Map<String, dynamic>.from(res['data'] as Map);
}
