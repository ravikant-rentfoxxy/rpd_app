import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:rpd_app/features/join/join_chrome.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/language_dropdown.dart';
import '../../core/widgets/ui.dart';
import '../card/membership_card_view.dart';
import '../session/logout_dialog.dart';
import '../session/session_controller.dart';

class MoreView extends StatelessWidget {
  const MoreView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: HomeColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('more'.tr),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: HomeColors.navy,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      body: Obx(() {
        final session = Get.find<SessionController>();
        session.profile.value;
        return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (session.canOpenVerification)
            AppCard(
              onTap: () => Get.toNamed(Routes.verification),
              child: CardTitle('verification_inbox'.trFallback('Verification inbox')),
            ),
          AppCard(
            onTap: () => Get.toNamed(Routes.posts),
            child: CardTitle('region_posts'.tr, sub: 'region_posts_sub'.tr),
          ),
          AppCard(
            onTap: showMembershipCardOverlay,
            child: CardTitle('membership_card'.tr),
          ),
          AppCard(onTap: () => Get.toNamed(Routes.boothHealth), child: CardTitle('booth_health'.tr)),
          if (session.canCreateOrgEvents)
            AppCard(
              onTap: () => Get.toNamed(Routes.createTask),
              child: CardTitle('create_task'.trFallback('Create task'), sub: 'create_task_sub'.trFallback('Assign work to members in your region')),
            ),
          AppCard(
            onTap: () => Get.toNamed(Routes.activityHub),
            child: CardTitle('record_activity'.tr, sub: 'record_activity_sub'.tr),
          ),
          AppCard(onTap: () => Get.toNamed(Routes.meeting), child: CardTitle('booth_meeting'.tr)),
          AppCard(
            child: Row(
              children: [
                Expanded(child: CardTitle('language'.tr)),
                const LanguageDropdown(),
              ],
            ),
          ),
          PrimaryButton('sign_out'.tr, ghost: true, onTap: showLogoutDialog),
        ],
      );
      }),
    );
  }
}
