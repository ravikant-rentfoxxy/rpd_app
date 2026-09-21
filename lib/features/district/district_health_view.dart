import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:rpd_app/features/join/join_chrome.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/api_error.dart';
import '../../core/widgets/empty_card.dart';
import '../../core/widgets/ui.dart';
import 'district_api.dart';

/// Colour per activity type, kept stable across the bars and the list.
const _typeColors = {
  'MEETING': HomeColors.orange,
  'GRIHA_SAMPARK': HomeColors.navyMid,
  'PUBLIC_PROGRAMME': Color(0xFF1B7350),
  'TRAINING': Color(0xFF7B5CF0),
  'ADD_MEMBER': Color(0xFFC45A12),
  'OTHER': HomeColors.muted,
};

Color _typeColor(String type) => _typeColors[type] ?? HomeColors.muted;

String _typeLabel(String type) => 'activity_$type'.trFallback(switch (type) {
      'MEETING' => 'Meeting',
      'GRIHA_SAMPARK' => 'Griha sampark',
      'PUBLIC_PROGRAMME' => 'Public programme',
      'TRAINING' => 'Training',
      'ADD_MEMBER' => 'Member added',
      _ => 'Other',
    });

class DistrictHealthView extends StatefulWidget {
  const DistrictHealthView({super.key});

  @override
  State<DistrictHealthView> createState() => _DistrictHealthViewState();
}

