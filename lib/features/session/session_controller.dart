import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import '../../core/constants/org_hierarchy.dart';
import '../../core/push/push_service.dart';
import '../../core/constants/post_issues.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/app_log.dart';
import '../../core/utils/network.dart';
import '../../core/widgets/flash.dart';
import '../../data/local/hive_service.dart';
import '../../data/models/home_feed.dart';
import '../../data/remote/api_client.dart';
import '../activity_event/activity_event_dialog.dart';
import '../engagement/engagement_dialog.dart';
import '../events/event_api.dart';
import '../notifications/notifications_api.dart';
import '../post/post_api.dart';
import 'complete_profile_dialog.dart';

class SessionController extends GetxController {
  final hive = Get.find<HiveService>();
  final api = Get.find<ApiClient>();

  final profile = Rxn<Map<String, dynamic>>();
  final home = Rxn<Map<String, dynamic>>();
  final homeLoading = false.obs;
  final locationDenied = false.obs;
  final lat = Rxn<double>();
  final lng = Rxn<double>();
  final syncCount = 0.obs;
  final online = true.obs;
  final unreadNotifications = 0.obs;
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
    api.onSessionExpired = () => signOut(notifyServer: false);
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

  static bool hasProfileBasics(Map<String, dynamic>? member) {
    if (member == null) return false;
    final name = '${member['fullName'] ?? ''}'.trim();
    final stateId = '${member['stateId'] ?? ''}'.trim();
    final districtId = '${member['districtId'] ?? ''}'.trim();
    return name.length >= 2 && stateId.isNotEmpty && districtId.isNotEmpty;
  }

  bool get hasCompleteProfileBasics => hasProfileBasics(member);

  static bool hasActionProfile(Map<String, dynamic>? member) {
    if (!hasProfileBasics(member)) return false;
    return '${member?['assemblyId'] ?? ''}'.trim().isNotEmpty;
  }

  bool get canUseMemberActions => hasActionProfile(member);

  String get joinRoute => hive.joinStep1Complete ? Routes.boothSelect : Routes.memberStatus;

  String get postAuthRoute => hasCompleteProfileBasics ? Routes.shell : Routes.profileBasics;

  void openHome() {
    shellIndex.value = 0;
    Get.offAllNamed(hasCompleteProfileBasics ? Routes.shell : Routes.profileBasics);
  }

  void openPostAuth() {
    shellIndex.value = 0;
    Get.offAllNamed(postAuthRoute);
  }

  void openJoinVerification() => Get.toNamed(joinRoute);

  void saveAndExitJoin() => openHome();

  bool guardVerifiedAccess() {
    if (!needsVerification) return true;
    openJoinVerification();
    return false;
  }

  bool guardCreatePost() => guardMemberActions();

  bool guardMemberActions() {
    if (canUseMemberActions) return true;
    showCompleteProfileDialog();
    return false;
  }

  Future<void> applyAuthData(Map<String, dynamic> data) async {
    if (data['tokens'] is Map) {
      final tokens = Map<String, dynamic>.from(data['tokens'] as Map);
      final access = '${tokens['accessToken'] ?? ''}';
      final refresh = '${tokens['refreshToken'] ?? ''}';
      if (access.isNotEmpty && refresh.isNotEmpty) {
        await hive.saveTokens(access: access, refresh: refresh);
      }
    }
    final member = data['member'] is Map
        ? Map<String, dynamic>.from(data['member'] as Map)
        : <String, dynamic>{};
    if (data.containsKey('verified')) member['verified'] = data['verified'];
    if (data.containsKey('verifyStatus')) {
      member['verifyStatus'] = data['verifyStatus'];
    } else if (member['verifyStatus'] == null && member['status'] != null) {
      member['verifyStatus'] = member['status'];
    }
    if (data.containsKey('isNewMember')) member['isNewMember'] = data['isNewMember'];
    if (data['post'] != null) member['post'] = data['post'];
    if (member.isEmpty) return;
    final previousPost = '${hive.profile?['post'] ?? ''}';
    await hive.mergeProfile(member);
    profile.value = Map<String, dynamic>.from(hive.profile ?? {});
    profile.refresh();
    final nextPost = '${profile.value?['post'] ?? ''}';
    if (nextPost.isNotEmpty && nextPost != previousPost && data['tokens'] is! Map) {
      await api.refreshAccessToken(expireOnFail: false);
    }
  }

  Future<void> verifyOtp(String mobile, String code) async {
    api.signedOut = false;
    final fcmToken = Get.isRegistered<PushService>() ? Get.find<PushService>().token.value : null;
    final res = await api.post('/auth/otp/verify', data: {
      'mobile': mobile,
      'code': code,
      if (fcmToken != null && fcmToken.isNotEmpty) 'fcmToken': fcmToken,
    });
    final data = Map<String, dynamic>.from(res['data'] as Map);
    await applyAuthData(data);
    final saved = member ?? {};
    final isNew = data['isNewMember'] == true ||
        saved['status'] == 'DRAFT' ||
        (saved['fullName'] as String?)?.trim().isEmpty == true;
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
    if (Get.isRegistered<PushService>()) {
      unawaited(Get.find<PushService>().syncToken());
    }
    openPostAuth();
  }

