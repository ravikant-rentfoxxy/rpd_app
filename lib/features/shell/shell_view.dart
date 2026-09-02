import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../home/home_view.dart';
import '../work/work_view.dart';
import '../members/members_view.dart';
import '../more/more_view.dart';
import '../activity/add_sheet.dart';

class ShellController extends GetxController {
  final index = 0.obs;
}

class ShellView extends StatelessWidget {
  const ShellView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(ShellController());
    final pages = const [HomeView(), WorkView(), SizedBox(), MembersView(), MoreView()];
    return Obx(
      () => Scaffold(
        body: pages[c.index.value],
        bottomNavigationBar: BottomAppBar(
          color: AppColors.card,
          elevation: 2,
          notchMargin: 6,
          shape: const CircularNotchedRectangle(),
          child: SizedBox(
            height: 60,
            child: Row(
              children: [
                _Nav(0, Icons.home_outlined, 'home'.tr, c),
                _Nav(1, Icons.insights_outlined, 'work'.tr, c),
                const SizedBox(width: 48),
                _Nav(3, Icons.groups_outlined, 'members'.tr, c),
                _Nav(4, Icons.more_horiz, 'more'.tr, c),
              ],
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppColors.brand,
          onPressed: () => showAddSheet(context),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}

class _Nav extends StatelessWidget {
  const _Nav(this.i, this.icon, this.label, this.c);
  final int i;
  final IconData icon;
  final String label;
  final ShellController c;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: () => c.index.value = i,
        child: Obx(() {
          final on = c.index.value == i;
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: on ? AppColors.brandLight : AppColors.ink3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: on ? FontWeight.w700 : FontWeight.w400,
                  color: on ? AppColors.brandLight : AppColors.ink3,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
