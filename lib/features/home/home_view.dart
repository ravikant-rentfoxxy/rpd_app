import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/local_image.dart';
import '../../core/utils/relative_time.dart';
import '../../core/widgets/language_dropdown.dart';
import '../../data/models/home_feed.dart';
import '../session/session_controller.dart';
import 'home_widgets.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionController>();
    if (session.home.value == null) {
      session.loadHome();
    }
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: HomeColors.navy,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Obx(() {
        final member = session.member ?? {};
        final home = session.home.value;
        final stats = Map<String, dynamic>.from(home?['stats'] as Map? ?? {});
        final booth = member['booth'] as Map?;
        final queue = session.syncCount.value;
        final events = upcomingEventsFrom(
          home?['upcomingEvents'] as List?,
          useFallback: true,
          limit: 5,
        );
        final videos = feedItemsFrom(home?['recentVideos'] as List?, fallback: recentVideos);
        final blogs = feedItemsFrom(home?['recentBlogs'] as List?, fallback: recentBlogs);
        session.postsTick.value;
        final nearbyPosts = session.hive.recentRegionalPosts(limit: 5);
        final boothScore = (stats['boothScore'] ?? booth?['healthScore'] ?? 61) as num;
        final displayName = _displayName(member);
        final topInset = MediaQuery.paddingOf(context).top;
        return ColoredBox(
          color: HomeColors.paper,
          child: RefreshIndicator(
            color: HomeColors.orange,
            displacement: topInset + 80,
            onRefresh: session.loadHome,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _HomeHeaderDelegate(
                    topInset: topInset,
                    greeting: _dayGreeting(),
                    name: displayName,
                    photoUrl: memberPhotoRef(member),
                    initials: _initials(member['fullName'] as String?),
                    score: boothScore,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 36),
                  sliver: SliverList.list(
                    children: [
                      if (queue > 0)
                        _InfoBanner(
                          title: 'queue_bar'.trParams({'n': '$queue'}),
                          subtitle: '',
                          icon: Icons.cloud_upload_outlined,
                          onTap: () => Get.toNamed(Routes.sync),
                        ),
                      if (session.needsVerification)
                        _InfoBanner(
                          title: 'not_verified'.tr,
                          subtitle: 'complete_verification'.tr,
                          icon: Icons.verified_outlined,
                          onTap: session.openJoinVerification,
                        ),
                      _InfoBanner(
                        title: 'tasks_due'.trParams({'n': '${_tasksDue(home).length}'}),
                        subtitle: 'tasks_activity_sub'.tr,
                        icon: Icons.check_rounded,
                        onTap: () => session.shellIndex.value = 1,
                      ),
                      HomeEventsBanner(events: events),
                      _StatsRow(
                        members: '${stats['membersAdded'] ?? 0}',
                        meetings: '${stats['meetingsHeld'] ?? 0}',
                      ),
                      _LeaderCard(
                        rank: '${stats['mandalRank'] ?? 1}',
                        size: '${stats['mandalSize'] ?? 1}',
                        monthPoints: '${stats['points'] ?? 0}',
                        score: boothScore,
                      ),
                      HomeSectionHeader(
                        title: 'recent_videos'.tr,
                        eyebrow: 'watch_learn'.tr,
                        onSeeMore: () => Get.toNamed(Routes.recentVideos),
                      ),
                      HomeVideoGrid(items: videos),
                      HomeSectionHeader(
                        title: 'recent_blogs'.tr,
                        onSeeMore: () => Get.toNamed(Routes.recentBlogs),
                      ),
                      HomeFeedRail(items: blogs, kind: HomeFeedKind.blog),
                      HomeSectionHeader(
                        title: 'recent_activity_near'.tr,
                        onSeeMore: () => Get.toNamed(Routes.posts),
                      ),
                      HomePostsRail(posts: nearbyPosts),
                      _LastActivityCard(
                        when: lastActiveWhen(home?['lastActiveAt']),
                        title: _lastActivitySub(home?['lastActivity']),
                        onTap: () {
                          if (!session.guardVerifiedAccess()) return;
                          session.shellIndex.value = 1;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _HomeHeaderDelegate extends SliverPersistentHeaderDelegate {
  _HomeHeaderDelegate({
    required this.topInset,
    required this.greeting,
    required this.name,
    required this.photoUrl,
    required this.initials,
    required this.score,
  });

  final double topInset;
  final String greeting;
  final String name;
  final String? photoUrl;
  final String initials;
  final num score;

  static const _expandedExtra = 214.0;
  static const _collapsedExtra = 70.0;

  @override
  double get maxExtent => topInset + _expandedExtra;

  @override
  double get minExtent => topInset + _collapsedExtra;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final range = (maxExtent - minExtent).clamp(1.0, 400.0);
    final collapse = (shrinkOffset / range).clamp(0.0, 1.0);
    final expand = 1 - collapse;
    final radius = 30.0 * expand;
    final avatar = 44.0 - (8 * collapse);
    return SizedBox.expand(
      child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [HomeColors.navy, HomeColors.navyMid],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(radius)),
        boxShadow: [
          if (collapse > 0.15)
            BoxShadow(
              color: const Color(0x331B1740).withValues(alpha: 0.28 * collapse),
              blurRadius: 16 * collapse,
              offset: Offset(0, 6 * collapse),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(radius)),
        child: Padding(
        padding: EdgeInsets.fromLTRB(20, topInset + 10 + (12 * expand), 20, 12 + (22 * expand)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Get.toNamed(Routes.profile),
                  child: Container(
                    width: avatar,
                    height: avatar,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [HomeColors.peach, Color(0xFFF0C48A)],
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: localOrNetworkPhoto(
                      raw: photoUrl,
                      fallback: Center(
                        child: Text(
                          initials,
                          style: GoogleFonts.poppins(color: HomeColors.navy, fontWeight: FontWeight.w800, fontSize: 14 - (2 * collapse)),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRect(
                        child: Align(
                          alignment: Alignment.topLeft,
                          heightFactor: expand,
                          child: Opacity(
                            opacity: expand,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text(greeting, style: const TextStyle(color: HomeColors.navyMuted, fontSize: 12)),
                            ),
                          ),
                        ),
                      ),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 19 - (3 * collapse),
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const LanguageDropdown(pill: true),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => Get.toNamed(Routes.notifications),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 17),
                      ),
                      Positioned(
                        top: -5,
                        right: -5,
                        child: Container(
                          width: 17,
                          height: 17,
                          decoration: BoxDecoration(
                            color: HomeColors.orange,
                            shape: BoxShape.circle,
                            border: Border.all(color: HomeColors.navy, width: 2),
                          ),
                          alignment: Alignment.center,
                          child: const Text('2', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: expand,
                child: Opacity(
                  opacity: expand,
                  child: IgnorePointer(
                    ignoring: expand < 0.55,
                    child: Padding(
                    padding: EdgeInsets.only(top: 26 * expand),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('community_score'.tr, style: const TextStyle(color: HomeColors.navyMuted, fontSize: 12)),
                              const SizedBox(height: 6),
                              Text.rich(
                                TextSpan(
                                  text: '${score.round()}',
                                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800, height: 1),
                                  children: [
                                    TextSpan(
                                      text: '/100',
                                      style: GoogleFonts.poppins(color: HomeColors.navyMuted, fontSize: 16, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Get.toNamed(Routes.boothHealth),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                            decoration: BoxDecoration(
                              color: HomeColors.orange,
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: const [BoxShadow(color: Color(0x66F07E1D), blurRadius: 16, offset: Offset(0, 8))],
                            ),
                            child: Text(
                              'view_booth'.tr,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ),
                ),
              ),
            ),
          ],
        ),
        ),
      ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _HomeHeaderDelegate oldDelegate) {
    return oldDelegate.topInset != topInset ||
        oldDelegate.greeting != greeting ||
        oldDelegate.name != name ||
        oldDelegate.photoUrl != photoUrl ||
        oldDelegate.initials != initials ||
        oldDelegate.score != score;
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(18)),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [HomeColors.peach, HomeColors.peach2],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(color: HomeColors.orange, shape: BoxShape.circle),
                    child: Icon(icon, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: HomeColors.ink)),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 1),
                          Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF8A7A5E))),
                        ],
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_rounded, color: HomeColors.orange, size: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.members, required this.meetings});
  final String members;
  final String meetings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              value: members,
              label: 'members_added'.tr,
              icon: Icons.groups_outlined,
              iconBg: HomeColors.navy,
              iconColor: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              value: meetings,
              label: 'meetings_held'.tr,
              icon: Icons.calendar_month_outlined,
              iconBg: HomeColors.peach,
              iconColor: HomeColors.orangeDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });
  final String value;
  final String label;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0x0F1B1740), blurRadius: 20, offset: Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 17),
          ),
          const SizedBox(height: 14),
          Text(value, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w800, color: HomeColors.ink, height: 1)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12, color: HomeColors.muted)),
        ],
      ),
    );
  }
}

