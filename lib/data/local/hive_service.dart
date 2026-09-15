import 'dart:convert';

import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/post_issues.dart';
import '../../core/utils/distance.dart';
import '../../core/utils/dob.dart';
import '../models/booth.dart';

class HiveService extends GetxService {
  late Box settings;
  late Box booths;
  late Box user;
  late Box activities;
  late Box tasks;
  late Box syncQueue;
  late Box recruits;
  late Box draft;
  late Box posts;

  Future<HiveService> init() async {
    await Hive.initFlutter();
    settings = await Hive.openBox('settings');
    booths = await Hive.openBox('booths');
    user = await Hive.openBox('user');
    activities = await Hive.openBox('activities');
    tasks = await Hive.openBox('tasks');
    syncQueue = await Hive.openBox('sync_queue');
    recruits = await Hive.openBox('recruits');
    draft = await Hive.openBox('draft');
    posts = await Hive.openBox('region_posts');
    await seedIssuesIfEmpty();
    return this;
  }

  String? get currentMobile {
    final fromProfile = (profile?['mobile'] as String?)?.replaceAll(RegExp(r'\D'), '') ?? '';
    if (fromProfile.isNotEmpty) return fromProfile;
    final fromDraft = (draft.get('mobile') as String?)?.replaceAll(RegExp(r'\D'), '') ?? '';
    return fromDraft.isEmpty ? null : fromDraft;
  }

  String? get locale => settings.get('locale') as String?;
  Future<void> setLocale(String code) => settings.put('locale', code);

  String? get apiBaseUrl => settings.get('api_base_url') as String?;
  Future<void> setApiBaseUrl(String url) => settings.put('api_base_url', url);

  String? get accessToken => settings.get('access_token') as String?;
  String? get refreshToken => settings.get('refresh_token') as String?;

  Future<void> saveTokens({required String access, required String refresh}) async {
    await settings.put('access_token', access);
    await settings.put('refresh_token', refresh);
  }

  Future<void> clearJoinDraft() async {
    await draft.deleteAll([
      'fullName',
      'dob',
      'gender',
      'photoPath',
      'photoUrl',
      'photoKey',
      'boothId',
      'booth',
      'address',
      'pincode',
      'stateId',
      'districtId',
      'assemblyId',
      'pledgeUpdates',
      'step1Done',
    ]);
  }

  bool get joinDraftMatchesUser {
    final draftMobile = (draft.get('mobile') as String?)?.replaceAll(RegExp(r'\D'), '') ?? '';
    final profileMobile = (profile?['mobile'] as String?)?.replaceAll(RegExp(r'\D'), '') ?? '';
    if (draftMobile.isEmpty || profileMobile.isEmpty) return false;
    return profileMobile.endsWith(draftMobile) || draftMobile.endsWith(profileMobile);
  }

  bool get joinStep1Complete {
    if (!joinDraftMatchesUser) return false;
    final name = (draft.get('fullName') as String?)?.trim() ?? '';
    final dob = (draft.get('dob') as String?)?.trim() ?? '';
    return name.length >= 2 && isValidDob(dob);
  }

  Future<void> clearSession() async {
    await settings.delete('access_token');
    await settings.delete('refresh_token');
    await user.clear();
    await draft.clear();
    await syncQueue.clear();
    await recruits.clear();
    await posts.clear();
    await activities.clear();
    await tasks.clear();
  }

