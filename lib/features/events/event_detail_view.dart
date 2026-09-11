import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/api_error.dart';
import '../../core/utils/local_image.dart';
import '../../core/widgets/ui.dart';
import '../../data/models/home_feed.dart';
import '../home/home_widgets.dart';
import '../join/join_chrome.dart';
import '../session/session_controller.dart';
import 'event_api.dart';
import 'join_celebration.dart';

class EventDetailView extends StatefulWidget {
  const EventDetailView({super.key});

  @override
  State<EventDetailView> createState() => _EventDetailViewState();
}

class _EventDetailViewState extends State<EventDetailView> {
  UpcomingEvent? event;
  bool joining = false;

  @override
  void initState() {
    super.initState();
    final raw = Get.arguments;
    if (raw is UpcomingEvent) {
      event = raw;
    } else if (raw is Map) {
      event = UpcomingEvent.fromJson(Map<String, dynamic>.from(raw));
    }
    final id = event?.id ?? '';
    if (id.isNotEmpty) _refresh(id);
  }

  Future<void> _refresh(String id) async {
    try {
      final fresh = await fetchOrgEvent(id);
      Get.find<SessionController>().patchUpcomingEvent(fresh);
      if (!mounted) return;
      setState(() => event = UpcomingEvent.fromJson(fresh));
    } catch (_) {}
  }

  UpcomingEvent get data {
    final current = event;
    if (current == null) return const UpcomingEvent(title: '', when: '', place: '', imageUrl: '');
    final home = Get.find<SessionController>().home.value;
    final raw = (home?['upcomingEvents'] as List? ?? []).whereType<Map>().where((item) => '${item['id']}' == current.id);
    if (current.id.isNotEmpty && raw.isNotEmpty) {
      return UpcomingEvent.fromJson(Map<String, dynamic>.from(raw.first));
    }
    return current;
  }

  Future<void> _join() async {
    final current = data;
    if (current.id.isEmpty || current.joined || joining) return;
    setState(() => joining = true);
    try {
      await Get.find<SessionController>().joinUpcomingEvent(current.id);
      if (!mounted) return;
      await showJoinCelebration(context);
      setState(() {});
    } catch (e) {
      Get.snackbar('Error', apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => joining = false);
    }
  }

  void _viewPhoto() {
    final url = resolveMediaUrl(data.imageUrl);
    if (url == null || url.isEmpty) return;
    Get.to(() => _EventImageViewer(url: url, title: data.title));
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      Get.find<SessionController>().home.value;
      final item = data;
      return Scaffold(
        backgroundColor: const Color(0xFFFAF6F0),
        appBar: OrganicAppBar(
          title: item.title.isEmpty ? 'event_detail'.trFallback('Event') : item.title,
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: item.joined || joining ? null : _join,
                style: FilledButton.styleFrom(
                  backgroundColor: item.joined ? const Color(0xFF1B8A6A) : const Color(0xFFF5821F),
                  disabledBackgroundColor: item.joined ? const Color(0xFF1B8A6A) : const Color(0xFFC6BBA8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  elevation: 0,
                ),
                child: Text(
                  joining
                      ? '…'
                      : item.joined
                          ? 'joined'.trFallback('Joined')
                          : 'join'.tr,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFEFE4D6), width: 0.5),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: item.imageUrl.isEmpty ? null : _viewPhoto,
                    child: SizedBox(
                      height: 210,
                      width: double.infinity,
                      child: localOrNetworkPhoto(
                        raw: item.imageUrl,
                        fit: BoxFit.cover,
                        fallback: EventPlaceholder(type: item.type),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: HomeColors.ink)),
                        const SizedBox(height: 12),
                        _MetaRow(icon: Icons.schedule_rounded, text: item.when),
                        if (item.place.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _MetaRow(icon: Icons.place_outlined, text: item.place),
                        ],
                        if (item.hostName.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _MetaRow(icon: Icons.person_outline_rounded, text: 'hosted_by'.trParams({'name': item.hostName})),
                        ],
                        if (item.description.trim().isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text('event_notes'.trFallback('Notes'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFA6957A), letterSpacing: 0.2)),
                          const SizedBox(height: 6),
                          Text(item.description, style: const TextStyle(fontSize: 15, height: 1.45, color: HomeColors.ink)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Color(0xFFEFE4D6), width: 0.5),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Row(
                  children: [
                    const Icon(Icons.groups_outlined, size: 20, color: HomeColors.orange),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'members_joining'.trParams({'n': '${item.joining}'}),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: HomeColors.ink),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFFC2600F)),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14, height: 1.35, color: HomeColors.ink))),
      ],
    );
  }
}

class _EventImageViewer extends StatelessWidget {
  const _EventImageViewer({required this.url, required this.title});
  final String url;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, title: Text(title)),
      body: Center(
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Image.network(url, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
