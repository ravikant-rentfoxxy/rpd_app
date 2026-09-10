import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/api_error.dart';
import '../../core/widgets/ui.dart';
import '../session/session_controller.dart';
import 'engagement_api.dart';

Future<void> showEngagementDialog(Map<String, dynamic> event) async {
  if (Get.isDialogOpen == true) return;
  await Get.dialog(
    EngagementInviteDialog(event: event),
    barrierDismissible: false,
    barrierColor: Colors.black54,
  );
}

class EngagementInviteDialog extends StatelessWidget {
  const EngagementInviteDialog({super.key, required this.event});
  final Map<String, dynamic> event;

  String get type => '${event['type'] ?? ''}'.toUpperCase();

  Future<void> _close() async {
    final id = '${event['id'] ?? ''}';
    try {
      if (id.isNotEmpty) await dismissEngagement(id);
      Get.find<SessionController>().clearEngagementPrompt();
    } catch (e) {
      Get.snackbar('Error', apiErrorMessage(e));
    }
    if (Get.isDialogOpen == true) Get.back();
  }

  void _play() {
    if (Get.isDialogOpen == true) Get.back();
    Get.toNamed(Routes.engagementPlay, arguments: event);
  }

  @override
  Widget build(BuildContext context) {
    final title = '${event['title'] ?? ''}'.trim();
    final description = '${event['description'] ?? ''}'.trim();
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              type == 'QUIZ' ? 'engagement_quiz'.tr : 'engagement_poll'.tr,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: HomeColors.orange),
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: HomeColors.ink)),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(description, style: const TextStyle(fontSize: 14, height: 1.4, color: HomeColors.muted)),
            ],
            const SizedBox(height: 20),
            PrimaryButton('engagement_play'.tr, onTap: _play),
            const SizedBox(height: 8),
            PrimaryButton('engagement_close'.tr, ghost: true, onTap: _close),
          ],
        ),
      ),
    );
  }
}
