import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rpd_app/features/join/join_chrome.dart';
import '../../core/constants/org_hierarchy.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/api_error.dart';
import '../../core/widgets/empty_card.dart';
import '../../core/widgets/ui.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/endpoints.dart';
import '../../core/widgets/flash.dart';
import '../../core/widgets/iro_ui.dart';
import '../session/session_controller.dart';
import 'leaders_api.dart';
import 'invite_api.dart';

/// Levels the ladder leaves out. See [_MyLeadersViewState._load].
const _hiddenLevels = {'MANDAL', 'BOOTH'};

/// Step-by-step chain of office bearers above the member, from national down to
/// their assembly.
class MyLeadersView extends StatefulWidget {
  const MyLeadersView({super.key});

  @override
  State<MyLeadersView> createState() => _MyLeadersViewState();
}

class _MyLeadersViewState extends State<MyLeadersView> {
  List<Map<String, dynamic>> levels = const [];
  /// Which posts this member may issue a code for. Empty for anyone without a
  /// post above the one being offered, which keeps the action off their screen.
  List<AssignablePost> assignable = const [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = levels.isEmpty;
      error = null;
    });
    try {
      final rows = await fetchMyLeaders();
      // Mandal and booth are left off the ladder: there are none on the
      // register, so both rungs only ever read "No one appointed yet" with no
      // area beside them. Drop this filter to bring them back once booths
      // exist — the server still sends them.
      final shown = rows.where((row) => !_hiddenLevels.contains('${row['level'] ?? ''}')).toList();
      // Best effort: the ladder is the point, and an ordinary member is
      // expected to be refused here.
      final posts = await fetchAssignablePosts().catchError((_) => <AssignablePost>[]);
      if (!mounted) return;
      setState(() {
        levels = shown;
        assignable = posts;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeColors.paper,
      appBar: OrganicAppBar(title: 'my_leaders'.trFallback('My leaders')),
      body: Builder(
        builder: (context) {
          if (loading) {
            return const Center(child: CircularProgressIndicator(color: HomeColors.orange));
          }
          if (error != null && levels.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: AppEmptyCard(
                  icon: Icons.account_tree_outlined,
                  title: error!,
                  actionLabel: 'retry'.trFallback('Retry'),
                  onAction: _load,
                ),
              ),
            );
          }
          if (levels.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: AppEmptyCard(
                  icon: Icons.account_tree_outlined,
                  title: 'my_leaders_empty'.trFallback('Add your booth to your profile to see your leaders.'),
                ),
              ),
            );
          }
          return RefreshIndicator(
            color: HomeColors.orange,
            onRefresh: _load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'my_leaders_intro'.trFallback('Office bearers who lead your area, from the top down to your constituency.'),
                    style: const TextStyle(fontSize: 13, color: HomeColors.muted),
                  ),
                ),
                for (var i = 0; i < levels.length; i++)
                  _LevelStep(
                    level: levels[i],
                    step: i + 1,
                    isLast: i == levels.length - 1,
                    assignable: assignable,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LevelStep extends StatelessWidget {
  const _LevelStep({
    required this.level,
    required this.step,
    required this.isLast,
    this.assignable = const [],
  });

  final Map<String, dynamic> level;
  final int step;
  final bool isLast;
  final List<AssignablePost> assignable;

  /// The posts at this level this member is allowed to hand out. The server
  /// decides which posts; this only sorts them onto the right rung.
  List<AssignablePost> get _offerable {
    final code = '${level['level'] ?? ''}';
    return assignable.where((p) => levelOfPost(p.post) == code).toList();
  }

  String get _levelTitle {
    final code = '${level['level'] ?? ''}';
    final fallback = switch (code) {
      'NATIONAL' => 'National',
      'STATE' => 'State',
      'REGION' => 'Region',
      'DISTRICT' => 'District',
      'ASSEMBLY' => 'Assembly',
      'MANDAL' => 'Mandal',
      'BOOTH' => 'Booth',
      _ => code,
    };
    return 'leader_level_$code'.trFallback(fallback);
  }

  String get _areaName {
    final hi = '${level['areaNameHi'] ?? ''}'.trim();
    final en = '${level['areaName'] ?? ''}'.trim();
    final lang = Get.locale?.languageCode ?? 'en';
    if (hi.isNotEmpty && (lang == 'hi' || lang == 'bho')) return hi;
    return en;
  }

  @override
  Widget build(BuildContext context) {
    final leaders = (level['leaders'] as List? ?? const []).whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList();
    final area = _areaName;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: leaders.isEmpty ? HomeColors.border : HomeColors.navy,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$step',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: leaders.isEmpty ? HomeColors.muted : Colors.white,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, margin: const EdgeInsets.symmetric(vertical: 4), color: HomeColors.border),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: _levelTitle,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: HomeColors.ink),
                          ),
                          if (area.isNotEmpty)
                            TextSpan(
                              text: '  ·  $area',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: HomeColors.muted),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (leaders.isEmpty)
                    Text(
                      'leader_not_appointed'.trFallback('No one appointed yet'),
                      style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: HomeColors.muted2),
                    )
                  else
                    for (final leader in leaders) _LeaderTile(leader: leader),
                  // Under the names rather than in place of them: a level can
                  // have someone in post and still have room for another.
                  if (_offerable.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _InviteAction(posts: _offerable, areaName: area),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderTile extends StatelessWidget {
  const _LeaderTile({required this.leader});

  final Map<String, dynamic> leader;

  @override
  Widget build(BuildContext context) {
    final name = '${leader['name'] ?? ''}'.trim();
    final code = '${leader['post'] ?? ''}';
    final fallback = '${leader['postLabel'] ?? ''}'.trim();
    var post = postLabelKey(code).trFallback(fallback.isEmpty ? code.replaceAll('_', ' ') : fallback);
    final page = leader['pageNumber'];
    if (code == 'PANNA_PRAMUKH' && page != null) post = '$post · ${'page'.trFallback('Page')} $page';
    final isMe = leader['isMe'] == true;
    final initials = name.isEmpty
        ? '?'
        : name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).take(2).map((p) => p[0].toUpperCase()).join();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? HomeColors.peach2 : HomeColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isMe ? HomeColors.orangeSoft : HomeColors.border),
      ),
      child: Row(
        children: [
          AvatarCircle(
            initials,
            radius: 20,
            imageUrl: leader['photoUrl'] as String?,
            color: HomeColors.navy,
            bg: HomeColors.peach,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: HomeColors.ink),
                ),
                const SizedBox(height: 2),
                Text(post, style: const TextStyle(fontSize: 13, color: HomeColors.muted)),
              ],
            ),
          ),
          if (isMe)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: HomeColors.orange, borderRadius: BorderRadius.circular(999)),
              child: Text(
                'you'.trFallback('You'),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

/// Hands out a code for a post at this level.
///
/// Only drawn when the server says this member may issue one, so the button
/// appearing is itself the answer to "am I senior enough". Minting and sharing
/// are one press: a code nobody was given is just a row in a table.
class _InviteAction extends StatefulWidget {
  const _InviteAction({required this.posts, required this.areaName});

  final List<AssignablePost> posts;
  final String areaName;

  @override
  State<_InviteAction> createState() => _InviteActionState();
}

class _InviteActionState extends State<_InviteAction> {
  bool busy = false;

  Future<void> _run() async {
    if (busy) return;
    final post = widget.posts.length == 1 ? widget.posts.first : await _pick();
    if (post == null || !mounted) return;

    setState(() => busy = true);
    try {
      // The area comes from the sharer's own profile: this ladder is their own
      // chain, so their district is the district, their assembly the assembly.
      final member = Get.isRegistered<SessionController>() ? Get.find<SessionController>().member : null;
      final areaId = areaIdFor(member, post.requires);
      if (post.requires != null && areaId == null) {
        // Only reachable if the server starts asking for a scope the profile
        // does not carry; fetchAssignablePosts drops the known ones already.
        flash('Error', 'refer_no_area'.trFallback('Add this area to your profile first.'));
        return;
      }
      final invite = await createPostInvite(
        post: post.post,
        // Only sent when the server asks for one — a district post takes the
        // issuer's own district, and passing an id it did not ask for is how
        // an invite ends up scoped to the wrong place.
        scopeField: post.requires,
        areaId: areaId,
      );
      if (!mounted) return;
      await _share(invite);
    } catch (e) {
      flash('Error', apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  /// Which post, when a level holds more than one.
  Future<AssignablePost?> _pick() {
    return Get.bottomSheet<AssignablePost>(
      SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: const BoxDecoration(
            color: Iro.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(color: Iro.line, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 14),
              Text('refer_pick_post'.trFallback('Which post?'), style: iroDisplay(size: 16)),
              const SizedBox(height: 10),
              for (final post in widget.posts)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.badge_outlined, size: 20, color: Iro.green),
                  title: Text(post.title, style: iroLabel(size: 13.5, weight: FontWeight.w700)),
                  onTap: () => Get.back(result: post),
                ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> _share(PostInvite invite) async {
    final where = invite.where.isEmpty ? widget.areaName : invite.where;
    final text = [
      'refer_post_intro'.trParams({'post': invite.postTitle, 'where': where}),
      'refer_share_code'.trParams({'code': invite.code}),
      ExternalLinks.playStore,
    ].join('\n\n');

    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: invite.postTitle,
        sharePositionOrigin: box == null ? Rect.zero : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.posts.length == 1
        ? 'refer_invite_post'.trParams({'post': widget.posts.first.title})
        : 'refer_invite'.trFallback('Invite someone');
    return Align(
      alignment: Alignment.centerLeft,
      child: IroGhostButton(
        label: busy ? '…' : label,
        icon: Icons.person_add_alt_1_rounded,
        tone: Iro.green,
        onTap: busy ? null : _run,
      ),
    );
  }
}
