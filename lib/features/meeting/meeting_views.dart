import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/ui.dart';
import '../../data/remote/api_client.dart';

class MeetingDetailView extends StatelessWidget {
  const MeetingDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final meetings = Rxn<List>();
    Get.find<ApiClient>().get('/meetings').then((r) {
      meetings.value = r['data']['meetings'] as List?;
    }).ignore();
    return Scaffold(
      appBar: AppBar(title: Text('booth_meeting'.tr)),
      body: Obx(() {
        final first = meetings.value?.isNotEmpty == true ? Map<String, dynamic>.from(meetings.value!.first as Map) : null;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppCard(tone: CardTone.brand, child: CardTitle('Starting in 20 minutes', sub: '${first?['invitees']?.length ?? 11} invited · ${first?['checkIns']?.length ?? 0} checked in')),
            AppCard(child: CardTitle('Agenda', sub: first?['agenda'] as String? ?? '1. Membership drive review\n2. Panna Pramukh appointments\n3. Sampark programme dates')),
            PrimaryButton('start_checkin'.tr, onTap: () => Get.toNamed(Routes.checkIn, arguments: first?['id'])),
            const SizedBox(height: 12),
            Text('invited'.tr, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink3)),
            ...((first?['invitees'] as List?) ?? []).map((e) {
              final i = Map<String, dynamic>.from(e as Map);
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const AvatarCircle('M'),
                title: Text(i['postLabel'] as String? ?? ''),
                trailing: Pill('Not yet'),
              );
            }),
          ],
        );
      }),
    );
  }
}

class CheckInView extends StatelessWidget {
  const CheckInView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Check-in'), actions: [TextButton(onPressed: () {}, child: const Text('Manual'))]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 190,
            decoration: BoxDecoration(color: const Color(0xFF141018), borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Text('Point at the member\'s card QR', style: TextStyle(color: Colors.white70))),
          ),
          const SizedBox(height: 12),
          AppCard(tone: CardTone.ok, child: CardTitle('✓ Sunita Devi checked in', sub: 'RPD-0004102891 · 6:04 pm')),
          AppCard(tone: CardTone.flat, child: CardTitle('Working offline', sub: 'Cards are verified on this phone. Check-ins upload later.')),
        ],
      ),
    );
  }
}
