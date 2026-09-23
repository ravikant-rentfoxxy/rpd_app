import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/ui.dart';
import '../join/join_chrome.dart';

Future<void> showCompleteProfileDialog() async {
  final go = await Get.dialog<bool>(
    const CompleteProfileDialog(),
    barrierDismissible: true,
    barrierColor: Colors.black54,
  );
  if (go == true) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.toNamed(Routes.profileEdit, arguments: {'openProfileAfterSave': true});
    });
  }
}

class CompleteProfileDialog extends StatelessWidget {
  const CompleteProfileDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpace.cardRadius)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'complete_profile_title'.trFallback('Complete your profile'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink),
            ),
            const SizedBox(height: 8),
            Text(
              'complete_profile_body'.trFallback(
                'Add your name, state and assembly constituency in Profile first.',
              ),
              style: const TextStyle(fontSize: 14, height: 1.4, color: AppColors.ink2),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    'got_it'.trFallback('OK'),
                    ghost: true,
                    onTap: () => Get.back(result: false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PrimaryButton(
                    'go_to_profile'.trFallback('Go to profile'),
                    onTap: () => Get.back(result: true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
