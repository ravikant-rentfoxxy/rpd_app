import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/language_dropdown.dart';
import '../../core/utils/api_error.dart';
import '../../core/utils/app_log.dart';
import '../../core/utils/dob.dart';
import '../../core/widgets/ui.dart';
import '../../data/local/hive_service.dart';
import '../../data/remote/api_client.dart';
import '../session/session_controller.dart';

class MembersListController extends GetxController {
  final data = Rxn<Map<String, dynamic>>();

  @override
  void onInit() {
    super.onInit();
    refreshList();
    ever(Get.find<SessionController>().recruitsTick, (_) => refreshList());
  }

  void apply(Map<String, dynamic> payload) {
    data.value = payload;
  }

  Future<void> refreshList() async {
    try {
      final r = await Get.find<ApiClient>().get('/members/recruits');
      data.value = Map<String, dynamic>.from(r['data'] as Map);
    } catch (err, stack) {
      AppLog.error('Recruits list failed', error: err, stack: stack, tag: 'MEMBERS');
    }
  }
}

class MembersView extends StatelessWidget {
  const MembersView({super.key});

  @override
  Widget build(BuildContext context) {
    final listController = Get.put(MembersListController());
    return Scaffold(
      appBar: OrganicAppBar(
        title: 'my_recruits'.tr,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Center(child: LanguageDropdown(pill: true)),
          ),
        ],
      ),
      body: Obx(() {
        final data = listController.data;
        final counts = Map<String, dynamic>.from(data.value?['counts'] as Map? ?? {});
        final list = (data.value?['recruits'] as List?) ?? [];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                _c('${counts['verified'] ?? 0}', 'verified'.tr, HomeColors.navyMid),
                _c('${counts['pending'] ?? 0}', 'pending'.tr, HomeColors.orange),
                _c('${counts['rejected'] ?? 0}', 'rejected'.tr, HomeColors.muted),
              ],
            ),
            const SizedBox(height: 8),
            PrimaryButton(
              'add_member'.tr,
              onTap: () {
                if (!Get.find<SessionController>().guardVerifiedAccess()) return;
                Get.toNamed(Routes.addMember);
              },
            ),
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
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            DisplayText(n, size: 24, color: c),
            Text(l, style: const TextStyle(fontSize: 11, color: AppColors.ink3)),
          ]),
        ),
      );
}

class AddMemberView extends StatelessWidget {
  const AddMemberView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.find<SessionController>().guardVerifiedAccess()) {
      return Scaffold(appBar: AppBar(title: Text('add_member'.tr)), body: const SizedBox.shrink());
    }
    final mobile = TextEditingController();
    final exists = Rxn<Map<String, dynamic>>();
    return Scaffold(
      appBar: AppBar(title: Text('add_member'.tr)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const StepBar(total: 2, current: 1),
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
                Get.toNamed(Routes.recruitConsent, arguments: {'mobile': mobile.text.trim()});
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
    final args = Get.arguments;
    final rawMobile = args is Map ? args['mobile'] : args;
    final mobile = (rawMobile as String? ?? '').replaceAll(RegExp(r'\D'), '');
    final session = Get.find<SessionController>();
    final hive = Get.find<HiveService>();
    final agreed = false.obs;
    final submitting = false.obs;
    final formTick = 0.obs;
    final gender = 'MALE'.obs;
    final name = TextEditingController();
    final dob = TextEditingController();
    final otp = TextEditingController();

    void tick() => formTick.value++;

    String? recruiterBoothId() {
      final direct = session.member?['boothId'];
      if (direct is String && direct.isNotEmpty) return direct;
      final nested = (session.member?['booth'] as Map?)?['id'];
      if (nested is String && nested.isNotEmpty) return nested;
      return null;
    }

    Future<void> submit() async {
      if (mobile.length != 10) {
        Get.snackbar('Error', 'mobile_number'.tr);
        return;
      }
      final fullName = name.text.trim();
      final dobValue = dobToIso(dob.text);
      if (fullName.length < 2 || !isValidDob(dobValue)) {
        Get.snackbar('Error', !isValidDob(dobValue) ? 'dob_invalid'.tr : 'complete_steps'.tr);
        return;
      }
      submitting.value = true;
      try {
        final boothId = recruiterBoothId();
        final payload = await session.recruitMember({
          'mobile': mobile,
          'fullName': fullName,
          'dateOfBirth': dobValue,
          'gender': gender.value,
          ?'boothId': boothId,
          'locale': switch (hive.locale) {
            'en' => 'EN',
            'bho' => 'BHO',
            _ => 'HI',
          },
          'requiredConsentVersion': '2026.08',
          'whatsappOptIn': false,
        });
        if (Get.isRegistered<MembersListController>()) {
          Get.find<MembersListController>().apply(payload);
        }
        session.shellIndex.value = 3;
        Get.until((route) => route.settings.name == Routes.shell);
        Get.snackbar('member_added'.tr, fullName);
      } catch (err, stack) {
        AppLog.error('Recruit member failed', error: err, stack: stack, tag: 'MEMBERS');
        Get.snackbar('Error', apiErrorMessage(err));
      } finally {
        submitting.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text('add_member'.tr)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          const StepBar(total: 2, current: 2),
          AppCard(tone: CardTone.brand, child: CardTitle('hand_phone'.tr, sub: 'must_agree'.tr)),
          AppField(label: 'full_name'.tr, controller: name, hint: 'enter_name'.tr, onChanged: (_) => tick()),
          GestureDetector(
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: parseDobDate(dob.text) ?? DateTime(now.year - 25, 1, 1),
                firstDate: DateTime(now.year - 120),
                lastDate: now,
              );
              if (picked == null) return;
              dob.text = dateToDisplay(picked);
              tick();
            },
            child: AbsorbPointer(
              child: AppField(label: '${'dob'.tr} *', controller: dob, hint: 'dob_hint'.tr, keyboard: TextInputType.none),
            ),
          ),
          Obx(
            () => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'gender'.tr,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: gender.value,
                    items: [
                      DropdownMenuItem(value: 'MALE', child: Text('male'.tr)),
                      DropdownMenuItem(value: 'FEMALE', child: Text('female'.tr)),
                      DropdownMenuItem(value: 'OTHER', child: Text('other'.tr)),
                    ],
                    onChanged: (v) {
                      gender.value = v ?? 'MALE';
                      tick();
                    },
                  ),
                ),
              ),
            ),
          ),
          Obx(() => AppCard(onTap: agreed.toggle, child: CardTitle('${agreed.value ? '☑' : '☐'} ${'i_agree'.tr}', sub: 'required'.tr))),
          AppField(
            label: 'OTP',
            controller: otp,
            keyboard: TextInputType.number,
            mono: true,
            hint: '6-digit code',
            maxLength: 6,
            digitsOnly: true,
            onChanged: (_) => tick(),
          ),
          Obx(() {
            formTick.value;
            submitting.value;
            final canSubmit = agreed.value &&
                otp.text.length == 6 &&
                name.text.trim().length >= 2 &&
                isValidDob(dob.text) &&
                !submitting.value;
            return PrimaryButton(
              submitting.value ? '…' : 'submit_app'.tr,
              enabled: canSubmit,
              onTap: submit,
            );
          }),
        ],
      ),
    );
  }
}
