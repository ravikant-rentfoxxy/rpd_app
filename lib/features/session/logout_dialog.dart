import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/ui.dart';
import 'session_controller.dart';

Future<void> showLogoutDialog() async {
  final confirmed = await Get.dialog<bool>(
    const LogoutDialog(),
    barrierDismissible: true,
    barrierColor: Colors.black54,
  );
  if (confirmed == true) {
    await Get.find<SessionController>().signOut();
  }
}

class LogoutDialog extends StatelessWidget {
  const LogoutDialog({super.key});

  String _text(String key, String fallback) {
    final value = key.tr;
    if (value != key) return value;
    final lang = Get.locale?.languageCode;
    return switch (key) {
      'sign_out' => lang == 'hi' || lang == 'bho' ? 'साइन आउट' : fallback,
      'sign_out_confirm' => switch (lang) {
          'hi' => 'क्या आप साइन आउट करना चाहते हैं?',
          'bho' => 'का रउआ साइन आउट करे चाहत बानी?',
          _ => fallback,
        },
      'cancel' => switch (lang) {
          'hi' => 'रद्द करें',
          'bho' => 'रद्द करीं',
          _ => fallback,
        },
      _ => fallback,
    };
  }

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
              _text('sign_out', 'Sign out'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink),
            ),
            const SizedBox(height: 8),
            Text(
              _text('sign_out_confirm', 'Are you sure you want to sign out?'),
              style: const TextStyle(fontSize: 14, height: 1.4, color: AppColors.ink2),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(_text('cancel', 'Cancel'), ghost: true, onTap: () => Get.back(result: false)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PrimaryButton(_text('sign_out', 'Sign out'), onTap: () => Get.back(result: true)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
