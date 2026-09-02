import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/app_log.dart';
import '../../data/local/hive_service.dart';
import '../../data/models/booth.dart';
import '../../data/remote/api_client.dart';

class SessionController extends GetxController {
  final hive = Get.find<HiveService>();
  final api = Get.find<ApiClient>();

  final profile = Rxn<Map<String, dynamic>>();
  final home = Rxn<Map<String, dynamic>>();
  final nearbyBooths = <Booth>[].obs;
  final locationDenied = false.obs;
  final lat = Rxn<double>();
  final lng = Rxn<double>();
  final syncCount = 0.obs;
  final online = true.obs;

  Map<String, dynamic>? get member => profile.value ?? hive.profile;

  @override
  void onInit() {
    super.onInit();
    profile.value = hive.profile;
    syncCount.value = hive.pendingSync().length;
  }

  Future<void> applyLocale(String code) async {
    await hive.setLocale(code);
    final locale = switch (code) {
      'hi' => const Locale('hi', 'IN'),
      'bho' => const Locale('bho', 'IN'),
      _ => const Locale('en', 'US'),
    };
    Get.updateLocale(locale);
  }

  Future<void> requestOtp(String mobile) async {
    await api.post('/auth/otp/request', data: {'mobile': mobile, 'channel': 'WHATSAPP'});
    hive.draft.put('mobile', mobile);
  }

  Future<void> verifyOtp(String mobile, String code) async {
    api.signedOut = false;
    final res = await api.post('/auth/otp/verify', data: {'mobile': mobile, 'code': code});
    final tokens = res['data']['tokens'] as Map<String, dynamic>;
    await hive.saveTokens(access: tokens['accessToken'] as String, refresh: tokens['refreshToken'] as String);
    final member = Map<String, dynamic>.from(res['data']['member'] as Map);
    await hive.saveProfile(member);
    profile.value = member;
    final isNew = res['data']['isNewMember'] == true || (member['fullName'] as String?)?.isEmpty == true;
    Get.offAllNamed(isNew ? Routes.personal : Routes.shell);
  }

  Future<void> loadHome() async {
    try {
      final res = await api.get('/home');
      home.value = Map<String, dynamic>.from(res['data'] as Map);
      if (home.value?['member'] is Map) {
        final m = Map<String, dynamic>.from(home.value!['member'] as Map);
        await hive.saveProfile(m);
        profile.value = m;
      }
    } catch (e, stack) {
      AppLog.error('loadHome failed', error: e, stack: stack, tag: 'HOME');
    }
  }

  Future<void> syncNearbyBooths() async {
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
        'radiusKm': 8,
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
    }
  }

  Future<void> registerMember(Map<String, dynamic> body) async {
    final res = await api.post('/members/register', data: body);
    final member = Map<String, dynamic>.from(res['data']['member'] as Map);
    await hive.saveProfile(member);
    profile.value = member;
    Get.offAllNamed(Routes.shell);
  }

  Future<void> signOut() async {
    api.signedOut = true;
    await hive.clearSession();
    profile.value = null;
    home.value = null;
    Get.offAllNamed(Routes.mobile);
  }
}