  Map<String, dynamic>? get profile {
    final raw = user.get('profile');
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  Future<void> saveProfile(Map<String, dynamic> json) => user.put('profile', json);

  Future<void> mergeProfile(Map<String, dynamic> incoming) async {
    final current = profile ?? {};
    final next = <String, dynamic>{...current, ...incoming};
    for (final key in const ['booth', 'card', 'recruitedBy']) {
      if (incoming[key] == null && current[key] != null) next[key] = current[key];
    }
    await saveProfile(next);
  }

  Future<void> upsertBooths(List<Booth> list) async {
    for (final booth in list) {
      await booths.put(booth.id, booth.toJson());
    }
    await settings.put('booths_fetched_at', DateTime.now().toIso8601String());
  }

  List<Booth> allBooths() {
    return booths.values
        .whereType<Map>()
        .map((e) => Booth.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  List<Booth> nearbyLocal({required double lat, required double lng, int limit = 8}) {
    final list = allBooths()
        .map((b) => b.copyWith(distanceMetres: haversineMetres(lat, lng, b.latitude, b.longitude)))
        .toList()
      ..sort((a, b) => (a.distanceMetres ?? 1 << 30).compareTo(b.distanceMetres ?? 1 << 30));
    return list.take(limit).toList();
  }

  List<Booth> searchLocal(String q) {
    final query = q.toLowerCase();
    return allBooths()
        .where(
          (b) =>
              b.village.toLowerCase().contains(query) ||
              b.partNumber.contains(query) ||
              b.code.toLowerCase().contains(query) ||
              b.name.toLowerCase().contains(query) ||
              b.pincode.contains(query),
        )
        .toList();
  }

  Future<void> saveActivityRow(Map<String, dynamic> row) async {
    final id = '${row['id'] ?? DateTime.now().millisecondsSinceEpoch}';
    await activities.put(id, Map<String, dynamic>.from(row));
  }

  Map<String, dynamic> workLedger() {
    return {'points': 0, 'entries': []};
  }

  List<Map<String, dynamic>> allPosts() {
    return posts.values.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
      ..sort(comparePostsByIssuePriority);
  }

  List<Map<String, dynamic>> savedIssues() => _parseIssues(settings.get('post_issues'));

  List<Map<String, dynamic>> localIssues() {
    final stored = savedIssues();
    if (stored.isNotEmpty) return stored;
    return fallbackPostIssues.map(Map<String, dynamic>.from).toList();
  }

  String? get issuesTimestamp {
    final raw = '${settings.get('post_issues_synced_at') ?? ''}'.trim();
    return raw.isEmpty ? null : raw;
  }

  bool issuesMatchServer(String? serverTimestamp) {
    final stamp = '${serverTimestamp ?? ''}'.trim();
    if (stamp.isEmpty || savedIssues().isEmpty) return false;
    return issuesTimestamp == stamp;
  }

  Future<void> seedIssuesIfEmpty() async {
    final stored = savedIssues();
    final hasChildren = stored.any((issue) => (issue['children'] as List?)?.isNotEmpty == true);
    if (hasChildren) return;
    await settings.put('post_issues', jsonEncode(fallbackPostIssues));
  }

  Future<void> saveIssues(List<Map<String, dynamic>> items, {String? timestamp}) async {
    if (items.isEmpty) return;
    await settings.put('post_issues', jsonEncode(items));
    final stamp = timestamp?.trim();
    if (stamp != null && stamp.isNotEmpty) {
      await settings.put('post_issues_synced_at', stamp);
    }
  }

  List<Map<String, dynamic>> _parseIssues(Object? raw) {
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        }
      } catch (_) {}
    }
    if (raw is List) {
      return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  Future<void> savePost(Map<String, dynamic> row) async {
    final id = '${row['id'] ?? DateTime.now().millisecondsSinceEpoch}';
    await posts.put(id, Map<String, dynamic>.from(row));
  }

  Future<void> deletePost(String id) async {
    if (id.isEmpty) return;
    await posts.delete(id);
  }

  bool _isPendingPost(Map<String, dynamic> post) => post['pending'] == true;

  bool _isImagePost(Map<String, dynamic> post) {
    final type = '${post['mediaType'] ?? 'image'}'.toLowerCase();
    return type == 'image';
  }

  /// Local box is only an offline image queue. Uploaded / video / audio rows are dropped.
  Future<void> keepPendingImagePostsOnly() async {
    final keep = <String, Map<String, dynamic>>{};
    for (final post in allPosts()) {
      if (!_isPendingPost(post) || !_isImagePost(post)) continue;
      final id = '${post['id'] ?? ''}';
      if (id.isNotEmpty) keep[id] = post;
    }
    await posts.clear();
    for (final post in keep.values) {
      await savePost(post);
    }
  }

  List<Map<String, dynamic>> pendingPosts() => allPosts().where(_isPendingPost).toList();

  List<Map<String, dynamic>> regionalPosts() {
    final member = profile ?? {};
    final booth = member['booth'] is Map ? Map<String, dynamic>.from(member['booth'] as Map) : <String, dynamic>{};
    final districtId = '${member['districtId'] ?? booth['districtId'] ?? ''}';
    final assemblyId = '${member['assemblyId'] ?? booth['assemblyId'] ?? ''}';
    final mobile = (currentMobile ?? member['mobile'] as String? ?? '').replaceAll(RegExp(r'\D'), '');
    final all = allPosts();
    if (districtId.isEmpty && assemblyId.isEmpty && mobile.isEmpty) return all;
    return all.where((post) {
      final sameDistrict = districtId.isNotEmpty && '${post['districtId']}' == districtId;
      final sameAssembly = assemblyId.isNotEmpty && '${post['assemblyId']}' == assemblyId;
      return sameDistrict || sameAssembly || isOwnPost(post);
    }).toList();
  }

  bool isOwnPost(Map<String, dynamic> post) {
    final member = profile ?? {};
    final memberId = '${member['id'] ?? ''}';
    final mobile = (currentMobile ?? member['mobile'] as String? ?? '').replaceAll(RegExp(r'\D'), '');
    final authorId = '${post['authorId'] ?? ''}';
    final authorMobile = '${post['authorMobile'] ?? ''}'.replaceAll(RegExp(r'\D'), '');
    if (memberId.isNotEmpty && authorId == memberId) return true;
    if (mobile.isEmpty || authorMobile.isEmpty) return false;
    return mobile == authorMobile || mobile.endsWith(authorMobile) || authorMobile.endsWith(mobile);
  }

  List<Map<String, dynamic>> recentRegionalPosts({int limit = 5}) {
    final items = regionalPosts();
    items.sort((a, b) {
      final aAt = DateTime.tryParse('${a['createdAt'] ?? ''}') ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bAt = DateTime.tryParse('${b['createdAt'] ?? ''}') ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bAt.compareTo(aAt);
    });
    return items.take(limit).toList();
  }

  List<Map<String, dynamic>> myPosts() => regionalPosts().where(isOwnPost).toList();

  List<Map<String, dynamic>> otherPosts() => regionalPosts().where((post) => !isOwnPost(post)).toList();

  Future<void> enqueueSync(Map<String, dynamic> item) async {
    await syncQueue.put(item['id'], item);
  }

  List<Map<String, dynamic>> pendingSync() {
    return syncQueue.values.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> removeSync(String id) => syncQueue.delete(id);
}
