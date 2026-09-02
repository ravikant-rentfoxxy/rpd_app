import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/ui.dart';
import '../session/session_controller.dart';

class MoreView extends StatelessWidget {
  const MoreView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('more'.tr)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(onTap: () => Get.toNamed(Routes.card), child: CardTitle('membership_card'.tr)),
          AppCard(onTap: () => Get.toNamed(Routes.boothHealth), child: CardTitle('booth_health'.tr)),
          AppCard(onTap: () => Get.toNamed(Routes.tasks), child: CardTitle('my_tasks'.tr)),
          AppCard(onTap: () => Get.toNamed(Routes.sync), child: CardTitle('sync_queue'.tr)),
          AppCard(onTap: () => Get.toNamed(Routes.meeting), child: CardTitle('booth_meeting'.tr)),
          AppCard(onTap: () => Get.offAllNamed(Routes.language), child: CardTitle('language'.tr)),
          AppCard(onTap: () => Get.toNamed(Routes.apiSettings), child: CardTitle('api_url'.tr)),
          AppCard(onTap: () => Get.toNamed(Routes.errorLog), child: CardTitle('error_log'.tr)),
          PrimaryButton('sign_out'.tr, ghost: true, onTap: Get.find<SessionController>().signOut),
        ],
      ),
    );
  }
}
