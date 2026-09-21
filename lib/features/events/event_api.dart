import 'dart:io';

import 'package:dio/dio.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:http_parser/http_parser.dart';
import '../../data/remote/api_client.dart';

Future<Map<String, dynamic>> verifyPlace(String address) async {
  final res = await Get.find<ApiClient>().get('/geo/geocode', query: {'q': address.trim()});
  return Map<String, dynamic>.from(res['data'] as Map);
}

Future<Map<String, dynamic>> createOrgEvent({
  required String type,
  required String title,
  required DateTime startsAt,
  required int durationMinutes,
  required String venue,
  String? description,
  String? imagePath,
  double? latitude,
  double? longitude,
}) async {
  final hasImage = imagePath != null && imagePath.isNotEmpty && File(imagePath).existsSync();
  final name = hasImage ? imagePath.split(RegExp(r'[/\\]')).last : '';
  final form = FormData.fromMap({
    'type': type,
    'title': title,
    'startsAt': startsAt.toUtc().toIso8601String(),
    'durationMinutes': '$durationMinutes',
    'venue': venue,
    if (description != null && description.isNotEmpty) 'description': description,
    if (latitude != null && longitude != null) ...{'latitude': '$latitude', 'longitude': '$longitude'},
    if (hasImage)
      'file': await MultipartFile.fromFile(
        imagePath,
        filename: name.isEmpty ? 'event.jpg' : name,
        contentType: MediaType('image', 'jpeg'),
      ),
  });
  final res = await Get.find<ApiClient>().postMultipart('/events', form);
  return Map<String, dynamic>.from((res['data'] as Map)['event'] as Map);
}

Future<Map<String, dynamic>> joinOrgEvent(String id) async {
  final res = await Get.find<ApiClient>().post('/events/$id/join');
  return Map<String, dynamic>.from((res['data'] as Map)['event'] as Map);
}

Future<Map<String, dynamic>> fetchOrgEvent(String id) async {
  final res = await Get.find<ApiClient>().get('/events/$id');
  return Map<String, dynamic>.from((res['data'] as Map)['event'] as Map);
}

Future<List<Map<String, dynamic>>> fetchOrgEvents() async {
  final res = await Get.find<ApiClient>().get('/events');
  final items = ((res['data'] as Map?)?['events'] as List?) ?? [];
  return items.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
}

Future<List<Map<String, dynamic>>> fetchJoinedEvents() async {
  final res = await Get.find<ApiClient>().get('/events/joined');
  final items = ((res['data'] as Map?)?['events'] as List?) ?? [];
  return items.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
}

/// Server checks the member is within 500 m of the venue. Returns `{event, alreadyIn, metres}`.
Future<Map<String, dynamic>> checkInOrgEvent(String id, {required double latitude, required double longitude}) async {
  final res = await Get.find<ApiClient>().post('/events/$id/check-in', data: {
    'latitude': latitude,
    'longitude': longitude,
  });
  return Map<String, dynamic>.from(res['data'] as Map);
}

/// Events the current member created: upcoming, live, and those that ended in the last 30 days.
Future<List<Map<String, dynamic>>> fetchHostedEvents() async {
  final res = await Get.find<ApiClient>().get('/events/hosted');
  final items = ((res['data'] as Map?)?['events'] as List?) ?? [];
  return items.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
}
