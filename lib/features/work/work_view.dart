import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/api_error.dart';
import '../../core/utils/app_log.dart';
import '../../core/widgets/flash.dart';
import '../../core/widgets/iro_header.dart';
import '../../core/widgets/iro_ui.dart';
import '../../core/widgets/language_dropdown.dart';
import '../../core/widgets/ui.dart';
import '../../data/models/district_snapshot.dart';
import 'work_api.dart';
import '../activity/add_sheet.dart';
import '../events/event_api.dart';
import '../events/event_qr.dart';
import '../join/join_chrome.dart';
import '../session/session_controller.dart';

/// Work is the shift: what the member is on the hook for today, how far they
/// have got, and the next thing to walk to.
class WorkView extends StatefulWidget {
  const WorkView({super.key});

  @override
  State<WorkView> createState() => _WorkViewState();
}

enum _TaskTab { active, completed, drives }

class _WorkViewState extends State<WorkView> {
  _TaskTab tab = _TaskTab.active;
  final board = WorkBoard().obs;
  final loading = false.obs;
  bool sendingDuty = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    loading.value = true;
    try {
      board.value = await fetchWorkBoard();
    } catch (e, stack) {
      AppLog.error('work board failed', error: e, stack: stack, tag: 'WORK');
    } finally {
      loading.value = false;
    }
  }

  /// The toggle writes through to the server, so going on duty survives closing
  /// the app. The card redraws from whatever comes back, not from a local flip.
  Future<void> _toggleDuty() async {
    if (sendingDuty) return;
    setState(() => sendingDuty = true);
    try {
      final shift = await setOnDuty(!board.value.shift.onDuty);
      board.value = WorkBoard(
        shift: shift,
        rank: board.value.rank,
        active: board.value.active,
        completed: board.value.completed,
        drives: board.value.drives,
      );
    } catch (e) {
      flash('Error', apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => sendingDuty = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionController>();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: iroOverlay,
      child: Scaffold(
        backgroundColor: Iro.mint,
        body: Column(
          children: [
            SafeArea(bottom: false, child: IroTopBar(section: 'work'.tr)),
            Expanded(
              child: RefreshIndicator(
                color: Iro.bright,
                onRefresh: _load,
                child: Obx(() {
                  final data = board.value;
                  final tasks = switch (tab) {
                    _TaskTab.active => data.active,
                    _TaskTab.completed => data.completed,
                    _TaskTab.drives => data.drives,
                  };
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 104),
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      _ShiftCard(shift: data.shift, busy: sendingDuty, onToggle: _toggleDuty),
                      _RankCard(rank: data.rank),
                      const SizedBox(height: 2),
                      IroSegmented(
                        items: [
                          '${'active_tasks'.tr} (${data.active.length})',
                          '${'completed'.tr} (${data.completed.length})',
                          '${'district_drives'.tr} (${data.drives.length})',
                        ],
                        index: _TaskTab.values.indexOf(tab),
                        onChanged: (i) => setState(() => tab = _TaskTab.values[i]),
                      ),
                      const SizedBox(height: 14),
                      for (final row in tasks) _TaskCard(task: row),
                      if (tasks.isEmpty && !loading.value)
                        Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: Text(
                            'no_tasks_today'.tr,
                            textAlign: TextAlign.center,
                            style: iroLabel(size: 13, color: Iro.muted),
                          ),
                        ),
                      const SizedBox(height: 4),
                      if (session.canCreateOrgEvents)
                        IroActionButton(
                          label: 'create_task'.tr,
                          icon: Icons.add_task_rounded,
                          onTap: () async {
                            await Get.toNamed(Routes.createTask);
                            await _load();
                          },
                        ),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Today's shift, with the duty dial on a dark band so it reads at arm's
/// length in sunlight.
class _ShiftCard extends StatelessWidget {
  const _ShiftCard({required this.shift, required this.busy, required this.onToggle});
  final WorkShift shift;
  final bool busy;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final onDuty = shift.onDuty;
    final since = shift.onDutySince;
    final line = onDuty && since != null
        ? 'on_duty_since'.trParams({'time': DateFormat('h:mm a').format(since)})
        : shift.sector.isEmpty
        ? ''
        : '${'shift_label'.tr}: ${shift.sector}';

    return IroCard(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(9, 8, 9, 0),
            child: Row(
              children: [
                Expanded(
                  child: IroChip(
                    onDuty ? 'field_shift_active'.tr.toUpperCase() : 'away'.tr.toUpperCase(),
                    dot: true,
                    size: 9.5,
                    fg: onDuty ? Iro.greenMid : Iro.muted,
                    bg: onDuty ? Iro.wash : Iro.wash2,
                  ),
                ),
                if (shift.streakDays > 0)
                  IroChip(
                    'day_streak'.trParams({'n': '${shift.streakDays}'}),
                    icon: Icons.local_fire_department_rounded,
                    size: 9.5,
                    fg: Iro.gold,
                    bg: Iro.goldWash,
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(9, 9, 9, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (shift.sector.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(color: Iro.wash2, borderRadius: BorderRadius.circular(7)),
                    child: Text(
                      shift.sector,
                      style: iroLabel(size: 10.5, color: Iro.ink2, weight: FontWeight.w700),
                    ),
                  ),
                if (line.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded, size: 14, color: Iro.greenMid),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          line,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: iroLabel(size: 11.5, color: Iro.ink2, weight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
            decoration: BoxDecoration(gradient: Iro.headerGradient, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                IroRing(value: shift.saturation, size: 46),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'duty_done'.trParams({'done': '${shift.done}', 'total': '${shift.total}'}),
                        style: iroDisplay(size: 15, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'duty_saturation'.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: iroLabel(size: 10.5, color: Iro.onDark, weight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: onDuty ? Iro.leaf : const Color(0x33FFFFFF),
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: busy ? null : onToggle,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            onDuty ? Icons.check_circle_rounded : Icons.pause_circle_outline_rounded,
                            size: 14,
                            color: onDuty ? Iro.forest : Colors.white,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            busy ? '…' : (onDuty ? 'on_duty'.tr : 'away'.tr),
                            style: iroLabel(
                              size: 11,
                              color: onDuty ? Iro.forest : Colors.white,
                              weight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Rank, tier and the distance to the next level — the same tasks-and-points
/// ladder the organisation scores members on.
class _RankCard extends StatelessWidget {
  const _RankCard({required this.rank});
  final WorkRank rank;

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionController>();
    final member = session.member ?? {};
    final booth = member['booth'] is Map ? Map<String, dynamic>.from(member['booth'] as Map) : const {};
    final district = '${member['districtName'] ?? booth['districtName'] ?? ''}'.trim();
    final area = rank.area.isNotEmpty
        ? rank.area
        : district.isEmpty
        ? 'your_district'.tr
        : '$district ${'district'.tr}';

    return IroCard(
      padding: const EdgeInsets.fromLTRB(13, 13, 13, 13),
      onTap: () => Get.toNamed(Routes.tasks),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(shape: BoxShape.circle, gradient: Iro.goldGradient),
                child: Center(
                  child: Text('${rank.rank}', style: iroDisplay(size: 18, color: Iro.forest)),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(area, maxLines: 1, overflow: TextOverflow.ellipsis, style: iroDisplay(size: 16)),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        IroChip('tier_label'.trParams({'n': '${rank.tier}'}), dense: true, size: 9.5),
                        if (rank.xpToday > 0) ...[
                          const SizedBox(width: 6),
                          IroChip(
                            'xp_today'.trParams({'n': '${rank.xpToday}'}),
                            dense: true,
                            size: 9.5,
                            fg: Iro.gold,
                            bg: Iro.goldWash,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Text('#${rank.rank}', style: iroDisplay(size: 22, color: Iro.gold)),
            ],
          ),
          const SizedBox(height: 11),
          Text(
            'xp_needed'.trParams({'n': '${rank.xpRemaining}', 'level': rank.nextLevelName}),
            style: iroLabel(size: 11.5, color: Iro.muted, weight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          IroMeter(value: rank.progress),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: Text(
                  'level_line'.trParams({'n': '${rank.level}', 'name': rank.levelName}),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: iroLabel(size: 11, color: Iro.ink2, weight: FontWeight.w700),
                ),
              ),
              Text(
                '${groupIndian(rank.xp)} / ${groupIndian(rank.xpForNext)} XP',
                style: iroLabel(size: 11, color: Iro.muted, weight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One task, whatever list it came from. Drives carry no due date, so the row
/// shows who called them instead.
class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task});
  final Map<String, dynamic> task;

  @override
  Widget build(BuildContext context) {
    final title = '${task['title'] ?? ''}'.trim();
    final detail = '${task['detail'] ?? ''}'.trim();
    final priority = '${task['priority'] ?? ''}'.toUpperCase();
    final status = '${task['status'] ?? ''}'.toUpperCase();
    final assigner = '${task['assignerName'] ?? ''}'.trim();
    final dueAt = DateTime.tryParse('${task['dueAt'] ?? ''}')?.toLocal();
    final drive = priority == 'DRIVE';
    final (fg, bg) = switch (priority) {
      'URGENT' || 'HIGH' => (Iro.alert, Iro.alertWash),
      'DRIVE' => (Iro.sky, Iro.skyWash),
      _ when status == 'DONE' => (Iro.greenMid, Iro.wash),
      _ => (Iro.gold, Iro.goldWash),
    };
    final label = status == 'DONE' ? 'completed'.tr.toUpperCase() : priority;

    return IroCard(
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 13),
      onTap: () => Get.toNamed(Routes.tasks),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (label.isNotEmpty) IroChip(label, dense: true, size: 9, fg: fg, bg: bg),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Icon(drive ? Icons.campaign_outlined : Icons.schedule_rounded, size: 12.5, color: Iro.muted),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        drive
                            ? assigner
                            : dueAt == null
                            ? ''
                            : DateFormat('dd MMM · h:mm a').format(dueAt),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: iroLabel(size: 10.5, color: Iro.muted, weight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: Iro.wash2, borderRadius: BorderRadius.circular(9)),
                child: Icon(drive ? Icons.flag_outlined : Icons.assignment_outlined, size: 15, color: Iro.greenMid),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(title.isEmpty ? 'my_tasks'.tr : title, style: iroDisplay(size: 16.5).copyWith(height: 1.28)),
          if (detail.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
              decoration: BoxDecoration(
                color: Iro.wash2,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: Iro.line),
              ),
              child: _TaskLine(icon: Icons.adjust_rounded, label: 'target_label'.tr, value: detail),
            ),
          ],
          if (!drive && assigner.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person_outline_rounded, size: 13, color: Iro.greenMid),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    assigner,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: iroLabel(size: 11, color: Iro.greenMid, weight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TaskLine extends StatelessWidget {
  const _TaskLine({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: Iro.greenMid),
        const SizedBox(width: 7),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: iroLabel(size: 11.5, color: Iro.ink2, weight: FontWeight.w600),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: iroLabel(size: 11.5, color: Iro.muted, weight: FontWeight.w600),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ActivityHubView extends StatefulWidget {
  const ActivityHubView({super.key});

  @override
  State<ActivityHubView> createState() => _ActivityHubViewState();
}

class _ActivityHubViewState extends State<ActivityHubView> {
  final hosted = <Map<String, dynamic>>[].obs;
  Worker? _homeWorker;

  @override
  void initState() {
    super.initState();
    final session = Get.find<SessionController>();
    // Only office bearers can create events, so nobody else has a "Your events" list.
    if (!session.canCreateOrgEvents) return;
    _loadHosted();
    // Creating an event reloads home, so refresh this list when that happens.
    _homeWorker = ever(session.home, (_) => _loadHosted());
  }

  @override
  void dispose() {
    _homeWorker?.dispose();
    super.dispose();
  }

  Future<void> _loadHosted() async {
    try {
      final events = await fetchHostedEvents();
      final now = DateTime.now();
      DateTime parse(Map e, String key) => DateTime.tryParse('${e[key] ?? ''}')?.toLocal() ?? now;
      final active = events.where((e) => parse(e, 'endsAt').isAfter(now)).toList()
        ..sort((a, b) => parse(a, 'startsAt').compareTo(parse(b, 'startsAt')));
      final ended = events.where((e) => !parse(e, 'endsAt').isAfter(now)).toList()
        ..sort((a, b) => parse(b, 'startsAt').compareTo(parse(a, 'startsAt')));
      hosted.assignAll([...active, ...ended]);
    } catch (_) {
      // Leave the current list; the activity grid still works.
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionController>();
    if (session.needsVerification) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (session.needsVerification) session.openJoinVerification();
      });
      return Scaffold(appBar: _hubAppBar(), backgroundColor: HomeColors.paper, body: const SizedBox.shrink());
    }
    return Scaffold(
      backgroundColor: HomeColors.paper,
      appBar: _hubAppBar(),
      body: RefreshIndicator(
        color: HomeColors.orange,
        onRefresh: _loadHosted,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
          children: [
            _SectionHeading(title: 'what_did_you'.tr, hint: 'tap_to_open_form'.tr),
            const SizedBox(height: 4),
            Text('pick_one'.tr, style: const TextStyle(color: AppColors.ink3, fontSize: 13)),
            const SizedBox(height: 14),
            const ActivityActionGrid(aspectRatio: 1.55),
            const SizedBox(height: 12),
            const _LocationStampCard(),
            // Shown only to members who have created events.
            Obx(() {
              if (hosted.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Text(
                    'your_events'.trFallback('Your events').toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: HomeColors.muted,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final event in hosted) _HostedEventCard(event: event),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// Heading with the small upright accent bar, and a muted hint on the right.
class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, this.hint});
  final String title;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 5,
          height: 18,
          decoration: BoxDecoration(color: HomeColors.teal, borderRadius: BorderRadius.circular(999)),
        ),
        const SizedBox(width: 9),
        Expanded(child: DisplayText(title, size: 20)),
        if (hint != null) ...[
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              hint!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 11.5, color: HomeColors.muted),
            ),
          ),
        ],
      ],
    );
  }
}

/// What gets stamped onto anything recorded here: the member's area and
/// whether location is actually available. Tapping retries the permission.
class _LocationStampCard extends StatelessWidget {
  const _LocationStampCard();

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionController>();
    return Obx(() {
      final member = session.member ?? {};
      final booth = member['booth'] is Map ? Map<String, dynamic>.from(member['booth'] as Map) : const {};
      final area = [
        '${booth['name'] ?? ''}'.trim(),
        '${member['assemblyName'] ?? booth['assemblyName'] ?? ''}'.trim(),
        '${member['districtName'] ?? booth['districtName'] ?? ''}'.trim(),
      ].firstWhere((value) => value.isNotEmpty, orElse: () => '');
      final located = session.lat.value != null && session.lng.value != null;
      final tint = located ? AppColors.ok : AppColors.warn;

      return Material(
        color: HomeColors.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: HomeColors.border, width: 1.5),
        ),
        child: InkWell(
          onTap: located ? null : session.captureLocation,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    located ? Icons.location_on_outlined : Icons.location_off_outlined,
                    color: tint,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        area.isEmpty ? 'geo_current_area'.tr : '${'geo_current_area'.tr}: $area',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        located ? 'geo_tagging_on'.tr : 'geo_tagging_off'.tr,
                        maxLines: 2,
                        style: const TextStyle(fontSize: 11.5, color: HomeColors.muted, height: 1.25),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(located ? Icons.verified_rounded : Icons.refresh_rounded, color: tint, size: 20),
              ],
            ),
          ),
        ),
      );
    });
  }
}

PreferredSizeWidget _hubAppBar() {
  return OrganicAppBar(
    title: 'record_activity'.tr,
    actions: const [
      Padding(
        padding: EdgeInsets.only(right: 12),
        child: Center(child: LanguageDropdown(pill: true)),
      ),
    ],
  );
}

enum _EventPhase { upcoming, live, ended }

class _HostedEventCard extends StatelessWidget {
  const _HostedEventCard({required this.event});
  final Map<String, dynamic> event;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startsAt = DateTime.tryParse('${event['startsAt'] ?? ''}')?.toLocal();
    final endsAt = DateTime.tryParse('${event['endsAt'] ?? ''}')?.toLocal();
    final phase = endsAt != null && !endsAt.isAfter(now)
        ? _EventPhase.ended
        : startsAt != null && !startsAt.isAfter(now)
        ? _EventPhase.live
        : _EventPhase.upcoming;
    final ended = phase == _EventPhase.ended;
    final joined = (event['joining'] as num?)?.toInt() ?? 0;
    final checkedIn = (event['checkedInCount'] as num?)?.toInt() ?? 0;
    final venue = '${event['venue'] ?? event['place'] ?? ''}'.trim();
    final type = '${event['type'] ?? ''}';
    final title = '${event['title'] ?? ''}'.trim().isEmpty ? 'activity_$type'.trFallback(type) : '${event['title']}';

    String timeText() {
      if (startsAt == null) return '${event['when'] ?? ''}';
      final start = DateFormat('dd MMM · hh:mm a').format(startsAt);
      return endsAt == null ? start : '$start – ${DateFormat('hh:mm a').format(endsAt)}';
    }

    return AppCard(
      onTap: () => Get.toNamed(Routes.eventDetail, arguments: event),
      child: Opacity(
        opacity: ended ? 0.72 : 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: HomeColors.ink),
                  ),
                ),
                const SizedBox(width: 8),
                _PhasePill(phase: phase),
              ],
            ),
            const SizedBox(height: 6),
            _Meta(icon: Icons.schedule_rounded, text: timeText()),
            if (venue.isNotEmpty) ...[const SizedBox(height: 3), _Meta(icon: Icons.place_outlined, text: venue)],
            const SizedBox(height: 10),
            const Divider(height: 1, thickness: 1, color: HomeColors.border),
            const SizedBox(height: 10),
            Row(
              children: [
                _Stat(
                  icon: Icons.groups_outlined,
                  value: joined,
                  label: 'event_joined_count'.trFallback('joined'),
                  color: HomeColors.navyMid,
                ),
                const SizedBox(width: 18),
                _Stat(
                  icon: Icons.verified_outlined,
                  value: checkedIn,
                  label: 'event_checked_in_count'.trFallback('checked in'),
                  color: AppColors.ok,
                ),
                const Spacer(),
                // Members scan this to check in, so keep it on the card itself.
                if (!ended)
                  TextButton.icon(
                    onPressed: () => showEventQrSheet(context, event),
                    style: TextButton.styleFrom(
                      foregroundColor: HomeColors.navy,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                    label: Text(
                      'event_show_qr'.trFallback('QR'),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                    ),
                  ),
                const Icon(Icons.chevron_right_rounded, color: HomeColors.muted2),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PhasePill extends StatelessWidget {
  const _PhasePill({required this.phase});
  final _EventPhase phase;

  @override
  Widget build(BuildContext context) {
    final (label, fg, bg) = switch (phase) {
      _EventPhase.live => ('event_live'.trFallback('Live now'), AppColors.ok, AppColors.okBg),
      _EventPhase.upcoming => ('event_upcoming'.trFallback('Upcoming'), HomeColors.orangeDark, HomeColors.peach2),
      _EventPhase.ended => ('event_ended'.trFallback('Ended'), AppColors.ink3, AppColors.sunk),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (phase == _EventPhase.live) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: fg),
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: HomeColors.muted),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12.5, color: HomeColors.muted),
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label, required this.color});
  final IconData icon;
  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 5),
        Text(
          '$value',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12.5, color: HomeColors.muted)),
      ],
    );
  }
}
