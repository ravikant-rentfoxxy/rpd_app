import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/language_dropdown.dart';
import '../../core/widgets/ui.dart';
import '../activity/add_sheet.dart';
import '../events/event_api.dart';
import '../events/event_qr.dart';
import '../join/join_chrome.dart';
import '../session/session_controller.dart';
import '../tasks/tasks_view.dart';

class WorkView extends StatelessWidget {
  const WorkView({super.key});

  @override
  Widget build(BuildContext context) {
    return const TasksView(asTab: true);
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
      return Scaffold(
        appBar: _hubAppBar(),
        backgroundColor: HomeColors.paper,
        body: const SizedBox.shrink(),
      );
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
            DisplayText('what_did_you'.tr, size: 22),
            const SizedBox(height: 4),
            Text('pick_one'.tr, style: const TextStyle(color: AppColors.ink3, fontSize: 13)),
            const SizedBox(height: 16),
            const ActivityActionGrid(aspectRatio: 1.15),
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
            if (venue.isNotEmpty) ...[
              const SizedBox(height: 3),
              _Meta(icon: Icons.place_outlined, text: venue),
            ],
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
            Container(width: 6, height: 6, decoration: BoxDecoration(color: fg, shape: BoxShape.circle)),
            const SizedBox(width: 5),
          ],
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: fg)),
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
        Text('$value', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12.5, color: HomeColors.muted)),
      ],
    );
  }
}
