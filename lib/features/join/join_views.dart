import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/api.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/api_error.dart';
import '../../core/utils/app_log.dart';
import '../../core/utils/dob.dart';
import '../../core/widgets/ui.dart';
import '../../data/local/hive_service.dart';
import '../../data/models/booth.dart';
import '../../data/remote/api_client.dart';
import '../session/profile_photo_sheet.dart';
import '../session/session_controller.dart';
import 'contribute_dialog.dart';
import 'invite_field.dart';
import 'join_chrome.dart';
import '../../core/widgets/flash.dart';

String _draftText(HiveService hive, String key) {
  if (!hive.joinDraftMatchesUser) return '';
  final value = (hive.draft.get(key) as String?)?.trim() ?? '';
  if (value == 'Suresh Kumar Yadav' || value == '1988-03-14') return '';
  return value;
}

class PersonalView extends StatelessWidget {
  const PersonalView({super.key});

  @override
  Widget build(BuildContext context) => const AboutYouForm();
}

class AboutYouForm extends StatelessWidget {
  const AboutYouForm({super.key, this.embedded = false});
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final hive = Get.find<HiveService>();
    final session = Get.find<SessionController>();
    final name = TextEditingController(text: _draftText(hive, 'fullName'));
    final dob = TextEditingController(text: formatDobDisplay(_draftText(hive, 'dob')));
    final gender = (_draftText(hive, 'gender').isEmpty ? 'MALE' : _draftText(hive, 'gender')).obs;
    final photoPath = Rxn<String>(_draftText(hive, 'photoPath').isEmpty ? null : _draftText(hive, 'photoPath'));
    final photoUrl = Rxn<String>(_draftText(hive, 'photoUrl').isEmpty ? null : _draftText(hive, 'photoUrl'));

    void persist() {
      hive.draft.put('fullName', name.text.trim());
      hive.draft.put('dob', dobToIso(dob.text));
      hive.draft.put('gender', gender.value);
      if (photoPath.value != null) hive.draft.put('photoPath', photoPath.value);
    }

    void openPhotoSheet() {
      showProfilePhotoSheet(
        onUploaded: (path, url) {
          photoPath.value = path;
          photoUrl.value = url;
          hive.draft.put('photoPath', path);
        },
      );
    }

