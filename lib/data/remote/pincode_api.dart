import 'package:get/get.dart';
import 'api_client.dart';

Future<Map<String, dynamic>> lookupPincode(String pincode) async {
  final pin = pincode.trim();
  final res = await Get.find<ApiClient>().get('/geo/pincode/$pin');
  return Map<String, dynamic>.from(res['data'] as Map? ?? {});
}

String? pincodeStateId(Map<String, dynamic> hit) {
  final nested = hit['state'] is Map ? Map<String, dynamic>.from(hit['state'] as Map) : null;
  final id = '${nested?['id'] ?? hit['stateId'] ?? ''}'.trim();
  return id.isEmpty ? null : id;
}

String pincodeStateName(Map<String, dynamic> hit) {
  final nested = hit['state'] is Map ? Map<String, dynamic>.from(hit['state'] as Map) : null;
  return '${nested?['name'] ?? hit['matchedStateName'] ?? hit['stateName'] ?? ''}'.trim();
}

String? pincodeDistrictId(Map<String, dynamic> hit) {
  final nested = hit['district'] is Map ? Map<String, dynamic>.from(hit['district'] as Map) : null;
  final id = '${nested?['id'] ?? hit['districtId'] ?? ''}'.trim();
  return id.isEmpty ? null : id;
}

String pincodeDistrictName(Map<String, dynamic> hit) {
  final nested = hit['district'] is Map ? Map<String, dynamic>.from(hit['district'] as Map) : null;
  return '${nested?['name'] ?? hit['matchedDistrictName'] ?? hit['districtName'] ?? ''}'.trim();
}
