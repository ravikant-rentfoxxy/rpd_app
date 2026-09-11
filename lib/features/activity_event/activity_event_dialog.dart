import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/ui.dart';
import '../join/join_chrome.dart';
import '../session/session_controller.dart';

Future<void> showActivityEventDialog(Map<String, dynamic> event) async {
  if (Get.isDialogOpen == true) return;
  await Get.dialog(
    ActivityEventInviteDialog(event: event),
    barrierDismissible: false,
    barrierColor: Colors.black54,
  );
}

class ActivityEventInviteDialog extends StatelessWidget {
  const ActivityEventInviteDialog({super.key, required this.event});
  final Map<String, dynamic> event;

  void _open() {
    if (Get.isDialogOpen == true) Get.back();
    Get.find<SessionController>().clearActivityEventPrompt();
    Get.toNamed(Routes.activityEventPlay, arguments: event);
  }

  void _close() {
    Get.find<SessionController>().clearActivityEventPrompt();
    if (Get.isDialogOpen == true) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final title = '${event['title'] ?? ''}'.trim();
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
              'activity_event'.trFallback('Activity event'),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: HomeColors.orange),
            ),
            const SizedBox(height: 8),
            Text(
              title.isEmpty ? 'activity_event'.trFallback('Activity event') : title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: HomeColors.ink),
            ),
            const SizedBox(height: 20),
            PrimaryButton('activity_event_open'.trFallback('Open'), onTap: _open),
            const SizedBox(height: 8),
            PrimaryButton('activity_event_later'.trFallback('Later'), ghost: true, onTap: _close),
          ],
        ),
      ),
    );
  }
}
