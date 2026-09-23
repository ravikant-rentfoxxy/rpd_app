import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../home/home_view.dart';
import '../session/session_controller.dart';
import '../work/work_view.dart';
import '../community/community_view.dart';
import '../more/more_view.dart';
import '../../core/routes/app_routes.dart';

class ShellView extends StatelessWidget {
  const ShellView({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionController>();
    final pages = const [HomeView(), WorkView(), SizedBox(), CommunityView(), MoreView()];
    return Obx(
      () => Scaffold(
        body: pages[session.shellIndex.value],
        backgroundColor: HomeColors.paper,
        bottomNavigationBar: BottomAppBar(
          color: HomeColors.navBar,
          elevation: 0,
          padding: EdgeInsets.zero,
          shadowColor: Colors.transparent,
          surfaceTintColor: HomeColors.navBar,
          child: Container(
            height: 66,
            decoration: const BoxDecoration(
              color: HomeColors.navBar,
              border: Border(top: BorderSide(color: HomeColors.border)),
            ),
            child: Row(
              children: [
                _Nav(0, Icons.home_outlined, 'home'.tr, session),
                _Nav(1, Icons.assignment_outlined, 'work'.tr, session),
                const SizedBox(width: 56),
                _Nav(3, Icons.groups_outlined, 'community'.tr, session),
                _Nav(4, Icons.menu_rounded, 'more'.tr, session),
              ],
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: DecoratedBox(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Color(0x5915633A), blurRadius: 20, offset: Offset(0, 10))],
          ),
          child: Material(
            // The fill is the header gradient, so the one button that creates
            // anything reads as the same green as the chrome above it. Material
            // takes a colour but not a gradient, hence the Ink inside it.
            color: Iro.green,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: Ink(
              decoration: const BoxDecoration(gradient: Iro.headerGradient, shape: BoxShape.circle),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () {
                  if (!session.guardCreatePost()) return;
                  Get.toNamed(Routes.createPost);
                },
                child: const SizedBox(
                  width: 54,
                  height: 54,
                  child: Icon(Icons.add_rounded, color: Colors.white, size: 24),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Nav extends StatelessWidget {
  const _Nav(this.i, this.icon, this.label, this.session);
  final int i;
  final IconData icon;
  final String label;
  final SessionController session;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: () => session.shellIndex.value = i,
        child: Obx(() {
          final on = session.shellIndex.value == i;
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 19, color: on ? HomeColors.navActive : HomeColors.muted2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: on ? HomeColors.navActive : HomeColors.muted2,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
