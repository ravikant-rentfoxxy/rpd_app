import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
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
    final tiles = [
      ('meeting'.tr, 'बैठक', 'MEETING'),
      ('add_member'.tr, 'सदस्य जोड़ें', 'ADD_MEMBER'),
      ('griha'.tr, 'गृह संपर्क', 'GRIHA_SAMPARK'),
      ('programme'.tr, 'कार्यक्रम', 'PUBLIC_PROGRAMME'),
      ('training'.tr, 'प्रशिक्षण', 'TRAINING'),
      ('something_else'.tr, 'अन्य', 'OTHER'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 34, height: 4, decoration: BoxDecoration(color: AppColors.rule2, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 12),
          Text('what_did_you'.tr, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          Text('pick_one'.tr, style: const TextStyle(color: AppColors.ink3, fontSize: 12)),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.5,
            children: tiles
                .map(
                  (t) => InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      if (t.$3 == 'ADD_MEMBER') {
                        Get.toNamed(Routes.addMember);
                      } else {
                        Get.toNamed(Routes.activityDetails, arguments: t.$3);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.card2,
                        border: Border.all(color: AppColors.rule),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(t.$1, style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(t.$2, style: const TextStyle(fontSize: 11, color: AppColors.ink3)),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
