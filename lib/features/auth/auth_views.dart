import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/api_error.dart';
import '../../core/utils/app_log.dart';
import '../../core/widgets/ui.dart';
import '../../data/local/hive_service.dart';
import '../session/session_controller.dart';

class MobileView extends StatelessWidget {
  const MobileView({super.key});

  @override
  Widget build(BuildContext context) {
    final mobile = TextEditingController();
    final loading = false.obs;
    return Scaffold(
      appBar: AppBar(title: Text('sign_in'.tr)),
      body: Padding(
        padding: const EdgeInsets.all(AppSpace.screen),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DisplayText('your_mobile'.tr),
            const SizedBox(height: 6),
            Text('mobile_help'.tr, style: const TextStyle(color: AppColors.ink3, fontSize: 13)),
            const SizedBox(height: 16),
            AppField(
              label: 'mobile_number'.tr,
              controller: mobile,
              keyboard: TextInputType.phone,
              mono: true,
              prefix: '+91  ',
              maxLength: 10,
              hint: '98•••• ••••',
            ),
            Obx(
              () => PrimaryButton(
                'send_code'.tr,
                enabled: !loading.value,
                onTap: () async {
                  final number = mobile.text.replaceAll(RegExp(r'\D'), '');
                  if (!RegExp(r'^[6-9]\d{9}$').hasMatch(number)) {
                    Get.snackbar('Error', 'Enter a 10-digit Indian mobile number');
                    return;
                  }
                  loading.value = true;
                  try {
                    await Get.find<SessionController>().requestOtp(number);
                    Get.toNamed(Routes.otp, arguments: number);
                  } catch (e, stack) {
                    AppLog.error('OTP request failed', error: e, stack: stack, tag: 'AUTH');
                    Get.snackbar('Error', apiErrorMessage(e));
                  } finally {
                    loading.value = false;
                  }
                },
              ),
            ),
            const SizedBox(height: 12),
            Text('terms_line'.tr, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: AppColors.ink3)),
          ],
        ),
      ),
    );
  }
}

class OtpView extends StatelessWidget {
  const OtpView({super.key});

  @override
  Widget build(BuildContext context) {
    final mobile = (Get.arguments as String?) ?? Get.find<HiveService>().draft.get('mobile') as String? ?? '';
    final code = TextEditingController();
    final loading = false.obs;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('verify'.tr),
            Text('+91 $mobile · ${'change'.tr}', style: const TextStyle(fontSize: 12, color: AppColors.ink3)),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpace.screen),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DisplayText('enter_code'.tr),
            const SizedBox(height: 6),
            Text('code_sent'.tr, style: const TextStyle(color: AppColors.ink3, fontSize: 13)),
            const SizedBox(height: 16),
            AppField(label: 'OTP', controller: code, keyboard: TextInputType.number, mono: true, hint: '6-digit code'),
            AppCard(
              tone: CardTone.flat,
              child: CardTitle('auto_read'.tr, sub: 'auto_read_sub'.tr),
            ),
            Obx(
              () => PrimaryButton(
                'continue'.tr,
                enabled: !loading.value,
                onTap: () async {
                  final otp = code.text.trim();
                  if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
                    Get.snackbar('Error', 'Enter the 6-digit code');
                    return;
                  }
                  loading.value = true;
                  try {
                    await Get.find<SessionController>().verifyOtp(mobile, otp);
                  } catch (e, stack) {
                    AppLog.error('OTP verify failed', error: e, stack: stack, tag: 'AUTH');
                    Get.snackbar('Error', apiErrorMessage(e));
                  } finally {
                    loading.value = false;
                  }
                },
              ),
            ),
            const SizedBox(height: 10),
            Center(child: Text('${'resend'.tr} · ${'sms_instead'.tr}', style: const TextStyle(color: AppColors.ink3))),
          ],
        ),
      ),
    );
  }
}
