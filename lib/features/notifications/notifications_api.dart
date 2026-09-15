import 'package:get/get.dart';
import '../../data/remote/api_client.dart';

Future<Map<String, dynamic>> fetchNotifications() async {
  final res = await Get.find<ApiClient>().get('/notifications');
  return Map<String, dynamic>.from(res['data'] as Map? ?? {});
}

Future<int> fetchUnreadNotificationCount() async {
  final res = await Get.find<ApiClient>().get('/notifications/unread-count');
  final data = Map<String, dynamic>.from(res['data'] as Map? ?? {});
  return (data['unreadCount'] as num?)?.toInt() ?? 0;
}

Future<int> markNotificationSeen(String id) async {
  final res = await Get.find<ApiClient>().patch('/notifications/$id/seen');
  final data = Map<String, dynamic>.from(res['data'] as Map? ?? {});
  return (data['unreadCount'] as num?)?.toInt() ?? 0;
}

Future<void> markAllNotificationsSeen() async {
  await Get.find<ApiClient>().post('/notifications/seen-all');
}
