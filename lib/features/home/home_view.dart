import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/local_image.dart';
import '../../core/widgets/language_dropdown.dart';
import '../../data/models/home_feed.dart';
import '../session/session_controller.dart';
import 'home_shimmer.dart';
import 'home_widgets.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionController>();
    if (session.home.value == null && !session.homeLoading.value) {
      session.loadHome();
    }
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: HomeColors.navy,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Obx(() {
        final topInset = MediaQuery.paddingOf(context).top;
        final showShimmer = session.homeLoading.value && session.home.value == null;
        if (showShimmer) {
          return HomeShimmer(topInset: topInset);
        }
        final member = session.member ?? {};
        final home = session.home.value;
        final stats = Map<String, dynamic>.from(home?['stats'] as Map? ?? {});
        final booth = member['booth'] as Map?;
        final queue = session.syncCount.value;
        final events = upcomingEventsFrom(
          home?['upcomingEvents'] as List?,
          useFallback: home == null,
          limit: 5,
        );
        final videos = feedItemsFrom(home?['recentVideos'] as List?, fallback: recentVideos);
        final blogs = feedItemsFrom(home?['recentBlogs'] as List?, fallback: recentBlogs);
        session.postsTick.value;
        final nearbyPosts = session.recentRegionalPosts(limit: 4);
        final boothScore = (stats['boothScore'] ?? booth?['healthScore'] ?? 61) as num;
        // A member who is not verified yet is not placed on the board, so show 0
        // rather than a position they have not earned.
        final rank = session.needsVerification ? '0' : '${stats['mandalRank'] ?? 0}';
        final size = '${stats['mandalSize'] ?? 0}';
        return ColoredBox(
          color: HomeColors.paper,
          child: RefreshIndicator(
            color: HomeColors.orange,
            displacement: topInset + 80,
            onRefresh: session.loadHome,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                SliverToBoxAdapter(
                  child: _HomeHero(
                    topInset: topInset,
                    greeting: _dayGreeting(),
                    name: _displayName(member),
                    photoUrl: memberPhotoRef(member),
                    initials: _initials(member['fullName'] as String?),
                    activities: (stats['activitiesThisMonth'] as num?) ?? 0,
                    unreadCount: session.unreadNotifications.value,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 36),
                  sliver: SliverList.list(
                    children: [
                      if (queue > 0)
                        _TaskBanner(
                          title: 'queue_bar'.trParams({'n': '$queue'}),
                          subtitle: '',
                          icon: Icons.cloud_upload_outlined,
                          onTap: () => Get.toNamed(Routes.sync),
                        ),
                      _TaskBanner(
                        title: 'tasks_due'.trParams({'n': '${_tasksDue(home).length}'}),
                        subtitle: 'tasks_activity_sub'.tr,
                        icon: Icons.check_rounded,
                        onTap: () => session.shellIndex.value = 1,
                      ),
                      HomeEventsBanner(events: events),
                      HomeStatsRow(
                        members: '${stats['membersAdded'] ?? 0}',
                        events: '${stats['currentEvents'] ?? 0}',
                      ),
                      HomeLeaderboard(
                        rank: rank,
                        size: size,
                        score: boothScore,
                        points: (stats['points'] as num?) ?? 0,
                        scope: '${stats['leaderboardScope'] ?? 'assembly'}',
                        area: '${stats['leaderboardArea'] ?? ''}',
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
                      HomeBlogRail(items: blogs),
                      HomeSectionHeader(
                        title: 'recent_activity_near'.tr,
                        onSeeMore: () => Get.toNamed(Routes.posts),
                      ),
                      HomeActivityRail(posts: nearbyPosts),
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

class _HomeHero extends StatelessWidget {
  const _HomeHero({
    required this.topInset,
    required this.greeting,
    required this.name,
    required this.photoUrl,
    required this.initials,
    required this.activities,
    required this.unreadCount,
  });

  final double topInset;
  final String greeting;
  final String name;
  final String? photoUrl;
  final String initials;
  /// Activities this member recorded in the current calendar month.
  final num activities;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: HomeColors.navy,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      padding: EdgeInsets.fromLTRB(20, topInset + 12, 20, 30),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Get.toNamed(Routes.profile),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: HomeColors.accent300),
                      clipBehavior: Clip.antiAlias,
                      child: localOrNetworkPhoto(
                        raw: photoUrl,
                        fallback: Center(
                          child: Text(
                            initials,
                            style: GoogleFonts.bricolageGrotesque(
                              color: HomeColors.accent900,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (!Get.find<SessionController>().canUseMemberActions)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53935),
                            shape: BoxShape.circle,
                            border: Border.all(color: HomeColors.navy, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(greeting, style: const TextStyle(color: HomeColors.navyMuted, fontSize: 12)),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.bricolageGrotesque(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const LanguageDropdown(pill: true),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () async {
                  await Get.toNamed(Routes.notifications);
                  await Get.find<SessionController>().refreshUnreadNotifications();
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(color: HomeColors.navyMid, shape: BoxShape.circle),
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 17),
                      if (unreadCount > 0)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: HomeColors.orange,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: HomeColors.navy, width: 2),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              unreadCount > 99 ? '99+' : '$unreadCount',
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'activities_this_month'.tr,
                      style: const TextStyle(color: HomeColors.navyMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${activities.round()}',
                      style: GoogleFonts.bricolageGrotesque(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w500,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Get.toNamed(Routes.districtHealth),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(color: HomeColors.orange, borderRadius: BorderRadius.circular(999)),
                  child: Text(
                    'view_district'.tr,
                    style: GoogleFonts.bricolageGrotesque(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TaskBanner extends StatelessWidget {
  const _TaskBanner({
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
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: HomeColors.peach,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
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
                        const SizedBox(height: 2),
                        Text(subtitle, style: const TextStyle(fontSize: 12, color: HomeColors.orangeDark)),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_rounded, color: HomeColors.orangeDark, size: 18),
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
