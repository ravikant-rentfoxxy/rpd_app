import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/ui.dart';
import '../join/join_views.dart';
import '../session/logout_dialog.dart';
import '../session/session_controller.dart';

class MemberStatusView extends StatelessWidget {
  const MemberStatusView({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionController>();
    final checking = false.obs;

    Future<void> checkStatus() async {
      checking.value = true;
      await session.refreshMe();
      checking.value = false;
      if (SessionController.isVerified(session.member)) {
        session.openPostAuth();
      }
    }

    return Obx(() {
      final member = session.member ?? {};
      final status = (member['verifyStatus'] as String?) ?? (member['status'] as String?) ?? 'DRAFT';
      final name = (member['fullName'] as String?)?.trim() ?? '';
      final needsForm = status == 'DRAFT' || status == 'REJECTED' || name.isEmpty;

      if (needsForm) {
        return const AboutYouForm();
      }

      final (title, body, tone) = switch (status) {
        'PENDING' => ('verification_pending_title'.tr, 'verification_pending_body'.tr, CardTone.warn),
        'SUSPENDED' => ('verification_suspended_title'.tr, 'verification_suspended_body'.tr, CardTone.bad),
        'WITHDRAWN' => ('verification_withdrawn_title'.tr, 'verification_withdrawn_body'.tr, CardTone.flat),
        'VERIFIED' => ('verification_done_title'.tr, 'verification_done_body'.tr, CardTone.ok),
        _ => ('verification_pending_title'.tr, 'verification_pending_body'.tr, CardTone.warn),
      };

      return Scaffold(
        appBar: VerificationAppBar(title: 'verification_title'.tr),
        body: ListView(
          padding: const EdgeInsets.all(AppSpace.screen),
          children: [
            const StepBar(total: 3, current: 3),
            Text('step_of'.trParams({'current': '3', 'total': '3'}), style: const TextStyle(fontSize: 12, color: AppColors.ink3)),
            const SizedBox(height: 8),
            DisplayText(title),
            const SizedBox(height: 8),
            Text(body, style: const TextStyle(color: AppColors.ink3, fontSize: 13)),
            const SizedBox(height: 16),
            AppCard(tone: CardTone.ok, child: CardTitle('about_you'.tr, sub: name.isEmpty ? '—' : name)),
            AppCard(
              tone: CardTone.ok,
              child: CardTitle('which_booth'.tr, sub: (member['booth'] as Map?)?['name'] as String? ?? '—'),
            ),
            AppCard(tone: CardTone.ok, child: CardTitle('your_consent'.tr, sub: 'i_agree'.tr)),
            AppCard(
              tone: tone,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CardTitle(title, sub: (member['mobile'] as String?) ?? ''),
                  const SizedBox(height: 8),
                  Pill(status, tone: switch (status) {
                    'VERIFIED' => PillTone.ok,
                    'PENDING' => PillTone.warn,
                    'REJECTED' || 'SUSPENDED' => PillTone.bad,
                    _ => PillTone.neutral,
                  }),
                ],
              ),
            ),
            Obx(
              () => PrimaryButton('check_status'.tr, enabled: !checking.value, onTap: checkStatus),
            ),
            const SizedBox(height: 8),
            PrimaryButton('sign_out'.tr, ghost: true, onTap: showLogoutDialog),
          ],
        ),
      );
    });
  }
}
