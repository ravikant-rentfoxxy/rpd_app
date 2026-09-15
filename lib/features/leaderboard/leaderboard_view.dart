import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/api_error.dart';
import '../../core/widgets/empty_card.dart';
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
          title: 'leaderboard'.trFallback('Leaderboard'),
          automaticallyImplyLeading: false,
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
      decoration: BoxDecoration(color: HomeColors.navy, borderRadius: BorderRadius.circular(24)),
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
        decoration: BoxDecoration(color: HomeColors.navyMid, borderRadius: BorderRadius.circular(16)),
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
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(name, style: homeTitleStyle(size: 16)),
            ),
          if (rank != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'rank_of'.trParams({'rank': '$rank', 'size': '$total'}),
                style: const TextStyle(color: HomeColors.muted, fontWeight: FontWeight.w600),
              ),
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
              return _RankRow(row: row);
            }),
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.row});
  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final rank = row['rank'] as num? ?? 0;
    final name = '${row['fullName'] ?? ''}'.trim();
    final tasks = row['tasksDone'] as num? ?? 0;
    final points = row['points'] as num? ?? 0;
    final mine = row['isMe'] == true;
    final initials = name.isEmpty ? '?' : name.trim().split(RegExp(r'\s+')).take(2).map((p) => p[0]).join().toUpperCase();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
      decoration: BoxDecoration(
        color: mine ? HomeColors.peach2 : HomeColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: mine ? HomeColors.orange : HomeColors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$rank',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: rank <= 3 ? HomeColors.orange : HomeColors.navy,
              ),
            ),
          ),
          const SizedBox(width: 8),
          AvatarCircle(initials, imageUrl: row['photoUrl'] as String?, radius: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mine ? '$name (${'you'.trFallback('you')})' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, color: HomeColors.ink),
                ),
                Text(
                  'leaderboard_score'.trParams({'tasks': '$tasks', 'points': '$points'}),
                  style: const TextStyle(fontSize: 12, color: HomeColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
