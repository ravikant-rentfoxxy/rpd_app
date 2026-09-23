import 'dart:io';

import 'package:dio/dio.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:http_parser/http_parser.dart';
import '../../core/utils/local_image.dart';
import '../../core/utils/network.dart';
import '../../data/local/hive_service.dart';
import '../../data/remote/api_client.dart';

Future<Map<String, dynamic>> uploadRegionPost({
  required String clientUuid,
  required String mediaType,
  String? filePath,
  required String description,
  String? issueId,
  String? issueCode,
  String? subIssueId,
  String? subIssueCode,
  double? latitude,
  double? longitude,
  Object? districtId,
  Object? assemblyId,
  Object? boothId,
  String? regionLabel,
  String? authorName,
  Object? authorMobile,
  String? thumbnailPath,
  String? documentPath,
}) async {
  final hasFile = filePath != null && filePath.isNotEmpty && File(filePath).existsSync();
  final name = hasFile ? filePath.split(RegExp(r'[/\\]')).last : '';
  final thumbName = thumbnailPath?.split(RegExp(r'[/\\]')).last;
  final kind = mediaType.toUpperCase();
  final form = FormData.fromMap({
    'clientUuid': clientUuid,
    'mediaType': kind,
    'description': description,
    if (issueId != null && issueId.isNotEmpty) 'issueId': issueId,
    if (issueCode != null && issueCode.isNotEmpty) 'issueCode': issueCode,
    if (subIssueId != null && subIssueId.isNotEmpty) 'subIssueId': subIssueId,
    if (subIssueCode != null && subIssueCode.isNotEmpty) 'subIssueCode': subIssueCode,
    if (hasFile)
      'file': await MultipartFile.fromFile(
        filePath!,
        filename: name.isEmpty ? 'post.bin' : name,
        contentType: _contentTypeFor(kind, filePath!),
      ),
    if (thumbnailPath != null && thumbnailPath.isNotEmpty && File(thumbnailPath).existsSync())
      'thumbnail': await MultipartFile.fromFile(
        thumbnailPath,
        filename: (thumbName == null || thumbName.isEmpty) ? 'thumb.jpg' : thumbName,
        contentType: MediaType('image', 'jpeg'),
      ),
    if (documentPath != null && documentPath.isNotEmpty && File(documentPath).existsSync())
      'document': await MultipartFile.fromFile(
        documentPath,
        filename: documentPath.split(RegExp(r'[/\\]')).last,
        contentType: _contentTypeFor('DOCUMENT', documentPath),
      ),
    ?'latitude': latitude,
    ?'longitude': longitude,
    if (districtId != null && '$districtId'.isNotEmpty) 'districtId': districtId,
    if (assemblyId != null && '$assemblyId'.isNotEmpty) 'assemblyId': assemblyId,
    if (boothId != null && '$boothId'.isNotEmpty) 'boothId': boothId,
    if (regionLabel != null && regionLabel.isNotEmpty) 'regionLabel': regionLabel,
  });
  final res = await Get.find<ApiClient>().postMultipart('/posts', form);
  final post = Map<String, dynamic>.from((res['data'] as Map)['post'] as Map);
  post['pending'] = false;
  post['id'] = post['clientUuid'] ?? post['id'] ?? clientUuid;
  post['authorId'] ??= Get.find<HiveService>().profile?['id'];
  return post;
}

Future<void> persistUploadedPost(
  Map<String, dynamic> post, {
  String? localPath,
  String? thumbnailPath,
  String? documentPath,
}) async {
  final hive = Get.find<HiveService>();
  final id = '${post['id'] ?? ''}';
  final clientUuid = '${post['clientUuid'] ?? ''}';
  if (id.isNotEmpty) await hive.deletePost(id);
  if (clientUuid.isNotEmpty && clientUuid != id) await hive.deletePost(clientUuid);
  await _deleteLocalFile(localPath);
  await _deleteLocalFile(thumbnailPath);
  await _deleteLocalFile(documentPath);
}

Future<void> _deleteLocalFile(String? path) async {
  if (path == null || path.isEmpty || isHttpUrl(path)) return;
  final file = File(path);
  if (!file.existsSync()) return;
  try {
    await file.delete();
  } catch (_) {}
}

MediaType _contentTypeFor(String mediaType, String path) {
  final ext = path.split('.').last.toLowerCase();
  return switch (mediaType) {
    'IMAGE' => MediaType('image', ext == 'png' ? 'png' : ext == 'webp' ? 'webp' : 'jpeg'),
    'AUDIO' => MediaType('audio', ext == 'mp3' || ext == 'mpeg' ? 'mpeg' : 'mp4'),
    'VIDEO' => MediaType('video', ext == 'mov' || ext == 'qt' ? 'quicktime' : 'mp4'),
    'DOCUMENT' => switch (ext) {
        'pdf' => MediaType('application', 'pdf'),
        'doc' => MediaType('application', 'msword'),
        'docx' => MediaType('application', 'vnd.openxmlformats-officedocument.wordprocessingml.document'),
        'png' => MediaType('image', 'png'),
        'webp' => MediaType('image', 'webp'),
        'jpg' || 'jpeg' => MediaType('image', 'jpeg'),
        _ => MediaType('application', 'octet-stream'),
      },
    _ => MediaType('application', 'octet-stream'),
  };
}

