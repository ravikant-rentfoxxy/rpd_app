import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/constants/post_issues.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/update/app_upgrade.dart';
import '../../core/utils/api_error.dart';
import '../../core/utils/distance.dart';
import '../../core/utils/media_url.dart';
import '../../core/widgets/iro_header.dart';
import 'package:latlong2/latlong.dart';
import '../../core/widgets/iro_map.dart';
import '../../core/widgets/iro_ui.dart';
import '../../data/models/broadcast.dart';
import '../../data/models/district_snapshot.dart';
import '../../data/models/home_feed.dart';
import '../post/post_views.dart';
import '../session/session_controller.dart';
import 'district_map_view.dart';
import 'home_shimmer.dart';
import 'home_widgets.dart';

/// Home answers one question before anything else: what is happening in my
/// district right now. The sector view comes first, the four numbers that
/// change daily come second, and the issue posts a member can walk to come
/// third.
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionController>();
    if (session.home.value == null && !session.homeLoading.value) {
      session.loadHome();
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: iroOverlay,
      // The update prompt lives here rather than at the root, so it meets a
      // member who is already in the app and can act on it.
      child: AppUpgradeGate(
        child: Scaffold(
          backgroundColor: Iro.mint,
          body: Obx(() {
            if (session.homeLoading.value && session.home.value == null) {
              return HomeShimmer(topInset: 0);
            }
            final home = session.home.value;
            final snapshot = DistrictSnapshot.fromJson(home?['districtSnapshot']);
            final events = upcomingEventsFrom(home?['upcomingEvents'] as List?, limit: 5);
            final videos = feedItemsFrom(home?['recentVideos'] as List?);
            final blogs = feedItemsFrom(home?['recentBlogs'] as List?);
            // Reading the tick here is what redraws the rail after a vote or a
            // post of the member's own lands.
            session.postsTick.value;
            final issuePosts = session.homeIssuePosts();
            // RPD's own home content, which IRO has no equivalent for because it
            // runs with no server: the announcement and the upload queue.
            final announcement = Broadcast.fromJson(home?['announcement']);
            final queue = session.syncCount.value;

            // The bar spans the screen, so it sits above the list rather than
            // inside its padding.
            return Column(
              children: [
                SafeArea(bottom: false, child: IroTopBar(section: 'home'.tr)),
                Expanded(
                  child: RefreshIndicator(
                    color: Iro.bright,
                    onRefresh: session.loadHome,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 104),
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        if (announcement != null) HomeBroadcastCard(broadcast: announcement),
                        _SectorPanel(
                          snapshot: snapshot,
                          posts: issuePosts,
                          events: events,
                          centre: districtCentreFrom(home?['districtCentre']),
                        ),
                        _SnapshotGrid(snapshot: snapshot),
                        const SizedBox(height: 14),
                        if (queue > 0) _QueueBanner(queue: queue),
                        IroSectionHeading(
                          'important_issues'.tr,
                          trailing: 'verified_nearby'.trParams({'n': '${snapshot.verifiedNearby}'}),
                          // The count is of posts other members filed, so land on that pane.
                          onTrailingTap: () => Get.toNamed(Routes.posts, arguments: PostsTab.others),
                        ),
                        _IssuePostRail(posts: issuePosts),
                        // Always shown, empty or not: a member who sees nothing here
                        // should be told there is nothing on, not left wondering
                        // whether the section exists.
                        const SizedBox(height: 20),
                        HomeEventsBanner(events: events),
                        if (videos.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          HomeSectionHeader(
                            title: 'recent_videos'.tr,
                            onSeeMore: () => Get.toNamed(Routes.recentVideos),
                          ),
                          HomeVideoGrid(items: videos),
                        ],
                        if (blogs.isNotEmpty) ...[
                          HomeSectionHeader(title: 'recent_blogs'.tr, onSeeMore: () => Get.toNamed(Routes.recentBlogs)),
                          SizedBox(
                            height: 214,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              clipBehavior: Clip.none,
                              padding: const EdgeInsets.only(bottom: 6),
                              itemCount: blogs.length,
                              separatorBuilder: (_, _) => const SizedBox(width: 12),
                              itemBuilder: (context, index) => HomeFeedCard(item: blogs[index]),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

/// The district header and its painted sector view. The map is drawn locally —
/// the app has no tiles to fetch and still has to show a member where the
/// open incidents sit.
class _SectorPanel extends StatefulWidget {
  const _SectorPanel({required this.snapshot, required this.posts, required this.events, required this.centre});
  final DistrictSnapshot snapshot;
  final List<Map<String, dynamic>> posts;
  final List<UpcomingEvent> events;

  /// The middle of the member's district, so the map opens there rather than on
  /// the country when nothing has been filed.
  final LatLng? centre;

  @override
  State<_SectorPanel> createState() => _SectorPanelState();
}

class _SectorPanelState extends State<_SectorPanel> {
  bool showEvents = false;

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionController>();
    final member = session.member ?? {};
    final booth = member['booth'] is Map ? Map<String, dynamic>.from(member['booth'] as Map) : const {};
    final district = '${member['districtName'] ?? booth['districtName'] ?? ''}'.trim();
    final state = '${member['stateName'] ?? booth['stateName'] ?? ''}'.trim();
    final sector = '${member['assemblyName'] ?? booth['assemblyName'] ?? booth['name'] ?? ''}'.trim();
    final title = district.isEmpty ? 'your_district'.tr : '$district ${'district'.tr}';
    final line = [if (state.isNotEmpty) state, if (sector.isNotEmpty) sector].join(' • ');

    // Both sets are built: the panel shows one, and the full screen it opens
    // needs the other to toggle to. Anything without a fix is left off rather
    // than dropped at the origin.
    final eventPins = [
      for (final event in widget.events)
        ?pinFrom(
          event.latitude,
          event.longitude,
          tone: Iro.green,
          icon: Icons.event_rounded,
          label: event.title,
          onTap: event.id.isEmpty
              ? null
              : () => Get.toNamed(
                  event.kind == 'MEETING' ? Routes.meeting : Routes.eventDetail,
                  arguments: event.toJson(),
                ),
        ),
    ];
    final issuePins = [
      for (final post in widget.posts)
        ?pinFrom(
          post['latitude'],
          post['longitude'],
          tone: '${post['status'] ?? ''}'.toUpperCase() == 'RESOLVED' ? Iro.greenMid : Iro.alert,
          icon: issueIconOf(post),
          label: issueLabelOf(post),
          onTap: () => Get.toNamed(Routes.postDetail, arguments: post),
        ),
    ];
    final pins = showEvents ? eventPins : issuePins;

    return IroCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_rounded, size: 18, color: Iro.greenMid),
              const SizedBox(width: 5),
              Flexible(
                child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: iroDisplay(size: 18)),
              ),
              const SizedBox(width: 3),
              const Icon(Icons.expand_more_rounded, size: 18, color: Iro.muted),
              const Spacer(),
              IroChip('live_gis'.tr, dot: true, fg: Iro.greenMid, bg: Iro.wash),
            ],
          ),
          if (line.isNotEmpty) ...[
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.only(left: 23),
              child: Text(line, maxLines: 1, overflow: TextOverflow.ellipsis, style: iroLabel(size: 11.5)),
            ),
          ],
          const SizedBox(height: 11),
          IroMap(
            height: 168,
            pins: pins,
            fallbackCentre: widget.centre,
            // Tapping the panel opens the same map with the screen to itself.
            onTap: () => Get.toNamed(
              Routes.districtMap,
              arguments: DistrictMapArgs(
                issues: issuePins,
                events: eventPins,
                centre: widget.centre,
                showEvents: showEvents,
                title: title,
              ),
            ),
            overlay: [
              Positioned(
                left: 9,
                top: 9,
                child: IroChip(
                  'sector_zone'.trParams({'name': (sector.isEmpty ? title : sector).toUpperCase()}),
                  dense: true,
                  size: 9,
                  fg: Colors.white,
                  bg: const Color(0xD90C3320),
                ),
              ),
              Positioned(
                right: 9,
                top: 9,
                child: IroChip(
                  'live_geofence'.tr,
                  dense: true,
                  size: 9,
                  dot: true,
                  fg: Iro.goldBright,
                  bg: const Color(0xD90C3320),
                ),
              ),
              Positioned(
                left: 10,
                bottom: 10,
                child: Row(
                  children: [
                    const Icon(Icons.place_rounded, size: 13, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      'active_incidents'.trParams({'n': '${pins.length}'}),
                      style: iroLabel(size: 10.5, color: Colors.white, weight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              // OpenStreetMap's tile policy asks for this on every map.
              const Positioned(left: 10, bottom: 34, child: IroMapCredit()),
              Positioned(
                right: 9,
                bottom: 9,
                child: _MapToggle(showEvents: showEvents, onChanged: (value) => setState(() => showEvents = value)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MapToggle extends StatelessWidget {
  const _MapToggle({required this.showEvents, required this.onChanged});
  final bool showEvents;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget seg(String label, bool on, VoidCallback tap) => Material(
      color: on ? Iro.surface : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: tap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          child: Text(
            label,
            style: iroLabel(size: 10.5, color: on ? Iro.ink : Colors.white, weight: FontWeight.w700),
          ),
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: const Color(0xB30C3320), borderRadius: BorderRadius.circular(11)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          seg('issues'.tr, !showEvents, () => onChanged(false)),
          seg('events'.tr, showEvents, () => onChanged(true)),
        ],
      ),
    );
  }
}

/// Four numbers, two rows. IntrinsicHeight so both tiles in a row match even
/// when one label wraps — a stretched Row inside a list would otherwise have no
/// height to lay out against.
class _SnapshotGrid extends StatelessWidget {
  const _SnapshotGrid({required this.snapshot});
  final DistrictSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionController>();
    final member = session.member ?? {};
    final booth = member['booth'] is Map ? Map<String, dynamic>.from(member['booth'] as Map) : const {};
    final sector = '${member['assemblyName'] ?? booth['name'] ?? ''}'.trim();

    Widget row(List<Widget> tiles) => IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: tiles[0]),
          const SizedBox(width: 10),
          Expanded(child: tiles[1]),
        ],
      ),
    );

    return Column(
      children: [
        row([
          IroStatTile(
            label: 'district_members'.tr,
            value: groupIndian(snapshot.members),
            note: 'joined_today'.trParams({'n': '${snapshot.joinedToday}'}),
            icon: Icons.groups_rounded,
            noteTone: Iro.greenMid,
            onTap: () => Get.toNamed(Routes.members),
          ),
          IroStatTile(
            label: 'ground_active'.tr,
            value: '${snapshot.groundActive}',
            note: sector.isEmpty ? 'active_ground'.tr : sector,
            icon: Icons.directions_walk_rounded,
          ),
        ]),
        const SizedBox(height: 10),
        row([
          IroStatTile(
            label: 'urgent_issues'.tr,
            value: '${snapshot.urgentIssues}',
            note: 'needs_action'.tr,
            icon: Icons.error_outline_rounded,
            tone: Iro.alert,
            noteTone: Iro.alert,
            onTap: () => Get.toNamed(Routes.posts),
          ),
          IroStatTile(
            label: 'resolution_rate'.tr,
            value: '${snapshot.resolutionRate}%',
            note: 'quarter_target'.tr,
            icon: Icons.verified_outlined,
            onTap: () => Get.toNamed(Routes.districtHealth),
          ),
        ]),
      ],
    );
  }
}

/// Work waiting to leave the phone. Only drawn when the queue is not empty, so
/// it never sits on the screen as a permanent scold.
class _QueueBanner extends StatelessWidget {
  const _QueueBanner({required this.queue});
  final int queue;

  @override
  Widget build(BuildContext context) {
    return IroCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 11, 14, 11),
      onTap: () => Get.toNamed(Routes.sync),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: Iro.goldWash, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.cloud_upload_outlined, color: Iro.gold, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IroChip(
                  'sync_queue'.tr,
                  icon: Icons.cloud_off_rounded,
                  size: 9.5,
                  dense: true,
                  fg: Iro.gold,
                  bg: Iro.goldWash,
                ),
                const SizedBox(height: 5),
                Text(
                  'queue_bar'.trParams({'n': '$queue'}),
                  style: iroLabel(size: 13, color: Iro.ink, weight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_rounded, color: Iro.gold, size: 18),
        ],
      ),
    );
  }
}

/// The issue posts a member can act on without leaving their ward.
class _IssuePostRail extends StatelessWidget {
  const _IssuePostRail({required this.posts});
  final List<Map<String, dynamic>> posts;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return IroCard(
        margin: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            const Icon(Icons.outlined_flag_rounded, size: 20, color: Iro.muted2),
            const SizedBox(width: 10),
            Expanded(child: Text('no_issues_nearby'.tr, style: iroLabel(size: 12.5))),
          ],
        ),
      );
    }
    final width = (MediaQuery.sizeOf(context).width - 74).clamp(230.0, 330.0);
    // A Row rather than a horizontal ListView: a ListView has to be told one
    // height for every card, which is what left a short description sitting
    // over a gap. Here each card is as tall as its own text needs and the rail
    // takes the height of the tallest. The rail holds at most eight cards, so
    // there is nothing to gain from building them lazily.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < posts.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            SizedBox(
              width: width,
              child: _IssuePostCard(post: posts[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _IssuePostCard extends StatefulWidget {
  const _IssuePostCard({required this.post});
  final Map<String, dynamic> post;

  @override
  State<_IssuePostCard> createState() => _IssuePostCardState();
}

class _IssuePostCardState extends State<_IssuePostCard> {
  bool sending = false;

  Map<String, dynamic> get post => widget.post;

  /// A post the member has not pushed yet has no server row to vote against.
  bool get _pending => post['pending'] == true || '${post['serverId'] ?? ''}'.isEmpty;

  Future<void> _vote(String side) async {
    if (sending || _pending) return;
    setState(() => sending = true);
    try {
      await Get.find<SessionController>().voteOnPost(post, side);
    } catch (e) {
      Get.snackbar('Error', apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = issueCategoryLabelOf(post);
    final title = issueLabelOf(post);
    final body = '${post['description'] ?? ''}'.trim();
    final place = '${post['regionLabel'] ?? ''}'.trim();
    final metres = post['distanceMetres'];
    final distance = formatMetres(metres is num ? metres.round() : null);
    final where = [if (distance.isNotEmpty) distance, if (place.isNotEmpty) place].join(' • ');
    final icon = issueIconOf(post);
    final image = post['thumbnailUrl'] ?? post['thumbnailPath'] ?? postImageUrl(post);
    final myVote = '${post['myVote'] ?? ''}'.toUpperCase();
    final likes = (post['likes'] as num?)?.round() ?? 0;
    final dislikes = (post['dislikes'] as num?)?.round() ?? 0;
    final resolved = '${post['status'] ?? ''}'.toUpperCase() == 'RESOLVED';
    final views = (post['views'] as num?)?.round() ?? 0;

    return IroCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 128,
            child: Stack(
              fit: StackFit.expand,
              children: [
                IroPhoto(url: image?.toString(), icon: icon, seed: title.length),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x4D0C3320), Color(0x00000000), Color(0x800C3320)],
                      stops: [0, 0.4, 1],
                    ),
                  ),
                ),
                if (category.isNotEmpty)
                  Positioned(
                    left: 9,
                    top: 9,
                    child: SizedBox(
                      width: 168,
                      child: IroChip(
                        category,
                        dense: true,
                        size: 9.5,
                        icon: icon,
                        fg: Colors.white,
                        bg: const Color(0xD9114A2C),
                      ),
                    ),
                  ),
                if (where.isNotEmpty)
                  Positioned(
                    left: 9,
                    bottom: 9,
                    child: IroChip(where, dense: true, size: 9.5, fg: Iro.ink, bg: const Color(0xF2FFFFFF)),
                  ),
                if (post['authorVerified'] == true)
                  const Positioned(
                    right: 9,
                    top: 9,
                    child: Icon(Icons.verified_rounded, size: 17, color: Colors.white),
                  ),
                if (resolved)
                  Positioned(
                    right: 9,
                    bottom: 9,
                    child: IroChip(
                      'resolve_resolved'.tr,
                      dense: true,
                      size: 9,
                      fg: Colors.white,
                      bg: const Color(0xD91C7D48),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: iroDisplay(size: 15)),
                const SizedBox(height: 5),
                // One line of description makes a short card, six make a tall
                // one. The cap is there so a 2000-character grievance cannot
                // push the rail off the screen.
                Text(
                  body.isEmpty ? category : body,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                  style: iroLabel(size: 11.5, color: Iro.muted, weight: FontWeight.w500).copyWith(height: 1.45),
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    IroVoteButton(
                      icon: myVote == 'LIKE' ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
                      count: likes,
                      on: myVote == 'LIKE',
                      tone: Iro.greenMid,
                      enabled: !_pending,
                      onTap: () => _vote('LIKE'),
                    ),
                    const SizedBox(width: 8),
                    IroVoteButton(
                      icon: myVote == 'DISLIKE' ? Icons.thumb_down_rounded : Icons.thumb_down_outlined,
                      count: dislikes,
                      on: myVote == 'DISLIKE',
                      tone: Iro.alert,
                      enabled: !_pending,
                      onTap: () => _vote('DISLIKE'),
                    ),
                    const Spacer(),
                    // A post nobody has opened yet says nothing rather than
                    // boasting about zero.
                    if (views > 0) ...[IroViewCount(views), const SizedBox(width: 10)],
                    IroActionButton(
                      label: 'inspect'.tr,
                      height: 36,
                      wide: false,
                      onTap: () => Get.toNamed(Routes.postDetail, arguments: post),
                    ),
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
