import 'package:get/get.dart';

String lastActiveWhen(Object? raw) {
  final at = _parseDate(raw);
  if (at == null) return 'last_activity_none'.tr;
  final delta = DateTime.now().difference(at.toLocal());
  if (delta.inMinutes < 1) return 'last_activity_just_now'.tr;
  if (delta.inHours < 1) return 'last_activity_minutes'.trParams({'n': '${delta.inMinutes}'});
  if (delta.inHours < 24) return 'last_activity_hours'.trParams({'n': '${delta.inHours}'});
  if (delta.inDays == 1) return 'last_activity_yesterday'.tr;
  return 'last_activity_days'.trParams({'n': '${delta.inDays}'});
}

DateTime? _parseDate(Object? raw) {
  if (raw is DateTime) return raw;
  if (raw is String && raw.isNotEmpty) return DateTime.tryParse(raw);
  return null;
}
