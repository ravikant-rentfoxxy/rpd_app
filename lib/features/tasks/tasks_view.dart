import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:rpd_app/features/join/join_chrome.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/api_error.dart';
import '../../core/utils/open_url.dart';
import '../../core/widgets/empty_card.dart';
import '../../core/widgets/iro_ui.dart';
import '../../core/widgets/ui.dart';
import '../events/event_api.dart';
import '../events/event_qr.dart';
import '../session/session_controller.dart';
import 'task_api.dart';
import '../../core/widgets/flash.dart';
import '../../core/constants/endpoints.dart';

class TasksView extends StatefulWidget {
  const TasksView({super.key, this.asTab = false});
  final bool asTab;

  @override
  State<TasksView> createState() => _TasksViewState();
}

class _TasksViewState extends State<TasksView> {
  final data = Rxn<Map<String, dynamic>>();
  final joinedEvents = <Map<String, dynamic>>[].obs;
  bool loading = true;
  final starting = <String>{};
  final checkingIn = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    await Future.wait([_loadTasks(), _loadJoinedEvents()]);
    if (mounted) setState(() => loading = false);
  }

  Future<void> _loadTasks() async {
    try {
      data.value = await fetchTasks();
    } catch (_) {
      data.value ??= {};
    }
  }

  Future<void> _loadJoinedEvents() async {
    try {
      joinedEvents.assignAll(await fetchJoinedEvents());
    } catch (_) {
      // Keep whatever was shown; tasks still render.
    }
  }

  Future<void> _checkIn(Map<String, dynamic> event) async {
    final id = '${event['id'] ?? ''}';
    if (id.isEmpty || checkingIn.contains(id)) return;
    setState(() => checkingIn.add(id));
    try {
      final session = Get.find<SessionController>();
      final located = await session.captureLocation();
      final lat = session.lat.value;
      final lng = session.lng.value;
      if (!located || lat == null || lng == null) {
        flash(
          'Error',
          session.locationDenied.value
              ? 'check_in_location_denied'.trFallback('Allow location access to check in')
              : 'check_in_location_off'.trFallback('Turn on location to check in'),
        );
        return;
      }
      final result = await checkInOrgEvent(id, latitude: lat, longitude: lng);
      final updated = Map<String, dynamic>.from(result['event'] as Map);
      final index = joinedEvents.indexWhere((row) => '${row['id']}' == id);
      if (index >= 0) joinedEvents[index] = updated;
      flash(
        result['alreadyIn'] == true
            ? 'check_in_already'.trFallback('Already checked in')
            : 'event_checked_in'.trFallback('Checked in'),
        '${updated['title'] ?? ''}',
      );
    } catch (e) {
      flash('Error', apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => checkingIn.remove(id));
    }
  }

  /// Scan the host's QR for this event, then check in. The scanner returns the
  /// updated event so the card flips to "checked in" without another fetch.
  Future<void> _scanCheckIn(Map<String, dynamic> event) async {
    final id = '${event['id'] ?? ''}';
    if (id.isEmpty) return;
    final result = await Get.to<Map<String, dynamic>>(() => EventScanCheckInView(event: event));
    if (result == null || !mounted) return;
    final index = joinedEvents.indexWhere((row) => '${row['id']}' == id);
    if (index >= 0) joinedEvents[index] = result;
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
            // Stretch, not start: otherwise each card sizes to its own title
            // and a list of them comes out ragged.
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              IroSectionHeading(
                title,
                top: 10,
                leading: Icon(
                  bad ? Icons.error_outline_rounded : Icons.checklist_rounded,
                  size: 17,
                  color: bad ? Iro.alert : Iro.greenMid,
                ),
              ),
              ...items.map((e) {
                final t = Map<String, dynamic>.from(e as Map);
                final assigner = t['assigner'] is Map ? Map<String, dynamic>.from(t['assigner'] as Map) : <String, dynamic>{};
                final sub = '${t['detail'] ?? t['description'] ?? assigner['fullName'] ?? t['assignerName'] ?? ''}'.trim();
                if (region) {
                  return RegionTaskCard(
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
        final events = joinedEvents.toList();
        final empty = events.isEmpty && region.isEmpty && overdue.isEmpty && today.isEmpty && week.isEmpty && ((groups['later'] as List?) ?? []).isEmpty;

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
                if (events.isNotEmpty) ...[
                  IroSectionHeading(
                    'joined_events'.trFallback('Events you joined'),
                    top: 10,
                    leading: const Icon(Icons.event_available_rounded, size: 17, color: Iro.greenMid),
                  ),
                  for (final event in events)
                    _JoinedEventCard(
                      event: event,
                      checkingIn: checkingIn.contains('${event['id'] ?? ''}'),
                      onCheckIn: () => _checkIn(event),
                      onScan: () => _scanCheckIn(event),
                    ),
                ],
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

/// A task handed to everyone in the region, rather than to one member.
///
/// Built on [IroCard] like the rest of the app. The old one was a plain white
/// box whose column shrink-wrapped, so two tasks side by side came out
/// different widths depending on how long their titles were.
class RegionTaskCard extends StatelessWidget {
  const RegionTaskCard({
    super.key,
    required this.task,
    required this.sub,
    required this.starting,
    required this.onStart,
  });
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
    final title = '${task['title'] ?? ''}'.trim();

    return IroCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(13, 13, 13, 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // A square mark so a list of tasks scans down the left edge
              // rather than as a wall of text.
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: started ? Iro.wash : Iro.mint,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  started ? Icons.timelapse_rounded : Icons.assignment_outlined,
                  size: 19,
                  color: started ? Iro.greenMid : Iro.green,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: iroDisplay(size: 15)),
                    if (sub.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        sub,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: iroLabel(size: 11.5, color: Iro.muted, weight: FontWeight.w500).copyWith(height: 1.45),
                      ),
                    ],
                  ],
                ),
              ),
              if (started) ...[
                const SizedBox(width: 8),
                IroChip('task_in_progress'.trFallback('In progress'), dense: true, size: 9.5, dot: true),
              ],
            ],
          ),
          if (from.isNotEmpty || count is num) ...[
            const SizedBox(height: 11),
            // One line each rather than side by side. A long name next to
            // "Nobody started yet" does not fit on a narrow phone, and the
            // Hindi and Bhojpuri both run longer than the English — stacking
            // them means neither can ever overflow, and each ellipsises.
            if (from.isNotEmpty)
              _TaskMeta(icon: Icons.person_outline_rounded, label: from, strong: true),
            // Nobody has picked it up yet, which is worth saying plainly
            // rather than as a bare "0 started".
            if (count is num) ...[
              if (from.isNotEmpty) const SizedBox(height: 5),
              _TaskMeta(
                icon: Icons.groups_outlined,
                label: count == 0
                    ? 'task_started_none'.trFallback('Nobody started yet')
                    : 'task_started_count'.trParams({'n': '$count'}),
              ),
            ],
          ],
          if (canStart && !started) ...[
            const SizedBox(height: 12),
            IroActionButton(
              label: 'start_task'.trFallback('Start'),
              icon: Icons.play_arrow_rounded,
              height: 42,
              enabled: !starting,
              onTap: starting ? null : onStart,
            ),
          ],
        ],
      ),
    );
  }
}

