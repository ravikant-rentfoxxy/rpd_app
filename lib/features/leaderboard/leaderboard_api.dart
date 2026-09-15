import 'package:get/get.dart';
import '../../data/remote/api_client.dart';

Future<Map<String, dynamic>> fetchLeaderboard() async {
  final res = await Get.find<ApiClient>().get('/leaderboard');
  return Map<String, dynamic>.from(res['data'] as Map? ?? {});
}
