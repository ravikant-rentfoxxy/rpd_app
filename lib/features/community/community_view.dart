import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/constants/post_issues.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_log.dart';
import '../../core/utils/relative_time.dart';
import '../../core/widgets/iro_header.dart';
import '../../core/widgets/iro_ui.dart';
import '../../data/models/district_snapshot.dart';
import '../../data/models/home_feed.dart';
import '../events/event_api.dart';
import '../home/home_widgets.dart';
import '../join/join_chrome.dart';
import '../session/session_controller.dart';
import 'community_api.dart';

/// Community is the district talking to itself: how it is doing against the
/// state, the stories coming off the ground, and what was fixed since
/// yesterday.
class CommunityView extends StatefulWidget {
  const CommunityView({super.key});

  @override
  State<CommunityView> createState() => _CommunityViewState();
}

enum _Filter { all, videos, stories, dispatches }

class _CommunityViewState extends State<CommunityView> {
  _Filter filter = _Filter.all;
  final board = CommunityBoard().obs;
  /// Events this member said they would be at. Read from the endpoint the
  /// tasks screen already uses — nothing new was added on the server for this.
  final joinedEvents = <UpcomingEvent>[].obs;
  final loading = false.obs;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    loading.value = true;
    // The two are independent: a failure on one must not empty the other.
    await Future.wait([_loadBoard(), _loadJoinedEvents()]);
    loading.value = false;
  }

  Future<void> _loadBoard() async {
    try {
      board.value = await fetchCommunityBoard();
    } catch (e, stack) {
      AppLog.error('community board failed', error: e, stack: stack, tag: 'COMMUNITY');
    }
  }

  Future<void> _loadJoinedEvents() async {
    try {
      final rows = await fetchJoinedEvents();
      joinedEvents.assignAll(rows.map(UpcomingEvent.fromJson));
    } catch (e, stack) {
      // Keep whatever was already listed rather than blanking the section.
      AppLog.error('joined events failed', error: e, stack: stack, tag: 'COMMUNITY');
    }
  }

  /// Opening a story dims its ring. The list is patched locally so the rail
  /// settles straight away rather than waiting on a reload.
  Future<void> _openStory(DistrictStory story) async {
    board.value = board.value.withStories(
      board.value.stories.map((s) => s.id == story.id ? s.asSeen() : s).toList(),
    );
    markStorySeen(story.id).catchError((Object e) {
      AppLog.error('mark story seen failed', error: e, tag: 'COMMUNITY');
    });
    await Get.toNamed(Routes.story, arguments: story);
  }

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionController>();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: iroOverlay,
      child: Scaffold(
        backgroundColor: Iro.mint,
        body: Column(
          children: [
            SafeArea(bottom: false, child: IroTopBar(section: 'community'.tr)),
            Expanded(
              child: Obx(() {
                final data = board.value;
                final home = session.home.value;
                final videos = feedItemsFrom(home?['recentVideos'] as List?);
                final events = joinedEvents.toList();
                // Personal, not a feed category — it rides with the full view
                // rather than adding a fifth chip to the filter.
                final showEvents = filter == _Filter.all;
                final showStories = filter == _Filter.all || filter == _Filter.stories;
                final showVideos = filter == _Filter.all || filter == _Filter.videos;
                final showDispatches = filter == _Filter.all || filter == _Filter.dispatches;
                final empty = (!showEvents || events.isEmpty) &&
                    (!showStories || data.stories.isEmpty) &&
                    (!showVideos || videos.isEmpty) &&
                    (!showDispatches || data.grassroots.isEmpty);

                return RefreshIndicator(
                  color: Iro.bright,
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 104),
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      _DistrictBanner(banner: data.banner),
                      const SizedBox(height: 4),
                      IroSegmented(
                        items: ['all_feed'.tr, 'short_videos'.tr, 'field_stories'.tr, 'grassroots_updates'.tr],
                        index: _Filter.values.indexOf(filter),
                        onChanged: (i) => setState(() => filter = _Filter.values[i]),
                      ),
                      const SizedBox(height: 14),
                      if (showEvents) ...[
                        IroSectionHeading(
                          'joined_events'.trFallback('Events you joined'),
                          leading: const Icon(Icons.event_available_rounded, size: 17, color: Iro.greenMid),
                        ),
                        if (events.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              'no_joined_events'.trFallback('Nothing yet. Join an event from Home.'),
                              style: iroLabel(size: 12, color: Iro.muted, weight: FontWeight.w500),
                            ),
                          )
                        else
                          for (final event in events)
                            HomeEventCard(event: event, margin: const EdgeInsets.only(bottom: 12)),
                        // Sits with the events because that is the other half
                        // of what a member has been asked to turn up for.
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IroGhostButton(
                            label: 'my_tasks'.tr,
                            icon: Icons.checklist_rounded,
                            tone: Iro.green,
                            onTap: () => Get.toNamed(Routes.tasks),
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],
                      if (showStories && data.stories.isNotEmpty) ...[
                        IroSectionHeading(
                          'district_stories'.tr,
                          trailing: 'live_updates'.tr,
                          leading: const Icon(Icons.auto_awesome_rounded, size: 17, color: Iro.gold),
                        ),
                        _StoryRail(stories: data.stories, onOpen: _openStory),
                        const SizedBox(height: 16),
                      ],
                      if (showVideos && videos.isNotEmpty) ...[
                        HomeSectionHeader(
                          title: 'recent_videos'.tr,
                          onSeeMore: () => Get.toNamed(Routes.recentVideos),
                        ),
                        HomeVideoGrid(items: videos),
                      ],
                      if (showDispatches && data.grassroots.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        IroSectionHeading('grassroots_updates'.tr, trailing: 'latest_dispatch'.tr),
                        for (final item in data.grassroots) _DispatchCard(item: item),
                      ],
                      if (empty && !loading.value)
                        Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: Text(
                            'no_updates_yet'.tr,
                            textAlign: TextAlign.center,
                            style: iroLabel(size: 13, color: Iro.muted),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

/// The dark band: where the district stands, in three numbers.
class _DistrictBanner extends StatelessWidget {
  const _DistrictBanner({required this.banner});
  final CommunityBanner banner;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 14),
      decoration: BoxDecoration(
        gradient: Iro.headerGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x330C3320), blurRadius: 18, offset: Offset(0, 8))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _BannerTag(
                  icon: Icons.location_on_rounded,
                  label: 'your_district'.tr.toUpperCase(),
                  value: (banner.districtName.isEmpty ? 'app_name'.tr : banner.districtName).toUpperCase(),
                  tone: Iro.onDark,
                ),
              ),
              Expanded(
                child: _BannerTag(
                  icon: Icons.emoji_events_rounded,
                  label: banner.hasRank
                      ? 'rank_in_state'.trParams({'n': '${banner.memberRank}'})
                      : 'not_ranked_yet'.tr,
                  value: banner.membersInState == 0
                      ? null
                      : 'of_n'.trParams({'n': '${banner.membersInState}'}),
                  tone: Iro.goldBright,
                  // The number is this member's own standing, so the tag opens
                  // the board it came from.
                  onTap: () => Get.toNamed(Routes.leaderboard),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _BannerStat(
                value: groupIndian(banner.members),
                label: 'members'.tr,
                icon: Icons.groups_rounded,
              ),
              _BannerStat(
                value: '${banner.groundActive}',
                label: 'active_ground'.tr,
                icon: Icons.directions_walk_rounded,
              ),
              _BannerStat(
                value: '${banner.civicScore}%',
                label: 'civic_score'.tr,
                icon: Icons.insights_rounded,
                tone: Iro.goldBright,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BannerTag extends StatelessWidget {
  const _BannerTag({required this.icon, required this.label, this.value, required this.tone, this.onTap});
  final IconData icon;
  final String label;
  final String? value;
  final Color tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final body = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      child: Row(
        children: [
          Icon(icon, size: 15, color: tone),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: value == null ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: iroLabel(size: 9, color: tone, weight: FontWeight.w700),
                ),
                if (value != null)
                  Text(
                    value!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: iroLabel(size: 12, color: Colors.white, weight: FontWeight.w800),
                  ),
              ],
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 2),
            Icon(Icons.chevron_right_rounded, size: 16, color: tone),
          ],
        ],
      ),
    );

    final radius = BorderRadius.circular(14);
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Material(
        color: const Color(0x1FFFFFFF),
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: onTap == null ? body : InkWell(onTap: onTap, borderRadius: radius, child: body),
      ),
    );
  }
}

class _BannerStat extends StatelessWidget {
  const _BannerStat({required this.value, required this.label, required this.icon, this.tone = Colors.white});
  final String value;
  final String label;
  final IconData icon;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: iroDisplay(size: 19, color: tone)),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 11, color: Iro.onDark),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: iroLabel(size: 10, color: Iro.onDark, weight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StoryRail extends StatelessWidget {
  const _StoryRail({required this.stories, required this.onOpen});
  final List<DistrictStory> stories;
  final ValueChanged<DistrictStory> onOpen;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 98,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: stories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) => _StoryBubble(
          story: stories[index],
          onTap: () => onOpen(stories[index]),
        ),
      ),
    );
  }
}