  bool get hasSession => !api.signedOut && (hive.accessToken?.isNotEmpty ?? false);

  Future<bool> refreshMe() async {
    if (!hasSession && hive.accessToken == null) return false;
    try {
      final res = await api.get('/auth/me');
      final data = Map<String, dynamic>.from(res['data'] as Map);
      await applyAuthData(data);
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
    homeLoading.value = true;
    try {
      await refreshMe();
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
      await refreshUnreadNotifications();
      final stamp = '${home.value?['issuesTimestamp'] ?? ''}'.trim();
      if (!hive.issuesMatchServer(stamp.isEmpty ? null : stamp)) {
        await syncPostIssues(force: true, serverTimestamp: stamp.isEmpty ? null : stamp);
      }
      await syncPendingPosts();
      await syncPendingActivities();
      await refreshRegionPosts();
      promptActivityEvent();
      promptEngagement();
    } finally {
      homeLoading.value = false;
    }
  }

  Future<void> refreshUnreadNotifications() async {
    if (!hasSession) {
      unreadNotifications.value = 0;
      return;
    }
    try {
      unreadNotifications.value = await fetchUnreadNotificationCount();
    } catch (e, stack) {
      if (!api.signedOut) {
        AppLog.error('unread notifications failed', error: e, stack: stack, tag: 'NOTIF');
      }
    }
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

  bool _isUnderMyPost(Map<String, dynamic> post) {
    return post['showResolve'] == true || post['canResolve'] == true;
  }

  List<Map<String, dynamic>> myPosts() {
    return visiblePosts().where((post) => hive.isOwnPost(post) || _isUnderMyPost(post)).toList();
  }

  List<Map<String, dynamic>> otherPosts() {
    return visiblePosts().where((post) => post['pending'] != true && !hive.isOwnPost(post) && !_isUnderMyPost(post)).toList();
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

  /// The issue posts the server picked for the home rail: open, most urgent
  /// first, inside the member's own district. When the server has none — offline,
  /// or a district with nothing filed — the member's own regional feed stands in
  /// so the rail is not a blank strip.
  List<Map<String, dynamic>> homeIssuePosts({int limit = 8}) {
    final raw = home.value?['nearbyIssuePosts'] as List? ?? const [];
    final items = raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    if (items.isEmpty) return recentRegionalPosts(limit: limit);
    return items.take(limit).toList();
  }

  /// Send the side the member tapped. The server treats the side they already
  /// hold as taking the vote back, and answers with the whole post, which is
  /// written into both the rail and the regional feed so the two agree.
  /// Returns the post as the server left it, so a screen holding its own copy
  /// can show the new tally without refetching.
  Future<Map<String, dynamic>> voteOnPost(Map<String, dynamic> post, String? vote) async {
    final updated = await voteOnRegionPost(post, vote);
    upsertRegionPost(updated);
    final id = '${updated['clientUuid'] ?? updated['id'] ?? ''}';
    final current = home.value;
    final rail = current?['nearbyIssuePosts'] as List?;
    if (id.isEmpty || current == null || rail == null) return updated;
    final next = rail
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .map((item) => '${item['clientUuid'] ?? item['id'] ?? ''}' == id ? updated : item)
        .toList();
    home.value = {...current, 'nearbyIssuePosts': next};
    return updated;
  }

  /// Write a fresh like/dislike tally back into the cached home feed, so the
  /// card keeps its counts when the screen rebuilds and the two rails agree
  /// without refetching the whole of Home.
  void patchContentVote(HomeFeedItem item) {
    final current = home.value;
    if (current == null || item.id.isEmpty) return;
    final next = Map<String, dynamic>.from(current);
    var touched = false;
    for (final key in ['recentVideos', 'recentBlogs']) {
      final rows = current[key];
      if (rows is! List) continue;
      next[key] = rows.map((row) {
        if (row is! Map || '${row['id'] ?? ''}' != item.id) return row;
        touched = true;
        return {
          ...Map<String, dynamic>.from(row),
          'likes': item.likes,
          'dislikes': item.dislikes,
          'myVote': item.myVote,
        };
      }).toList();
    }
    if (touched) home.value = next;
  }

  /// Write a fresh view total into the cached copies of a post, so the card the
  /// member came from shows the new number when they go back.
  void patchPostViews(Map<String, dynamic> post, int views) {
    final id = '${post['clientUuid'] ?? post['id'] ?? ''}';
    if (id.isEmpty) return;
    var touched = false;
    for (var i = 0; i < regionPosts.length; i++) {
      if ('${regionPosts[i]['clientUuid'] ?? regionPosts[i]['id'] ?? ''}' != id) continue;
      regionPosts[i] = {...regionPosts[i], 'views': views};
      touched = true;
    }
    final current = home.value;
    final rail = current?['nearbyIssuePosts'];
    if (current != null && rail is List) {
      home.value = {
        ...current,
        'nearbyIssuePosts': rail.map((row) {
          if (row is! Map || '${row['clientUuid'] ?? row['id'] ?? ''}' != id) return row;
          return {...Map<String, dynamic>.from(row), 'views': views};
        }).toList(),
      };
    }
    if (touched) postsTick.value++;
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
          subIssueId: '${item['subIssueId'] ?? ''}'.isEmpty ? null : '${item['subIssueId']}',
          subIssueCode: '${item['subIssueCode'] ?? ''}'.isEmpty ? null : '${item['subIssueCode']}',
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

  static const _activityTypes = {
    'MEETING',
    'ADD_MEMBER',
    'GRIHA_SAMPARK',
    'PUBLIC_PROGRAMME',
    'TRAINING',
    'OTHER',
  };

  Future<void> syncPendingActivities({bool throwOnError = false}) async {
    Object? lastError;
    final pending = hive.pendingSync().where((item) => _activityTypes.contains('${item['type'] ?? ''}'));
    for (final item in pending) {
      final id = '${item['id'] ?? item['clientUuid'] ?? ''}';
      if (id.isEmpty) continue;
      final occurred = DateTime.tryParse('${item['occurredAt'] ?? item['createdAt'] ?? ''}') ?? DateTime.now();
      final booth = member?['booth'] as Map?;
      final boothId = item['boothId'] ?? booth?['id'] ?? hive.draft.get('boothId');
      try {
        await api.post('/activities', data: {
          'clientUuid': '${item['clientUuid'] ?? id}',
          'type': item['type'],
          if (boothId != null) 'boothId': boothId,
          'occurredAt': occurred.toUtc().toIso8601String(),
          if ('${item['notes'] ?? item['placeName'] ?? ''}'.trim().isNotEmpty)
            'notes': '${item['notes'] ?? item['placeName']}'.trim(),
          if ((item['latitude'] as num?) != null) 'latitude': (item['latitude'] as num).toDouble(),
          if ((item['longitude'] as num?) != null) 'longitude': (item['longitude'] as num).toDouble(),
        });
        await hive.removeSync(id);
      } catch (e, stack) {
        lastError = e;
        AppLog.error('Pending activity sync failed', error: e, stack: stack, tag: 'ACTIVITY');
      }
    }
    syncCount.value = hive.pendingSync().length;
    if (throwOnError && lastError != null) throw lastError;
  }

  Future<void> syncPending() async {
    await syncPendingPosts();
    await syncPendingActivities(throwOnError: true);
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

  /// Profile photo upload state, shown on the avatar while a new photo is on its way.
  final photoUploading = false.obs;
  final photoUploadProgress = 0.0.obs;
  final photoUploadPath = RxnString();

  Future<String> uploadProfilePhoto(String path) async {
    final form = FormData.fromMap({
      'photo': await MultipartFile.fromFile(path, filename: 'profile.jpg'),
    });
    final res = await api.postMultipart(
      '/members/photo',
      form,
      onSendProgress: (sent, total) {
        if (total > 0) photoUploadProgress.value = (sent / total).clamp(0.0, 1.0);
      },
    );
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
    final data = Map<String, dynamic>.from(res['data'] as Map);
    final member = Map<String, dynamic>.from(data['member'] as Map);
    member['stateName'] ??= hive.draft.get('stateName');
    member['districtName'] ??= hive.draft.get('districtName');
    member['assemblyName'] ??= hive.draft.get('assemblyName');
    await hive.saveProfile(member);
    profile.value = member;

    // An invite code that was spent has just changed which post this member
    // holds, and the post is baked into the access token — so the old one now
    // understates them and would be turned away from their own screens.
    final invite = data['invite'];
    if (invite is Map && invite['applied'] == true) {
      await hive.draft.delete('inviteCode');
      await api.refreshAccessToken(expireOnFail: false);
      final where = '${invite['where'] ?? ''}';
      flash(
        'ok',
        where.isEmpty
            ? 'invite_applied'.trParams({'post': '${invite['postTitle'] ?? ''}'})
            : 'invite_applied_at'.trParams({'post': '${invite['postTitle'] ?? ''}', 'where': where}),
      );
    } else if (invite is Map && invite['reason'] != null) {
      // The form went through; only the code did not. Saying so is better than
      // letting them find out later that they are an ordinary member.
      flash('Error', '${invite['reason']}');
    }
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

  Future<void> signOut({bool notifyServer = true}) async {
    if (notifyServer) unawaited(api.logoutRemote());
    api.signedOut = true;
    await hive.clearSession();
    profile.value = null;
    home.value = null;
    homeLoading.value = false;
    unreadNotifications.value = 0;
    regionPosts.clear();
    _engagementShown = false;
    _activityEventShown = false;
    shellIndex.value = 0;
    if (Get.isRegistered<PushService>()) {
      unawaited(Get.find<PushService>().rotateToken());
    }
    if (Get.context != null && Get.currentRoute != Routes.mobile) {
      Get.offAllNamed(Routes.mobile);
    }
  }
}
