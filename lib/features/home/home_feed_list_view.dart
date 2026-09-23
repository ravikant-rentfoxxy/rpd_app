import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/ui.dart';
import '../../core/widgets/empty_card.dart';
import '../../data/models/home_feed.dart';
import '../session/session_controller.dart';
import 'home_widgets.dart';

class HomeFeedListView extends StatelessWidget {
  const HomeFeedListView({super.key, required this.title, required this.items});

  final String title;
  final List<HomeFeedItem> items;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeColors.paper,
      appBar: OrganicAppBar(title: title),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) => HomeFeedCard(item: items[index], expanded: true),
      ),
    );
  }
}

class UpcomingEventsView extends StatefulWidget {
  const UpcomingEventsView({super.key});

  @override
  State<UpcomingEventsView> createState() => _UpcomingEventsViewState();
}

class _UpcomingEventsViewState extends State<UpcomingEventsView> {
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    await Get.find<SessionController>().loadAllUpcomingEvents();
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeColors.paper,
      appBar: OrganicAppBar(title: 'upcoming_events'.tr),
      body: Obx(() {
        final session = Get.find<SessionController>();
        session.home.value;
        final events = upcomingEventsFrom(
          session.allUpcomingEvents.isNotEmpty
              ? session.allUpcomingEvents
              : session.home.value?['upcomingEvents'] as List?,
        );
        if (loading && events.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: HomeColors.orange));
        }
        if (events.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: AppEmptyCard(
                icon: Icons.event_outlined,
                title: 'upcoming_events_empty'.tr,
              ),
            ),
          );
        }
        return RefreshIndicator(
          color: HomeColors.orange,
          onRefresh: _load,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
            itemCount: events.length,
            itemBuilder: (context, index) => HomeEventCard(event: events[index]),
          ),
        );
      }),
    );
  }
}