class _DistrictHealthViewState extends State<DistrictHealthView> {
  final data = Rxn<Map<String, dynamic>>();
  final loading = true.obs;
  final error = ''.obs;
  final days = Rxn<int>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    loading.value = true;
    try {
      data.value = await fetchDistrictHealth(days: days.value);
      error.value = '';
    } catch (e) {
      error.value = apiErrorMessage(e);
    } finally {
      loading.value = false;
    }
  }

  void _setRange(int? value) {
    if (days.value == value) return;
    days.value = value;
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeColors.paper,
      appBar: OrganicAppBar(title: 'district_health'.tr),
      body: Obx(() {
        final payload = data.value;
        if (loading.value && payload == null) {
          return const Center(child: CircularProgressIndicator(color: HomeColors.orange));
        }
        if (payload == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: AppEmptyCard(
                icon: Icons.insights_outlined,
                title: error.value.isEmpty ? 'district_health'.tr : error.value,
              ),
            ),
          );
        }

        final district = Map<String, dynamic>.from(payload['district'] as Map? ?? {});
        final totals = Map<String, dynamic>.from(payload['totals'] as Map? ?? {});
        final byType = (payload['byType'] as List? ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        final activities =
            (payload['activities'] as List? ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        final from = DateTime.tryParse('${payload['from'] ?? ''}')?.toLocal();

        return RefreshIndicator(
          color: HomeColors.orange,
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
            children: [
              _Summary(district: district, totals: totals, from: from),
              const SizedBox(height: 14),
              _RangeChips(selected: days.value, onSelect: _setRange),
              const SizedBox(height: 18),
              _SectionTitle('activity_mix'.trFallback('Activity mix')),
              const SizedBox(height: 8),
              if (byType.every((row) => ((row['count'] as num?) ?? 0) == 0))
                AppEmptyCard(
                  icon: Icons.bar_chart_rounded,
                  title: 'district_no_activity'.trFallback('No activity recorded in this period yet.'),
                )
              else
                AppCard(
                  child: Column(
                    children: [
                      for (final row in byType)
                        _TypeBar(
                          type: '${row['type']}',
                          count: (row['count'] as num?)?.toInt() ?? 0,
                          percent: (row['percent'] as num?)?.toDouble() ?? 0,
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 18),
              _SectionTitle(
                '${'district_activities'.trFallback('Activities in your district')} (${activities.length})',
              ),
              const SizedBox(height: 8),
              if (activities.isEmpty)
                AppEmptyCard(
                  icon: Icons.history_rounded,
                  title: 'district_no_activity'.trFallback('No activity recorded in this period yet.'),
                )
              else
                for (final activity in activities) _ActivityRow(activity: activity),
            ],
          ),
        );
      }),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: HomeColors.muted),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.district, required this.totals, required this.from});
  final Map<String, dynamic> district;
  final Map<String, dynamic> totals;
  final DateTime? from;

  @override
  Widget build(BuildContext context) {
    final verifiedPercent = (totals['verifiedPercent'] as num?)?.toDouble() ?? 0;
    final activePercent = (totals['activeMemberPercent'] as num?)?.toDouble() ?? 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: HomeColors.navy,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${district['name'] ?? ''}',
                      style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900),
                    ),
                    if (from != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${'since'.trFallback('Since')} ${DateFormat('dd MMM').format(from!)}',
                        style: const TextStyle(color: HomeColors.navyMuted, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${(totals['activities'] as num?)?.toInt() ?? 0}',
                    style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900, height: 1),
                  ),
                  Text(
                    'activities'.trFallback('activities'),
                    style: const TextStyle(color: HomeColors.navyMuted, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _DarkBar(
            label: 'verified_share'.trFallback('Verified'),
            detail: '${(totals['verified'] as num?)?.toInt() ?? 0} '
                '${'of'.trFallback('of')} ${(totals['activities'] as num?)?.toInt() ?? 0}',
            percent: verifiedPercent,
            color: AppColors.ok,
          ),
          const SizedBox(height: 12),
          _DarkBar(
            label: 'active_members'.trFallback('Members active'),
            detail: '${(totals['activeMembers'] as num?)?.toInt() ?? 0} '
                '${'of'.trFallback('of')} ${(totals['members'] as num?)?.toInt() ?? 0}',
            percent: activePercent,
            color: HomeColors.orange,
          ),
          if (((totals['pending'] as num?)?.toInt() ?? 0) > 0) ...[
            const SizedBox(height: 12),
            Text(
              '${(totals['pending'] as num?)?.toInt()} ${'awaiting_verification'.trFallback('awaiting verification')}',
              style: const TextStyle(color: HomeColors.navyMuted, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _DarkBar extends StatelessWidget {
  const _DarkBar({required this.label, required this.detail, required this.percent, required this.color});
  final String label;
  final String detail;
  final double percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
            ),
            Text('${percent.toStringAsFixed(percent % 1 == 0 ? 0 : 1)}%',
                style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: (percent / 100).clamp(0.0, 1.0),
            minHeight: 7,
            backgroundColor: HomeColors.navyDeep,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        const SizedBox(height: 4),
        Text(detail, style: const TextStyle(color: HomeColors.navyMuted, fontSize: 11.5)),
      ],
    );
  }
}

class _RangeChips extends StatelessWidget {
  const _RangeChips({required this.selected, required this.onSelect});
  final int? selected;
  final ValueChanged<int?> onSelect;

  @override
  Widget build(BuildContext context) {
    final options = <(String, int?)>[
      ('this_month'.trFallback('This month'), null),
      ('last_7_days'.trFallback('7 days'), 7),
      ('last_30_days'.trFallback('30 days'), 30),
      ('last_90_days'.trFallback('90 days'), 90),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (label, value) in options)
          _Chip(label: label, selected: selected == value, onTap: () => onSelect(value)),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? HomeColors.peach : Colors.white,
      shape: StadiumBorder(side: BorderSide(color: selected ? HomeColors.orange : HomeColors.border)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: selected ? HomeColors.orangeDark : HomeColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeBar extends StatelessWidget {
  const _TypeBar({required this.type, required this.count, required this.percent});
  final String type;
  final int count;
  final double percent;

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(type);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _typeLabel(type),
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: HomeColors.ink),
                ),
              ),
              Text('$count', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: HomeColors.ink)),
              const SizedBox(width: 8),
              SizedBox(
                width: 46,
                child: Text(
                  '${percent.toStringAsFixed(percent % 1 == 0 ? 0 : 1)}%',
                  textAlign: TextAlign.end,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: (percent / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.sunk,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity});
  final Map<String, dynamic> activity;

  (String, Color, Color) _status() {
    return switch ('${activity['status']}') {
      'VERIFIED' => ('verified'.trFallback('Verified'), AppColors.ok, AppColors.okBg),
      'NOT_VERIFIED' => ('not_verified'.trFallback('Not verified'), AppColors.bad, AppColors.badBg),
      'APPEALED' => ('appealed'.trFallback('Appealed'), AppColors.warn, AppColors.warnBg),
      _ => ('pending'.trFallback('Pending'), AppColors.ink3, AppColors.sunk),
    };
  }

  @override
  Widget build(BuildContext context) {
    final type = '${activity['type']}';
    final color = _typeColor(type);
    final occurredAt = DateTime.tryParse('${activity['occurredAt'] ?? ''}')?.toLocal();
    final place = '${activity['place'] ?? ''}'.trim();
    final boothCode = '${activity['boothCode'] ?? ''}'.trim();
    final attendees = (activity['attendeeCount'] as num?)?.toInt() ?? 0;
    final homes = (activity['homesCovered'] as num?)?.toInt() ?? 0;
    final (statusLabel, statusFg, statusBg) = _status();
    final detail = [
      if (occurredAt != null) DateFormat('dd MMM · hh:mm a').format(occurredAt),
      if (boothCode.isNotEmpty) boothCode,
      if (place.isNotEmpty) place,
      if (attendees > 0) '$attendees ${'attendees'.trFallback('attendees')}',
      if (homes > 0) '$homes ${'homes'.trFallback('homes')}',
    ].join(' · ');

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.check_circle_outline_rounded, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _typeLabel(type),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: HomeColors.ink),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(99)),
                      child: Text(
                        statusLabel,
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: statusFg),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${activity['actorName'] ?? ''}',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: HomeColors.navyMid),
                ),
                if (detail.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(detail, style: const TextStyle(fontSize: 12, color: HomeColors.muted, height: 1.35)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
