import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/api_error.dart';
import '../../core/utils/app_log.dart';
import '../../core/utils/dob.dart';
import '../../core/utils/local_image.dart';
import '../../core/widgets/ui.dart';
import '../../data/models/booth.dart';
import '../../data/remote/api_client.dart';
import '../join/join_chrome.dart';
import '../session/profile_photo_sheet.dart';
import '../card/membership_card_view.dart';
import '../session/session_controller.dart';

class _GeoOption {
  const _GeoOption({required this.id, required this.name});
  final String id;
  final String name;
}

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late final _ProfileController c;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<_ProfileController>()) {
      Get.delete<_ProfileController>(force: true);
    }
    c = Get.put(_ProfileController());
  }

  @override
  void dispose() {
    if (Get.isRegistered<_ProfileController>()) {
      Get.delete<_ProfileController>(force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionController>();
    return Scaffold(
      backgroundColor: HomeColors.paper,
      appBar: AppBar(
        backgroundColor: HomeColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('profile'.trFallback('Profile')),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: HomeColors.navy,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      body: Obx(() {
        session.profile.value;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            Center(
              child: GestureDetector(
                onTap: showProfilePhotoSheet,
                child: Stack(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [HomeColors.peach, Color(0xFFF0C48A)],
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: localOrNetworkPhoto(
                        raw: memberPhotoRef(session.member ?? {}),
                        fallback: Center(
                          child: Text(
                            c.initials,
                            style: const TextStyle(
                              color: HomeColors.navy,
                              fontWeight: FontWeight.w800,
                              fontSize: 28,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: HomeColors.orange,
                          shape: BoxShape.circle,
                          border: Border.all(color: HomeColors.paper, width: 3),
                        ),
                        child: const Icon(Icons.photo_camera_outlined, size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'change_photo'.trFallback('Tap to change photo'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: HomeColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 22),
            AppField(
              label: 'card_member_id'.trFallback('Member ID'),
              controller: c.memberId,
              icon: Icons.badge_outlined,
              readOnly: true,
            ),
            AppField(
              label: 'mobile_number'.tr,
              controller: c.mobile,
              icon: Icons.phone_outlined,
              readOnly: true,
            ),
            AppField(
              label: 'full_name'.tr,
              controller: c.name,
              hint: 'enter_name'.tr,
              icon: Icons.person_outline_rounded,
            ),
            AppField(
              label: '${'dob'.tr} *',
              controller: c.dob,
              hint: 'dob_hint'.tr,
              icon: Icons.calendar_today_outlined,
              readOnly: true,
              suffix: const Icon(Icons.calendar_month_outlined, size: 18, color: AppColors.ink3),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: dobInitialDate(c.dob.text),
                  firstDate: dobFirstSelectableDate(),
                  lastDate: dobLastSelectableDate(),
                  initialEntryMode: DatePickerEntryMode.calendarOnly,
                  helpText: 'dob'.tr,
                );
                if (picked == null) return;
                c.dob.text = dateToDisplay(picked);
              },
            ),
            Obx(
              () => AppSelect<String>(
                label: 'gender'.tr,
                icon: Icons.groups_outlined,
                value: c.gender.value,
                items: [
                  DropdownMenuItem(value: 'MALE', child: Text('male'.tr)),
                  DropdownMenuItem(value: 'FEMALE', child: Text('female'.tr)),
                  DropdownMenuItem(value: 'OTHER', child: Text('other'.tr)),
                ],
                onChanged: (value) => c.gender.value = value ?? 'MALE',
              ),
            ),
            AppField(
              label: 'address'.tr,
              controller: c.address,
              hint: 'address_hint'.tr,
              icon: Icons.home_outlined,
              maxLines: 2,
            ),
            AppField(
              label: 'pincode'.tr,
              controller: c.pincode,
              hint: 'pincode_hint'.tr,
              icon: Icons.credit_card_outlined,
              keyboard: TextInputType.number,
              digitsOnly: true,
              maxLength: 6,
            ),
            Obx(
              () => AppSelect<String>(
                label: '${'state'.tr} *',
                hint: 'select_state'.tr,
                icon: Icons.map_outlined,
                value: c.states.any((s) => s.id == c.stateId.value) ? c.stateId.value : null,
                items: c.states.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                loading: c.loadingStates.value,
                onChanged: c.onStateChanged,
              ),
            ),
            Obx(
              () => AppSelect<String>(
                label: '${'district'.tr} *',
                hint: 'select_district'.tr,
                icon: Icons.location_city_outlined,
                value: c.districts.any((d) => d.id == c.districtId.value) ? c.districtId.value : null,
                items: c.districts.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList(),
                enabled: c.stateId.value != null,
                loading: c.loadingDistricts.value,
                onChanged: c.onDistrictChanged,
              ),
            ),
            Obx(
              () => AppSelect<String>(
                label: '${'assembly'.tr} *',
                hint: 'select_assembly'.tr,
                icon: Icons.account_balance_outlined,
                value: c.assemblies.any((a) => a.id == c.assemblyId.value) ? c.assemblyId.value : null,
                items: c.assemblies.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
                enabled: c.districtId.value != null,
                loading: c.loadingAssemblies.value,
                onChanged: c.onAssemblyChanged,
              ),
            ),
            const SizedBox(height: 8),
            Obx(
              () => PrimaryButton(
                c.saving.value ? '…' : 'save_changes'.trFallback('Save changes'),
                enabled: !c.saving.value,
                onTap: c.save,
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _ProfileController extends GetxController {
  final api = Get.find<ApiClient>();
  final session = Get.find<SessionController>();

  late final TextEditingController name;
  late final TextEditingController dob;
  late final TextEditingController address;
  late final TextEditingController pincode;
  late final TextEditingController memberId;
  late final TextEditingController mobile;

  final gender = 'MALE'.obs;
  final states = <_GeoOption>[].obs;
  final districts = <_GeoOption>[].obs;
  final assemblies = <_GeoOption>[].obs;
  final stateId = RxnString();
  final districtId = RxnString();
  final assemblyId = RxnString();
  final boothId = RxnString();
  final loadingStates = false.obs;
  final loadingDistricts = false.obs;
  final loadingAssemblies = false.obs;
  final saving = false.obs;

  Map<String, dynamic> get member => session.member ?? {};

  String get initials {
    final source = '${member['fullName'] ?? ''}'.trim();
    if (source.isEmpty) return 'RP';
    final parts = source.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.length == 1) return parts.first.substring(0, parts.first.length.clamp(0, 2)).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  void onInit() {
    super.onInit();
    name = TextEditingController(text: '${member['fullName'] ?? ''}');
    dob = TextEditingController(text: formatDobDisplay('${member['dateOfBirth'] ?? ''}'));
    address = TextEditingController(text: '${member['address'] ?? ''}');
    pincode = TextEditingController(text: '${member['pincode'] ?? ''}');
    memberId = TextEditingController(text: displayMemberId(member));
    mobile = TextEditingController(text: _mobileDigits('${member['mobile'] ?? ''}'));
    final currentGender = '${member['gender'] ?? 'MALE'}';
    gender.value = {'MALE', 'FEMALE', 'OTHER'}.contains(currentGender) ? currentGender : 'MALE';
    stateId.value = _id(member['stateId']);
    districtId.value = _id(member['districtId']);
    assemblyId.value = _id(member['assemblyId']);
    boothId.value = _id(member['boothId']);
    session.refreshMe();
    loadStates();
  }

  @override
  void onClose() {
    name.dispose();
    dob.dispose();
    address.dispose();
    pincode.dispose();
    memberId.dispose();
    mobile.dispose();
    super.onClose();
  }

  String? _id(Object? raw) {
    final value = raw?.toString().trim() ?? '';
    return value.isEmpty ? null : value;
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
      AppLog.error('profile loadStates failed', error: e, stack: stack, tag: 'PROFILE');
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
      AppLog.error('profile loadDistricts failed', error: e, stack: stack, tag: 'PROFILE');
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
      AppLog.error('profile loadAssemblies failed', error: e, stack: stack, tag: 'PROFILE');
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
      if (list.isNotEmpty) boothId.value = list.first.id;
    } catch (e, stack) {
      AppLog.error('profile assignBooth failed', error: e, stack: stack, tag: 'PROFILE');
    }
  }

  Future<void> onStateChanged(String? id) async {
    stateId.value = id;
    districtId.value = null;
    assemblyId.value = null;
    boothId.value = null;
    districts.clear();
    assemblies.clear();
    if (id != null) await loadDistricts();
  }

  Future<void> onDistrictChanged(String? id) async {
    districtId.value = id;
    assemblyId.value = null;
    boothId.value = null;
    assemblies.clear();
    if (id != null) await loadAssemblies();
  }

  Future<void> onAssemblyChanged(String? id) async {
    assemblyId.value = id;
    boothId.value = null;
    if (id != null) await _assignBoothForAssembly();
  }

  Future<void> save() async {
    if (name.text.trim().length < 2) {
      Get.snackbar('Error', 'enter_name'.tr);
      return;
    }
    if (!isValidDob(dob.text)) {
      Get.snackbar('Error', 'dob_invalid'.tr);
      return;
    }
    final pin = pincode.text.trim();
    if (pin.isNotEmpty && !RegExp(r'^\d{6}$').hasMatch(pin)) {
      Get.snackbar('Error', 'pincode_invalid'.tr);
      return;
    }
    if (stateId.value == null || districtId.value == null || assemblyId.value == null) {
      Get.snackbar('Error', 'complete_steps'.tr);
      return;
    }
    saving.value = true;
    try {
      await session.updateProfile({
        'fullName': name.text.trim(),
        'dateOfBirth': dobToIso(dob.text),
        'gender': gender.value,
        'address': address.text.trim(),
        'pincode': pin,
        'assemblyId': assemblyId.value,
        if (boothId.value != null) 'boothId': boothId.value,
      });
      Get.snackbar(
        'saved'.tr,
        'profile_saved'.trFallback('Your details were saved.'),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.ok,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 10,
      );
    } catch (e, stack) {
      AppLog.error('update profile failed', error: e, stack: stack, tag: 'PROFILE');
      Get.snackbar('Error', apiErrorMessage(e));
    } finally {
      saving.value = false;
    }
  }
}

String _mobileDigits(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return '';
  return digits.length > 10 ? digits.substring(digits.length - 10) : digits;
}