class _LeaderCard extends StatelessWidget {
  const _LeaderCard({
    required this.rank,
    required this.size,
    required this.monthPoints,
    required this.score,
  });
  final String rank;
  final String size;
  final String monthPoints;
  final num score;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [HomeColors.navy, Color(0xFF2C2564)],
        ),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('mandal_leaderboard'.tr, style: const TextStyle(fontSize: 12, color: HomeColors.navyMuted)),
              const SizedBox(height: 4),
              Text('rank_of'.trParams({'rank': rank, 'size': size}), style: homeTitleStyle(size: 21, color: Colors.white)),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: ColoredBox(
                  color: Colors.white.withValues(alpha: 0.18),
                  child: SizedBox(
                    height: 7,
                    width: double.infinity,
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (score / 100).clamp(0, 1).toDouble(),
                      child: const ColoredBox(color: HomeColors.orange),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text('$monthPoints ${'points_month'.tr}', style: const TextStyle(fontSize: 12, color: Color(0xFFC9C6DF))),
                  const Spacer(),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${score.round()}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                        TextSpan(text: ' ${'points'.tr}', style: const TextStyle(color: Color(0xFFC9C6DF), fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: HomeColors.orange, shape: BoxShape.circle),
              child: Text(rank, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

class _LastActivityCard extends StatelessWidget {
  const _LastActivityCard({required this.when, required this.title, required this.onTap});
  final String when;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Color(0x0F1B1740), blurRadius: 20, offset: Offset(0, 8))],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    gradient: RadialGradient(
                      center: Alignment(-0.2, -0.3),
                      radius: 0.9,
                      colors: [Color(0xFFE5533C), Color(0xFFA5271A), Color(0xFF6C1712)],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('last_activity_label'.tr, style: const TextStyle(fontSize: 11, color: HomeColors.muted)),
                      const SizedBox(height: 2),
                      Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: HomeColors.ink)),
                      const SizedBox(height: 2),
                      Text(when, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: HomeColors.orangeDark)),
                    ],
                  ),
                ),
                const Icon(Icons.north_east_rounded, size: 15, color: HomeColors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

List<Map<String, dynamic>> _tasksDue(Map<String, dynamic>? home) {
  return ((home?['tasksDueToday'] as List?) ?? [])
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}

String _lastActivitySub(Object? raw) {
  if (raw is! Map) return 'opened_the_app'.tr;
  final data = Map<String, dynamic>.from(raw);
  final type = (data['type'] as String?) ?? 'OTHER';
  return 'activity_$type'.tr;
}

String _displayName(Map<String, dynamic> member) {
  final name = (member['fullName'] as String?)?.trim() ?? '';
  if (name.isNotEmpty) return name;
  final post = member['post'] as String?;
  if (post != null && post.isNotEmpty) return 'post_$post'.tr;
  return 'post_MEMBER'.tr;
}

String _dayGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'good_morning'.tr;
  if (hour < 17) return 'good_afternoon'.tr;
  return 'good_evening'.tr;
}

String _initials(String? name) {
  final cleaned = (name ?? '').trim();
  if (cleaned.isEmpty) return 'RP';
  if (RegExp(r'^\d+$').hasMatch(cleaned)) {
    return cleaned.length >= 2 ? cleaned.substring(cleaned.length - 2) : cleaned;
  }
  final parts = cleaned.split(RegExp(r'\s+'));
  if (parts.length == 1) return parts.first.substring(0, parts.first.length.clamp(0, 2)).toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}
