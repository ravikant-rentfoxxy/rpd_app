import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/ui.dart';
import '../../data/remote/api_client.dart';

class VerificationInboxView extends StatelessWidget {
  const VerificationInboxView({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <dynamic>[].obs;
    final error = Rxn<String>();
    Get.find<ApiClient>().get('/verification/inbox').then((r) {
      items.assignAll((r['data']['items'] as List?) ?? []);
    }).catchError((e) {
      error.value = e.toString();
    });
    return Scaffold(
      appBar: AppBar(title: Text('to_check'.tr)),
      body: Obx(() {
        if (error.value != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const DisplayText('Only for office bearers', center: true),
                  const SizedBox(height: 8),
                  const Text('Verification inbox opens for Mandal President and above.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.ink3)),
                  const SizedBox(height: 16),
                  PrimaryButton('booth_health'.tr, ghost: true, onTap: Get.back),
                ],
              ),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: items.map((raw) {
            final a = Map<String, dynamic>.from(raw as Map);
            return AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CardTitle('${a['type']} · ${a['booth']?['code'] ?? ''}', sub: '${a['actor']?['fullName'] ?? ''} · ${a['attendeeCount'] ?? 0} attended'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: PrimaryButton('accept'.tr, onTap: () => Get.find<ApiClient>().post('/verification/${a['id']}/accept'))),
                      const SizedBox(width: 8),
                      Expanded(child: PrimaryButton('ask_again'.tr, ghost: true, onTap: () {})),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        );
      }),
    );
  }
}
