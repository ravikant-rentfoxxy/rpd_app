import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/api_error.dart';
import '../../core/utils/app_log.dart';
import '../../core/utils/local_image.dart';
import '../../core/utils/open_url.dart';
import '../../core/widgets/empty_card.dart';
import '../../core/translations/app_translations.dart';
import '../../data/models/broadcast.dart';
import '../../data/models/home_feed.dart';
import 'content_vote_bar.dart';
import '../events/join_celebration.dart';
import '../join/join_chrome.dart';
import '../post/post_media.dart';
import '../session/session_controller.dart';
import '../../core/widgets/flash.dart';

enum HomeFeedKind { video, blog, nearby }

Future<void> openHomeFeedItem(HomeFeedItem item) async {
  // Blogs written in the admin portal have no link to follow — read them here.
  if (item.readInApp) {
    Get.toNamed(Routes.blogArticle, arguments: item);
    return;
  }
  // A video uploaded through the portal lives on Bunny Stream, so it plays in
  // the app's own player rather than being handed to a browser that would only
  // download the file.
  if (item.isUploadedVideo) {
    Get.toNamed(Routes.postVideo, arguments: {
      'path': item.url,
      'mediaUrl': resolveVideoHlsUrl(item.url) ?? item.url,
      'mediaKey': item.mediaKey,
      'videoId': streamVideoId(item.mediaKey ?? item.url),
    });
    return;
  }
  if (item.url.trim().isEmpty) return;
  await openExternalUrl(item.url, preferExternal: item.youtubeId != null);
}

/// The accent rule across the top of a card. A gradient by default, or a flat
/// [color] for the tiles that mark themselves apart by hue.
class HomeCardAccent extends StatelessWidget {
  const HomeCardAccent({super.key, this.color, this.height = 5});
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color,
        gradient: color != null
            ? null
            : const LinearGradient(
                colors: [HomeColors.teal, HomeColors.tealMid],
              ),
      ),
    );
  }
}

/// Tinted chip used on the home cards: an icon and a short label.
class HomeStatusPill extends StatelessWidget {
  const HomeStatusPill({
    super.key,
    required this.label,
    required this.fg,
    required this.bg,
    this.icon,
  });
  final String label;
  final Color fg;
  final Color bg;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

/// The English line under a Hindi or Bhojpuri label. Renders nothing in English.
class HomeEnglishLabel extends StatelessWidget {
  const HomeEnglishLabel(
    this.translationKey, {
    super.key,
    this.size = 11,
    this.color = HomeColors.muted2,
    this.top = 1,
  });
  final String translationKey;
  final double size;
  final Color color;
  final double top;

