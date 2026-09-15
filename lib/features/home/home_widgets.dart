import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/routes/app_routes.dart';
import '../../core/constants/post_issues.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/api_error.dart';
import '../../core/utils/local_image.dart';
import '../../core/utils/open_url.dart';
import '../../core/widgets/empty_card.dart';
import '../../core/utils/relative_time.dart';
import '../../data/models/home_feed.dart';
import '../events/join_celebration.dart';
import '../join/join_chrome.dart';
import '../post/post_media.dart';
import '../session/session_controller.dart';
import '../../core/widgets/flash.dart';

enum HomeFeedKind { video, blog, nearby }

Future<void> openHomeFeedItem(HomeFeedItem item) async {
  if (item.url.trim().isEmpty) return;
  await openExternalUrl(item.url, preferExternal: item.youtubeId != null);
}

TextStyle homeTitleStyle({double size = 18, Color color = HomeColors.ink, FontWeight weight = FontWeight.w600}) {
  return GoogleFonts.bricolageGrotesque(fontSize: size, fontWeight: weight, color: color, height: 1.25);
}

class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({
    super.key,
    required this.title,
    required this.onSeeMore,
    this.eyebrow,
    this.top = 4,
  });
  final String title;
  final VoidCallback onSeeMore;
  final String? eyebrow;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: top, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (eyebrow != null) ...[
            Text(
              eyebrow!,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: HomeColors.orange,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(child: Text(title, style: homeTitleStyle(size: 18))),
              GestureDetector(
                onTap: onSeeMore,
                child: Text(
                  'see_more'.tr,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: HomeColors.orange),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class HomeEventCard extends StatefulWidget {
  const HomeEventCard({super.key, required this.event, this.margin});
  final UpcomingEvent event;
  final EdgeInsetsGeometry? margin;

  @override
  State<HomeEventCard> createState() => _HomeEventCardState();
}

class _HomeEventCardState extends State<HomeEventCard> {
  bool joining = false;

  UpcomingEvent get event {
    final session = Get.find<SessionController>();
    final id = widget.event.id;
    if (id.isNotEmpty) {
      for (final item in session.allUpcomingEvents) {
        if ('${item['id']}' == id) return UpcomingEvent.fromJson(item);
      }
      final home = session.home.value;
      for (final item in (home?['upcomingEvents'] as List? ?? [])) {
        if (item is Map && '${item['id']}' == id) {
          return UpcomingEvent.fromJson(Map<String, dynamic>.from(item));
        }
      }
    }
    return widget.event;
  }

  Future<void> _join() async {
    final current = event;
    if (current.id.isEmpty) {
      Get.toNamed(Routes.upcomingEvents);
      return;
    }
    if (current.joined || joining) return;
    setState(() => joining = true);
    try {
      await Get.find<SessionController>().joinUpcomingEvent(current.id);
      if (!mounted) return;
      await showJoinCelebration(context);
    } catch (e) {
      flash('Error', apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => joining = false);
    }
  }

  void _showJoiners() {
    final people = event.joiners;
    Get.bottomSheet(
      SafeArea(
        child: Container(
          constraints: const BoxConstraints(maxHeight: 420),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
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
                  decoration: BoxDecoration(color: AppColors.rule2, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'members_joining'.trParams({'n': '${event.joining}'}),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: HomeColors.ink),
              ),
              const SizedBox(height: 8),
              if (people.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: AppEmptyCard(
                    compact: true,
                    icon: Icons.group_outlined,
                    title: 'no_joiners_yet'.trFallback('No one has joined yet.'),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: people.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final person = people[index];
                      final name = '${person['fullName'] ?? ''}'.trim();
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: HomeColors.navy,
                          child: Text(
                            name.isEmpty ? '?' : String.fromCharCode(name.runes.first).toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ),
                        title: Text(name.isEmpty ? 'Member' : name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const imageHeight = 150.0;
    const joinHeight = 38.0;
    return Obx(() {
      Get.find<SessionController>().home.value;
      Get.find<SessionController>().allUpcomingEvents.length;
      final data = event;
      return Padding(
        padding: widget.margin ?? const EdgeInsets.only(bottom: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [BoxShadow(color: Color(0x1A291668), blurRadius: 18, offset: Offset(0, 8))],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: data.id.isEmpty ? null : () => Get.toNamed(Routes.eventDetail, arguments: data.toJson()),
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Column(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                        child: SizedBox(
                          height: imageHeight,
                          width: double.infinity,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              localOrNetworkPhoto(
                                raw: data.imageUrl,
                                fit: BoxFit.cover,
                                fallback: EventPlaceholder(type: data.type),
                              ),
                              const DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Color(0x0D140F32), Color(0xBF140F32)],
                                    stops: [0.45, 1],
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 12,
                                left: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    data.when.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: HomeColors.ink,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 16,
                                right: 108,
                                bottom: 22,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(data.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: homeTitleStyle(size: 16, color: Colors.white)),
                                    const SizedBox(height: 2),
                                    Text(
                                      data.place,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 11.5, color: Colors.white.withValues(alpha: 0.85)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      DecoratedBox(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 22, 108, 16),
                          child: Row(
                            children: [
                              const Icon(Icons.groups_outlined, size: 18, color: HomeColors.orange),
                              const SizedBox(width: 8),
                              Expanded(
                                child: GestureDetector(
                                  onTap: data.id.isEmpty ? null : _showJoiners,
                                  child: Text(
                                    'members_joining'.trParams({'n': '${data.joining}'}),
                                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF4B4768)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    right: 16,
                    top: imageHeight - (joinHeight / 2),
                    child: GestureDetector(
                      onTap: _join,
                      child: Container(
                        height: joinHeight,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: data.joined ? const Color(0xFF1B8A6A) : HomeColors.navy,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: const [BoxShadow(color: Color(0x331B1740), blurRadius: 12, offset: Offset(0, 4))],
                        ),
                        child: Text(
                          joining
                              ? '…'
                              : data.joined
                                  ? 'joined'.trFallback('Joined')
                                  : 'join'.tr,
                          style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700),
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
    });
  }
}

class EventPlaceholder extends StatelessWidget {
  const EventPlaceholder({super.key, this.type = ''});
  final String type;

  @override
  Widget build(BuildContext context) {
    final icon = switch (type.toUpperCase()) {
      'GRIHA_SAMPARK' => Icons.home_outlined,
      'PUBLIC_PROGRAMME' => Icons.campaign_outlined,
      'TRAINING' => Icons.menu_book_outlined,
      _ => Icons.groups_outlined,
    };
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [HomeColors.tealMid, HomeColors.teal],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            bottom: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(shape: BoxShape.circle, color: HomeColors.tealMid.withValues(alpha: 0.55)),
            ),
          ),
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: HomeColors.navyMuted.withValues(alpha: 0.55),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: HomeColors.navyDeep, size: 30),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeEventsBanner extends StatelessWidget {
  const HomeEventsBanner({super.key, required this.events});
  final List<UpcomingEvent> events;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          title: 'upcoming_events'.tr,
          eyebrow: 'happening_soon'.tr,
          onSeeMore: () => Get.toNamed(Routes.upcomingEvents),
        ),
        if (events.isEmpty)
          const _HomeEventsEmpty()
        else
          HomeEventCard(event: events.first),
      ],
    );
  }
}

class _HomeEventsEmpty extends StatelessWidget {
  const _HomeEventsEmpty();

  @override
  Widget build(BuildContext context) {
    final canCreate = Get.isRegistered<SessionController>() && Get.find<SessionController>().canCreateOrgEvents;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: InkWell(
        onTap: () => Get.toNamed(canCreate ? Routes.createEvent : Routes.upcomingEvents),
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
          decoration: BoxDecoration(
            color: HomeColors.navy,
            borderRadius: BorderRadius.circular(28),
          ),
          child: AppEmptyCard(
            compact: true,
            onDark: true,
            icon: Icons.event_outlined,
            title: 'upcoming_events_empty'.tr,
            sub: canCreate ? 'create_event_eyebrow'.trFallback('Create an upcoming event') : null,
          ),
        ),
      ),
    );
  }
}

class HomeVideoGrid extends StatelessWidget {
  const HomeVideoGrid({super.key, required this.items});
  final List<HomeFeedItem> items;

  @override
  Widget build(BuildContext context) {
    final shown = items.take(2).toList();
    if (shown.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          for (var i = 0; i < shown.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(child: _HomeVideoCard(item: shown[i], alt: i.isOdd)),
          ],
        ],
      ),
    );
  }
}

class _HomeVideoCard extends StatelessWidget {
  const _HomeVideoCard({required this.item, this.alt = false});
  final HomeFeedItem item;
  final bool alt;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => openHomeFeedItem(item),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 120,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (item.imageUrl != null)
                    Image.network(item.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, _, _) => ColoredBox(color: alt ? HomeColors.navyMid : HomeColors.orangeSoft))
                  else
                    ColoredBox(color: alt ? HomeColors.navyMid : HomeColors.orangeSoft),
                  const Center(
                    child: CircleAvatar(
                      radius: 19,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.play_arrow_rounded, color: HomeColors.navy, size: 22),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, height: 1.3, color: HomeColors.ink),
          ),
          if (item.source.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(item.source, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: HomeColors.muted)),
          ],
        ],
      ),
    );
  }
}

class HomeStatsRow extends StatelessWidget {
  const HomeStatsRow({super.key, required this.members, required this.meetings});
  final String members;
  final String meetings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              value: members,
              label: 'members_added'.tr,
              icon: Icons.groups_outlined,
              iconBg: HomeColors.navy,
              iconFg: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              value: meetings,
              label: 'meetings_held'.tr,
              icon: Icons.calendar_month_outlined,
              iconBg: HomeColors.peach,
              iconFg: HomeColors.orange,
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
    required this.iconFg,
  });
  final String value;
  final String label;
  final IconData icon;
  final Color iconBg;
  final Color iconFg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: HomeColors.surface, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconFg, size: 16),
          ),
          const SizedBox(height: 12),
          Text(value, style: homeTitleStyle(size: 24)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12, color: HomeColors.muted)),
        ],
      ),
    );
  }
}

