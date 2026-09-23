import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/relative_time.dart';
import '../../core/widgets/empty_card.dart';
import '../../core/widgets/ui.dart';
import '../session/session_controller.dart';
import 'notifications_api.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  final items = <Map<String, dynamic>>[].obs;
  final loading = true.obs;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    loading.value = true;
    try {
      final data = await fetchNotifications();
      final list = (data['notifications'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      items.assignAll(list);
      Get.find<SessionController>().unreadNotifications.value =
          (data['unreadCount'] as num?)?.toInt() ?? list.where((n) => n['seen'] != true).length;
    } catch (_) {
      items.clear();
    } finally {
      loading.value = false;
    }
  }

  Future<void> _markOne(int index) async {
    final n = items[index];
    final id = '${n['id'] ?? ''}';
    if (id.isEmpty || n['seen'] == true) return;
    items[index] = {...n, 'seen': true};
    try {
      final unread = await markNotificationSeen(id);
      Get.find<SessionController>().unreadNotifications.value = unread;
    } catch (_) {
      await Get.find<SessionController>().refreshUnreadNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: OrganicAppBar(title: 'notifications'.tr),
      body: Obx(() {
        if (loading.value) {
          return const Center(child: CircularProgressIndicator(color: HomeColors.orange));
        }
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: AppEmptyCard(
                icon: Icons.notifications_none_rounded,
                title: 'notif_empty'.tr,
              ),
            ),
          );
        }
        return RefreshIndicator(
          color: HomeColors.orange,
          onRefresh: _load,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final n = items[index];
              final unread = n['seen'] != true;
              return AppCard(
                tone: unread ? CardTone.ok : CardTone.plain,
                onTap: () => _markOne(index),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CardTitle('${n['title'] ?? ''}', sub: '${n['body'] ?? ''}'),
                          const SizedBox(height: 6),
                          MonoText(lastActiveWhen(n['createdAt'])),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (unread) const Pill('NEW', tone: PillTone.brand),
                  ],
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
