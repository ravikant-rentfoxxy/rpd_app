import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rpd_app/features/join/join_chrome.dart';
import '../../core/routes/app_routes.dart';
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
      appBar: OrganicAppBar(title: 'more'.tr),
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
            // Adding a member is what this is nearly always tapped for, so it
            // opens there. My recruits is pushed underneath first, so Back
            // lands on the list rather than dropping straight out to More.
            onTap: () {
              Get.toNamed(Routes.members);
              Get.toNamed(Routes.addMember);
            },
            child: CardTitle('members'.tr, sub: 'members_more_sub'.trFallback('Add members and see your recruits')),
          ),
          AppCard(
            onTap: () => Get.toNamed(Routes.myLeaders),
            child: CardTitle(
              'my_leaders'.trFallback('My leaders'),
              sub: 'my_leaders_sub'.trFallback('Leaders of your area, step by step'),
            ),
          ),
          AppCard(
            onTap: () => Get.toNamed(Routes.posts),
            child: CardTitle('region_posts'.tr, sub: 'region_posts_sub'.tr),
          ),
          // The board moved off the tab bar to make room for Community, so it
          // is reached from here.
          AppCard(
            onTap: () => Get.toNamed(Routes.leaderboard),
            child: CardTitle(
              'leaderboard_nav'.trFallback('Rank'),
              sub: 'leaderboard_sub'.trFallback('Where you stand in your area'),
            ),
          ),
          if (session.canCreateOrgEvents)
            AppCard(
              onTap: () => Get.toNamed(Routes.grievance),
              child: CardTitle(
                'grievance'.trFallback('Grievance'),
                sub: 'grievance_sub'.trFallback('Pending posts in your region to assign'),
              ),
            ),
          AppCard(
            onTap: showMembershipCardOverlay,
            child: CardTitle('membership_card'.tr),
          ),
          AppCard(
            onTap: () => Get.toNamed(Routes.districtHealth),
            child: CardTitle('district_health'.tr, sub: 'district_health_sub'.tr),
          ),
          // What has been handed to this member. Sits above Create task so the
          // two read as a pair: your own work first, then work you hand out.
          AppCard(
            onTap: () => Get.toNamed(Routes.tasks),
            child: CardTitle(
              'my_tasks'.tr,
              sub: 'my_tasks_sub'.trFallback('Work assigned to you, and events you joined'),
            ),
          ),
          if (session.canCreateOrgEvents)
            AppCard(
              onTap: () => Get.toNamed(Routes.createTask),
              child: CardTitle('create_task'.trFallback('Create task'), sub: 'create_task_sub'.trFallback('Assign work to members in your region')),
            ),
          AppCard(
            onTap: () => Get.toNamed(Routes.activityEvents),
            child: CardTitle(
              'activity_events'.trFallback('Activity events'),
              sub: 'activity_events_sub'.trFallback('Answer live activity events'),
            ),
          ),
          if (session.canCreateOrgEvents)
            AppCard(
              onTap: () => Get.toNamed(Routes.activityHub),
              child: CardTitle('record_activity'.tr, sub: 'record_activity_sub'.tr),
            ),
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
