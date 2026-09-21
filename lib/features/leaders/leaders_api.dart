import 'package:get/get.dart';
import '../../data/remote/api_client.dart';

/// Office bearers leading the signed-in member's area, national level first, booth last.
Future<List<Map<String, dynamic>>> fetchMyLeaders() async {
  final res = await Get.find<ApiClient>().get('/members/leaders');
  final data = Map<String, dynamic>.from(res['data'] as Map);
  return (data['levels'] as List? ?? const [])
      .whereType<Map>()
      .map((row) => Map<String, dynamic>.from(row))
      .toList();
}
