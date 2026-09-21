import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rpd_app/features/join/join_chrome.dart';
import '../../core/constants/org_hierarchy.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/api_error.dart';
import '../../core/widgets/empty_card.dart';
import '../../core/widgets/ui.dart';
import 'leaders_api.dart';

/// Step-by-step chain of office bearers above the member, from national down to their booth.
class MyLeadersView extends StatefulWidget {
  const MyLeadersView({super.key});

  @override
  State<MyLeadersView> createState() => _MyLeadersViewState();
}

class _MyLeadersViewState extends State<MyLeadersView> {
  List<Map<String, dynamic>> levels = const [];
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
      if (!mounted) return;
      setState(() => levels = rows);
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
                    'my_leaders_intro'.trFallback('Office bearers who lead your area, from the top down to your booth.'),
                    style: const TextStyle(fontSize: 13, color: HomeColors.muted),
                  ),
                ),
                for (var i = 0; i < levels.length; i++)
                  _LevelStep(level: levels[i], step: i + 1, isLast: i == levels.length - 1),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LevelStep extends StatelessWidget {
  const _LevelStep({required this.level, required this.step, required this.isLast});

  final Map<String, dynamic> level;
  final int step;
  final bool isLast;

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
