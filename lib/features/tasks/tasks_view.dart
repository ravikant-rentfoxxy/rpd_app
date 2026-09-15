import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rpd_app/features/join/join_chrome.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/api_error.dart';
import '../../core/widgets/empty_card.dart';
import '../../core/widgets/ui.dart';
import 'task_api.dart';
import '../../core/widgets/flash.dart';

class TasksView extends StatefulWidget {
  const TasksView({super.key, this.asTab = false});
  final bool asTab;

  @override
  State<TasksView> createState() => _TasksViewState();
}

class _TasksViewState extends State<TasksView> {
  final data = Rxn<Map<String, dynamic>>();
  bool loading = true;
  final starting = <String>{};

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

  Future<void> _start(Map<String, dynamic> task) async {
    final id = '${task['id'] ?? ''}';
    if (id.isEmpty || starting.contains(id)) return;
    setState(() => starting.add(id));
    try {
      final updated = await startOrgTask(id);
      final groups = Map<String, dynamic>.from(data.value?['groups'] as Map? ?? {});
      final region = [...((groups['region'] as List?) ?? [])];
      final index = region.indexWhere((item) => '${(item as Map)['id']}' == id);
      if (index >= 0) region[index] = updated;
      groups['region'] = region;
      data.value = {...?data.value, 'groups': groups};
      data.refresh();
      flash('task_started'.trFallback('Task started'), 'task_started_sub'.trFallback('This task is now in progress.'));
    } catch (e) {
      flash('Error', apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => starting.remove(id));
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
        Widget group(String title, List items, {bool bad = false, bool region = false}) {
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
                if (region) {
                  return _RegionTaskCard(
                    task: t,
                    sub: sub,
                    starting: starting.contains('${t['id'] ?? ''}'),
                    onStart: () => _start(t),
                  );
                }
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
        final empty = region.isEmpty && overdue.isEmpty && today.isEmpty && week.isEmpty && ((groups['later'] as List?) ?? []).isEmpty;

        return RefreshIndicator(
          color: HomeColors.orange,
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (empty)
                Padding(
                  padding: const EdgeInsets.only(top: 36),
                  child: AppEmptyCard(
                    icon: Icons.task_alt_rounded,
                    title: 'no_tasks'.trFallback('No tasks yet'),
                    sub: 'create_task_sub'.trFallback('Assign work to members in your region'),
                  ),
                )
              else ...[
                group('region_tasks'.trFallback('Region tasks'), region, region: true),
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

class _RegionTaskCard extends StatelessWidget {
  const _RegionTaskCard({required this.task, required this.sub, required this.starting, required this.onStart});
  final Map<String, dynamic> task;
  final String sub;
  final bool starting;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final started = task['started'] == true;
    final canStart = task['canStart'] == true;
    final count = task['startedCount'];
    final from = '${task['assignerName'] ?? ''}'.trim();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardTitle(task['title'] as String? ?? '', sub: sub.isEmpty ? null : sub),
          if (from.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '${'assigned_by'.trFallback('From')} $from',
              style: const TextStyle(fontSize: 12, color: HomeColors.muted),
            ),
          ],
          if (count is num) ...[
            const SizedBox(height: 4),
            Text(
              'task_started_count'.trParams({'n': '$count'}),
              style: const TextStyle(fontSize: 12, color: HomeColors.muted),
            ),
          ],
          if (canStart || started) ...[
            const SizedBox(height: 12),
            if (started)
              Text(
                'task_in_progress'.trFallback('In progress'),
                style: const TextStyle(fontWeight: FontWeight.w800, color: HomeColors.orange),
              )
            else
              SizedBox(
                height: 42,
                child: FilledButton(
                  onPressed: starting ? null : onStart,
                  style: FilledButton.styleFrom(
                    backgroundColor: HomeColors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  ),
                  child: starting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text('start_task'.trFallback('Start'), style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
