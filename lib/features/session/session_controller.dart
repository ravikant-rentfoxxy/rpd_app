import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import '../../core/constants/org_hierarchy.dart';
import '../../core/constants/post_issues.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/app_log.dart';
import '../../core/utils/network.dart';
import '../../data/local/hive_service.dart';
import '../../data/models/booth.dart';
import '../../data/remote/api_client.dart';
import '../activity_event/activity_event_dialog.dart';
import '../engagement/engagement_dialog.dart';
import '../events/event_api.dart';
import '../post/post_api.dart';

class SessionController extends GetxController {
  final hive = Get.find<HiveService>();
  final api = Get.find<ApiClient>();

  final profile = Rxn<Map<String, dynamic>>();
  final home = Rxn<Map<String, dynamic>>();
  final nearbyBooths = <Booth>[].obs;
  final boothsLoading = false.obs;
  final locationDenied = false.obs;
  final lat = Rxn<double>();
  final lng = Rxn<double>();
  final syncCount = 0.obs;
  final online = true.obs;
  final recruitsTick = 0.obs;
  final postsTick = 0.obs;
  final regionPosts = <Map<String, dynamic>>[].obs;
  final allUpcomingEvents = <Map<String, dynamic>>[].obs;
  final shellIndex = 0.obs;
  final localeCode = 'en'.obs;
  StreamSubscription<bool>? _networkSub;
  bool _engagementShown = false;
  bool _activityEventShown = false;

  Map<String, dynamic>? get member => profile.value ?? hive.profile;

  bool get isSuperAdmin => member?['isSuperAdmin'] == true || member?['post'] == 'SUPER_ADMIN';

  bool get canOpenVerification {
    if (isSuperAdmin) return true;
    final post = member?['post'] as String?;
    return post != null && verificationPosts.contains(post);
  }

  bool get canCreateOrgEvents => officerCanCreateOrgEvents(member?['post'] as String?, isSuperAdmin: isSuperAdmin);

  @override
  void onInit() {
    super.onInit();
    profile.value = hive.profile;
    syncCount.value = hive.pendingSync().length;
    localeCode.value = hive.locale ?? 'en';
    api.onSessionExpired = signOut;
    _networkSub = watchNetwork().listen((up) => online.value = up);
    unawaited(hive.keepPendingImagePostsOnly());
  }

  @override
  void onClose() {
    _networkSub?.cancel();
    super.onClose();
  }

  Future<void> applyLocale(String code) async {
    await hive.setLocale(code);
    localeCode.value = code;
    final locale = switch (code) {
      'hi' => const Locale('hi', 'IN'),
      'bho' => const Locale('bho', 'IN'),
      _ => const Locale('en', 'US'),
    };
    Get.updateLocale(locale);
  }

  Future<void> requestOtp(String mobile) async {
    final previous = (hive.draft.get('mobile') as String?) ?? '';
    if (previous != mobile) {
      await hive.clearJoinDraft();
    }
    await api.post('/auth/otp/request', data: {'mobile': mobile, 'channel': 'WHATSAPP'});
    await hive.draft.put('mobile', mobile);
  }

  static bool isVerified(Map<String, dynamic>? member) {
    if (member == null) return false;
    if (member['isSuperAdmin'] == true || member['post'] == 'SUPER_ADMIN') return true;
    if (member['verified'] == true) return true;
    return member['status'] == 'VERIFIED' || member['verifyStatus'] == 'VERIFIED';
  }

  bool get needsVerification => !isVerified(member);

  String get joinRoute => hive.joinStep1Complete ? Routes.boothSelect : Routes.memberStatus;

  String get postAuthRoute {
    if (isVerified(member)) return Routes.shell;
    return joinRoute;
  }

  void openPostAuth() {
    shellIndex.value = 0;
    Get.offAllNamed(postAuthRoute);
  }

  void openJoinVerification() => Get.toNamed(joinRoute);

  void saveAndExitJoin() {
    shellIndex.value = 0;
    Get.offAllNamed(Routes.shell);
  }

  bool guardVerifiedAccess() {
    if (!needsVerification) return true;
    openJoinVerification();
    return false;
  }

