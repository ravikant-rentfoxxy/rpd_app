import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/ui.dart';
import '../post/post_views.dart';
import '../session/session_controller.dart';

class ActivityAction {
  const ActivityAction({
    required this.title,
    required this.sub,
    required this.type,
    required this.icon,
    required this.color,
    required this.wash,
  });

  final String title;
  final String sub;
  final String type;
  final IconData icon;
  final Color color;
  final Color wash;
}

List<ActivityAction> activityActions() => [
      ActivityAction(
        title: 'meeting'.tr,
        sub: 'बैठक',
        type: 'MEETING',
        icon: Icons.groups_outlined,
        color: AppColors.brand,
        wash: AppColors.brandWash,
      ),
      ActivityAction(
        title: 'griha'.tr,
        sub: 'गृह संपर्क',
        type: 'GRIHA_SAMPARK',
        icon: Icons.home_outlined,
        color: HomeColors.orange,
        wash: HomeColors.taskBg,
      ),
      ActivityAction(
        title: 'programme'.tr,
        sub: 'कार्यक्रम',
        type: 'PUBLIC_PROGRAMME',
        icon: Icons.campaign_outlined,
        color: const Color(0xFF2F6FED),
        wash: const Color(0xFFE8EFFF),
      ),
      ActivityAction(
        title: 'training'.tr,
        sub: 'प्रशिक्षण',
        type: 'TRAINING',
        icon: Icons.menu_book_outlined,
        color: AppColors.warn,
        wash: AppColors.warnBg,
      ),
    ];

void openActivityAction(ActivityAction action, {BuildContext? sheetContext}) {
  if (!Get.find<SessionController>().guardVerifiedAccess()) return;
  if (sheetContext != null) Navigator.pop(sheetContext);
  if (action.type == 'ADD_MEMBER') {
    Get.toNamed(Routes.addMember);
    return;
  }
  const eventTypes = {'MEETING', 'GRIHA_SAMPARK', 'PUBLIC_PROGRAMME', 'TRAINING'};
  if (eventTypes.contains(action.type) && Get.find<SessionController>().canCreateOrgEvents) {
    Get.toNamed(Routes.createEvent, arguments: action.type);
    return;
  }
  Get.toNamed(Routes.activityDetails, arguments: action.type);
}

class ActivityActionGrid extends StatelessWidget {
  const ActivityActionGrid({super.key, this.popSheet = false, this.aspectRatio = 2.55});
  final bool popSheet;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    final tiles = activityActions();
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: aspectRatio,
      children: tiles
          .map(
            (action) => _ActivityTile(
              action: action,
              onTap: () => openActivityAction(action, sheetContext: popSheet ? context : null),
            ),
          )
          .toList(),
    );
  }
}

Future<void> showAddSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const AddSheet(),
  );
}

class AddSheet extends StatelessWidget {
  const AddSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: AppColors.rule2, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 10),
            DisplayText('what_did_you'.tr, size: 16),
            Text('pick_one'.tr, style: const TextStyle(color: AppColors.ink3, fontSize: 12)),
            const SizedBox(height: 12),
            CreatePostEntry(
              onTap: () {
                if (!Get.find<SessionController>().guardVerifiedAccess()) return;
                Navigator.pop(context);
                Get.toNamed(Routes.createPost);
              },
            ),
            const SizedBox(height: 12),
            const ActivityActionGrid(popSheet: true),
          ],
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.action, required this.onTap});
  final ActivityAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: action.wash,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: action.color.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(action.icon, color: action.color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.ink),
                    ),
                    Text(
                      action.sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10, color: action.color, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