Future<List<Map<String, dynamic>>> fetchRegionPosts() async {
  final res = await Get.find<ApiClient>().get('/posts');
  final items = ((res['data'] as Map?)?['posts'] as List?) ?? [];
  return items.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
}

Future<List<Map<String, dynamic>>> fetchGrievancePosts() async {
  final res = await Get.find<ApiClient>().get('/posts/grievances');
  final items = ((res['data'] as Map?)?['posts'] as List?) ?? [];
  return items.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
}

String _postRef(Map<String, dynamic> post) {
  final serverId = '${post['serverId'] ?? ''}'.trim();
  if (serverId.isNotEmpty) return serverId;
  return '${post['clientUuid'] ?? post['id'] ?? ''}';
}

Future<Map<String, dynamic>> fetchRegionPost(Map<String, dynamic> post) async {
  final res = await Get.find<ApiClient>().get('/posts/${_postRef(post)}');
  return Map<String, dynamic>.from((res['data'] as Map)['post'] as Map);
}

Future<List<Map<String, dynamic>>> fetchPostAssignees(Map<String, dynamic> post) async {
  final res = await Get.find<ApiClient>().get('/posts/${_postRef(post)}/assignees');
  final items = ((res['data'] as Map?)?['members'] as List?) ?? [];
  return items.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
}

Future<Map<String, dynamic>> assignRegionPost(Map<String, dynamic> post, String? memberId) async {
  final res = await Get.find<ApiClient>().post('/posts/${_postRef(post)}/assign', data: {'memberId': memberId});
  return Map<String, dynamic>.from((res['data'] as Map)['post'] as Map);
}

Future<Map<String, dynamic>> resolveRegionPost(Map<String, dynamic> post, String status) async {
  final res = await Get.find<ApiClient>().post('/posts/${_postRef(post)}/resolve', data: {'status': status});
  return Map<String, dynamic>.from((res['data'] as Map)['post'] as Map);
}

/// Record that this member opened the post and get back the fresh total. One
/// row per member, so the number is how many people have seen it.
Future<int> markPostViewed(Map<String, dynamic> post) async {
  final res = await Get.find<ApiClient>().post('/posts/${_postRef(post)}/view');
  final data = (res['data'] as Map?) ?? const {};
  return (data['views'] as num?)?.round() ?? 0;
}

/// Like or dislike an issue post. Sending the side already held clears it, so
/// the caller passes what the member tapped, not what they should end up with.
/// `null` takes the vote back outright.
Future<Map<String, dynamic>> voteOnRegionPost(Map<String, dynamic> post, String? vote) async {
  final res = await Get.find<ApiClient>().post('/posts/${_postRef(post)}/vote', data: {'vote': vote});
  return Map<String, dynamic>.from((res['data'] as Map)['post'] as Map);
}

Future<String> summariseRegionPost(Map<String, dynamic> post) async {
  final res = await Get.find<ApiClient>().post('/posts/${_postRef(post)}/summary');
  return '${((res['data'] as Map?)?['summary'] ?? '')}'.trim();
}

List<Map<String, dynamic>> localPostIssues() => Get.find<HiveService>().localIssues();

Future<List<Map<String, dynamic>>> fetchPostIssues() => syncPostIssues(force: true);

Future<List<Map<String, dynamic>>>? _issueSyncInFlight;

Future<List<Map<String, dynamic>>> syncPostIssues({bool force = false, String? serverTimestamp}) async {
  final hive = Get.find<HiveService>();
  final token = hive.accessToken;
  if (token == null || token.isEmpty) return hive.localIssues();
  if (!force && hive.issuesMatchServer(serverTimestamp)) return hive.localIssues();
  if (_issueSyncInFlight != null) return _issueSyncInFlight!;
  _issueSyncInFlight = _fetchPostIssues(hive);
  try {
    return await _issueSyncInFlight!;
  } finally {
    _issueSyncInFlight = null;
  }
}

Future<List<Map<String, dynamic>>> _fetchPostIssues(HiveService hive) async {
  if (!await hasNetwork()) return hive.localIssues();
  try {
    final res = await Get.find<ApiClient>().get('/posts/issues');
    final data = (res['data'] as Map?) ?? {};
    final items = (data['issues'] as List?) ?? [];
    final issues = items.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    final timestamp = '${data['timestamp'] ?? ''}'.trim();
    if (issues.isNotEmpty) await hive.saveIssues(issues, timestamp: timestamp);
  } catch (_) {}
  return hive.localIssues();
}