class HomeLeaderboard extends StatelessWidget {
  const HomeLeaderboard({
    super.key,
    required this.rank,
    required this.size,
    required this.score,
    this.scope = 'assembly',
    this.area = '',
  });
  final String rank;
  final String size;
  final num score;
  final String scope;
  final String area;

  String get _title {
    if (area.trim().isNotEmpty) {
      return 'leaderboard_area_title'.trParams({'area': area.trim()});
    }
    switch (scope) {
      case 'district':
        return 'leaderboard_district'.trFallback('District');
      case 'state':
        return 'leaderboard_state'.trFallback('State');
      default:
        return 'leaderboard_ac'.trFallback('AC');
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = (score / 100).clamp(0, 1).toDouble();
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: GestureDetector(
        onTap: () => Get.find<SessionController>().shellIndex.value = 3,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          decoration: BoxDecoration(color: HomeColors.navy, borderRadius: BorderRadius.circular(28)),
          child: Stack(
            children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_title, style: const TextStyle(fontSize: 12, color: HomeColors.navyMuted)),
                const SizedBox(height: 4),
                Text('rank_of'.trParams({'rank': rank, 'size': size}), style: homeTitleStyle(size: 21, color: Colors.white)),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: value,
                    minHeight: 7,
                    backgroundColor: HomeColors.navyMid,
                    color: HomeColors.orange,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'points_this_month'.trParams({'n': '${(score * 4).round()}'}),
                        style: const TextStyle(fontSize: 12, color: HomeColors.navyMuted),
                      ),
                    ),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: '${score.round()}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                          TextSpan(text: ' ${'points'.tr}', style: const TextStyle(color: HomeColors.navyMuted, fontSize: 12)),
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
                decoration: const BoxDecoration(color: HomeColors.orange, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(rank, style: homeTitleStyle(size: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class HomeBlogRail extends StatelessWidget {
  const HomeBlogRail({super.key, required this.items});
  final List<HomeFeedItem> items;

  @override
  Widget build(BuildContext context) {
    final shown = items.take(6).toList();
    if (shown.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        height: 186,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: shown.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, index) => HomeFeedCard(item: shown[index]),
        ),
      ),
    );
  }
}

class HomeActivityRail extends StatelessWidget {
  const HomeActivityRail({super.key, required this.posts});
  final List<Map<String, dynamic>> posts;

  static const _washes = [HomeColors.teal, HomeColors.accent300, HomeColors.navyMid, HomeColors.orangeSoft];

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: AppEmptyCard(
          compact: true,
          icon: Icons.forum_outlined,
          title: 'region_posts_empty'.tr,
        ),
      );
    }
    final shown = posts.take(6).toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: SizedBox(
        height: 228,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: shown.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, index) => _ActivityCard(post: shown[index], wash: _washes[index % _washes.length]),
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.post, required this.wash});
  final Map<String, dynamic> post;
  final Color wash;

  @override
  Widget build(BuildContext context) {
    final raw = postImageUrl(post) ?? post['thumbnailUrl'] ?? post['mediaPath'] ?? post['photoPath'];
    final path = resolveStorageUrl(raw) ?? localPhotoPath(raw);
    final video = isVideoPost(post);
    final issue = issueLabelOf(post);
    final description = '${post['description'] ?? ''}'.trim();
    final when = lastActiveWhen(post['createdAt']);
    return InkWell(
      onTap: () => Get.toNamed(Routes.postDetail, arguments: post),
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: 220,
        child: DecoratedBox(
          decoration: BoxDecoration(color: HomeColors.surface, borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: SizedBox(
                  height: 110,
                  width: 220,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      path != null && path.isNotEmpty
                          ? localOrNetworkPhoto(raw: path, fit: BoxFit.cover, fallback: ColoredBox(color: wash))
                          : ColoredBox(color: wash),
                      if (video) ...[
                        const ColoredBox(color: Color(0x40000000)),
                        const VideoPlayBadge(size: 44),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (issue.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: HomeColors.peach, borderRadius: BorderRadius.circular(999)),
                        child: Text(issue, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: HomeColors.orangeDark)),
                      ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, height: 1.4, color: HomeColors.ink)),
                    ],
                    if (when.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(when, style: const TextStyle(fontSize: 11, color: HomeColors.muted)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class HomeFeedRail extends StatelessWidget {
  const HomeFeedRail({super.key, required this.items, required this.kind});
  final List<HomeFeedItem> items;
  final HomeFeedKind kind;

  @override
  Widget build(BuildContext context) {
    final height = switch (kind) {
      HomeFeedKind.video => 196.0,
      HomeFeedKind.blog => 214.0,
      HomeFeedKind.nearby => 120.0,
    };
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) => HomeFeedCard(item: items[index], kind: kind),
      ),
    );
  }
}

class HomeFeedCard extends StatelessWidget {
  const HomeFeedCard({super.key, required this.item, this.kind = HomeFeedKind.blog, this.expanded = false});
  final HomeFeedItem item;
  final HomeFeedKind kind;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    if (kind == HomeFeedKind.nearby && !expanded) {
      return _NearbyTile(item: item);
    }
    if (kind == HomeFeedKind.video && !expanded) {
      return SizedBox(width: 168, child: _HomeVideoCard(item: item));
    }
    return _BlogTile(item: item, expanded: expanded, video: item.video || kind == HomeFeedKind.video);
  }
}