  @override
  Widget build(BuildContext context) {
    final english = englishLabel(translationKey);
    if (english == null) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(top: top),
      child: Text(
        english,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: size,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

TextStyle homeTitleStyle({
  double size = 18,
  Color color = HomeColors.ink,
  FontWeight weight = FontWeight.w600,
}) {
  return GoogleFonts.bricolageGrotesque(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: 1.25,
  );
}

class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({
    super.key,
    required this.title,
    required this.onSeeMore,
    this.eyebrow,
    this.top = 4,
    this.titleKey,
  });
  final String title;
  final VoidCallback onSeeMore;
  final String? eyebrow;
  final double top;

  /// Translation key behind [title], so the English wording can be paired
  /// under it on the Hindi and Bhojpuri locales.
  final String? titleKey;

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
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: HomeColors.orange,
                  ),
                ),
              ),
            ],
          ),
          if (titleKey != null) HomeEnglishLabel(titleKey!, size: 11.5, top: 2),
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
                  decoration: BoxDecoration(
                    color: AppColors.rule2,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'members_joining'.trParams({'n': '${event.joining}'}),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: HomeColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              if (people.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: AppEmptyCard(
                    compact: true,
                    icon: Icons.group_outlined,
                    title: 'no_joiners_yet'.trFallback(
                      'No one has joined yet.',
                    ),
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
                            name.isEmpty
                                ? '?'
                                : String.fromCharCode(
                                    name.runes.first,
                                  ).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        title: Text(
                          name.isEmpty ? 'Member' : name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
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
    // The image carries the card and the Join pill straddles its lower edge, so
    // both heights are named: the pill is offset by half its own height.
    const imageHeight = 168.0;
    const actionHeight = 38.0;
    final radius = BorderRadius.circular(20);
    return Obx(() {
      Get.find<SessionController>().home.value;
      Get.find<SessionController>().allUpcomingEvents.length;
      final data = event;
      // A meeting is attended by invitation and has no event row behind it, so
      // its card opens the meetings screen and states standing, not an action.
      final meeting = data.kind == 'MEETING';
      return Padding(
        padding: widget.margin ?? const EdgeInsets.only(bottom: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: const [BoxShadow(color: Color(0x140C3320), blurRadius: 24, offset: Offset(0, 10))],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: data.id.isEmpty
                  ? null
                  : meeting
                  ? () => Get.toNamed(Routes.meeting)
                  : () => Get.toNamed(Routes.eventDetail, arguments: data.toJson()),
              borderRadius: radius,
              child: Stack(
                // The pill hangs past the image, so it must not be clipped.
                clipBehavior: Clip.none,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                              // Darkens the foot of the image so white type
                              // holds up over any photograph.
                              const DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Color(0x0D0C3320), Color(0xBF0C3320)],
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
                              // Kept clear of the pill's column on the right.
                              Positioned(
                                left: 16,
                                right: 108,
                                bottom: 22,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      data.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: homeTitleStyle(size: 16, color: Colors.white),
                                    ),
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
                          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                        ),
                        child: Padding(
                          // The right inset leaves the pill its room.
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
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: Iro.ink2,
                                    ),
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
                    top: imageHeight - (actionHeight / 2),
                    child: GestureDetector(
                      onTap: meeting ? null : _join,
                      child: Container(
                        height: actionHeight,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: data.joined || meeting ? Iro.greenMid : HomeColors.navy,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: const [BoxShadow(color: Color(0x330C3320), blurRadius: 12, offset: Offset(0, 4))],
                        ),
                        child: Text(
                          meeting
                              ? 'invited'.tr
                              : joining
                              ? '…'
                              : data.joined
                              ? 'joined'.trFallback('Joined')
                              : 'join'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.biggest.shortestSide;
        final glyph = (side.isFinite ? side * 0.44 : 30.0).clamp(18.0, 46.0);
        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [HomeColors.peach2, HomeColors.peach],
            ),
          ),
          child: Center(
            child: Icon(icon, color: HomeColors.orange, size: glyph),
          ),
        );
      },
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
          titleKey: 'upcoming_events',
          onSeeMore: () => Get.toNamed(Routes.upcomingEvents),
        ),
        if (events.isEmpty)
          const _HomeEventsEmpty()
        else
          // A rail rather than a single card: a member with three things on this
          // week should see all three without leaving Home. A Row rather than a
          // horizontal ListView, because a ListView hands every card the same
          // height and an event with no image was left sitting over a gap.
          Builder(
            builder: (context) {
              final shown = events.take(5).toList();
              final cardWidth = (MediaQuery.sizeOf(context).width - 64).clamp(260.0, 420.0);
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < shown.length; i++) ...[
                      if (i > 0) const SizedBox(width: 12),
                      SizedBox(
                        width: cardWidth,
                        child: HomeEventCard(event: shown[i], margin: EdgeInsets.zero),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

class _HomeEventsEmpty extends StatelessWidget {
  const _HomeEventsEmpty();

  @override
  Widget build(BuildContext context) {
    final canCreate =
        Get.isRegistered<SessionController>() &&
        Get.find<SessionController>().canCreateOrgEvents;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: InkWell(
        onTap: () =>
            Get.toNamed(canCreate ? Routes.createEvent : Routes.upcomingEvents),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          decoration: BoxDecoration(
            // Lilac into cream: the two washes behind the navy and orange
            // families, so the card stays light and belongs to both.
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.brandWash, HomeColors.peach2],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: HomeColors.border, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.event_outlined, color: HomeColors.orange, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                'upcoming_events_empty'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: HomeColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
              if (canCreate) ...[
                const SizedBox(height: 3),
                Text(
                  'create_event_eyebrow'.trFallback('Create an upcoming event'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: HomeColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
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
    if (shown.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: AppEmptyCard(
          compact: true,
          icon: Icons.play_circle_outline_rounded,
          title: 'recent_videos_empty'.trFallback('No videos yet.'),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          for (var i = 0; i < shown.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(child: _HomeVideoCard(item: shown[i])),
          ],
        ],
      ),
    );
  }
}

class _HomeVideoCard extends StatelessWidget {
  const _HomeVideoCard({required this.item});
  final HomeFeedItem item;

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
                    Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const PostMediaPlaceholder(
                        kind: PostPlaceholderKind.video,
                      ),
                    )
                  else
                    const PostMediaPlaceholder(kind: PostPlaceholderKind.video),
                  const Center(
                    child: CircleAvatar(
                      radius: 19,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: HomeColors.navy,
                        size: 22,
                      ),
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
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              height: 1.3,
              color: HomeColors.ink,
            ),
          ),
          if (item.source.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              item.source,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: HomeColors.muted),
            ),
          ],
          const SizedBox(height: 7),
          ContentVoteBar(item: item, compact: true),
        ],
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
    if (shown.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: AppEmptyCard(
          compact: true,
          icon: Icons.article_outlined,
          title: 'recent_blogs_empty'.trFallback('No blogs yet.'),
        ),
      );
    }
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
        itemBuilder: (context, index) =>
            HomeFeedCard(item: items[index], kind: kind),
      ),
    );
  }
}

class HomeFeedCard extends StatelessWidget {
  const HomeFeedCard({
    super.key,
    required this.item,
    this.kind = HomeFeedKind.blog,
    this.expanded = false,
  });
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
    return _BlogTile(
      item: item,
      expanded: expanded,
      video: item.video || kind == HomeFeedKind.video,
    );
  }
}

