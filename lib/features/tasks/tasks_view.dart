import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/ui.dart';
import '../../data/remote/api_client.dart';

class TasksView extends StatelessWidget {
  const TasksView({super.key});

  @override
  Widget build(BuildContext context) {
    final data = Rxn<Map<String, dynamic>>();
    Get.find<ApiClient>().get('/tasks').then((r) {
      data.value = Map<String, dynamic>.from(r['data'] as Map);
    }).ignore();
    return Scaffold(
      appBar: AppBar(title: Text('my_tasks'.tr)),
      body: Obx(() {
        final groups = Map<String, dynamic>.from(data.value?['groups'] as Map? ?? {});
        Widget group(String title, List items, {bool bad = false}) {
          if (items.isEmpty) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 6),
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink3, fontSize: 12)),
              ),
              ...items.map((e) {
                final t = Map<String, dynamic>.from(e as Map);
                return AppCard(
                  tone: bad ? CardTone.bad : CardTone.plain,
                  child: CardTitle(t['title'] as String? ?? '', sub: t['detail'] as String? ?? t['assigner']?['fullName'] as String?),
                );
              }),
            ],
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            group('overdue'.tr, (groups['overdue'] as List?) ?? [], bad: true),
            group('due_today'.tr, (groups['today'] as List?) ?? []),
            group('this_week'.tr, (groups['thisWeek'] as List?) ?? []),
          ],
        );
      }),
    );
  }
}
