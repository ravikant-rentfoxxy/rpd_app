import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/constants/org_hierarchy.dart';
import '../../core/constants/post_issues.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/api_error.dart';
import '../../core/utils/app_log.dart';
import '../../core/utils/local_image.dart';
import '../../core/utils/relative_time.dart';
import '../join/join_chrome.dart';
import '../session/session_controller.dart';
import 'post_api.dart';
import 'post_assign_sheet.dart';
import 'post_media.dart';
import 'post_summary_sheet.dart';
import 'post_views.dart';
import 'summary_loading.dart';
import '../../core/widgets/flash.dart';

class PostDetailView extends StatefulWidget {
  const PostDetailView({super.key});

  @override
  State<PostDetailView> createState() => _PostDetailViewState();
}

class _PostDetailViewState extends State<PostDetailView> {
  late Map<String, dynamic> data;
  var assigning = false;
  var resolving = false;
  var summarising = false;

  @override
  void initState() {
    super.initState();
    final raw = Get.arguments;
    data = raw is Map ? Map<String, dynamic>.from(raw) : {};
    _refresh();
  }

  Future<void> _refresh() async {
    if (data['pending'] == true) return;
    try {
      final updated = await fetchRegionPost(data);
      if (!mounted) return;
      setState(() => data = updated);
      Get.find<SessionController>().upsertRegionPost(updated);
    } catch (e, stack) {
      AppLog.error('Load post detail failed', error: e, stack: stack, tag: 'POST');
    }
  }

  String get _authorName => '${data['authorName'] ?? ''}'.trim();
  String get _authorMobile => '${data['authorMobile'] ?? ''}'.trim();
  String get _assigneeName => '${data['assigneeName'] ?? ''}'.trim();
  String get _assigneePost {
    final code = '${data['assigneePost'] ?? ''}'.trim();
    final fallback = '${data['assigneePostLabel'] ?? ''}'.trim();
    if (code.isEmpty) return fallback;
    return postLabelKey(code).trFallback(fallback.isEmpty ? code.replaceAll('_', ' ') : fallback);
  }

  // The assignee already knows it's theirs — show who handed it over instead.
  bool get _assignedToMe => data['isAssignedToMe'] == true;
  String get _assignerName => '${data['assignedByName'] ?? ''}'.trim();
  String get _assignerPost {
    final code = '${data['assignedByPost'] ?? ''}'.trim();
    final fallback = '${data['assignedByPostLabel'] ?? ''}'.trim();
    if (code.isEmpty) return fallback;
    return postLabelKey(code).trFallback(fallback.isEmpty ? code.replaceAll('_', ' ') : fallback);
  }

  Future<void> _assign() async {
    if (assigning) return;
    setState(() => assigning = true);
    try {
      final members = await fetchPostAssignees(data);
      if (!mounted) return;
      final picked = await showPostAssignSheet(
        context: context,
        members: members,
        selectedId: '${data['assignedToId'] ?? ''}',
      );
      if (picked == null || picked.isEmpty) return;
      final updated = await assignRegionPost(data, picked);
      if (!mounted) return;
      setState(() => data = updated);
      Get.find<SessionController>().upsertRegionPost(updated);
      flash('assign_issue_done'.trFallback('Assigned'), '${updated['assigneeName'] ?? ''}');
    } catch (e, stack) {
      AppLog.error('Assign post failed', error: e, stack: stack, tag: 'POST');
      flash('Error', apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => assigning = false);
    }
  }

  Future<void> _setStatus(String status) async {
    if (resolving) return;
    setState(() => resolving = true);
    try {
      final updated = await resolveRegionPost(data, status);
      if (!mounted) return;
      setState(() => data = updated);
      Get.find<SessionController>().upsertRegionPost(updated);
      flash(
        status == 'RESOLVED'
            ? 'resolve_done'.trFallback('Marked as resolved')
            : 'resolve_reopened'.trFallback('Reopened'),
        '',
      );
    } catch (e, stack) {
      AppLog.error('Resolve post failed', error: e, stack: stack, tag: 'POST');
      flash('Error', apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => resolving = false);
    }
  }

