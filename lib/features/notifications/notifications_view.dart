import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/ui.dart';

class _DummyNotice {
  const _DummyNotice({
    required this.title,
    required this.body,
    required this.time,
    required this.unread,
  });
  final String title;
  final String body;
  final String time;
  final bool unread;
}

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _DummyNotice(
        title: 'New member added',
        body: 'Ramesh Yadav is now in your recruits list.',
        time: '2 min ago',
        unread: true,
      ),
      _DummyNotice(
        title: 'Task due today',
        body: 'Booth committee list · Griha sampark report',
        time: '1 hr ago',
        unread: true,
      ),
      _DummyNotice(
        title: 'Meeting tomorrow',
        body: 'Booth meeting at 6:00 PM · School ground',
        time: 'Yesterday',
        unread: false,
      ),
      _DummyNotice(
        title: 'Activity verified',
        body: 'Your booth meeting was verified by the Mandal President.',
        time: '2 days ago',
        unread: false,
      ),
    ].obs;

    return Scaffold(
      appBar: OrganicAppBar(
        title: 'notifications'.tr,
        actions: [
          TextButton(
            onPressed: () {
              items.assignAll(items.map((n) => _DummyNotice(
                    title: n.title,
                    body: n.body,
                    time: n.time,
                    unread: false,
                  )));
            },
            child: Text(
              'mark_all_read'.tr,
              style: const TextStyle(color: HomeColors.orangeSoft, fontWeight: FontWeight.w700, fontSize: 12.5),
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (items.isEmpty) {
          return Center(child: Text('notif_empty'.tr, style: const TextStyle(color: AppColors.ink3)));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 4),
          itemBuilder: (context, index) {
            final n = items[index];
            return AppCard(
              tone: n.unread ? CardTone.ok : CardTone.plain,
              onTap: () {
                items[index] = _DummyNotice(
                  title: n.title,
                  body: n.body,
                  time: n.time,
                  unread: false,
                );
              },
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CardTitle(n.title, sub: n.body),
                        const SizedBox(height: 6),
                        MonoText(n.time),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      if (n.unread) const Pill('NEW', tone: PillTone.brand),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}
