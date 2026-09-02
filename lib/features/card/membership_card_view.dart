import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/ui.dart';
import '../session/session_controller.dart';

class MembershipCardView extends StatelessWidget {
  const MembershipCardView({super.key});

  @override
  Widget build(BuildContext context) {
    final m = Get.find<SessionController>().member ?? {};
    final booth = m['booth'] as Map?;
    return Scaffold(
      appBar: AppBar(title: Text('membership_card'.tr), actions: [TextButton(onPressed: () {}, child: Text('share'.tr))]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.brand, borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const PartyMark(size: 26, onBrand: true),
                    const SizedBox(width: 8),
                    Text('app_name'.tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    Text('active_member'.tr, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(width: 56, height: 68, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m['fullName'] as String? ?? 'Suresh Kumar Yadav', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                          const SizedBox(height: 4),
                          MonoText(m['membershipNumber'] as String? ?? 'RPD-0004821936-7', color: Colors.white70),
                          const SizedBox(height: 8),
                          Text(
                            '${m['post'] ?? 'Panna Pramukh'} · ${booth?['code'] ?? 'B045'}\n${booth?['mandalName'] ?? 'Sihani'}, ${booth?['districtName'] ?? 'Ghaziabad'}\n${'valid_to'.trParams({'date': '31 Mar 2028'})}',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12, height: 1.45),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppColors.ink,
              ),
              child: const Icon(Icons.qr_code_2, color: Colors.white, size: 88),
            ),
          ),
          const SizedBox(height: 8),
          Text('qr_help'.tr, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.ink3, fontSize: 12)),
          const SizedBox(height: 16),
          PrimaryButton('show_scan'.tr, ghost: true, onTap: () {}),
        ],
      ),
    );
  }
}