  Future<void> _summarise() async {
    if (summarising || data['pending'] == true) return;
    setState(() => summarising = true);
    try {
      final summary = await runWithSummaryLoading(context, () => summariseRegionPost(data));
      if (!mounted) return;
      if (summary.isEmpty) {
        flash('Error', 'summary_empty'.trFallback('Could not create a summary'));
        return;
      }
      setState(() => summarising = false);
      await showPostSummarySheet(
        context: context,
        summary: summary,
        onRegenerate: () => summariseRegionPost(data),
      );
    } catch (e, stack) {
      AppLog.error('Summarise post failed', error: e, stack: stack, tag: 'POST');
      flash('Error', apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => summarising = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = '${data['mediaType'] ?? 'image'}'.toLowerCase();
    final raw = data['mediaUrl'] ?? data['mediaPath'] ?? data['photoPath'] ?? data['mediaKey'];
    final path = switch (type) {
      'video' => postVideoUrl(data) ?? localPhotoPath(raw),
      'audio' => postAudioUrl(data) ?? localPhotoPath(raw),
      _ => postImageUrl(data) ?? localPhotoPath(raw),
    };
    final thumb = data['thumbnailUrl'] ?? data['thumbnailPath'] ?? data['thumbnailKey'] ?? resolveStreamThumbnailUrl(raw);
    final description = '${data['description'] ?? ''}'.trim();
    final issue = issueLabelOf(data);
    final region = '${data['regionLabel'] ?? ''}'.trim();
    final pending = data['pending'] == true;
    final canAssign = data['canAssign'] == true;
    final canSummarise = data['canSummarise'] == true;
    final showResolve = data['showResolve'] == true;
    final canResolve = data['canResolve'] == true;
    final resolved = '${data['status'] ?? ''}'.toUpperCase() == 'RESOLVED';
    final resolver = '${data['resolvedByName'] ?? ''}'.trim();
    return Scaffold(
      backgroundColor: HomeColors.paper,
      appBar: AppBar(
        backgroundColor: HomeColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: Text('post_details'.trFallback('Post')),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: HomeColors.navy,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: HomeColors.border, width: 0.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (path != null && path.isNotEmpty)
                  _DetailMedia(type: type, path: path, thumbnail: thumb, post: data),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (issue.isNotEmpty) ...[
                        IssueChip(label: issue, priority: issuePriorityOf(data)),
                        const SizedBox(height: 12),
                      ],
                      if (description.isNotEmpty) ...[
                        Text(
                          description,
                          style: const TextStyle(fontSize: 16, height: 1.45, color: HomeColors.ink),
                        ),
                        const SizedBox(height: 14),
                      ],
                      Text(
                        [
                          lastActiveWhen(data['createdAt']),
                          if (region.isNotEmpty) region,
                          if (pending) 'post_saved_offline'.trFallback('Saved on this phone'),
                        ].join(' · '),
                        style: const TextStyle(fontSize: 13, color: HomeColors.muted),
                      ),
                      if (_authorName.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _MetaBlock(
                          title: 'posted_by'.trFallback('Posted by'),
                          name: _authorName,
                          detail: _authorMobile,
                        ),
                      ],
                      if (_assignedToMe && _assignerName.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _MetaBlock(
                          title: 'post_assigned_by'.trFallback('Assigned by'),
                          name: _assignerName,
                          detail: _assignerPost,
                        ),
                      ] else if (!_assignedToMe && _assigneeName.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _MetaBlock(
                          title: 'assigned_to'.trFallback('Assigned to'),
                          name: _assigneeName,
                          detail: _assigneePost,
                        ),
                      ],
                      if (canSummarise) ...[
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: summarising ? null : _summarise,
                            icon: AiSparkleIcon(animating: summarising),
                            label: Text(
                              'get_summary'.trFallback('Summary by AI'),
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: HomeColors.orange,
                              side: const BorderSide(color: HomeColors.orange),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                            ),
                          ),
                        ),
                      ],
                      if (canAssign) ...[
                        SizedBox(height: canSummarise ? 10 : 18),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton(
                            onPressed: assigning ? null : _assign,
                            style: FilledButton.styleFrom(
                              backgroundColor: HomeColors.orange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                            ),
                            child: assigning
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                                  )
                                : Text(
                                    _assigneeName.isEmpty
                                        ? 'assign_issue'.trFallback('Assign to resolve')
                                        : 'assign_issue_change'.trFallback('Change assignee'),
                                    style: const TextStyle(fontWeight: FontWeight.w800),
                                  ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (showResolve) ...[
            const SizedBox(height: 12),
            Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: HomeColors.border, width: 0.5),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'resolve_section'.trFallback('Resolve'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: HomeColors.ink),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: resolved ? HomeColors.tealWash : HomeColors.peach2,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            resolved
                                ? 'resolve_resolved'.trFallback('Resolved')
                                : 'resolve_open'.trFallback('Open'),
                            style: TextStyle(
                              color: resolved ? HomeColors.teal : HomeColors.orangeDark,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (resolved && resolver.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${'resolve_by'.trFallback('Resolved by')} $resolver',
                              style: const TextStyle(fontSize: 13, color: HomeColors.muted),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (canResolve) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          onPressed: resolving ? null : () => _setStatus(resolved ? 'OPEN' : 'RESOLVED'),
                          style: FilledButton.styleFrom(
                            backgroundColor: resolved ? HomeColors.navy : HomeColors.teal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                          ),
                          child: resolving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                                )
                              : Text(
                                  resolved
                                      ? 'resolve_reopen'.trFallback('Reopen')
                                      : 'resolve_mark'.trFallback('Mark as resolved'),
                                  style: const TextStyle(fontWeight: FontWeight.w800),
                                ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaBlock extends StatelessWidget {
  const _MetaBlock({required this.title, required this.name, this.detail});
  final String title;
  final String name;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final extra = '${detail ?? ''}'.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: HomeColors.muted)),
        const SizedBox(height: 4),
        Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: HomeColors.ink)),
        if (extra.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(extra, style: const TextStyle(fontSize: 13, color: HomeColors.ink)),
        ],
      ],
    );
  }
}

class _DetailMedia extends StatelessWidget {
  const _DetailMedia({required this.type, required this.path, this.thumbnail, this.post});
  final String type;
  final String? path;
  final Object? thumbnail;
  final Map<String, dynamic>? post;

  @override
  Widget build(BuildContext context) {
    if (path == null || path!.isEmpty) {
      return const ColoredBox(color: HomeColors.navy, child: SizedBox(height: 220, width: double.infinity));
    }
    if (type == 'audio') return AudioListenBar(path: path!);
    if (type == 'video') {
      return VideoThumbTile(
        videoPath: path!,
        thumbnail: thumbnail,
        height: 240,
        onTap: () => Get.toNamed(Routes.postVideo, arguments: {
          ...?post,
          'path': path,
        }),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: localOrNetworkPhoto(
        raw: path,
        fit: BoxFit.cover,
        fallback: const ColoredBox(color: HomeColors.navy, child: SizedBox(height: 220)),
      ),
    );
  }
}
