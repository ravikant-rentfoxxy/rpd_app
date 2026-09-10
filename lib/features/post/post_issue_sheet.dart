import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/post_issues.dart';
import '../../core/theme/app_colors.dart';
import '../join/join_chrome.dart';

Future<String?> showIssueSelectSheet({
  required BuildContext context,
  required List<Map<String, dynamic>> issues,
  String? selectedId,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (context) => _IssueSelectSheet(issues: issues, selectedId: selectedId),
  );
}

class _IssueSelectSheet extends StatefulWidget {
  const _IssueSelectSheet({required this.issues, this.selectedId});
  final List<Map<String, dynamic>> issues;
  final String? selectedId;

  @override
  State<_IssueSelectSheet> createState() => _IssueSelectSheetState();
}

class _IssueSelectSheetState extends State<_IssueSelectSheet> {
  final query = TextEditingController();

  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filtered {
    final q = query.text.trim().toLowerCase();
    final rows = [...widget.issues]..sort((a, b) => issuePriorityOf(a).compareTo(issuePriorityOf(b)));
    if (q.isEmpty) return rows;
    return rows.where((issue) {
      final label = issueLabelOf(issue).toLowerCase();
      final code = '${issue['code'] ?? ''}'.toLowerCase().replaceAll('_', ' ');
      return label.contains(q) || code.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: const Color(0xFFF7F4EE),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.86,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8D2C6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 8, 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'issue_sheet_title'.trFallback('What issue is this?'),
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A1A1A),
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'issue_sheet_sub'.trFallback('Select one to continue'),
                              style: const TextStyle(color: Color(0xFF8A8478), fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF1A1A1A), size: 26),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 16, 22, 8),
                  child: TextField(
                    controller: query,
                    onChanged: (_) => setState(() {}),
                    cursorColor: HomeColors.orange,
                    decoration: InputDecoration(
                      hintText: 'search_issues'.trFallback('Search issues'),
                      hintStyle: const TextStyle(color: Color(0xFFB0A89C), fontSize: 15),
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFB0A89C)),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 10, 22, 6),
                    child: Text(
                      'all_categories'.trFallback('All categories'),
                      style: const TextStyle(color: Color(0xFF8A8478), fontSize: 14),
                    ),
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            'no_matches'.trFallback('No matches'),
                            style: const TextStyle(color: Color(0xFF8A8478), fontWeight: FontWeight.w600),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final issue = filtered[index];
                            final id = issueKey(issue);
                            return _IssueRow(
                              issue: issue,
                              selected: id == widget.selectedId,
                              onTap: () => Navigator.pop(context, id),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IssueRow extends StatelessWidget {
  const _IssueRow({required this.issue, required this.selected, required this.onTap});
  final Map<String, dynamic> issue;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tone = _issueTone(issue);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: selected ? const Color(0xFFFFF3E4) : Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(color: tone.wash, shape: BoxShape.circle),
                  child: Icon(_issueIcon(issue), color: tone.ink, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    issueLabelOf(issue),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: const Color(0xFF1A1A1A),
                      height: 1.25,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_rounded, color: Color(0xFFC56A1A), size: 22)
                else
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFD8D2C6), width: 1.6),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

({Color wash, Color ink}) _issueTone(Map<String, dynamic> issue) {
  return switch ('${issue['code'] ?? ''}') {
    'WATER' => (wash: const Color(0xFFD7E8FF), ink: const Color(0xFF2B5C9E)),
    'ROADS_TRANSPORT' => (wash: const Color(0xFFFFE0C2), ink: const Color(0xFFB85A12)),
    'ELECTRICITY' => (wash: const Color(0xFFFFF0B8), ink: const Color(0xFFB8860B)),
    'HEALTH' => (wash: const Color(0xFFFFD6DE), ink: const Color(0xFFB04A5A)),
    'SANITATION_GARBAGE' => (wash: const Color(0xFFE8D6F2), ink: const Color(0xFF7A4A8C)),
    'DRAINAGE_SEWERAGE' => (wash: const Color(0xFFD4EEF2), ink: const Color(0xFF2F7A86)),
    'EDUCATION' => (wash: const Color(0xFFD8F0C8), ink: const Color(0xFF4A8A2A)),
    'GOVERNMENT_SERVICES' => (wash: const Color(0xFFE4DCF6), ink: const Color(0xFF5A4588)),
    'PUBLIC_SAFETY' => (wash: const Color(0xFFFFD8C8), ink: const Color(0xFFB04A28)),
    'AGRICULTURE_RURAL' => (wash: const Color(0xFFFFD8C2), ink: const Color(0xFFB85A28)),
    'ENVIRONMENT' => (wash: const Color(0xFFCDEECA), ink: const Color(0xFF2F7A3A)),
    'WOMEN_CHILD_WELFARE' => (wash: const Color(0xFFFFD6EA), ink: const Color(0xFFA84A78)),
    _ => (wash: const Color(0xFFE8E4DC), ink: const Color(0xFF6D6775)),
  };
}

IconData _issueIcon(Map<String, dynamic> issue) {
  return switch ('${issue['code'] ?? ''}') {
    'WATER' => Icons.water_drop_outlined,
    'ROADS_TRANSPORT' => Icons.alt_route_rounded,
    'ELECTRICITY' => Icons.bolt_rounded,
    'HEALTH' => Icons.health_and_safety_outlined,
    'SANITATION_GARBAGE' => Icons.delete_outline_rounded,
    'DRAINAGE_SEWERAGE' => Icons.waves_rounded,
    'EDUCATION' => Icons.menu_book_outlined,
    'GOVERNMENT_SERVICES' => Icons.account_balance_outlined,
    'PUBLIC_SAFETY' => Icons.shield_outlined,
    'AGRICULTURE_RURAL' => Icons.agriculture_outlined,
    'ENVIRONMENT' => Icons.park_outlined,
    'WOMEN_CHILD_WELFARE' => Icons.family_restroom_rounded,
    _ => Icons.flag_outlined,
  };
}
