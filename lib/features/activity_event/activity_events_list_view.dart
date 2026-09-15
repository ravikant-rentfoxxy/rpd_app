import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/api_error.dart';
import '../../core/widgets/empty_card.dart';
import '../../core/widgets/ui.dart';
import '../join/join_chrome.dart';
import 'activity_event_api.dart';
import '../../core/widgets/flash.dart';

class ActivityEventsListView extends StatefulWidget {
  const ActivityEventsListView({super.key});

  @override
  State<ActivityEventsListView> createState() => _ActivityEventsListViewState();
}

class _ActivityEventsListViewState extends State<ActivityEventsListView> {
  final events = <Map<String, dynamic>>[];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final list = await fetchActivityEvents();
      if (!mounted) return;
      setState(() {
        events
          ..clear()
          ..addAll(list);
      });
    } catch (e) {
      flash('Error', apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeColors.paper,
      appBar: AppBar(
        backgroundColor: HomeColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('activity_events'.trFallback('Activity events')),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: HomeColors.navy,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: HomeColors.orange))
          : RefreshIndicator(
              color: HomeColors.orange,
              onRefresh: _load,
              child: events.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 48),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: AppEmptyCard(
                            icon: Icons.campaign_outlined,
                            title: 'activity_events_empty'.trFallback('No activity events right now.'),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                      itemCount: events.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final event = events[index];
                        final answered = event['answered'] == true;
                        final isCreator = event['isCreator'] == true;
                        final count = (event['responseCount'] as num?)?.toInt();
                        final sub = isCreator && count != null
                            ? 'activity_event_member_count'.trParams({'n': '$count'})
                            : answered
                                ? 'activity_event_done'.trFallback('You already answered')
                                : 'activity_event_open_sub'.trFallback('Tap to answer Yes or No');
                        return AppCard(
                          onTap: () => Get.toNamed(Routes.activityEventPlay, arguments: event),
                          child: CardTitle(
                            '${event['title'] ?? 'activity_event'.trFallback('Activity event')}',
                            sub: sub,
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