/// One fact about a task: an icon and a line of text that gives way rather than
/// running off the card.
class _TaskMeta extends StatelessWidget {
  const _TaskMeta({required this.icon, required this.label, this.strong = false});
  final IconData icon;
  final String label;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Iro.muted),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: iroLabel(
              size: 11,
              color: strong ? Iro.ink2 : Iro.muted,
              weight: strong ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _JoinedEventCard extends StatelessWidget {
  const _JoinedEventCard({
    required this.event,
    required this.checkingIn,
    required this.onCheckIn,
    required this.onScan,
  });
  final Map<String, dynamic> event;
  final bool checkingIn;
  final VoidCallback onCheckIn;
  final VoidCallback onScan;

  void _openMaps() {
    final lat = event['latitude'];
    final lng = event['longitude'];
    final query = lat is num && lng is num ? '$lat,$lng' : Uri.encodeComponent('${event['venue'] ?? ''}');
    openExternalUrl(ExternalLinks.mapsSearch(query), preferExternal: true);
  }

  @override
  Widget build(BuildContext context) {
    final startsAt = DateTime.tryParse('${event['startsAt'] ?? ''}')?.toLocal();
    final endsAt = DateTime.tryParse('${event['endsAt'] ?? ''}')?.toLocal();
    final checkedInAt = DateTime.tryParse('${event['checkedInAt'] ?? ''}')?.toLocal();
    final checkedIn = event['checkedIn'] == true;
    final notStarted = startsAt != null && DateTime.now().isBefore(startsAt);
    final title = '${event['title'] ?? ''}';
    final venue = '${event['venue'] ?? event['place'] ?? ''}'.trim();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: HomeColors.peach2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: HomeColors.peach),
                ),
                child: Column(
                  children: [
                    Text(
                      startsAt == null ? '--' : DateFormat('MMM').format(startsAt).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10.5,
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w800,
                        color: HomeColors.orangeDark,
                      ),
                    ),
                    Text(
                      startsAt == null ? '' : DateFormat('d').format(startsAt),
                      style: const TextStyle(fontSize: 20, height: 1.1, fontWeight: FontWeight.w900, color: HomeColors.ink),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: HomeColors.ink),
                    ),
                    const SizedBox(height: 4),
                    if (startsAt != null)
                      _EventMeta(
                        icon: Icons.schedule_rounded,
                        text: endsAt == null
                            ? DateFormat('EEE, hh:mm a').format(startsAt)
                            : '${DateFormat('EEE, hh:mm a').format(startsAt)} – ${DateFormat('hh:mm a').format(endsAt)}',
                      ),
                    if (venue.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      _EventMeta(icon: Icons.place_outlined, text: venue, onTap: _openMaps),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (checkedIn)
            Container(
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.okBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified_rounded, size: 18, color: AppColors.ok),
                  const SizedBox(width: 6),
                  Text(
                    checkedInAt == null
                        ? 'event_checked_in'.trFallback('Checked in')
                        : '${'event_checked_in'.trFallback('Checked in')} · ${DateFormat('hh:mm a').format(checkedInAt)}',
                    style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ok),
                  ),
                ],
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: FilledButton.icon(
                      onPressed: checkingIn ? null : onScan,
                      style: FilledButton.styleFrom(
                        backgroundColor: HomeColors.orange,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: HomeColors.orange.withValues(alpha: 0.6),
                        disabledForegroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      ),
                      icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                      label: Text(
                        'event_scan_qr'.trFallback('Scan QR'),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Fallback for when the host's QR is not to hand: location only.
                SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: checkingIn ? null : onCheckIn,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: HomeColors.navy,
                      side: const BorderSide(color: HomeColors.border, width: 1.5),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    ),
                    icon: checkingIn
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: HomeColors.navy),
                          )
                        : const Icon(Icons.my_location_rounded, size: 18),
                    label: Text(
                      checkingIn
                          ? 'check_in_locating'.trFallback('Locating…')
                          : 'event_check_in'.trFallback('Check in'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              notStarted
                  ? '${'check_in_opens'.trFallback('Check-in opens at')} ${DateFormat('hh:mm a').format(startsAt)}'
                  : 'event_check_in_hint'.trFallback('Be within 500 m of the venue to check in'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, color: notStarted ? HomeColors.orangeDark : HomeColors.muted),
            ),
          ],
        ],
      ),
    );
  }
}

class _EventMeta extends StatelessWidget {
  const _EventMeta({required this.icon, required this.text, this.onTap});
  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Icon(icon, size: 14, color: HomeColors.muted),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  color: onTap == null ? HomeColors.muted : HomeColors.navyMid,
                  fontWeight: onTap == null ? FontWeight.w400 : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
