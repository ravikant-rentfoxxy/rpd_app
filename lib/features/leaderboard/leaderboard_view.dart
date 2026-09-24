import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/api_error.dart';
import '../../core/widgets/empty_card.dart';
import '../../core/widgets/iro_ui.dart';
import '../../core/widgets/ui.dart';
import '../home/home_widgets.dart';
import '../join/join_chrome.dart';
import 'leaderboard_api.dart';
import '../../core/widgets/flash.dart';

class LeaderboardView extends StatefulWidget {
  const LeaderboardView({super.key});

  @override
  State<LeaderboardView> createState() => _LeaderboardViewState();
}

class _LeaderboardViewState extends State<LeaderboardView> {
  final data = Rxn<Map<String, dynamic>>();
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      data.value = await fetchLeaderboard();
    } catch (e) {
      data.value ??= {};
      flash('Error', apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: HomeColors.paper,
        appBar: OrganicAppBar(
          // Every way in here is a push — from More, from Community, and from
          // the rank tag on Home — so there is always somewhere to go back to.
          title: 'leaderboard'.trFallback('Leaderboard'),
        ),
        body: loading && data.value == null
            ? const Center(child: CircularProgressIndicator(color: HomeColors.orange))
            : Obx(() {
                final boards = Map<String, dynamic>.from(data.value?['boards'] as Map? ?? {});
                final me = Map<String, dynamic>.from(data.value?['me'] as Map? ?? {});
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: _RankSummary(boards: boards, tasksDone: me['tasksDone'], points: me['points']),
                    ),
                    TabBar(
                      labelColor: HomeColors.navy,
                      unselectedLabelColor: HomeColors.muted,
                      indicatorColor: HomeColors.orange,
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      tabs: [
                        Tab(text: 'leaderboard_ac'.trFallback('AC')),
                        Tab(text: 'leaderboard_district'.trFallback('District')),
                        Tab(text: 'leaderboard_state'.trFallback('State')),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _BoardList(board: _board(boards, 'assembly'), area: 'assembly'.tr, onRefresh: _load),
                          _BoardList(board: _board(boards, 'district'), area: 'district'.tr, onRefresh: _load),
                          _BoardList(board: _board(boards, 'state'), area: 'state'.tr, onRefresh: _load),
                        ],
                      ),
                    ),
                  ],
                );
              }),
      ),
    );
  }

  Map<String, dynamic> _board(Map<String, dynamic> boards, String key) {
    return Map<String, dynamic>.from(boards[key] as Map? ?? {});
  }
}

class _RankSummary extends StatelessWidget {
  const _RankSummary({required this.boards, required this.tasksDone, required this.points});
  final Map<String, dynamic> boards;
  final Object? tasksDone;
  final Object? points;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        gradient: Iro.headerGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: iroCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'leaderboard_sub'.trFallback('Your rank by tasks and points'),
            style: const TextStyle(fontSize: 12, color: HomeColors.navyMuted),
          ),
          const SizedBox(height: 6),
          Text(
            'leaderboard_score'.trParams({'tasks': '${tasksDone ?? 0}', 'points': '${points ?? 0}'}),
            style: homeTitleStyle(size: 20, color: Colors.white),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _chip('leaderboard_ac'.trFallback('AC'), boards['assembly']),
              const SizedBox(width: 8),
              _chip('leaderboard_district'.trFallback('District'), boards['district']),
              const SizedBox(width: 8),
              _chip('leaderboard_state'.trFallback('State'), boards['state']),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Object? raw) {
    final board = Map<String, dynamic>.from(raw as Map? ?? {});
    final rank = board['rank'];
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: const Color(0x33FFFFFF), borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: HomeColors.navyMuted, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              rank == null ? '—' : '#$rank',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class _BoardList extends StatelessWidget {
  const _BoardList({required this.board, required this.area, required this.onRefresh});
  final Map<String, dynamic> board;
  final String area;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final items = (board['items'] as List?) ?? [];
    final rank = board['rank'];
    final total = board['total'] ?? 0;
    final name = '${board['name'] ?? ''}'.trim();
    final missing = rank == null && items.isEmpty && total == 0 && name.isEmpty;

    return RefreshIndicator(
      color: HomeColors.orange,
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (name.isNotEmpty)
            IroSectionHeading(
              name,
              top: 0,
              trailing: rank == null ? null : 'rank_of'.trParams({'rank': '$rank', 'size': '$total'}),
              leading: const Icon(Icons.emoji_events_rounded, size: 17, color: Iro.gold),
            ),
          if (missing)
            Padding(
              padding: const EdgeInsets.only(top: 36),
              child: AppEmptyCard(
                icon: Icons.map_outlined,
                title: 'leaderboard_no_area'.trParams({'area': area}),
              ),
            )
          else if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 36),
              child: AppEmptyCard(
                icon: Icons.emoji_events_outlined,
                title: 'leaderboard_empty'.trFallback('No members in this area yet.'),
              ),
            )
          else
            ...items.map((raw) {
              final row = Map<String, dynamic>.from(raw as Map);
              return RankRow(row: row);
            }),
        ],
      ),
    );
  }
}

/// One place on the board.
///
/// The top three carry a medal rather than a bare number, and the member's own
/// row is ringed so they can find themselves without reading every name.
class RankRow extends StatelessWidget {
  const RankRow({super.key, required this.row});
  final Map<String, dynamic> row;

  static const _medals = {1: Iro.gold, 2: Color(0xFF9AA5AD), 3: Color(0xFFB07B4F)};

  @override
  Widget build(BuildContext context) {
    final rank = (row['rank'] as num? ?? 0).toInt();
    final name = '${row['fullName'] ?? ''}'.trim();
    final tasks = row['tasksDone'] as num? ?? 0;
    final points = row['points'] as num? ?? 0;
    final mine = row['isMe'] == true;
    final medal = _medals[rank];
    final initials =
        name.isEmpty ? '?' : name.trim().split(RegExp(r'\s+')).take(2).map((p) => p[0]).join().toUpperCase();

    return IroCard(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.fromLTRB(11, 10, 12, 10),
      color: mine ? Iro.wash : Iro.surface,
      border: mine ? Iro.leaf : Iro.line,
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: medal == null
                ? Text(
                    '$rank',
                    textAlign: TextAlign.center,
                    style: iroLabel(size: 13, color: Iro.muted, weight: FontWeight.w800),
                  )
                : Icon(Icons.workspace_premium_rounded, size: 21, color: medal),
          ),
          const SizedBox(width: 7),
          AvatarCircle(initials, imageUrl: row['photoUrl'] as String?, radius: 19),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  mine ? '$name (${'you'.trFallback('you')})' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: iroDisplay(size: 14.5),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _Stat(icon: Icons.check_circle_outline_rounded, value: '$tasks'),
                    const SizedBox(width: 11),
                    _Stat(icon: Icons.bolt_rounded, value: '$points'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A figure with the icon that says what it counts, so the row does not have to
/// spell out "tasks" and "points" on every line.
class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value});
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Iro.muted),
        const SizedBox(width: 4),
        Text(value, style: iroLabel(size: 11.5, color: Iro.ink2, weight: FontWeight.w700)),
      ],
    );
  }
}
