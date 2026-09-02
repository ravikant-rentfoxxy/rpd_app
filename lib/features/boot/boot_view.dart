import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/api.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../data/local/hive_service.dart';

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

  void _openStartRoute() {
    final hive = Get.find<HiveService>();
    if (ApiConfig.resolved() == null) {
      Get.offAllNamed(Routes.apiSettings);
      return;
    }
    if (hive.locale == null) {
      Get.offAllNamed(Routes.language);
      return;
    }
    if (hive.accessToken == null || hive.accessToken!.isEmpty) {
      Get.offAllNamed(Routes.mobile);
      return;
    }
    Get.offAllNamed(Routes.shell);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.paper,
      body: Center(child: CircularProgressIndicator(color: AppColors.brand)),
    );
  }
}