class _BlogTile extends StatelessWidget {
  const _BlogTile({required this.item, required this.expanded, required this.video});
  final HomeFeedItem item;
  final bool expanded;
  final bool video;

  @override
  Widget build(BuildContext context) {
    final text = Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, height: 1.25, color: HomeColors.ink),
          ),
          if (item.source.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              item.source,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: HomeColors.muted),
            ),
          ],
        ],
      ),
    );
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: HomeColors.border, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openHomeFeedItem(item),
        child: SizedBox(
          width: expanded ? null : 190,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: expanded ? MainAxisSize.min : MainAxisSize.max,
            children: [
              SizedBox(
                height: 100,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (item.imageUrl != null)
                      Image.network(item.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, _, _) => const ColoredBox(color: HomeColors.navy))
                    else
                      const ColoredBox(color: HomeColors.navy),
                    if (item.imageUrl == null)
                      Center(
                        child: Icon(video ? Icons.play_arrow_rounded : Icons.description_outlined, color: HomeColors.orange, size: 24),
                      ),
                    if (video && item.imageUrl != null)
                      const Center(
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.play_arrow_rounded, color: HomeColors.navy, size: 18),
                        ),
                      ),
                  ],
                ),
              ),
              if (expanded) text else Flexible(child: text),
            ],
          ),
        ),
      ),
    );
  }
}

class _NearbyTile extends StatelessWidget {
  const _NearbyTile({required this.item});
  final HomeFeedItem item;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => openHomeFeedItem(item),
        child: SizedBox(
          width: 190,
          height: 120,
          child: item.imageUrl == null
              ? const ColoredBox(color: HomeColors.navy)
              : Image.network(item.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, _, _) => const ColoredBox(color: HomeColors.navy)),
        ),
      ),
    );
  }
}
