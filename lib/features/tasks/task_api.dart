import 'package:get/get.dart';
import '../../data/remote/api_client.dart';

Future<Map<String, dynamic>> createOrgTask({
  required String title,
  String? description,
}) async {
  final res = await Get.find<ApiClient>().post('/tasks', data: {
    'title': title,
    if (description != null && description.isNotEmpty) 'description': description,
  });
  return Map<String, dynamic>.from((res['data'] as Map)['task'] as Map);
}

Future<Map<String, dynamic>> fetchTasks() async {
  final res = await Get.find<ApiClient>().get('/tasks');
  return Map<String, dynamic>.from(res['data'] as Map? ?? {});
}
