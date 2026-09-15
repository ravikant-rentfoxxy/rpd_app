import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/post_issues.dart';
import '../../core/theme/app_colors.dart';
import '../join/join_chrome.dart';

class IssueSelection {
  const IssueSelection({required this.issue, required this.subIssue});
  final Map<String, dynamic> issue;
  final Map<String, dynamic> subIssue;
}

Future<IssueSelection?> showIssueSelectSheet({
  required BuildContext context,
  required List<Map<String, dynamic>> issues,
  String? selectedId,
  String? selectedSubId,
}) {
  return showModalBottomSheet<IssueSelection>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (context) => _IssueSelectSheet(
      issues: issues,
      selectedId: selectedId,
      selectedSubId: selectedSubId,
    ),
  );
}

class _IssueSelectSheet extends StatefulWidget {
  const _IssueSelectSheet({required this.issues, this.selectedId, this.selectedSubId});
  final List<Map<String, dynamic>> issues;
  final String? selectedId;
  final String? selectedSubId;

  @override
  State<_IssueSelectSheet> createState() => _IssueSelectSheetState();
}

class _IssueSelectSheetState extends State<_IssueSelectSheet> {
  final query = TextEditingController();
  Map<String, dynamic>? category;

  @override
  void initState() {
    super.initState();
    if (widget.selectedId != null) {
      for (final issue in widget.issues) {
        if (issueKey(issue) == widget.selectedId) {
          category = issue;
          break;
        }
      }
    }
  }

  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _categories {
    final rows = [...widget.issues]..sort((a, b) => issuePriorityOf(a).compareTo(issuePriorityOf(b)));
    return _filter(rows);
  }

  List<Map<String, dynamic>> get _subIssues {
    final rows = issueChildrenOf(category ?? {});
    return _filter(rows);
  }

