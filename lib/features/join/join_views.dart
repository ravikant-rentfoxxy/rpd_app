import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/api_error.dart';
import '../../core/utils/app_log.dart';
import '../../core/utils/distance.dart';
import '../../core/widgets/ui.dart';
import '../../data/local/hive_service.dart';
import '../../data/models/booth.dart';
import '../session/session_controller.dart';

class PersonalView extends StatelessWidget {
  const PersonalView({super.key});

  @override
  Widget build(BuildContext context) {
    final hive = Get.find<HiveService>();
    final name = TextEditingController(text: hive.draft.get('fullName') as String? ?? 'Suresh Kumar Yadav');
    final dob = TextEditingController(text: hive.draft.get('dob') as String? ?? '1988-03-14');
    final father = TextEditingController(text: hive.draft.get('father') as String? ?? '');
    final gender = (hive.draft.get('gender') as String? ?? 'MALE').obs;

    void persist() {
      hive.draft.put('fullName', name.text);
      hive.draft.put('dob', dob.text);
      hive.draft.put('father', father.text);
      hive.draft.put('gender', gender.value);
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('join'.tr),
            Text('Step 3 of 6 · ${'saved'.tr}', style: const TextStyle(fontSize: 12, color: AppColors.ink3)),
          ],
        ),
        actions: [TextButton(onPressed: persist, child: Text('save_exit'.tr))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.screen),
        children: [
          const StepBar(total: 6, current: 3),
          DisplayText('about_you'.tr),
          const SizedBox(height: 6),
          Text('about_you_sub'.tr, style: const TextStyle(color: AppColors.ink3, fontSize: 13)),
          const SizedBox(height: 16),
          AppField(label: 'full_name'.tr, controller: name, onChanged: (_) => persist()),
          AppField(label: 'dob'.tr, controller: dob, onChanged: (_) => persist()),
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
                      persist();
                    },
                  ),
                ),
              ),
            ),
          ),
          AppField(label: 'father_name'.tr, controller: father, hint: 'enter_name'.tr, onChanged: (_) => persist()),
          PrimaryButton('continue'.tr, onTap: () {
            persist();
            Get.toNamed(Routes.boothSelect);
          }),
        ],
      ),
    );
  }
}

class BoothSelectView extends StatelessWidget {
  const BoothSelectView({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionController>();
    session.syncNearbyBooths();
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('join'.tr),
            Text('Step 4 of 6 · ${'saved'.tr}', style: const TextStyle(fontSize: 12, color: AppColors.ink3)),
          ],
        ),
      ),
      body: Obx(() {
        final booths = session.nearbyBooths;
        return ListView(
          padding: const EdgeInsets.all(AppSpace.screen),
          children: [
            const StepBar(total: 6, current: 4),
            DisplayText('which_booth'.tr),
            const SizedBox(height: 6),
            Text('which_booth_sub'.tr, style: const TextStyle(color: AppColors.ink3, fontSize: 13)),
            const SizedBox(height: 12),
            if (session.locationDenied.value)
              AppCard(
                tone: CardTone.warn,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CardTitle('location_off'.tr, sub: 'location_off_sub'.tr),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: PrimaryButton('turn_on_loc'.tr, onTap: session.syncNearbyBooths)),
                        const SizedBox(width: 8),
                        Expanded(child: PrimaryButton('choose_manual'.tr, ghost: true, onTap: () => Get.toNamed(Routes.boothSearch))),
                      ],
                    ),
                  ],
                ),
              )
            else
              AppCard(tone: CardTone.brand, child: CardTitle('nearest_now'.tr, sub: 'found_location'.tr)),
            ...booths.map((b) => _BoothTile(booth: b, first: booths.first.id == b.id)),
            PrimaryButton('search_booth'.tr, ghost: true, onTap: () => Get.toNamed(Routes.boothSearch)),
          ],
        );
      }),
    );
  }
}

