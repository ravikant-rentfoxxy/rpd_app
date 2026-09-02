import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/ui.dart';
import '../session/session_controller.dart';

class LanguageView extends StatelessWidget {
  const LanguageView({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionController>();
    return Scaffold(
      backgroundColor: AppColors.brand,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const PartyMark(size: 62, onBrand: true),
              const SizedBox(height: 18),
              Text('app_name'.tr, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('app_tag'.tr, style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13)),
              const SizedBox(height: 28),
              Text('choose_language'.tr, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
              const SizedBox(height: 12),
              _LangBtn(label: 'हिन्दी', filled: true, onTap: () async {
                await session.applyLocale('hi');
                Get.offAllNamed(Routes.mobile);
              }),
              _LangBtn(label: 'English', onTap: () async {
                await session.applyLocale('en');
                Get.offAllNamed(Routes.mobile);
              }),
              _LangBtn(label: 'भोजपुरी', onTap: () async {
                await session.applyLocale('bho');
                Get.offAllNamed(Routes.mobile);
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _LangBtn extends StatelessWidget {
  const _LangBtn({required this.label, required this.onTap, this.filled = false});
  final String label;
  final VoidCallback onTap;
  final bool filled;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: filled
            ? FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.brand,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: onTap,
                child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              )
            : OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: onTap,
                child: Text(label, style: const TextStyle(fontSize: 16)),
              ),
      ),
    );
  }
}