    void openPhotoViewer(ImageProvider provider) {
      Get.dialog(
        Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image(image: provider, fit: BoxFit.contain),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  onPressed: Get.back,
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    void continueNext() {
      persist();
      if (name.text.trim().length < 2) {
        flash('Error', 'enter_name'.tr);
        return;
      }
      if (!isValidDob(dob.text)) {
        flash('Error', 'dob_invalid'.tr);
        return;
      }
      hive.draft.put('step1Done', true);
      Get.toNamed(Routes.boothSelect);
    }

    void saveAndExit() {
      persist();
      session.saveAndExitJoin();
    }

    ImageProvider? photoProvider() {
      final path = photoPath.value;
      if (path != null && File(path).existsSync()) return FileImage(File(path));
      final url = photoUrl.value;
      if (url != null && url.isNotEmpty) return NetworkImage(ApiConfig.adjustForPlatform(url));
      return null;
    }

    return VerifyPage(
      step: 1,
      total: 3,
      eyebrow: 'about_you'.tr,
      title: 'about_you_title'.trFallback("Let's start with the basics"),
      lede: 'about_you_sub'.tr,
      onSaveExit: saveAndExit,
      children: [
        Center(
          child: Obx(() {
            final provider = photoProvider();
            return GestureDetector(
              onTap: provider == null ? openPhotoSheet : () => openPhotoViewer(provider),
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: VerifyColors.pale,
                    backgroundImage: provider,
                    child: provider == null ? const Icon(Icons.person_outline_rounded, size: 44, color: VerifyColors.purple) : null,
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: GestureDetector(
                      onTap: openPhotoSheet,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: VerifyColors.orange,
                          shape: BoxShape.circle,
                          border: Border.all(color: VerifyColors.cream, width: 3),
                        ),
                        child: const Icon(Icons.photo_camera_outlined, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Obx(
          () => Text(
            photoProvider() == null ? 'photo_help'.tr : 'photo_view'.trFallback('Tap photo to view'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: VerifyColors.gray, fontSize: 10.5),
          ),
        ),
        const SizedBox(height: 20),
        AppField(
          label: 'full_name'.tr,
          controller: name,
          hint: 'enter_name'.tr,
          icon: Icons.person_outline_rounded,
          verifyStyle: true,
          onChanged: (_) => persist(),
        ),
        AppField(
          label: '${'dob'.tr} *',
          controller: dob,
          hint: 'dob_hint'.tr,
          icon: Icons.calendar_today_outlined,
          readOnly: true,
          verifyStyle: true,
          suffix: const Icon(Icons.calendar_month_outlined, size: 18, color: VerifyColors.purple),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: dobInitialDate(dob.text),
              firstDate: dobFirstSelectableDate(),
              lastDate: dobLastSelectableDate(),
              initialEntryMode: DatePickerEntryMode.calendarOnly,
              helpText: 'dob'.tr,
            );
            if (picked == null) return;
            dob.text = dateToDisplay(picked);
            persist();
          },
        ),
        Obx(
          () => AppSelect<String>(
            label: 'gender'.tr,
            icon: Icons.groups_outlined,
            value: gender.value,
            verifyStyle: true,
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
        const InviteCodeField(),
        VerifyButton('continue'.tr, onTap: continueNext),
      ],
    );
  }
}

class _GeoOption {
  const _GeoOption({required this.id, required this.name});
  final String id;
  final String name;
}

class JoinDetailsController extends GetxController {
  final api = Get.find<ApiClient>();
  final hive = Get.find<HiveService>();

  late final TextEditingController address;
  late final TextEditingController pincode;

  final states = <_GeoOption>[].obs;
  final districts = <_GeoOption>[].obs;
  final assemblies = <_GeoOption>[].obs;
  final stateId = RxnString();
  final districtId = RxnString();
  final assemblyId = RxnString();
  final boothId = RxnString();
  final pledgeUpdates = false.obs;
  final loadingStates = false.obs;
  final loadingDistricts = false.obs;
  final loadingAssemblies = false.obs;

  @override
  void onInit() {
    super.onInit();
    address = TextEditingController(text: _draftText(hive, 'address'));
    pincode = TextEditingController(text: _draftText(hive, 'pincode'));
    final savedState = _draftText(hive, 'stateId');
    final savedDistrict = _draftText(hive, 'districtId');
    final savedAssembly = _draftText(hive, 'assemblyId');
    final savedBooth = _draftText(hive, 'boothId');
    stateId.value = savedState.isEmpty ? null : savedState;
    districtId.value = savedDistrict.isEmpty ? null : savedDistrict;
    assemblyId.value = savedAssembly.isEmpty ? null : savedAssembly;
    boothId.value = savedBooth.isEmpty ? null : savedBooth;
    pledgeUpdates.value = hive.draft.get('pledgeUpdates') != false;
    persist();
    loadStates();
  }

  @override
  void onClose() {
    address.dispose();
    pincode.dispose();
    super.onClose();
  }

  void persist() {
    hive.draft.put('address', address.text.trim());
    hive.draft.put('pincode', pincode.text.trim());
    hive.draft.put('pledgeUpdates', pledgeUpdates.value);
    hive.draft.put('stateName', states.where((s) => s.id == stateId.value).firstOrNull?.name);
    hive.draft.put('districtName', districts.where((d) => d.id == districtId.value).firstOrNull?.name);
    hive.draft.put('assemblyName', assemblies.where((a) => a.id == assemblyId.value).firstOrNull?.name);
    if (stateId.value != null) {
      hive.draft.put('stateId', stateId.value);
    } else {
      hive.draft.delete('stateId');
    }
    if (districtId.value != null) {
      hive.draft.put('districtId', districtId.value);
    } else {
      hive.draft.delete('districtId');
    }
    if (assemblyId.value != null) {
      hive.draft.put('assemblyId', assemblyId.value);
    } else {
      hive.draft.delete('assemblyId');
    }
    if (boothId.value != null) {
      hive.draft.put('boothId', boothId.value);
    } else {
      hive.draft.delete('boothId');
    }
  }

  List<_GeoOption> _options(Map<String, dynamic> res, String key) {
    final data = res['data'] is Map ? Map<String, dynamic>.from(res['data'] as Map) : res;
    return ((data[key] as List?) ?? [])
        .whereType<Map>()
        .map((e) => _GeoOption(id: '${e['id']}', name: '${e['name'] ?? ''}'))
        .where((e) => e.id.isNotEmpty && e.name.isNotEmpty)
        .toList();
  }

  Future<void> loadStates() async {
    loadingStates.value = true;
    try {
      final res = await api.get('/geo/states');
      states.assignAll(_options(res, 'states'));
      if (stateId.value != null && !states.any((s) => s.id == stateId.value)) {
        stateId.value = null;
      }
      if (stateId.value != null) await loadDistricts();
    } catch (e, stack) {
      AppLog.error('loadStates failed', error: e, stack: stack, tag: 'JOIN');
    } finally {
      loadingStates.value = false;
    }
  }

  Future<void> loadDistricts() async {
    final id = stateId.value;
    if (id == null) {
      districts.clear();
      return;
    }
    loadingDistricts.value = true;
    try {
      final res = await api.get('/geo/districts', query: {'stateId': id});
      districts.assignAll(_options(res, 'districts'));
      if (districtId.value != null && !districts.any((d) => d.id == districtId.value)) {
        districtId.value = null;
        assemblies.clear();
      }
      if (districtId.value != null) await loadAssemblies();
    } catch (e, stack) {
      AppLog.error('loadDistricts failed', error: e, stack: stack, tag: 'JOIN');
    } finally {
      loadingDistricts.value = false;
    }
  }

  Future<void> loadAssemblies() async {
    final id = districtId.value;
    if (id == null) {
      assemblies.clear();
      return;
    }
    loadingAssemblies.value = true;
    try {
      final res = await api.get('/geo/assemblies', query: {'districtId': id});
      assemblies.assignAll(_options(res, 'assemblies'));
      if (assemblyId.value != null && !assemblies.any((a) => a.id == assemblyId.value)) {
        assemblyId.value = null;
        boothId.value = null;
      }
      if (assemblyId.value != null) await _assignBoothForAssembly();
    } catch (e, stack) {
      AppLog.error('loadAssemblies failed', error: e, stack: stack, tag: 'JOIN');
    } finally {
      loadingAssemblies.value = false;
    }
  }

  Future<void> _assignBoothForAssembly() async {
    final id = assemblyId.value;
    if (id == null) return;
    try {
      final res = await api.get('/booths', query: {'assemblyId': id});
      final data = res['data'] is Map ? Map<String, dynamic>.from(res['data'] as Map) : res;
      final list = ((data['booths'] as List?) ?? [])
          .whereType<Map>()
          .map((e) => Booth.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      if (list.isNotEmpty) {
        boothId.value = list.first.id;
        hive.draft.put('booth', list.first.toJson());
      }
    } catch (e, stack) {
      AppLog.error('assignBooth failed', error: e, stack: stack, tag: 'JOIN');
    }
  }

  Future<void> onStateChanged(String? id) async {
    stateId.value = id;
    districtId.value = null;
    assemblyId.value = null;
    boothId.value = null;
    districts.clear();
    assemblies.clear();
    hive.draft.delete('booth');
    persist();
    if (id != null) await loadDistricts();
  }

  Future<void> onDistrictChanged(String? id) async {
    districtId.value = id;
    assemblyId.value = null;
    boothId.value = null;
    assemblies.clear();
    hive.draft.delete('booth');
    persist();
    if (id != null) await loadAssemblies();
  }

  Future<void> onAssemblyChanged(String? id) async {
    assemblyId.value = id;
    boothId.value = null;
    hive.draft.delete('booth');
    persist();
    if (id != null) await _assignBoothForAssembly();
    persist();
  }

  Future<void> applyBooth(Booth booth) async {
    if (booth.stateId != null) {
      stateId.value = booth.stateId;
      await loadDistricts();
    }
    if (booth.districtId != null) {
      districtId.value = booth.districtId;
      await loadAssemblies();
    }
    boothId.value = booth.id;
    hive.draft.put('booth', booth.toJson());
    persist();
  }

  void continueNext() {
    persist();
    final session = Get.find<SessionController>();
    final draftName = (hive.draft.get('fullName') as String?)?.trim() ?? '';
    final memberName = '${session.member?['fullName'] ?? ''}'.trim();
    if (draftName.length < 2 && memberName.length < 2) {
      flash('Error', 'enter_name'.tr);
      return;
    }
    final dob = (hive.draft.get('dob') as String?)?.trim() ?? '';
    if (!isValidDob(dob)) {
      flash('Error', 'dob_invalid'.tr);
      return;
    }
    final pin = pincode.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
      flash('Error', 'pincode_invalid'.tr);
      return;
    }
    if (stateId.value == null || districtId.value == null || assemblyId.value == null) {
      flash('Error', 'complete_steps'.tr);
      return;
    }
    Get.toNamed(Routes.consent);
  }
}

class BoothSelectView extends StatefulWidget {
  const BoothSelectView({super.key});

  @override
  State<BoothSelectView> createState() => _BoothSelectViewState();
}

class _BoothSelectViewState extends State<BoothSelectView> {
  late final JoinDetailsController c;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<JoinDetailsController>()) {
      Get.delete<JoinDetailsController>(force: true);
    }
    c = Get.put(JoinDetailsController());
  }

  @override
  Widget build(BuildContext context) {
    return VerifyPage(
      step: 2,
      total: 3,
      eyebrow: 'join_details'.tr,
      title: 'join_details_title'.trFallback('Where should we reach you'),
      lede: 'join_details_sub'.tr,
      onBack: () {
        c.persist();
        Get.offNamed(Routes.personal);
      },
      onSaveExit: () {
        c.persist();
        Get.find<SessionController>().saveAndExitJoin();
      },
      children: [
        Obx(
          () => AppSearchSelect(
            label: '${'state'.tr} *',
            hint: 'select_state'.tr,
            searchHint: 'search_state'.tr,
            emptyHint: 'no_matches'.tr,
            icon: Icons.map_outlined,
            verifyStyle: true,
            value: c.states.any((s) => s.id == c.stateId.value) ? c.stateId.value : null,
            options: c.states.map((s) => SearchOption(id: s.id, name: s.name)).toList(),
            loading: c.loadingStates.value,
            onChanged: c.onStateChanged,
          ),
        ),
        Obx(
          () => AppSearchSelect(
            label: '${'district'.tr} *',
            hint: 'select_district'.tr,
            searchHint: 'search_district'.tr,
            emptyHint: 'no_matches'.tr,
            icon: Icons.location_city_outlined,
            verifyStyle: true,
            value: c.districts.any((d) => d.id == c.districtId.value) ? c.districtId.value : null,
            options: c.districts.map((d) => SearchOption(id: d.id, name: d.name)).toList(),
            enabled: c.stateId.value != null,
            loading: c.loadingDistricts.value,
            onChanged: c.onDistrictChanged,
          ),
        ),
        Obx(
          () => AppSearchSelect(
            label: '${'assembly'.tr} *',
            hint: 'select_assembly'.tr,
            searchHint: 'search_assembly'.tr,
            emptyHint: 'no_matches'.tr,
            icon: Icons.account_balance_outlined,
            verifyStyle: true,
            value: c.assemblies.any((a) => a.id == c.assemblyId.value) ? c.assemblyId.value : null,
            options: c.assemblies.map((a) => SearchOption(id: a.id, name: a.name)).toList(),
            enabled: c.districtId.value != null,
            loading: c.loadingAssemblies.value,
            onChanged: c.onAssemblyChanged,
          ),
        ),
        AppField(
          label: '${'pincode'.tr} *',
          controller: c.pincode,
          hint: 'pincode_hint'.tr,
          icon: Icons.credit_card_outlined,
          keyboard: TextInputType.number,
          digitsOnly: true,
          maxLength: 6,
          verifyStyle: true,
          onChanged: (_) => c.persist(),
        ),
        AppField(
          label: 'address'.tr,
          controller: c.address,
          hint: 'address_hint'.tr,
          icon: Icons.home_outlined,
          verifyStyle: true,
          onChanged: (_) => c.persist(),
        ),
        Obx(
          () => VerifyCheckCard(
            label: 'pledge_updates'.tr,
            checked: c.pledgeUpdates.value,
            onTap: () {
              c.pledgeUpdates.toggle();
              c.persist();
            },
          ),
        ),
        VerifyButton('continue'.tr, onTap: c.continueNext),
      ],
    );
  }
}

class ConsentView extends StatelessWidget {
  const ConsentView({super.key});

  @override
  Widget build(BuildContext context) {
    final requiredOk = false.obs;
    final wa = (Get.find<HiveService>().draft.get('pledgeUpdates') == true).obs;
    final hive = Get.find<HiveService>();
    return VerifyPage(
      step: 3,
      total: 3,
      eyebrow: 'your_consent'.tr,
      title: 'consent_title'.trFallback('Read this before you agree'),
      lede: 'consent_sub'.tr,
      onBack: () {
        if (Navigator.of(context).canPop()) {
          Get.back();
        } else {
          Get.offNamed(Routes.boothSelect);
        }
      },
      children: [
        VerifyInfoBox(
          title: 'consent_collect_title'.trFallback('What we collect, and why'),
          paragraphs: [
            'consent_collect_p1'.trFallback(
              'Your name, mobile number, date of birth, address and booth — so the party can maintain its membership register and assign you to a committee.',
            ),
            'consent_collect_p2'.trFallback('Your photograph, for your membership card.'),
            'consent_collect_p3'.trFallback('Activity you record in this app, with time and location.'),
            'consent_collect_p4'.trFallback(
              'We keep this while your membership is active, and for three years after. Grievance officer: privacy@party.in',
            ),
          ],
        ),
        Obx(
          () => VerifyCheckCard(
            label: 'i_agree'.tr,
            tag: 'required'.tr,
            checked: requiredOk.value,
            onTap: requiredOk.toggle,
          ),
        ),
        Obx(
          () => VerifyCheckCard(
            label: 'whatsapp_opt'.tr,
            tag: 'optional_later'.tr,
            checked: wa.value,
            onTap: wa.toggle,
          ),
        ),
        Obx(
          () => VerifyButton(
            'submit_app'.tr,
            enabled: requiredOk.value,
            orange: true,
            onTap: () async {
                try {
                  final fullName = (hive.draft.get('fullName') as String?)?.trim() ?? '';
                  final dob = (hive.draft.get('dob') as String?)?.trim() ?? '';
                  final boothId = hive.draft.get('boothId') as String?;
                  final assemblyId = hive.draft.get('assemblyId') as String?;
                  final address = (hive.draft.get('address') as String?)?.trim() ?? '';
                  final pincode = (hive.draft.get('pincode') as String?)?.trim() ?? '';
                  if (fullName.length < 2 || !isValidDob(dob) || (boothId == null && assemblyId == null)) {
                    flash(
                      'Error',
                      !isValidDob(dob) ? 'dob_invalid'.tr : 'complete_steps'.tr,
                    );
                    return;
                  }
                  final session = Get.find<SessionController>();
                  await session.registerMember({
                    'fullName': fullName,
                    'dateOfBirth': dobToIso(dob),
                    'gender': hive.draft.get('gender') ?? 'MALE',
                    if (boothId != null) 'boothId': boothId,
                    if (assemblyId != null) 'assemblyId': assemblyId,
                    if (address.length >= 3) 'address': address,
                    if (RegExp(r'^\d{6}$').hasMatch(pincode)) 'pincode': pincode,
                    if (session.lat.value != null && session.lng.value != null) 'latitude': session.lat.value,
                    if (session.lat.value != null && session.lng.value != null) 'longitude': session.lng.value,
                    'locale': switch (hive.locale) {
                      'en' => 'EN',
                      'bho' => 'BHO',
                      _ => 'HI',
                    },
                    'requiredConsentVersion': '2026.08',
                    'whatsappOptIn': wa.value,
                    // Judged on the server: a recruiting code credits its
                    // owner, an invite code hands over the post it carries.
                    if (inviteCodeFromDraft(hive).isNotEmpty) 'inviteCode': inviteCodeFromDraft(hive),
                  }, openHome: false);
                  await showContributeDialog();
                  session.openPostAuth();
                } catch (e, stack) {
                  AppLog.error('Register member failed', error: e, stack: stack, tag: 'JOIN');
                  flash('Error', apiErrorMessage(e));
                }
              },
            ),
          ),
        Text(
          'submit_footnote'.trFallback('By submitting, you confirm the details above are accurate.'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10, color: VerifyColors.gray),
        ),
      ],
    );
  }
}