class _BoothTile extends StatelessWidget {
  const _BoothTile({required this.booth, required this.first});
  final Booth booth;
  final bool first;
  @override
  Widget build(BuildContext context) {
    return AppCard(
      tone: first ? CardTone.ok : CardTone.plain,
      onTap: () {
        Get.find<HiveService>().draft.put('boothId', booth.id);
        Get.find<HiveService>().draft.put('booth', booth.toJson());
        Get.toNamed(Routes.consent);
      },
      child: CardTitle(
        'Booth ${booth.boothNumber} · ${booth.name}',
        sub: first
            ? 'Part ${booth.partNumber} · ${booth.assemblyName ?? ''} · ${booth.voterCount} ${'voters'.tr}'
            : 'Part ${booth.partNumber} · ${formatMetres(booth.distanceMetres)} ${'away'.tr} · ${booth.voterCount} ${'voters'.tr}',
      ),
    );
  }
}

class BoothSearchView extends StatelessWidget {
  const BoothSearchView({super.key});

  @override
  Widget build(BuildContext context) {
    final q = ''.obs;
    final hive = Get.find<HiveService>();
    return Scaffold(
      appBar: AppBar(title: Text('search_booth'.tr)),
      body: Padding(
        padding: const EdgeInsets.all(AppSpace.screen),
        child: Column(
          children: [
            TextField(
              onChanged: (v) => q.value = v,
              decoration: InputDecoration(
                hintText: 'search_booth'.tr,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Obx(() {
                final list = q.value.isEmpty ? hive.allBooths() : hive.searchLocal(q.value);
                return ListView(
                  children: list
                      .map(
                        (b) => AppCard(
                          onTap: () {
                            hive.draft.put('boothId', b.id);
                            hive.draft.put('booth', b.toJson());
                            Get.toNamed(Routes.consent);
                          },
                          child: CardTitle('${b.code} · ${b.name}', sub: '${b.village} · Part ${b.partNumber}'),
                        ),
                      )
                      .toList(),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class ConsentView extends StatelessWidget {
  const ConsentView({super.key});

  @override
  Widget build(BuildContext context) {
    final requiredOk = false.obs;
    final wa = false.obs;
    final hive = Get.find<HiveService>();
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('join'.tr),
            const Text('Step 6 of 6', style: TextStyle(fontSize: 12, color: AppColors.ink3)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.screen),
        children: [
          const StepBar(total: 6, current: 6),
          DisplayText('your_consent'.tr),
          const SizedBox(height: 6),
          Text('consent_sub'.tr, style: const TextStyle(color: AppColors.ink3, fontSize: 13)),
          const SizedBox(height: 12),
          const AppCard(
            child: CardTitle(
              'What we collect and why',
              sub:
                  'Your name, mobile number, date of birth, address and booth, so the party can maintain its membership register and assign you to a committee.\n\nYour photograph, for your membership card.\n\nActivity you record in this app, with time and location.\n\nWe keep this while your membership is active and for three years after. Grievance officer: privacy@party.in',
            ),
          ),
          Obx(
            () => AppCard(
              onTap: () => requiredOk.toggle(),
              child: CardTitle('${requiredOk.value ? '☑' : '☐'} ${'i_agree'.tr}', sub: 'required'.tr),
            ),
          ),
          Obx(
            () => AppCard(
              onTap: () => wa.toggle(),
              child: CardTitle('${wa.value ? '☑' : '☐'} ${'whatsapp_opt'.tr}', sub: 'optional_later'.tr),
            ),
          ),
          Obx(
            () => PrimaryButton(
              'submit_app'.tr,
              enabled: requiredOk.value,
              onTap: () async {
                try {
                  final father = (hive.draft.get('father') as String?)?.trim();
                  await Get.find<SessionController>().registerMember({
                    'fullName': hive.draft.get('fullName') ?? 'Suresh Kumar Yadav',
                    if (father != null && father.length >= 2) 'fatherOrHusbandName': father,
                    'dateOfBirth': hive.draft.get('dob') ?? '1988-03-14',
                    'gender': hive.draft.get('gender') ?? 'MALE',
                    'boothId': hive.draft.get('boothId'),
                    'locale': switch (hive.locale) {
                      'en' => 'EN',
                      'bho' => 'BHO',
                      _ => 'HI',
                    },
                    'requiredConsentVersion': '2026.08',
                    'whatsappOptIn': wa.value,
                  });
                } catch (e, stack) {
                  AppLog.error('Register member failed', error: e, stack: stack, tag: 'JOIN');
                  Get.snackbar('Error', apiErrorMessage(e));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
