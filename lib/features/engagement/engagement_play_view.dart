import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/api_error.dart';
import '../../core/widgets/ui.dart';
import '../session/session_controller.dart';
import 'engagement_api.dart';

class EngagementPlayView extends StatefulWidget {
  const EngagementPlayView({super.key});

  @override
  State<EngagementPlayView> createState() => _EngagementPlayViewState();
}

class _EngagementPlayViewState extends State<EngagementPlayView> {
  Map<String, dynamic> event = {};
  final answers = <String, String>{};
  bool loading = true;
  bool submitting = false;
  Map<String, dynamic>? result;

  String get id {
    final raw = Get.arguments;
    if (raw is Map) return '${raw['id'] ?? ''}';
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
      final data = await fetchEngagement(id);
      final fresh = Map<String, dynamic>.from(data['event'] as Map? ?? {});
      final chosen = (data['answers'] as List? ?? []).whereType<Map>();
      for (final row in chosen) {
        answers['${row['questionId']}'] = '${row['optionId']}';
      }
      if (data['completed'] == true) {
        result = data;
      }
      if (mounted) setState(() => event = fresh);
    } catch (e) {
      Get.snackbar('Error', apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _submit() async {
    final questions = (event['questions'] as List? ?? []).whereType<Map>().toList();
    if (answers.length < questions.length) {
      Get.snackbar('Error', 'engagement_answer_all'.tr);
      return;
    }
    setState(() => submitting = true);
    try {
      final data = await submitEngagement(
        id,
        answers.entries.map((e) => {'questionId': e.key, 'optionId': e.value}).toList(),
      );
      Get.find<SessionController>().clearEngagementPrompt();
      if (!mounted) return;
      setState(() {
        result = data;
        if (data['event'] is Map) event = Map<String, dynamic>.from(data['event'] as Map);
      });
    } catch (e) {
      Get.snackbar('Error', apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = '${event['type'] ?? ''}'.toUpperCase();
    final questions = (event['questions'] as List? ?? []).whereType<Map>().toList();
    final score = result?['score'] is Map ? Map<String, dynamic>.from(result!['score'] as Map) : null;
    final pollCounts = result?['pollCounts'] is Map ? Map<String, dynamic>.from(result!['pollCounts'] as Map) : null;
    return Scaffold(
      backgroundColor: HomeColors.paper,
      appBar: AppBar(
        backgroundColor: HomeColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(event['title'] as String? ?? 'engagement_play'.tr),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: HomeColors.navy,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      bottomNavigationBar: result != null || loading
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: PrimaryButton(
                  submitting ? '…' : 'engagement_submit'.tr,
                  onTap: submitting ? () {} : _submit,
                  enabled: !submitting,
                ),
              ),
            ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: HomeColors.orange))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                if ('${event['description'] ?? ''}'.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text('${event['description']}', style: const TextStyle(fontSize: 14, height: 1.4, color: HomeColors.muted)),
                  ),
                if (score != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'engagement_score'.trParams({'n': '${score['correct']}', 'total': '${score['total']}'}),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: HomeColors.ink),
                    ),
                  ),
                if (result != null && type == 'POLL')
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text('engagement_thanks'.tr, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ...questions.asMap().entries.map((entry) {
                  final question = Map<String, dynamic>.from(entry.value);
                  final qid = '${question['id']}';
                  final options = (question['options'] as List? ?? []).whereType<Map>();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Material(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: HomeColors.border, width: 0.5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${entry.key + 1}. ${question['prompt']}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                            const SizedBox(height: 8),
                            ...options.map((raw) {
                              final option = Map<String, dynamic>.from(raw);
                              final oid = '${option['id']}';
                              final selected = answers[qid] == oid;
                              final votes = pollCounts?[oid];
                              final correct = option['isCorrect'] == true;
                              return RadioListTile<String>(
                                dense: true,
                                value: oid,
                                groupValue: answers[qid],
                                onChanged: result != null
                                    ? null
                                    : (value) {
                                        if (value == null) return;
                                        setState(() => answers[qid] = value);
                                      },
                                title: Text(
                                  '${option['label']}${votes != null ? ' · $votes' : ''}${correct && result != null ? ' ✓' : ''}',
                                  style: TextStyle(
                                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                    color: correct && result != null ? const Color(0xFF1B8A6A) : HomeColors.ink,
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
