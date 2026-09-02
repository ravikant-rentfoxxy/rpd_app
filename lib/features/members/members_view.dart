import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_log.dart';
import '../../core/widgets/ui.dart';
import '../../data/remote/api_client.dart';

class MembersView extends StatelessWidget {
  const MembersView({super.key});

  @override
  Widget build(BuildContext context) {
    final data = Rxn<Map<String, dynamic>>();
    Get.find<ApiClient>().get('/members/recruits').then((r) {
      data.value = Map<String, dynamic>.from(r['data'] as Map);
    }).ignore();
    return Scaffold(
      appBar: AppBar(
        title: Text('my_recruits'.tr),
        actions: [TextButton(onPressed: () {}, child: Text('filter'.tr))],
      ),
      body: Obx(() {
        final counts = Map<String, dynamic>.from(data.value?['counts'] as Map? ?? {});
        final list = (data.value?['recruits'] as List?) ?? [];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                _c('${counts['verified'] ?? 98}', 'verified'.tr, AppColors.ok),
                _c('${counts['pending'] ?? 4}', 'pending'.tr, AppColors.warn),
                _c('${counts['rejected'] ?? 2}', 'rejected'.tr, AppColors.bad),
              ],
            ),
            const SizedBox(height: 8),
            PrimaryButton('add_member'.tr, onTap: () => Get.toNamed(Routes.addMember)),
            const SizedBox(height: 8),
            ...list.map((e) {
              final m = Map<String, dynamic>.from(e as Map);
              final status = m['status'] as String? ?? 'PENDING';
              final tone = switch (status) {
                'VERIFIED' => PillTone.ok,
                'REJECTED' => PillTone.bad,
                _ => PillTone.warn,
              };
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: AvatarCircle(((m['fullName'] as String? ?? 'M').split(' ').map((p) => p[0]).take(2).join())),
                title: Text(m['fullName'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: MonoText('${m['booth']?['code'] ?? ''} · ${status.toLowerCase()}'),
                trailing: Pill(status, tone: tone),
              );
            }),
            AppCard(tone: CardTone.flat, child: CardTitle('18 not yet at 90 days', sub: 'Points for these arrive as each one completes three months.')),
          ],
        );
      }),
    );
  }

  Widget _c(String n, String l, Color c) => Expanded(
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.rule), borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            DisplayText(n, size: 22, color: c),
            Text(l, style: const TextStyle(fontSize: 11, color: AppColors.ink3)),
          ]),
        ),
      );
}

class AddMemberView extends StatelessWidget {
  const AddMemberView({super.key});

  @override
  Widget build(BuildContext context) {
    final mobile = TextEditingController();
    final exists = Rxn<Map<String, dynamic>>();
    return Scaffold(
      appBar: AppBar(title: Text('add_member'.tr)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const StepBar(total: 4, current: 1),
          DisplayText('your_mobile'.tr),
          const SizedBox(height: 8),
          AppField(
            label: 'mobile_number'.tr,
            controller: mobile,
            keyboard: TextInputType.phone,
            mono: true,
            prefix: '+91  ',
            maxLength: 10,
            hint: '98•••• ••••',
          ),
          Obx(() {
            final e = exists.value;
            if (e == null) return const SizedBox.shrink();
            if (e['exists'] == true) {
              final m = e['member'] as Map? ?? {};
              return AppCard(
                tone: CardTone.warn,
                child: CardTitle('already_member'.tr, sub: '${m['membershipNumber']} · ${m['fullName']}'),
              );
            }
            return AppCard(tone: CardTone.ok, child: CardTitle('continue'.tr, sub: 'Number is free'));
          }),
          PrimaryButton('continue'.tr, onTap: () async {
            try {
              final res = await Get.find<ApiClient>().get('/members/check/${mobile.text.trim()}');
              exists.value = Map<String, dynamic>.from(res['data'] as Map);
              if (exists.value?['exists'] != true) {
                Get.toNamed(Routes.recruitConsent, arguments: mobile.text.trim());
              }
            } catch (err, stack) {
              AppLog.error('Member check failed', error: err, stack: stack, tag: 'MEMBERS');
              Get.snackbar('Error', err.toString());
            }
          }),
        ],
      ),
    );
  }
}

class RecruitConsentView extends StatelessWidget {
  const RecruitConsentView({super.key});

  @override
  Widget build(BuildContext context) {
    final agreed = false.obs;
    final otp = TextEditingController();
    return Scaffold(
      appBar: AppBar(title: Text('add_member'.tr)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const StepBar(total: 4, current: 4),
          AppCard(tone: CardTone.brand, child: CardTitle('hand_phone'.tr, sub: 'must_agree'.tr)),
          AppCard(child: CardTitle('▶ Play the notice aloud', sub: 'हिन्दी में सुनें · 40 seconds')),
          Obx(() => AppCard(onTap: agreed.toggle, child: CardTitle('${agreed.value ? '☑' : '☐'} ${'i_agree'.tr}', sub: 'required'.tr))),
          AppField(label: 'OTP', controller: otp, keyboard: TextInputType.number, mono: true),
          Obx(() => PrimaryButton('submit_app'.tr, enabled: agreed.value && otp.text.length >= 4, onTap: () => Get.back())),
        ],
      ),
    );
  }
}
