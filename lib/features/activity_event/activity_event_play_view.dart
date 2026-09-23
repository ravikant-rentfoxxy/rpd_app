import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/api_error.dart';
import '../../core/widgets/ui.dart';
import '../join/join_chrome.dart';
import 'activity_event_api.dart';
import '../../core/widgets/flash.dart';

class ActivityEventPlayView extends StatefulWidget {
  const ActivityEventPlayView({super.key});

  @override
  State<ActivityEventPlayView> createState() => _ActivityEventPlayViewState();
}

class _ActivityEventPlayViewState extends State<ActivityEventPlayView> {
  Map<String, dynamic> event = {};
  String? selectedId;
  bool loading = true;
  bool submitting = false;

  String get id {
    final raw = Get.arguments;
    if (raw is Map) return '${raw['id'] ?? ''}';
    if (raw is String) return raw;
    return '';
  }

  @override
  void initState() {
    super.initState();
    final raw = Get.arguments;
    if (raw is Map) event = Map<String, dynamic>.from(raw);
    _load();
  }

  Future<void> _load() async {
    if (id.isEmpty) {
      setState(() => loading = false);
      return;
    }
    try {
      final fresh = await fetchActivityEvent(id);
      if (!mounted) return;
      setState(() {
        event = fresh;
        selectedId = '${fresh['optionId'] ?? ''}'.trim().isEmpty ? null : '${fresh['optionId']}';
      });
    } catch (e) {
      flash('Error', apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _submit() async {
    final optionId = selectedId;
    if (optionId == null) {
      flash('Error', 'activity_event_pick'.trFallback('Choose Yes or No'));
      return;
    }
    setState(() => submitting = true);
    try {
      final fresh = await respondActivityEvent(id, optionId);
      if (!mounted) return;
      setState(() => event = fresh);
    } catch (e) {
      flash('Error', apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = '${event['title'] ?? ''}'.trim();
    final description = '${event['description'] ?? ''}'.trim();
    final answered = event['answered'] == true;
    final isCreator = event['isCreator'] == true;
    final responseCount = (event['responseCount'] as num?)?.toInt();
    final options = (event['options'] as List? ?? []).whereType<Map>().toList();
    final showResults = answered || isCreator;
    return Scaffold(
      backgroundColor: HomeColors.paper,
      appBar: OrganicAppBar(title: 'activity_event'.trFallback('Activity event')),
      bottomNavigationBar: loading || answered
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: PrimaryButton(
                  submitting ? '…' : 'activity_event_submit'.trFallback('Submit'),
                  onTap: submitting ? () {} : _submit,
                  enabled: !submitting,
                ),
              ),
            ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: HomeColors.orange))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
              children: [
                Text(
                  title.isEmpty ? 'activity_event'.trFallback('Activity event') : title,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: HomeColors.ink, height: 1.25),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(description, style: const TextStyle(fontSize: 14, height: 1.4, color: HomeColors.muted)),
                ],
                if (isCreator && responseCount != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'activity_event_member_count'.trParams({'n': '$responseCount'}),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: HomeColors.ink),
                  ),
                ],
                const SizedBox(height: 18),
                if (!answered)
                  Material(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: HomeColors.border, width: 0.5),
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < options.length; i++) ...[
                          if (i > 0) const Divider(height: 1, color: HomeColors.border),
                          CheckboxListTile(
                            value: selectedId == '${options[i]['id']}',
                            onChanged: (_) => setState(() => selectedId = '${options[i]['id']}'),
                            controlAffinity: ListTileControlAffinity.leading,
                            activeColor: HomeColors.orange,
                            title: Text(
                              '${options[i]['label'] ?? ''}',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                if (showResults) ...[
                  if (!answered) const SizedBox(height: 16),
                  Material(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: HomeColors.border, width: 0.5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: Column(
                        children: [
                          for (final option in options) ...[
                            _ResultBar(
                              label: '${option['label'] ?? ''}',
                              percent: (option['percent'] as num?)?.toDouble() ?? 0,
                              selected: selectedId == '${option['id']}',
                            ),
                            const SizedBox(height: 12),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
                if (answered) ...[
                  const SizedBox(height: 18),
                  Text(
                    'activity_event_thanks'.trFallback('Your answer was saved.'),
                    style: const TextStyle(fontWeight: FontWeight.w700, color: HomeColors.ink),
                  ),
                ],
              ],
            ),
    );
  }
}

class _ResultBar extends StatelessWidget {
  const _ResultBar({required this.label, required this.percent, required this.selected});
  final String label;
  final double percent;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final value = (percent / 100).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                  fontSize: 15,
                  color: HomeColors.ink,
                ),
              ),
            ),
            Text(
              '${percent.round()}%',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: selected ? HomeColors.orange : HomeColors.ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 10,
            backgroundColor: const Color(0xFFEFE8DC),
            color: HomeColors.orange,
          ),
        ),
      ],
    );
  }
}
