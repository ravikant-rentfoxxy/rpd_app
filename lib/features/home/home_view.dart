import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/ui.dart';
import '../session/session_controller.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionController>();
    session.loadHome();
    return Obx(() {
      final member = session.member ?? {};
      final stats = Map<String, dynamic>.from(session.home.value?['stats'] as Map? ?? {});
      final first = (member['fullName'] as String? ?? 'Suresh').split(' ').first;
      final booth = member['booth'] as Map?;
      final queue = session.syncCount.value;
      return RefreshIndicator(
        onRefresh: session.loadHome,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (queue > 0)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(vertical: 8),
                color: AppColors.warnBg,
                child: Text(
                  'queue_bar'.trParams({'n': '$queue'}),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.warn, fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
            SafeArea(
              bottom: false,
              child: Row(
                children: [
                  AvatarCircle(_initials(member['fullName'] as String?)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('namaste'.trParams({'name': first}), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        MonoText('${booth?['code'] ?? 'B045'} · ${member['post'] ?? 'PANNA_PRAMUKH'}'),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.toNamed(Routes.card),
                    icon: const Badge(label: Text('2'), child: Icon(Icons.notifications_none)),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(child: _stat('${stats['membersAdded'] ?? 104}', 'members_added'.tr)),
                const SizedBox(width: 8),
                Expanded(child: _stat('${stats['meetingsHeld'] ?? 18}', 'meetings_held'.tr)),
              ],
            ),
            const SizedBox(height: 8),
            AppCard(
              tone: CardTone.warn,
              onTap: () => Get.toNamed(Routes.tasks),
              child: CardTitle(
                'tasks_due'.trParams({'n': '${(session.home.value?['tasksDueToday'] as List?)?.length ?? 2}'}),
                sub: 'Booth committee list · Griha sampark report',
              ),
            ),
            AppCard(
              onTap: () => Get.toNamed(Routes.boothHealth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('your_booth'.trParams({'score': '${stats['boothScore'] ?? booth?['healthScore'] ?? 68}'}),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  ScoreBar(value: ((stats['boothScore'] ?? booth?['healthScore'] ?? 68) as num) / 100, color: AppColors.warn),
                  Text(stats['boothWeakest'] as String? ?? 'Weakest part: only 4 of 11 Panna Pramukhs appointed',
                      style: const TextStyle(color: AppColors.ink3, fontSize: 12)),
                ],
              ),
            ),
            AppCard(
              child: CardTitle(
                'rank_line'.trParams({'rank': '${stats['mandalRank'] ?? 3}', 'size': '${stats['mandalSize'] ?? 14}'}),
                sub: '${stats['points'] ?? 410} ${'points_month'.tr}',
              ),
            ),
            AppCard(
              tone: CardTone.flat,
              child: CardTitle('Last activity 2 days ago', sub: 'Booth meeting · verified by Mandal President'),
            ),
          ],
        ),
      );
    });
  }

  Widget _stat(String n, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.rule),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DisplayText(n, size: 22),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.ink3)),
        ],
      ),
    );
  }
}

String _initials(String? name) {
  final parts = (name ?? 'SY').trim().split(RegExp(r'\s+'));
  if (parts.length == 1) return parts.first.substring(0, parts.first.length.clamp(0, 2)).toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}
