import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/ui.dart';
import '../../data/local/hive_service.dart';
import '../session/session_controller.dart';

class SyncView extends StatelessWidget {
  const SyncView({super.key});

  @override
  Widget build(BuildContext context) {
    final hive = Get.find<HiveService>();
    final items = hive.pendingSync().obs;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('sync_queue'.tr),
            Text('${items.length} items', style: const TextStyle(fontSize: 12, color: AppColors.ink3)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            color: AppColors.warnBg,
            child: Text('offline_bar'.tr, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.warn, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 12),
          ...items.map((e) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const AvatarCircle('◷', bg: AppColors.warnBg, color: AppColors.warn),
                title: Text(e['title'] as String? ?? e['type'] as String? ?? 'Item', style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(e['size'] as String? ?? e['createdAt'] as String? ?? ''),
              )),
          AppCard(tone: CardTone.ok, child: CardTitle('nothing_lost'.tr, sub: 'These stay on your phone until they upload. You can close the app.')),
          PrimaryButton('try_upload'.tr, ghost: true, onTap: () {
            items.assignAll(hive.pendingSync());
            Get.find<SessionController>().syncCount.value = items.length;
          }),
        ],
      ),
    );
  }
}
