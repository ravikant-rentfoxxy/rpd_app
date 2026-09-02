import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/utils/distance.dart';
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
    return this;
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

  Future<void> clearSession() async {
    await settings.delete('access_token');
    await settings.delete('refresh_token');
    await user.clear();
  }

  Map<String, dynamic>? get profile {
    final raw = user.get('profile');
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  Future<void> saveProfile(Map<String, dynamic> json) => user.put('profile', json);

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

  Future<void> enqueueSync(Map<String, dynamic> item) async {
    await syncQueue.put(item['id'], item);
  }

  List<Map<String, dynamic>> pendingSync() {
    return syncQueue.values.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> removeSync(String id) => syncQueue.delete(id);
}