/// The picture in its ring, with the place it came from underneath. A gold ring
/// means live, green means unread, grey means already opened.
class _StoryBubble extends StatelessWidget {
  const _StoryBubble({required this.story, required this.onTap});
  final DistrictStory story;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ring = story.seen
        ? const LinearGradient(colors: [Iro.line, Iro.line])
        : (story.live ? Iro.goldGradient : Iro.actionGradient);
    return SizedBox(
      width: 70,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Container(
              width: 62,
              height: 62,
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: ring),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Iro.mint),
                child: ClipOval(
                  child: IroPhoto(
                    url: story.imageUrl,
                    icon: Icons.auto_awesome_rounded,
                    seed: story.place.length,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              story.place,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: iroLabel(size: 10.5, color: Iro.ink2, weight: FontWeight.w600).copyWith(height: 1.2),
            ),
          ],
        ),
      ),
    );
  }
}

/// One piece of work that was handed to someone, and where it got to.
class _DispatchCard extends StatelessWidget {
  const _DispatchCard({required this.item});
  final Dispatch item;

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusFg, statusBg) = item.resolved
        ? ('status_resolved'.tr, Iro.greenMid, Iro.wash)
        : ('status_in_progress'.tr, Iro.gold, Iro.goldWash);
    final title = issueLabelOf(item.raw);
    final when = item.movedAt == null ? '' : lastActiveWhen(item.movedAt!.toIso8601String());

    return IroCard(
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 13),
      onTap: () => Get.toNamed(Routes.postDetail, arguments: item.raw),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(color: Iro.wash, shape: BoxShape.circle),
                child: Icon(issueIconOf(item.raw), size: 17, color: Iro.greenMid),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.assigneeName.isEmpty ? 'app_name'.tr : item.assigneeName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: iroLabel(size: 12.5, color: Iro.ink, weight: FontWeight.w700),
                          ),
                        ),
                        if (item.assigneeVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified_rounded, size: 13, color: Iro.greenMid),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [if (item.place.isNotEmpty) item.place, if (when.isNotEmpty) when].join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: iroLabel(size: 10.5, color: Iro.muted, weight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IroChip(statusLabel, dense: true, size: 9, fg: statusFg, bg: statusBg),
            ],
          ),
          const SizedBox(height: 11),
          Text(title, style: iroDisplay(size: 15).copyWith(height: 1.3)),
          if (item.description.trim().isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              item.description,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: iroLabel(size: 12, color: Iro.muted, weight: FontWeight.w500).copyWith(height: 1.5),
            ),
          ],
          if (item.imageUrl != null) ...[
            const SizedBox(height: 11),
            ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: SizedBox(
                height: 140,
                width: double.infinity,
                child: IroPhoto(url: item.imageUrl, icon: issueIconOf(item.raw), seed: title.length),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