  List<Map<String, dynamic>> _filter(List<Map<String, dynamic>> rows) {
    final q = query.text.trim().toLowerCase();
    if (q.isEmpty) return rows;
    return rows.where((issue) {
      final label = localizedIssueName(issue).toLowerCase();
      final code = '${issue['code'] ?? ''}'.toLowerCase().replaceAll('_', ' ');
      final kids = issueChildrenOf(issue);
      final childHit = kids.any((child) {
        final name = localizedIssueName(child).toLowerCase();
        final childCode = '${child['code'] ?? ''}'.toLowerCase().replaceAll('_', ' ');
        return name.contains(q) || childCode.contains(q);
      });
      return label.contains(q) || code.contains(q) || childHit;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final onSub = category != null;
    final rows = onSub ? _subIssues : _categories;
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
                  padding: const EdgeInsets.fromLTRB(10, 10, 8, 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (onSub)
                        IconButton(
                          onPressed: () => setState(() {
                            category = null;
                            query.clear();
                          }),
                          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1A1A)),
                        )
                      else
                        const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              onSub
                                  ? localizedIssueName(category!)
                                  : 'issue_sheet_title'.trFallback('What issue is this?'),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A1A1A),
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              onSub
                                  ? 'issue_sheet_sub_step'.trFallback('Select the specific problem')
                                  : 'issue_sheet_sub'.trFallback('Select one to continue'),
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
                  padding: const EdgeInsets.fromLTRB(22, 12, 22, 8),
                  child: TextField(
                    controller: query,
                    onChanged: (_) => setState(() {}),
                    cursorColor: HomeColors.orange,
                    decoration: InputDecoration(
                      hintText: onSub
                          ? 'search_sub_issues'.trFallback('Search sub-issues')
                          : 'search_issues'.trFallback('Search issues'),
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
                    padding: const EdgeInsets.fromLTRB(22, 6, 22, 6),
                    child: Text(
                      onSub ? 'step_two_of_two'.trFallback('Step 2 of 2') : 'step_one_of_two'.trFallback('Step 1 of 2'),
                      style: const TextStyle(color: Color(0xFF8A8478), fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                Expanded(
                  child: rows.isEmpty
                      ? Center(
                          child: Text(
                            'no_matches'.trFallback('No matches'),
                            style: const TextStyle(color: Color(0xFF8A8478), fontWeight: FontWeight.w600),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                          itemCount: rows.length,
                          itemBuilder: (context, index) {
                            final issue = rows[index];
                            final id = issueKey(issue);
                            final selected = onSub ? id == widget.selectedSubId : id == widget.selectedId;
                            return _IssueRow(
                              issue: issue,
                              selected: selected,
                              showChevron: !onSub,
                              onTap: () {
                                if (!onSub) {
                                  setState(() {
                                    category = issue;
                                    query.clear();
                                  });
                                  return;
                                }
                                Navigator.pop(context, IssueSelection(issue: category!, subIssue: issue));
                              },
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
  const _IssueRow({
    required this.issue,
    required this.selected,
    required this.onTap,
    this.showChevron = false,
  });
  final Map<String, dynamic> issue;
  final bool selected;
  final VoidCallback onTap;
  final bool showChevron;

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
                    localizedIssueName(issue),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: const Color(0xFF1A1A1A),
                      height: 1.25,
                    ),
                  ),
                ),
                if (showChevron)
                  const Icon(Icons.chevron_right_rounded, color: Color(0xFFC56A1A))
                else if (selected)
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
    'LAND' || 'LAND_DISPUTE' || 'LAND_ENCROACHMENT' || 'COMMON_LAND_GRAB' || 'BOUNDARY' || 'MUTATION' || 'LAND_RECORD_ERROR' || 'PARTITION' || 'LEKHPAL' || 'COMPENSATION' =>
      (wash: const Color(0xFFFFE0C2), ink: const Color(0xFFB85A12)),
    'WATER' || 'HANDPUMP_BROKEN' || 'HANDPUMP_NEEDED' || 'WATER_DIRTY' || 'PIPELINE' || 'TANK_MOTOR' || 'WATER_SHORTAGE' =>
      (wash: const Color(0xFFD7E8FF), ink: const Color(0xFF2B5C9E)),
    'POWER' || 'TRANSFORMER' || 'POLE_WIRE' || 'NO_SUPPLY' || 'WRONG_BILL' || 'NEW_CONNECTION' || 'STREET_LIGHT' =>
      (wash: const Color(0xFFFFF0B8), ink: const Color(0xFFB8860B)),
    'ROAD_SANITATION' || 'ROAD_BROKEN' || 'ROAD_NOT_BUILT' || 'KHARANJA' || 'DRAIN' || 'WATERLOGGING' || 'GARBAGE' || 'CULVERT_BRIDGE' =>
      (wash: const Color(0xFFFFE0C2), ink: const Color(0xFFB85A12)),
    'RATION' || 'RATION_CARD_NEW' || 'NAME_MISSING' || 'CARD_CANCELLED' || 'LESS_GRAIN' || 'DEALER_SHOP' || 'EKYC' =>
      (wash: const Color(0xFFFFE4C4), ink: const Color(0xFFC45A12)),
    'PENSION' || 'OLD_AGE' || 'WIDOW' || 'DISABILITY' || 'PENSION_NEW' || 'BANK_ISSUE' =>
      (wash: const Color(0xFFE4DCF6), ink: const Color(0xFF5A4588)),
    'NREGA' || 'JOB_CARD' || 'CARD_WITHHELD' || 'NO_WORK' || 'WAGE_DELAY' || 'MUSTER_FAKE' || 'WORK_NOT_DONE' =>
      (wash: const Color(0xFFFFD8C2), ink: const Color(0xFFB85A28)),
    'HOUSING' || 'AWAS_NOT_GIVEN' || 'AWAS_INSTALMENT' || 'LIST_WRONG' || 'TOILET_NOT_BUILT' || 'TOILET_NEEDED' =>
      (wash: const Color(0xFFE8D6F2), ink: const Color(0xFF7A4A8C)),
    'HEALTH' || 'PHC_CLOSED' || 'NO_MEDICINE' || 'ASHA_ANM' || 'AMBULANCE' || 'AYUSHMAN' || 'VACCINATION' =>
      (wash: const Color(0xFFFFD6DE), ink: const Color(0xFFB04A5A)),
    'EDUCATION' || 'TEACHER_ABSENT' || 'SCHOOL_BUILDING' || 'MID_DAY_MEAL' || 'ANGANWADI' || 'SCHOLARSHIP' || 'ADMISSION' =>
      (wash: const Color(0xFFD8F0C8), ink: const Color(0xFF4A8A2A)),
    'FARMING' || 'CANAL' || 'TUBEWELL' || 'FERTILIZER' || 'CROP_INSURANCE' || 'CROP_DAMAGE' || 'STRAY_CATTLE' || 'MANDI_PAYMENT' =>
      (wash: const Color(0xFFCDEECA), ink: const Color(0xFF2F7A3A)),
    'DOCUMENTS' || 'CASTE_CERT' || 'INCOME_CERT' || 'RESIDENCE_CERT' || 'BIRTH_DEATH' || 'AADHAAR' =>
      (wash: const Color(0xFFE4DCF6), ink: const Color(0xFF5A4588)),
    'COMMON_PROPERTY' || 'POND' || 'GRAZING_LAND' || 'CREMATION' || 'PANCHAYAT_BHAWAN' || 'PLAYGROUND' =>
      (wash: const Color(0xFFCDEECA), ink: const Color(0xFF2F7A3A)),
    'GOVERNANCE' || 'BRIBE' || 'FUND_MISUSE' || 'NO_GRAM_SABHA' || 'OFFICIAL_ABSENT' || 'ILLEGAL_LIQUOR' || 'TRANSPORT' || 'NETWORK' =>
      (wash: const Color(0xFFFFD8C8), ink: const Color(0xFFB04A28)),
    _ => (wash: const Color(0xFFE8E4DC), ink: const Color(0xFF6D6775)),
  };
}

IconData _issueIcon(Map<String, dynamic> issue) {
  return switch ('${issue['code'] ?? ''}') {
    'LAND' => Icons.landscape_outlined,
    'WATER' => Icons.water_drop_outlined,
    'POWER' => Icons.bolt_rounded,
    'ROAD_SANITATION' => Icons.alt_route_rounded,
    'RATION' => Icons.rice_bowl_outlined,
    'PENSION' => Icons.payments_outlined,
    'NREGA' => Icons.construction_outlined,
    'HOUSING' => Icons.home_outlined,
    'HEALTH' => Icons.health_and_safety_outlined,
    'EDUCATION' => Icons.menu_book_outlined,
    'FARMING' => Icons.agriculture_outlined,
    'DOCUMENTS' => Icons.description_outlined,
    'COMMON_PROPERTY' => Icons.park_outlined,
    'GOVERNANCE' => Icons.account_balance_outlined,
    _ => Icons.flag_outlined,
  };
}
