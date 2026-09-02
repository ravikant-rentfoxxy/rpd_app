import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/ui.dart';
import '../../data/remote/api_client.dart';
import '../session/session_controller.dart';

class BoothHealthView extends StatelessWidget {
  const BoothHealthView({super.key});

  @override
  Widget build(BuildContext context) {
    final booth = Get.find<SessionController>().member?['booth'] as Map?;
    final id = booth?['id'] as String?;
    final data = Rxn<Map<String, dynamic>>();
    if (id != null) {
      Get.find<ApiClient>().get('/booths/$id/health').then((r) {
        data.value = Map<String, dynamic>.from(r['data'] as Map);
      }).ignore();
    }
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(booth?['code'] as String? ?? 'Booth B045'),
            MonoText('Part ${booth?['partNumber'] ?? '132'} · ${booth?['village'] ?? 'Sihani'}'),
          ],
        ),
      ),
      body: Obx(() {
        final score = data.value?['score'] ?? booth?['healthScore'] ?? 68;
        final components = (data.value?['components'] as List?) ??
            [
              {'label': 'Committee formed', 'score': 25, 'maxScore': 25, 'detail': 'all 11 posts filled'},
              {'label': 'Panna Pramukhs appointed', 'score': 9, 'maxScore': 25, 'detail': 'only 4 of 11 pages covered'},
              {'label': 'Members against voters', 'score': 14, 'maxScore': 20, 'detail': '182 members, 1,240 voters'},
              {'label': 'Recent activity', 'score': 20, 'maxScore': 20, 'detail': 'last verified 2 days ago'},
            ];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                DisplayText('$score', size: 42, color: AppColors.warn),
                const SizedBox(width: 8),
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text('of 100 · was 61 last month', style: TextStyle(color: AppColors.ink3)),
                ),
              ],
            ),
            const Pill('Needs attention', tone: PillTone.warn),
            const SizedBox(height: 16),
            ...components.map((raw) {
              final c = Map<String, dynamic>.from(raw as Map);
              final ratio = ((c['score'] as num?) ?? 0) / ((c['maxScore'] as num?) ?? 1);
              final color = ratio < 0.5 ? AppColors.bad : ratio < 0.8 ? AppColors.warn : AppColors.ok;
              return AppCard(
                tone: ratio < 0.5 ? CardTone.bad : CardTone.plain,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c['label'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ScoreBar(value: ratio, color: color),
                    Text(c['detail'] as String? ?? '', style: const TextStyle(color: AppColors.ink3, fontSize: 12)),
                  ],
                ),
              );
            }),
            PrimaryButton('appoint_panna'.tr, onTap: () {}),
          ],
        );
      }),
    );
  }
}
