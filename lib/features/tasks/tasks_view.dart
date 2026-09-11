import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rpd_app/features/join/join_chrome.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/ui.dart';
import 'task_api.dart';

class TasksView extends StatefulWidget {
  const TasksView({super.key, this.asTab = false});
  final bool asTab;

  @override
  State<TasksView> createState() => _TasksViewState();
}

class _TasksViewState extends State<TasksView> {
  final data = Rxn<Map<String, dynamic>>();
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      data.value = await fetchTasks();
    } catch (_) {
      data.value ??= {};
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeColors.paper,
      appBar: OrganicAppBar(
        title: widget.asTab ? 'work'.tr : 'my_tasks'.tr,
        automaticallyImplyLeading: !widget.asTab,
      ),
      body: Obx(() {
        final groups = Map<String, dynamic>.from(data.value?['groups'] as Map? ?? {});
        Widget group(String title, List items, {bool bad = false}) {
          if (items.isEmpty) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 6),
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: bad ? HomeColors.orange : HomeColors.muted,
                    fontSize: 11,
                  ),
                ),
              ),
              ...items.map((e) {
                final t = Map<String, dynamic>.from(e as Map);
                final assigner = t['assigner'] is Map ? Map<String, dynamic>.from(t['assigner'] as Map) : <String, dynamic>{};
                final sub = '${t['detail'] ?? t['description'] ?? assigner['fullName'] ?? t['assignerName'] ?? ''}'.trim();
                return AppCard(
                  tone: bad ? CardTone.warn : CardTone.plain,
                  child: CardTitle(t['title'] as String? ?? '', sub: sub.isEmpty ? null : sub),
                );
              }),
            ],
          );
        }

        if (loading && data.value == null) {
          return const Center(child: CircularProgressIndicator(color: HomeColors.orange));
        }

        final region = (groups['region'] as List?) ?? [];
        final overdue = (groups['overdue'] as List?) ?? [];
        final today = (groups['today'] as List?) ?? [];
        final week = (groups['thisWeek'] as List?) ?? [];
        final later = (groups['later'] as List?) ?? [];
        final empty = region.isEmpty && overdue.isEmpty && today.isEmpty && week.isEmpty && later.isEmpty;

        return RefreshIndicator(
          color: HomeColors.orange,
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (empty)
                Padding(
                  padding: const EdgeInsets.only(top: 48),
                  child: Text(
                    'no_tasks'.trFallback('No tasks yet'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: HomeColors.muted),
                  ),
                )
              else ...[
                group('region_tasks'.trFallback('Region tasks'), region),
                group('overdue'.tr, overdue, bad: true),
                group('due_today'.tr, today),
                group('this_week'.tr, week),
              ],
            ],
          ),
        );
      }),
    );
  }
}