class _BlogTile extends StatelessWidget {
  const _BlogTile({
    required this.item,
    required this.expanded,
    required this.video,
  });
  final HomeFeedItem item;
  final bool expanded;
  final bool video;

  /// A blog with no poster gets the dark forest tile, not the pale wash the
  /// post screens use for missing media. The rail sits on mint, so a pale tile
  /// disappears into the page; the dark one reads as a cover.
  Widget get _cover => ColoredBox(
        color: Iro.forest,
        child: Center(
          child: Icon(
            video ? Icons.play_arrow_rounded : Icons.description_outlined,
            color: Iro.bright,
            size: 24,
          ),
        ),
      );

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
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.25,
              color: HomeColors.ink,
            ),
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
          const SizedBox(height: 7),
          ContentVoteBar(item: item, compact: true),
        ],
      ),
    );
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: HomeColors.border, width: 1.5),
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
                      Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _cover,
                      )
                    else
                      _cover,
                    if (video && item.imageUrl != null)
                      const Center(
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: HomeColors.navy,
                            size: 18,
                          ),
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
              ? const PostMediaPlaceholder(kind: PostPlaceholderKind.image)
              : Image.network(
                  item.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const PostMediaPlaceholder(
                    kind: PostPlaceholderKind.image,
                  ),
                ),
        ),
      ),
    );
  }
}

/// WhatsApp's own green, so the share button is recognisable as theirs rather
/// than reading as another app action.
const _whatsappGreen = Color(0xFF2E9E4F);

/// The official-message card: an announcement from the leadership, with the
/// option to hear it and to pass it on.
class HomeBroadcastCard extends StatefulWidget {
  const HomeBroadcastCard({super.key, required this.broadcast});
  final Broadcast broadcast;

  @override
  State<HomeBroadcastCard> createState() => _HomeBroadcastCardState();
}

class _HomeBroadcastCardState extends State<HomeBroadcastCard> {
  AudioPlayer? _player;
  StreamSubscription<void>? _done;
  var _playing = false;

  Broadcast get broadcast => widget.broadcast;

  @override
  void dispose() {
    _done?.cancel();
    _player?.dispose();
    super.dispose();
  }

  /// Built lazily: most broadcasts carry no recording, and a player nobody uses
  /// still holds a platform channel open.
  Future<void> _toggleAudio() async {
    final url = broadcast.audioUrl;
    if (url == null) return;
    final player = _player ??= AudioPlayer();
    _done ??= player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playing = false);
    });
    try {
      if (_playing) {
        await player.pause();
        if (mounted) setState(() => _playing = false);
        return;
      }
      await player.play(UrlSource(url));
      if (mounted) setState(() => _playing = true);
    } catch (e, stack) {
      AppLog.error('broadcast audio failed', error: e, stack: stack, tag: 'HOME');
      if (mounted) flash('Error', apiErrorMessage(e));
    }
  }

  String get _when {
    final at = broadcast.sentAt;
    final now = DateTime.now();
    // No locale argument: the app never calls initializeDateFormatting, so
    // naming one throws LocaleDataException. Matches how dates read elsewhere.
    final time = DateFormat('hh:mm a').format(at);
    final sameDay = at.year == now.year && at.month == now.month && at.day == now.day;
    if (sameDay) return '${'broadcast_today'.trFallback('Today')}, $time';
    return '${DateFormat('d MMM').format(at)}, $time';
  }

  Future<void> _share(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        text: broadcast.message,
        subject: 'broadcast_official'.trFallback('Official message'),
        sharePositionOrigin: box == null ? Rect.zero : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [HomeColors.peach2, HomeColors.peach],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: HomeColors.border, width: 1.5),
          boxShadow: homeCardShadow,
        ),
        padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: HomeColors.orange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 17),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'broadcast_official'.trFallback('Official message'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: HomeColors.orangeDark,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _when,
                  style: const TextStyle(color: HomeColors.muted, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              broadcast.message,
              style: homeTitleStyle(size: 13.5, color: HomeColors.ink, weight: FontWeight.w700).copyWith(height: 1.35),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (broadcast.hasAudio) ...[
                  Expanded(
                    child: _BroadcastAction(
                      icon: _playing ? Icons.pause_rounded : Icons.volume_up_rounded,
                      label: _playing
                          ? 'broadcast_pause'.trFallback('Pause')
                          : 'broadcast_listen'.trFallback('Listen'),
                      background: Colors.white,
                      foreground: AppColors.ink,
                      onTap: _toggleAudio,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Builder(
                    builder: (buttonContext) => _BroadcastAction(
                      icon: Icons.share_outlined,
                      label: 'broadcast_share'.trFallback('Share on WhatsApp'),
                      background: _whatsappGreen,
                      foreground: Colors.white,
                      onTap: () => _share(buttonContext),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BroadcastAction extends StatelessWidget {
  const _BroadcastAction({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: foreground),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: foreground, fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
