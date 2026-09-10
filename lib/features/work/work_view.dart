import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/language_dropdown.dart';
import '../../core/widgets/ui.dart';
import '../activity/add_sheet.dart';
import '../session/session_controller.dart';
import '../tasks/tasks_view.dart';

class WorkView extends StatelessWidget {
  const WorkView({super.key});

  @override
  Widget build(BuildContext context) {
    return const TasksView(asTab: true);
  }
}

class ActivityHubView extends StatelessWidget {
  const ActivityHubView({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionController>();
    if (session.needsVerification) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (session.needsVerification) session.openJoinVerification();
      });
      return Scaffold(
        appBar: _hubAppBar(),
        backgroundColor: HomeColors.paper,
        body: const SizedBox.shrink(),
      );
    }
    return Scaffold(
      backgroundColor: HomeColors.paper,
      appBar: _hubAppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        children: [
          DisplayText('what_did_you'.tr, size: 22),
          const SizedBox(height: 4),
          Text('pick_one'.tr, style: const TextStyle(color: AppColors.ink3, fontSize: 13)),
          const SizedBox(height: 16),
          const ActivityActionGrid(aspectRatio: 2.2),
        ],
      ),
    );
  }
}

PreferredSizeWidget _hubAppBar() {
  return AppBar(
    backgroundColor: HomeColors.navy,
    foregroundColor: Colors.white,
    elevation: 0,
    scrolledUnderElevation: 0,
    title: Text('record_activity'.tr),
    actions: const [
      Padding(
        padding: EdgeInsets.only(right: 12),
        child: Center(child: LanguageDropdown(onDark: true)),
      ),
    ],
    systemOverlayStyle: const SystemUiOverlayStyle(
      statusBarColor: HomeColors.navy,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );
}
