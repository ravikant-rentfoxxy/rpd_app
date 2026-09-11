import 'package:get/get.dart';
import '../../data/remote/api_client.dart';

Future<List<Map<String, dynamic>>> fetchActivityEvents() async {
  final res = await Get.find<ApiClient>().get('/activity-events');
  final items = ((res['data'] as Map?)?['events'] as List?) ?? [];
  return items.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
}

Future<Map<String, dynamic>> fetchActivityEvent(String id) async {
  final res = await Get.find<ApiClient>().get('/activity-events/$id');
  return Map<String, dynamic>.from((res['data'] as Map)['event'] as Map);
}

Future<Map<String, dynamic>> respondActivityEvent(String id, String optionId) async {
  final res = await Get.find<ApiClient>().post('/activity-events/$id/respond', data: {'optionId': optionId});
  return Map<String, dynamic>.from((res['data'] as Map)['event'] as Map);
}
