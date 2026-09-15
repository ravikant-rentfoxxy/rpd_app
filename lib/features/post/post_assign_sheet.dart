import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/empty_card.dart';
import '../join/join_chrome.dart';

Future<String?> showPostAssignSheet({
  required BuildContext context,
  required List<Map<String, dynamic>> members,
  String? selectedId,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (context) => _PostAssignSheet(members: members, selectedId: selectedId),
  );
}

class _PostAssignSheet extends StatefulWidget {
  const _PostAssignSheet({required this.members, this.selectedId});
  final List<Map<String, dynamic>> members;
  final String? selectedId;

  @override
  State<_PostAssignSheet> createState() => _PostAssignSheetState();
}

class _PostAssignSheetState extends State<_PostAssignSheet> {
  final query = TextEditingController();

  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filtered {
    final q = query.text.trim().toLowerCase();
    if (q.isEmpty) return widget.members;
    return widget.members.where((member) {
      final name = '${member['fullName'] ?? ''}'.toLowerCase();
      final post = '${member['postLabel'] ?? member['post'] ?? ''}'.toLowerCase();
      return name.contains(q) || post.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.72,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + inset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: const Color(0xFFD8D0C4), borderRadius: BorderRadius.circular(99)),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'assign_issue_title'.trFallback('Assign this issue'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: HomeColors.ink),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: query,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'search'.trFallback('Search'),
                    prefixIcon: const Icon(Icons.search_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _filtered.isEmpty
                      ? Center(
                          child: AppEmptyCard(
                            compact: true,
                            icon: Icons.person_search_outlined,
                            title: 'assign_issue_empty'.trFallback('No members you can assign in your area.'),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _filtered.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final member = _filtered[index];
                            final id = '${member['id'] ?? ''}';
                            final selected = id == widget.selectedId;
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                '${member['fullName'] ?? ''}',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text('${member['postLabel'] ?? member['post'] ?? ''}'),
                              trailing: selected ? const Icon(Icons.check_rounded, color: HomeColors.orange) : null,
                              onTap: () => Get.back(result: id),
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
