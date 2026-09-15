import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rpd_app/features/join/join_chrome.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/api_error.dart';
import '../../core/widgets/empty_card.dart';
import '../../core/widgets/flash.dart';
import '../../core/widgets/ui.dart';
import '../session/session_controller.dart';
import 'post_api.dart';
import 'post_assign_sheet.dart';
import 'post_summary_sheet.dart';
import 'post_views.dart';
import 'summary_loading.dart';

class GrievanceView extends StatefulWidget {
  const GrievanceView({super.key});

  @override
  State<GrievanceView> createState() => _GrievanceViewState();
}

class _GrievanceViewState extends State<GrievanceView> {
  final items = <Map<String, dynamic>>[].obs;
  final loading = true.obs;
  final assigningId = ''.obs;
  final summarisingId = ''.obs;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    loading.value = true;
    try {
      final posts = await fetchGrievancePosts();
      items.assignAll(posts);
      for (final post in posts) {
        Get.find<SessionController>().upsertRegionPost(post);
      }
    } catch (e) {
      flash('Error', apiErrorMessage(e));
      items.clear();
    } finally {
      loading.value = false;
    }
  }

  Future<void> _assign(Map<String, dynamic> post) async {
    final id = '${post['serverId'] ?? post['clientUuid'] ?? post['id'] ?? ''}';
    if (id.isEmpty || assigningId.value.isNotEmpty) return;
    assigningId.value = id;
    try {
      final members = await fetchPostAssignees(post);
      if (!mounted) return;
      final selected = await showPostAssignSheet(
        context: context,
        members: members,
        selectedId: '${post['assignedToId'] ?? ''}',
      );
      if (selected == null || selected.isEmpty) return;
      final updated = await assignRegionPost(post, selected);
      Get.find<SessionController>().upsertRegionPost(updated);
      final index = items.indexWhere((row) => '${row['serverId'] ?? row['clientUuid'] ?? row['id']}' == id);
      if (index >= 0) {
        items[index] = updated;
      } else {
        await _load();
      }
      flash(
        'assign_issue_done'.trFallback('Assigned'),
        '${updated['assigneeName'] ?? ''}',
      );
    } catch (e) {
      flash('Error', apiErrorMessage(e));
    } finally {
      assigningId.value = '';
    }
  }

  Future<void> _summarise(Map<String, dynamic> post) async {
    final id = '${post['serverId'] ?? post['clientUuid'] ?? post['id'] ?? ''}';
    if (id.isEmpty || summarisingId.value.isNotEmpty) return;
    if (post['canSummarise'] != true) return;
    summarisingId.value = id;
    try {
      final summary = await runWithSummaryLoading(context, () => summariseRegionPost(post));
      if (!mounted) return;
      if (summary.isEmpty) {
        flash('Error', 'summary_empty'.trFallback('Could not create a summary'));
        return;
      }
      await showPostSummarySheet(context: context, summary: summary);
    } catch (e) {
      flash('Error', apiErrorMessage(e));
    } finally {
      summarisingId.value = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: OrganicAppBar(title: 'grievance'.trFallback('Grievance')),
      body: Obx(() {
        if (loading.value) {
          return const Center(child: CircularProgressIndicator(color: HomeColors.orange));
        }
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: AppEmptyCard(
                icon: Icons.assignment_outlined,
                title: 'grievance_empty'.trFallback('No pending grievances in your region.'),
              ),
            ),
          );
        }
        return RefreshIndicator(
          color: HomeColors.orange,
          onRefresh: _load,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final post = items[index];
              final postId = '${post['serverId'] ?? post['clientUuid'] ?? post['id'] ?? ''}';
              final canAssign = post['canAssign'] == true;
              final canSummarise = post['canSummarise'] == true;
              final busy = assigningId.value == postId;
              final summarising = summarisingId.value == postId;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RegionPostCard(
                    post: post,
                    onTap: () async {
                      await Get.toNamed(Routes.postDetail, arguments: post);
                      await _load();
                    },
                  ),
                  if (canSummarise || canAssign) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 4,
                      children: [
                        if (canSummarise)
                          TextButton.icon(
                            onPressed: summarising ? null : () => _summarise(post),
                            icon: summarising
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: HomeColors.orange),
                                  )
                                : const Icon(Icons.auto_awesome_rounded, size: 18),
                            label: Text(
                              'get_summary'.trFallback('Draft for X'),
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            style: TextButton.styleFrom(foregroundColor: HomeColors.orange),
                          ),
                        if (canAssign)
                          TextButton.icon(
                            onPressed: busy ? null : () => _assign(post),
                            icon: busy
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: HomeColors.orange),
                                  )
                                : const Icon(Icons.person_add_alt_1_rounded, size: 18),
                            label: Text(
                              '${post['assigneeName'] ?? ''}'.trim().isEmpty
                                  ? 'assign_issue'.trFallback('Assign to resolve')
                                  : 'assign_issue_change'.trFallback('Change assignee'),
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            style: TextButton.styleFrom(foregroundColor: HomeColors.orange),
                          ),
                      ],
                    ),
                  ],
                ],
              );
            },
          ),
        );
      }),
    );
  }
}
