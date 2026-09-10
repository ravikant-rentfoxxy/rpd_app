import 'package:get/get.dart';
import '../../data/remote/api_client.dart';

Future<void> dismissEngagement(String id) async {
  await Get.find<ApiClient>().post('/engagement/$id/dismiss');
}

Future<Map<String, dynamic>> fetchEngagement(String id) async {
  final res = await Get.find<ApiClient>().get('/engagement/$id');
  return Map<String, dynamic>.from(res['data'] as Map);
}

Future<Map<String, dynamic>> submitEngagement(String id, List<Map<String, String>> answers) async {
  final res = await Get.find<ApiClient>().post('/engagement/$id/submit', data: {'answers': answers});
  return Map<String, dynamic>.from(res['data'] as Map);
}
