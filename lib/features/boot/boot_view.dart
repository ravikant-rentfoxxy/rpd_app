import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/constants/api.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/push/push_service.dart';
import '../../data/local/hive_service.dart';
import '../session/session_controller.dart';

class BootView extends StatefulWidget {
  const BootView({super.key});

  @override
  State<BootView> createState() => _BootViewState();
}

class _BootViewState extends State<BootView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openStartRoute());
  }

  Future<void> _openStartRoute() async {
    final hive = Get.find<HiveService>();
    if (ApiConfig.resolved() == null) {
      Get.offAllNamed(Routes.apiSettings);
      return;
    }
    if (hive.accessToken == null || hive.accessToken!.isEmpty) {
      Get.offAllNamed(Routes.mobile);
      return;
    }
    final session = Get.find<SessionController>();
    final ok = await session.refreshMe();
    if (!ok || hive.accessToken == null) {
      if (Get.currentRoute != Routes.mobile) {
        Get.offAllNamed(Routes.mobile);
      }
      return;
    }
    session.markActive();
    if (Get.isRegistered<PushService>()) {
      unawaited(Get.find<PushService>().syncToken());
    }
    session.openPostAuth();
  }

  @override
  Widget build(BuildContext context) {
    // The same white and the same mark the OS splash just drew, so the moment
    // Flutter takes over nothing on screen moves. What this adds is the word
    // the splash cannot carry, and something turning while the session is
    // checked — on a slow connection that wait is several seconds.
    return const AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.splashBackground,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Mark(),
                SizedBox(height: 22),
                Text(
                  'राष्ट्रीय परिवर्तन दल',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.splashNavy,
                    fontSize: 21,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Rashtriya Parivartan Dal',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF6B5CA5),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.4,
                  ),
                ),
                SizedBox(height: 34),
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Color(0xFFEF8120),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The mark, ringed in white — the artwork is a square split on the diagonal,
/// and half of it is this very navy.
class _Mark extends StatelessWidget {
  const _Mark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 108,
      height: 108,
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      child: ClipOval(
        child: Image.asset('assets/images/app_logo.png', fit: BoxFit.cover),
      ),
    );
  }
}