  Future<void> verifyOtp(String mobile, String code) async {
    api.signedOut = false;
    final res = await api.post('/auth/otp/verify', data: {'mobile': mobile, 'code': code});
    final data = Map<String, dynamic>.from(res['data'] as Map);
    final tokens = Map<String, dynamic>.from(data['tokens'] as Map);
    await hive.saveTokens(access: tokens['accessToken'] as String, refresh: tokens['refreshToken'] as String);
    final member = Map<String, dynamic>.from(data['member'] as Map);
    member['verified'] = data['verified'] ?? member['verified'];
    member['verifyStatus'] = data['verifyStatus'] ?? member['verifyStatus'] ?? member['status'];
    await hive.saveProfile(member);
    profile.value = member;
    final isNew = data['isNewMember'] == true ||
        member['status'] == 'DRAFT' ||
        (member['fullName'] as String?)?.trim().isEmpty == true;
    if (isNew) {
      final draftMobile = (hive.draft.get('mobile') as String?)?.replaceAll(RegExp(r'\D'), '') ?? '';
      final digits = mobile.replaceAll(RegExp(r'\D'), '');
      final sameUser = draftMobile.isNotEmpty &&
          (digits.endsWith(draftMobile) || draftMobile.endsWith(digits));
      if (!sameUser) {
        await hive.clearJoinDraft();
      }
      await hive.draft.put('mobile', mobile);
    }
    openPostAuth();
  }

  bool get hasSession => !api.signedOut && (hive.accessToken?.isNotEmpty ?? false);

  Future<bool> refreshMe() async {
    if (!hasSession && hive.accessToken == null) return false;
    try {
      final res = await api.get('/auth/me');
      final data = Map<String, dynamic>.from(res['data'] as Map);
      final member = Map<String, dynamic>.from(data['member'] as Map);
      member['verified'] = data['verified'] ?? member['verified'];
      member['verifyStatus'] = data['verifyStatus'] ?? member['verifyStatus'] ?? member['status'];
      await hive.saveProfile(member);
      profile.value = member;
      return true;
    } on DioException catch (e, stack) {
      if (e.response?.statusCode == 401) return false;
      AppLog.error('refreshMe failed', error: e, stack: stack, tag: 'AUTH');
      return hive.profile != null;
    } catch (e, stack) {
      AppLog.error('refreshMe failed', error: e, stack: stack, tag: 'AUTH');
      return hive.profile != null;
    }
  }

  Future<void> markActive() async {
    if (!hasSession) return;
    try {
      await api.post('/home/active');
    } catch (e, stack) {
      if (api.signedOut) return;
      AppLog.error('markActive failed', error: e, stack: stack, tag: 'HOME');
    }
  }

  Future<void> loadHome() async {
    if (!hasSession) return;
    try {
      final res = await api.get('/home');
      home.value = Map<String, dynamic>.from(res['data'] as Map);
    } catch (e, stack) {
      if (!api.signedOut) {
        AppLog.error('loadHome failed', error: e, stack: stack, tag: 'HOME');
      }
    }
    if (!hasSession) return;
    final stamp = '${home.value?['issuesTimestamp'] ?? ''}'.trim();
    if (!hive.issuesMatchServer(stamp.isEmpty ? null : stamp)) {
      await syncPostIssues(force: true, serverTimestamp: stamp.isEmpty ? null : stamp);
    }
    await syncPendingPosts();
    await refreshRegionPosts();
    promptActivityEvent();
    promptEngagement();
  }

  void clearActivityEventPrompt() {
    final current = Map<String, dynamic>.from(home.value ?? {});
    current['activityEvent'] = null;
    home.value = current;
    home.refresh();
  }

