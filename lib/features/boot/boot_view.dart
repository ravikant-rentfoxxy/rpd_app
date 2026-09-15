import 'dart:async';

import 'package:flutter/material.dart';
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
    return const Scaffold(
      backgroundColor: AppColors.paper,
      body: Center(child: CircularProgressIndicator(color: AppColors.brand)),
    );
  }
}
