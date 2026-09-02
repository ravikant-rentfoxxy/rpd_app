import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_log.dart';
import '../../core/widgets/ui.dart';
import '../../data/local/hive_service.dart';
import '../../data/remote/api_client.dart';
import '../session/session_controller.dart';

class ActivityDetailsView extends StatelessWidget {
  const ActivityDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    final type = (Get.arguments as String?) ?? 'MEETING';
    final notes = TextEditingController();
    final hive = Get.find<HiveService>();
    final booth = hive.draft.get('booth') as Map? ?? Get.find<SessionController>().member?['booth'] as Map?;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: Get.back, icon: const Icon(Icons.close)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('booth_meeting'.tr),
            Text('Step 1 of 3 · details', style: const TextStyle(fontSize: 12, color: AppColors.ink3)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const StepBar(total: 3, current: 1),
          AppCard(
            tone: CardTone.flat,
            child: CardTitle(DateTime.now().toLocal().toString().substring(0, 16), sub: 'Taken from your phone.'),
          ),
          AppCard(child: CardTitle('Where', sub: '${booth?['code'] ?? 'B045'} · ${booth?['name'] ?? 'Primary School, Sihani'}')),
          AppCard(child: CardTitle('Meeting type', sub: type)),
          AppField(label: 'What was discussed', controller: notes, hint: 'Tap to type or speak'),
          AppCard(child: CardTitle('Photos · 0 of 2', sub: 'One wide shot of the meeting, one selfie at the venue.')),
          PrimaryButton('Take photos', onTap: () => Get.toNamed(Routes.activityConfirm, arguments: {'type': type, 'notes': notes.text})),
        ],
      ),
    );
  }
}

class ActivityConfirmView extends StatelessWidget {
  const ActivityConfirmView({super.key});

  @override
  Widget build(BuildContext context) {
    final args = (Get.arguments as Map?) ?? {};
    final session = Get.find<SessionController>();
    final booth = session.member?['booth'] as Map?;
    return Scaffold(
      appBar: AppBar(title: Text('booth_meeting'.tr)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const StepBar(total: 3, current: 3),
          Container(
            height: 110,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: AppColors.sunk, borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Icon(Icons.place, color: AppColors.brandLight, size: 32)),
          ),
          AppCard(tone: CardTone.ok, child: CardTitle('● 180 m from ${booth?['code'] ?? 'B045'}', sub: 'Within the normal range for this booth.')),
          AppCard(child: CardTitle('Who was there · 14', sub: '12 chosen from your booth list, 2 added by name')),
          AppCard(tone: CardTone.flat, child: CardTitle('2 photos attached', sub: 'Wide shot and selfie · 620 KB total')),
          PrimaryButton('save_meeting'.tr, onTap: () async {
            final hive = Get.find<HiveService>();
            final id = const Uuid().v4();
            final item = {
              'id': id,
              'type': args['type'] ?? 'MEETING',
              'title': 'Booth meeting',
              'createdAt': DateTime.now().toIso8601String(),
              'size': '620 KB',
            };
            await hive.enqueueSync(item);
            session.syncCount.value = hive.pendingSync().length;
            try {
              final boothId = booth?['id'] ?? hive.draft.get('boothId');
              if (boothId != null) {
                await Get.find<ApiClient>().post('/activities', data: {
                  'clientUuid': id,
                  'type': args['type'] ?? 'MEETING',
                  'boothId': boothId,
                  'occurredAt': DateTime.now().toUtc().toIso8601String(),
                  'notes': args['notes'],
                  'latitude': session.lat.value ?? 28.6692,
                  'longitude': session.lng.value ?? 77.4538,
                  'attendeeNames': ['Guest 1', 'Guest 2'],
                });
                await hive.removeSync(id);
                session.syncCount.value = hive.pendingSync().length;
              }
            } catch (e, stack) {
              AppLog.error('Activity upload failed, kept in sync queue', error: e, stack: stack, tag: 'ACTIVITY');
            }
            Get.offNamed(Routes.activitySaved);
          }),
          const SizedBox(height: 8),
          Text('saved_phone'.tr, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.ink3, fontSize: 12)),
        ],
      ),
    );
  }
}

class ActivitySavedView extends StatelessWidget {
  const ActivitySavedView({super.key});

  @override
  Widget build(BuildContext context) {
    final n = Get.find<SessionController>().syncCount.value;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(color: AppColors.okBg, shape: BoxShape.circle),
              child: const Icon(Icons.check, color: AppColors.ok, size: 32),
            ),
            const SizedBox(height: 16),
            DisplayText('meeting_saved'.tr, center: true),
            const SizedBox(height: 8),
            Text('saved_phone'.tr, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.ink3)),
            const SizedBox(height: 16),
            AppCard(child: CardTitle('waiting_upload'.tr, sub: '$n items in the queue')),
            AppCard(tone: CardTone.flat, child: CardTitle('25 points pending', sub: 'Added once your Mandal President verifies this meeting.')),
            PrimaryButton('record_else'.tr, onTap: () => Get.offAllNamed(Routes.shell)),
            const SizedBox(height: 8),
            PrimaryButton('back_home'.tr, ghost: true, onTap: () => Get.offAllNamed(Routes.shell)),
          ],
        ),
      ),
    );
  }
}

class ActivityRejectedView extends StatelessWidget {
  const ActivityRejectedView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('booth_meeting'.tr)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(tone: CardTone.bad, child: CardTitle('▲ ${'not_verified'.tr}', sub: 'Your Mandal President could not accept this one.')),
          const AppCard(
            child: CardTitle(
              'Reason given',
              sub:
                  '"This photograph was also submitted for the meeting on 22 August. Please attach a photo from this meeting."\n— Rajesh Sharma, Mandal President, 29 Aug',
            ),
          ),
          AppCard(tone: CardTone.flat, child: CardTitle('No points were deducted', sub: 'Deductions apply only to repeated cases. Correct it and resubmit.')),
          PrimaryButton('add_correct_photo'.tr, onTap: () => Get.toNamed(Routes.activityDetails)),
          const SizedBox(height: 8),
          PrimaryButton('i_disagree'.tr, ghost: true, onTap: () {}),
        ],
      ),
    );
  }
}
