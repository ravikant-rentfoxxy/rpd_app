import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
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
      appBar: AppBar(
        backgroundColor: HomeColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: HomeColors.navy,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
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
      appBar: AppBar(
        backgroundColor: HomeColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('upcoming_events'.tr, style: const TextStyle(fontWeight: FontWeight.w500)),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: HomeColors.navy,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
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
              padding: const EdgeInsets.all(32),
              child: Text(
                'upcoming_events_empty'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(color: HomeColors.muted),
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
