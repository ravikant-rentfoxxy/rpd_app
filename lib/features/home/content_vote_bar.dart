import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/api_error.dart';
import '../../core/widgets/flash.dart';
import '../../core/widgets/iro_ui.dart';
import '../../data/models/home_feed.dart';
import '../../data/remote/api_client.dart';
import '../session/session_controller.dart';

/// Like or dislike a published video or blog. Sends the side the member tapped;
/// the server reads the side they already hold as taking the vote back.
Future<HomeFeedItem> voteOnContent(HomeFeedItem item, String? vote) async {
  final res = await Get.find<ApiClient>().post(
    '/content/${item.voteKind}/${item.id}/vote',
    data: {'vote': vote},
  );
  final data = Map<String, dynamic>.from(res['data'] as Map);
  return item.withVote(
    likes: (data['likes'] as num?)?.round() ?? 0,
    dislikes: (data['dislikes'] as num?)?.round() ?? 0,
    myVote: '${data['myVote'] ?? ''}'.toUpperCase(),
  );
}

/// The like/dislike pair shown under a video or blog. Keeps the item it is
/// drawing in its own state, so a card redraws the moment the server answers
/// without waiting for the whole home feed to reload.
class ContentVoteBar extends StatefulWidget {
  const ContentVoteBar({super.key, required this.item, this.compact = false, this.alignEnd = false});

  final HomeFeedItem item;

  /// Tighter padding and no labels, for a card in a rail.
  final bool compact;
  final bool alignEnd;

  @override
  State<ContentVoteBar> createState() => _ContentVoteBarState();
}

class _ContentVoteBarState extends State<ContentVoteBar> {
  late HomeFeedItem item = widget.item;
  bool sending = false;

  @override
  void didUpdateWidget(ContentVoteBar old) {
    super.didUpdateWidget(old);
    // A reload of the feed brings fresh counts; adopt them unless this bar is
    // mid-flight with a vote of its own.
    if (!sending && widget.item.id != old.item.id) item = widget.item;
  }

  Future<void> _vote(String side) async {
    // An item the server has never seen has nothing to vote on.
    if (sending || item.id.isEmpty) return;
    setState(() => sending = true);
    try {
      final updated = await voteOnContent(item, side);
      if (!mounted) return;
      setState(() => item = updated);
      Get.find<SessionController>().patchContentVote(updated);
    } catch (e) {
      if (mounted) flash('Error', apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (item.id.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: widget.alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _VoteChip(
          icon: item.myVote == 'LIKE' ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
          count: item.likes,
          on: item.myVote == 'LIKE',
          tone: Iro.greenMid,
          compact: widget.compact,
          onTap: () => _vote('LIKE'),
        ),
        SizedBox(width: widget.compact ? 6 : 8),
        _VoteChip(
          icon: item.myVote == 'DISLIKE' ? Icons.thumb_down_rounded : Icons.thumb_down_outlined,
          count: item.dislikes,
          on: item.myVote == 'DISLIKE',
          tone: Iro.alert,
          compact: widget.compact,
          onTap: () => _vote('DISLIKE'),
        ),
      ],
    );
  }
}

class _VoteChip extends StatelessWidget {
  const _VoteChip({
    required this.icon,
    required this.count,
    required this.on,
    required this.tone,
    required this.compact,
    required this.onTap,
  });

  final IconData icon;
  final int count;
  final bool on;
  final Color tone;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = on ? tone : Iro.ink2;
    final radius = BorderRadius.circular(compact ? 8 : 10);
    return Material(
      color: on ? tone.withValues(alpha: 0.10) : Iro.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: on ? tone.withValues(alpha: 0.45) : Iro.line),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: compact
              ? const EdgeInsets.symmetric(horizontal: 7, vertical: 5)
              : const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: compact ? 13 : 15, color: fg),
              const SizedBox(width: 5),
              Text(
                '$count',
                style: iroLabel(size: compact ? 10.5 : 12, color: fg, weight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
