import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/constants/org_hierarchy.dart';
import '../../core/constants/post_issues.dart';
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
import 'post_media_viewer.dart';
import 'post_summary_sheet.dart';
import 'summary_loading.dart';
import '../../core/widgets/iro_ui.dart';
import '../../data/local/hive_service.dart';
import '../../core/widgets/ui.dart';
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
  var voting = false;

  @override
  void initState() {
    super.initState();
    final raw = Get.arguments;
    data = raw is Map ? Map<String, dynamic>.from(raw) : {};
    _refresh();
    _countView();
  }

  /// Opening the post is what counts as a view — this screen is where both the
  /// card tap and Inspect end up. Best effort: a post that cannot be counted
  /// still reads fine, so a failure is logged and nothing else.
  Future<void> _countView() async {
    if (data['pending'] == true) return;
    try {
      final views = await markPostViewed(data);
      if (!mounted) return;
      setState(() => data = {...data, 'views': views});
      Get.find<SessionController>().patchPostViews(data, views);
    } catch (e, stack) {
      AppLog.error('count post view failed', error: e, stack: stack, tag: 'POST');
    }
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

  int get _views => (data['views'] as num?)?.round() ?? 0;

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

  /// Voting on your own post is not a thing, so the member's own posts show
  /// the figures without the buttons — the same split the list makes.
  bool get _mine => Get.find<HiveService>().isOwnPost(data);

  bool get _pending => data['pending'] == true || '${data['serverId'] ?? ''}'.isEmpty;

  Future<void> _vote(String side) async {
    if (voting || _pending) return;
    setState(() => voting = true);
    try {
      final updated = await Get.find<SessionController>().voteOnPost(data, side);
      if (!mounted) return;
      setState(() => data = updated);
    } catch (e) {
      flash('Error', apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => voting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = isVideoPost(data) ? 'video' : '${data['mediaType'] ?? 'image'}'.toLowerCase();
    final raw = data['mediaUrl'] ?? data['mediaPath'] ?? data['photoPath'] ?? data['mediaKey'];
    final path = switch (type) {
      'video' => postVideoUrl(data) ?? localPhotoPath(raw),
      'audio' => postAudioUrl(data) ?? localPhotoPath(raw),
      _ => postImageUrl(data) ?? localPhotoPath(raw),
    };
    final thumb = data['thumbnailUrl'] ?? data['thumbnailPath'] ?? data['thumbnailKey'] ?? resolveStreamThumbnailUrl(raw);
    final description = '${data['description'] ?? ''}'.trim();
    final category = issueCategoryLabelOf(data);
    final title = issueLabelOf(data);
    final region = '${data['regionLabel'] ?? ''}'.trim();
    final pending = data['pending'] == true;
    final canAssign = data['canAssign'] == true;
    final canSummarise = data['canSummarise'] == true;
    final showResolve = data['showResolve'] == true;
    final canResolve = data['canResolve'] == true;
    final resolved = '${data['status'] ?? ''}'.toUpperCase() == 'RESOLVED';
    final resolver = '${data['resolvedByName'] ?? ''}'.trim();
    final myVote = '${data['myVote'] ?? ''}'.toUpperCase();
    final likes = (data['likes'] as num?)?.round() ?? 0;
    final dislikes = (data['dislikes'] as num?)?.round() ?? 0;
    final hasPeople = _authorName.isNotEmpty ||
        (_assignedToMe && _assignerName.isNotEmpty) ||
        (!_assignedToMe && _assigneeName.isNotEmpty);

    return Scaffold(
      backgroundColor: Iro.mint,
      appBar: OrganicAppBar(
        title: 'post_details'.trFallback('Post'),
        subtitle: region.isEmpty ? null : region,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          IroCard(
            margin: EdgeInsets.zero,
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    _DetailMedia(type: type, path: path, thumbnail: thumb, post: data),
                    if (category.isNotEmpty)
                      Positioned(
                        left: 10,
                        top: 10,
                        child: IroChip(
                          category,
                          dense: true,
                          size: 10,
                          icon: issueIconOf(data),
                          fg: Colors.white,
                          bg: const Color(0xD9114A2C),
                        ),
                      ),
                    if (resolved)
                      Positioned(
                        right: 10,
                        top: 10,
                        child: IroChip(
                          'resolve_resolved'.tr,
                          dense: true,
                          size: 10,
                          fg: Colors.white,
                          bg: const Color(0xD91C7D48),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 14, 15, 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: iroDisplay(size: 19)),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          description,
                          style: iroLabel(size: 13.5, color: Iro.ink2, weight: FontWeight.w500)
                              .copyWith(height: 1.5),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Text(
                        [
                          lastActiveWhen(data['createdAt']),
                          if (region.isNotEmpty) region,
                          if (pending) 'post_saved_offline'.trFallback('Saved on this phone'),
                        ].join(' · '),
                        style: iroLabel(size: 11.5, color: Iro.muted, weight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          IroVoteButton(
                            icon: myVote == 'LIKE' ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
                            count: likes,
                            on: myVote == 'LIKE',
                            tone: Iro.greenMid,
                            enabled: !_pending && !voting,
                            onTap: _mine ? null : () => _vote('LIKE'),
                          ),
                          const SizedBox(width: 8),
                          IroVoteButton(
                            icon: myVote == 'DISLIKE' ? Icons.thumb_down_rounded : Icons.thumb_down_outlined,
                            count: dislikes,
                            on: myVote == 'DISLIKE',
                            tone: Iro.alert,
                            enabled: !_pending && !voting,
                            onTap: _mine ? null : () => _vote('DISLIKE'),
                          ),
                          const Spacer(),
                          IroViewCount(_views, size: 12.5),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (hasPeople) ...[
            const SizedBox(height: 12),
            IroCard(
              margin: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_authorName.isNotEmpty)
                    _MetaBlock(
                      title: 'posted_by'.trFallback('Posted by'),
                      name: _authorName,
                      detail: _authorMobile,
                    ),
                  if (_assignedToMe && _assignerName.isNotEmpty) ...[
                    if (_authorName.isNotEmpty) const _MetaRule(),
                    _MetaBlock(
                      title: 'post_assigned_by'.trFallback('Assigned by'),
                      name: _assignerName,
                      detail: _assignerPost,
                    ),
                  ] else if (!_assignedToMe && _assigneeName.isNotEmpty) ...[
                    if (_authorName.isNotEmpty) const _MetaRule(),
                    _MetaBlock(
                      title: 'assigned_to'.trFallback('Assigned to'),
                      name: _assigneeName,
                      detail: _assigneePost,
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (canSummarise || canAssign) ...[
            const SizedBox(height: 12),
            IroCard(
              margin: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (canSummarise)
                    IroGhostButton(
                      label: 'get_summary'.trFallback('Summary by AI'),
                      tone: Iro.green,
                      onTap: summarising ? null : _summarise,
                    ),
                  if (canAssign) ...[
                    if (canSummarise) const SizedBox(height: 10),
                    IroActionButton(
                      label: _assigneeName.isEmpty
                          ? 'assign_issue'.trFallback('Assign to resolve')
                          : 'assign_issue_change'.trFallback('Change assignee'),
                      icon: Icons.person_add_alt_1_rounded,
                      enabled: !assigning,
                      onTap: assigning ? null : _assign,
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (showResolve) ...[
            const SizedBox(height: 12),
            IroCard(
              margin: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IroSectionHeading('resolve_section'.trFallback('Resolve')),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      IroChip(
                        resolved ? 'resolve_resolved'.tr : 'resolve_open'.trFallback('Open'),
                        dot: true,
                        size: 11,
                        fg: resolved ? Iro.green : Iro.bright,
                        bg: resolved ? Iro.wash : const Color(0xFFFFF1DC),
                      ),
                      if (resolved && resolver.isNotEmpty) ...[
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            '${'resolve_by'.trFallback('Resolved by')} $resolver',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: iroLabel(size: 11.5, color: Iro.muted, weight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (canResolve) ...[
                    const SizedBox(height: 14),
                    // Closing something out is the go-ahead; reopening is a
                    // step backwards, so it gets the quieter outlined button.
                    if (resolved)
                      IroGhostButton(
                        label: 'resolve_reopen'.trFallback('Reopen'),
                        icon: Icons.replay_rounded,
                        onTap: resolving ? null : () => _setStatus('OPEN'),
                      )
                    else
                      IroActionButton(
                        label: 'resolve_mark'.trFallback('Mark as resolved'),
                        icon: Icons.check_circle_outline_rounded,
                        enabled: !resolving,
                        onTap: resolving ? null : () => _setStatus('RESOLVED'),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A hairline between two people on the same card.
class _MetaRule extends StatelessWidget {
  const _MetaRule();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 11),
        child: Divider(height: 1, thickness: 1, color: Iro.line),
      );
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

/// The media at the top of a post.
///
/// Capped at [postMediaThumbFraction] of the screen. It used to size itself to
/// the picture, so a portrait photo pushed the description, the people and the
/// actions off the bottom — the thing a member opened the post to read was the
/// thing they could not see.
class _DetailMedia extends StatelessWidget {
  const _DetailMedia({required this.type, required this.path, this.thumbnail, this.post});
  final String type;
  final String? path;
  final Object? thumbnail;
  final Map<String, dynamic>? post;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * postMediaThumbFraction;
    final row = post ?? const <String, dynamic>{};

    if (path == null || path!.isEmpty) {
      return PostMediaPlaceholder(kind: PostMediaPlaceholder.kindFor(type), height: height);
    }
    // A recording is a control, not something to look at, so it stays inline
    // where it can be played while the rest of the post is read.
    if (type == 'audio') return AudioListenBar(path: path!);
    if (type == 'video') {
      return PostVideoThumb(post: row, videoPath: path!, thumbnail: thumbnail, height: height);
    }
    return PostImageThumb(post: row, raw: path, height: height);
  }
}