  void promptActivityEvent() {
    if (_activityEventShown) return;
    final raw = home.value?['activityEvent'];
    if (raw is! Map) return;
    final event = Map<String, dynamic>.from(raw);
    if ('${event['id'] ?? ''}'.isEmpty) return;
    _activityEventShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.context == null) return;
      showActivityEventDialog(event);
    });
  }

  void clearEngagementPrompt() {
    final current = Map<String, dynamic>.from(home.value ?? {});
    current['engagement'] = null;
    home.value = current;
    home.refresh();
  }

  void promptEngagement() {
    if (_engagementShown) return;
    if (home.value?['activityEvent'] is Map) return;
    final raw = home.value?['engagement'];
    if (raw is! Map) return;
    final event = Map<String, dynamic>.from(raw);
    if ('${event['id'] ?? ''}'.isEmpty) return;
    _engagementShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.context == null) return;
      showEngagementDialog(event);
    });
  }

  void patchUpcomingEvent(Map<String, dynamic> event) {
    final current = Map<String, dynamic>.from(home.value ?? {});
    final list = [
      for (final item in (current['upcomingEvents'] as List? ?? []))
        item is Map && '${item['id']}' == '${event['id']}' ? event : item,
    ];
    current['upcomingEvents'] = list.take(5).toList();
    home.value = current;
    home.refresh();
    final all = [
      for (final item in allUpcomingEvents)
        item['id']?.toString() == '${event['id']}' ? event : item,
    ];
    if (all.every((item) => item['id']?.toString() != '${event['id']}')) {
      all.insert(0, event);
    }
    allUpcomingEvents.assignAll(all);
  }

  Future<void> loadAllUpcomingEvents() async {
    if (!hasSession) return;
    try {
      allUpcomingEvents.assignAll(await fetchOrgEvents());
    } catch (e, stack) {
      AppLog.error('loadAllUpcomingEvents failed', error: e, stack: stack, tag: 'EVENT');
    }
  }

  Future<Map<String, dynamic>> joinUpcomingEvent(String id) async {
    final event = await joinOrgEvent(id);
    patchUpcomingEvent(event);
    return event;
  }

  List<Map<String, dynamic>> visiblePosts() {
    final byId = <String, Map<String, dynamic>>{};
    for (final post in regionPosts) {
      final id = '${post['clientUuid'] ?? post['id'] ?? ''}';
      if (id.isNotEmpty) byId[id] = Map<String, dynamic>.from(post);
    }
    for (final post in hive.pendingPosts()) {
      final id = '${post['clientUuid'] ?? post['id'] ?? ''}';
      if (id.isNotEmpty) byId[id] = Map<String, dynamic>.from(post);
    }
    return byId.values.toList()..sort(comparePostsByIssuePriority);
  }

  List<Map<String, dynamic>> myPosts() => visiblePosts().where(hive.isOwnPost).toList();

  List<Map<String, dynamic>> otherPosts() {
    return visiblePosts().where((post) => post['pending'] != true && !hive.isOwnPost(post)).toList();
  }

  List<Map<String, dynamic>> recentRegionalPosts({int limit = 4}) {
    final items = visiblePosts();
    items.sort((a, b) {
      final aAt = DateTime.tryParse('${a['createdAt'] ?? ''}') ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bAt = DateTime.tryParse('${b['createdAt'] ?? ''}') ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bAt.compareTo(aAt);
    });
    return items.take(limit).toList();
  }

  void upsertRegionPost(Map<String, dynamic> post) {
    final id = '${post['clientUuid'] ?? post['id'] ?? ''}';
    if (id.isEmpty) return;
    regionPosts.removeWhere((item) => '${item['clientUuid'] ?? item['id'] ?? ''}' == id);
    regionPosts.insert(0, Map<String, dynamic>.from(post));
    postsTick.value++;
  }

  Future<void> refreshRegionPosts() async {
    if (!hasSession) return;
    try {
      final remote = await fetchRegionPosts();
      await hive.keepPendingImagePostsOnly();
      regionPosts.assignAll(remote);
      postsTick.value++;
    } catch (e, stack) {
      AppLog.error('refreshRegionPosts failed', error: e, stack: stack, tag: 'POST');
    }
  }

  Future<void> syncPendingPosts() async {
    if (!await hasNetwork()) return;
    await hive.keepPendingImagePostsOnly();
    final pending = hive.pendingSync().where((item) => item['type'] == 'REGION_POST');
    for (final item in pending) {
      final id = '${item['id'] ?? ''}';
      final mediaType = '${item['mediaType'] ?? 'image'}'.toLowerCase();
      if (id.isEmpty) continue;
      if (mediaType != 'image') {
        await hive.deletePost(id);
        await hive.removeSync(id);
        continue;
      }
      final path = '${item['mediaPath'] ?? ''}';
      final hasFile = path.isNotEmpty && File(path).existsSync();
      if (!hasFile) {
        await hive.deletePost(id);
        await hive.removeSync(id);
        continue;
      }
      try {
        final thumb = '${item['thumbnailPath'] ?? ''}';
        final uploaded = await uploadRegionPost(
          clientUuid: '${item['clientUuid'] ?? id}',
          mediaType: 'image',
          filePath: path,
          description: '${item['description'] ?? ''}',
          issueId: '${item['issueId'] ?? ''}'.isEmpty ? null : '${item['issueId']}',
          issueCode: '${item['issueCode'] ?? ''}'.isEmpty ? null : '${item['issueCode']}',
          latitude: (item['latitude'] as num?)?.toDouble(),
          longitude: (item['longitude'] as num?)?.toDouble(),
          districtId: item['districtId'],
          assemblyId: item['assemblyId'],
          boothId: item['boothId'],
          regionLabel: item['regionLabel'] as String?,
          authorName: item['authorName'] as String?,
          authorMobile: item['authorMobile'],
          thumbnailPath: thumb.isEmpty ? null : thumb,
        );
        await persistUploadedPost(uploaded, localPath: path, thumbnailPath: thumb.isEmpty ? null : thumb);
        await hive.removeSync(id);
        upsertRegionPost(uploaded);
      } catch (e, stack) {
        AppLog.error('Pending post sync failed', error: e, stack: stack, tag: 'POST');
      }
    }
    syncCount.value = hive.pendingSync().length;
    postsTick.value++;
  }

  Future<bool> captureLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        locationDenied.value = true;
        return false;
      }
      locationDenied.value = false;
      final pos = await Geolocator.getCurrentPosition();
      lat.value = pos.latitude;
      lng.value = pos.longitude;
      return true;
    } catch (e, stack) {
      AppLog.error('captureLocation failed', error: e, stack: stack, tag: 'LOCATION');
      return false;
    }
  }

  Future<void> syncNearbyBooths() async {
    boothsLoading.value = true;
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        locationDenied.value = true;
        nearbyBooths.assignAll(hive.allBooths().take(5).toList());
        return;
      }
      locationDenied.value = false;
      final pos = await Geolocator.getCurrentPosition();
      lat.value = pos.latitude;
      lng.value = pos.longitude;
      final res = await api.get('/booths/nearby', query: {
        'lat': pos.latitude,
        'lng': pos.longitude,
        'radiusKm': 10,
      });
      final list = ((res['data']['booths'] as List?) ?? [])
          .whereType<Map>()
          .map((e) => Booth.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      await hive.upsertBooths(list);
      nearbyBooths.assignAll(hive.nearbyLocal(lat: pos.latitude, lng: pos.longitude));
    } catch (e, stack) {
      AppLog.error('syncNearbyBooths failed', error: e, stack: stack, tag: 'BOOTH');
      if (lat.value != null && lng.value != null) {
        nearbyBooths.assignAll(hive.nearbyLocal(lat: lat.value!, lng: lng.value!));
      } else {
        nearbyBooths.assignAll(hive.allBooths());
      }
    } finally {
      boothsLoading.value = false;
    }
  }

  Future<String> uploadProfilePhoto(String path) async {
    final form = FormData.fromMap({
      'photo': await MultipartFile.fromFile(path, filename: 'profile.jpg'),
    });
    final res = await api.postMultipart('/members/photo', form);
    final data = Map<String, dynamic>.from(res['data'] as Map);
    final photoUrl = data['photoUrl'] as String? ?? data['photoKey'] as String?;
    if (photoUrl != null) {
      hive.draft.put('photoUrl', photoUrl);
      hive.draft.put('photoKey', data['photoKey']);
    }
    if (data['member'] is Map) {
      final member = Map<String, dynamic>.from(data['member'] as Map);
      await hive.saveProfile(member);
      profile.value = member;
    }
    return photoUrl ?? '';
  }

  Future<Map<String, dynamic>> recruitMember(Map<String, dynamic> body) async {
    AppLog.info('POST /members/recruit ${body['mobile']}', tag: 'MEMBERS');
    final res = await api.post('/members/recruit', data: body);
    recruitsTick.value++;
    loadHome();
    return Map<String, dynamic>.from(res['data'] as Map);
  }

  Future<void> registerMember(Map<String, dynamic> body, {bool openHome = true}) async {
    final photoKey = hive.draft.get('photoKey') ?? hive.draft.get('photoUrl') ?? hive.profile?['photoUrl'];
    final res = await api.post('/members/register', data: {
      ...body,
      if (photoKey is String && photoKey.isNotEmpty) 'photoUrl': photoKey,
    });
    final member = Map<String, dynamic>.from(res['data']['member'] as Map);
    member['stateName'] ??= hive.draft.get('stateName');
    member['districtName'] ??= hive.draft.get('districtName');
    member['assemblyName'] ??= hive.draft.get('assemblyName');
    await hive.saveProfile(member);
    profile.value = member;
    if (openHome) openPostAuth();
  }

  Future<void> updateProfile(Map<String, dynamic> body) async {
    final res = await api.patch('/members/me', data: body);
    final member = Map<String, dynamic>.from(res['data']['member'] as Map);
    await hive.saveProfile(member);
    profile.value = member;
  }

  Future<void> saveContribution(Map<String, dynamic> body) async {
    try {
      final res = await api.post('/members/contribution', data: body);
      final member = Map<String, dynamic>.from(res['data']['member'] as Map);
      await hive.saveProfile(member);
      profile.value = member;
    } catch (e, stack) {
      AppLog.error('saveContribution failed', error: e, stack: stack, tag: 'JOIN');
      rethrow;
    }
  }

  Future<void> signOut() async {
    api.signedOut = true;
    await hive.clearSession();
    profile.value = null;
    home.value = null;
    regionPosts.clear();
    _engagementShown = false;
    _activityEventShown = false;
    shellIndex.value = 0;
    if (Get.currentRoute != Routes.mobile) {
      Get.offAllNamed(Routes.mobile);
    }
  }
}
