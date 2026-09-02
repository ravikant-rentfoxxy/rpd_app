import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/ui.dart';
import '../../data/remote/api_client.dart';

class WorkView extends StatelessWidget {
  const WorkView({super.key});

  @override
  Widget build(BuildContext context) {
    final data = Rxn<Map<String, dynamic>>();
    Get.find<ApiClient>().get('/work/ledger').then((r) {
      data.value = Map<String, dynamic>.from(r['data'] as Map);
    }).ignore();
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('my_work'.tr),
            const Text('August 2026', style: TextStyle(fontSize: 12, color: AppColors.ink3)),
          ],
        ),
      ),
      body: Obx(() {
        final d = data.value ?? {};
        final entries = (d['entries'] as List?) ?? [];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(child: DisplayText('${d['points'] ?? 410}', size: 42)),
            Center(child: Text('points_month'.tr, style: const TextStyle(color: AppColors.ink3))),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CardTitle('Rank ${d['mandalRank'] ?? 3} of ${d['mandalSize'] ?? 14}', sub: 'in Sihani mandal'),
                  const ScoreBar(value: 0.79),
                ],
              ),
            ),
            AppCard(tone: CardTone.flat, child: CardTitle('Rank ${d['boothRank'] ?? 1} of ${d['boothSize'] ?? 6}', sub: 'in Booth B045')),
            TextButton(onPressed: () => Get.toNamed(Routes.verification), child: Text('to_check'.tr)),
            ...entries.map((e) {
              final row = Map<String, dynamic>.from(e as Map);
              final debit = row['direction'] == 'DEBIT';
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: AvatarCircle(debit ? '!' : '✓', bg: debit ? AppColors.badBg : AppColors.brandWash, color: debit ? AppColors.bad : AppColors.brandLight),
                title: Text(row['note'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                trailing: MonoText('${debit ? '−' : ''}${row['points']}', size: 14, color: debit ? AppColors.bad : AppColors.ink),
              );
            }),
            AppCard(tone: CardTone.flat, child: CardTitle('18 members still pending', sub: 'Points arrive when they are verified and complete 90 days.')),
          ],
        );
      }),
    );
  }
}
