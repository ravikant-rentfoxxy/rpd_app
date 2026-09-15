import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/api_error.dart';
import '../../core/utils/app_log.dart';
import '../../core/utils/dob.dart';
import '../../core/utils/local_image.dart';
import '../../core/widgets/ui.dart';
import '../../data/models/booth.dart';
import '../../data/remote/api_client.dart';
import '../../data/remote/pincode_api.dart';
import '../join/join_chrome.dart';
import '../session/profile_photo_sheet.dart';
import '../card/membership_card_view.dart';
import '../session/session_controller.dart';
import '../../core/widgets/flash.dart';

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
      appBar: OrganicAppBar(
        title: 'edit_profile'.trFallback('Edit profile'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: showMembershipCardOverlay,
              child: Text(
                'card'.trFallback('Card'),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
        ],
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
                    if (!session.canUseMemberActions)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: HomeColors.muted2,
                            shape: BoxShape.circle,
                            border: Border.all(color: HomeColors.paper, width: 3),
                          ),
                          child: const Icon(Icons.priority_high_rounded, size: 14, color: Colors.white),
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
              label: 'voter_id'.trFallback('Voter ID card number'),
              controller: c.voterId,
              hint: 'voter_id_hint'.trFallback('As on voter ID, e.g. ABC1234567'),
              icon: Icons.badge_outlined,
              keyboard: TextInputType.visiblePassword,
              maxLength: 10,
              formatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                TextInputFormatter.withFunction((oldValue, newValue) {
                  return TextEditingValue(
                    text: newValue.text.toUpperCase(),
                    selection: newValue.selection,
                  );
                }),
              ],
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
              onChanged: c.onPincodeChanged,
            ),
            Obx(
              () => AppSelect<String>(
                label: '${'state'.tr} *',
                hint: 'select_state'.tr,
                icon: Icons.map_outlined,
                value: c.states.any((s) => s.id == c.stateId.value) ? c.stateId.value : null,
                items: c.states.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                loading: c.loadingStates.value || c.lookingUpPin.value,
                enabled: false,
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
          ],
        );
      }),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Obx(
          () => PrimaryButton(
            c.saving.value ? '…' : 'save_changes'.trFallback('Save changes'),
            enabled: !c.saving.value && !c.geoLoading,
            onTap: c.save,
          ),
        ),
      ),
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
  late final TextEditingController voterId;

  final gender = 'MALE'.obs;
  final states = <_GeoOption>[].obs;
  final districts = <_GeoOption>[].obs;
  final assemblies = <_GeoOption>[].obs;
  final stateId = RxnString();
  final districtId = RxnString();
  final assemblyId = RxnString();
  final boothId = RxnString();
  final loadingStates = false.obs;
  final lookingUpPin = false.obs;
  final loadingDistricts = false.obs;
  var _pinLookup = 0;
  final loadingAssemblies = false.obs;
  final saving = false.obs;

  /// Captured at open — Get.arguments can leak across navigations.
  late final bool openProfileAfterSave;

  bool get geoLoading =>
      loadingStates.value || lookingUpPin.value || loadingDistricts.value || loadingAssemblies.value;

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
    final args = Get.arguments;
    openProfileAfterSave = args is Map && args['openProfileAfterSave'] == true;
    name = TextEditingController(text: '${member['fullName'] ?? ''}');
    dob = TextEditingController(text: formatDobDisplay('${member['dateOfBirth'] ?? ''}'));
    address = TextEditingController(text: '${member['address'] ?? ''}');
    pincode = TextEditingController(text: '${member['pincode'] ?? ''}');
    memberId = TextEditingController(text: displayMemberId(member));
    mobile = TextEditingController(text: _mobileDigits('${member['mobile'] ?? ''}'));
    voterId = TextEditingController(text: '${member['voterId'] ?? ''}'.toUpperCase());
    final currentGender = '${member['gender'] ?? 'MALE'}';
    gender.value = {'MALE', 'FEMALE', 'OTHER'}.contains(currentGender) ? currentGender : 'MALE';
    stateId.value = _id(member['stateId']);
    districtId.value = _id(member['districtId']);
    assemblyId.value = _id(member['assemblyId']);
    boothId.value = _id(member['boothId']);
    _seedGeoFromMember();
    session.captureLocation();
    if (stateId.value != null) loadDistricts(silent: true);
  }

  void _seedGeoFromMember() {
    final sid = stateId.value;
    final sname = '${member['stateName'] ?? ''}'.trim();
    if (sid != null && sname.isNotEmpty) states.assignAll([_GeoOption(id: sid, name: sname)]);

    final did = districtId.value;
    final dname = '${member['districtName'] ?? ''}'.trim();
    if (did != null && dname.isNotEmpty) districts.assignAll([_GeoOption(id: did, name: dname)]);

    final aid = assemblyId.value;
    final aname = '${member['assemblyName'] ?? ''}'.trim();
    if (aid != null && aname.isNotEmpty) assemblies.assignAll([_GeoOption(id: aid, name: aname)]);
  }

  @override
  void onClose() {
    name.dispose();
    dob.dispose();
    address.dispose();
    pincode.dispose();
    memberId.dispose();
    mobile.dispose();
    voterId.dispose();
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

  Future<void> loadDistricts({bool silent = false}) async {
    final id = stateId.value;
    if (id == null) {
      districts.clear();
      return;
    }
    if (!silent) loadingDistricts.value = true;
    try {
      final res = await api.get('/geo/districts', query: {'stateId': id});
      districts.assignAll(_options(res, 'districts'));
      if (districtId.value != null && !districts.any((d) => d.id == districtId.value)) {
        districtId.value = null;
        assemblies.clear();
      }
      if (districtId.value != null) await loadAssemblies(silent: silent);
    } catch (e, stack) {
      AppLog.error('profile loadDistricts failed', error: e, stack: stack, tag: 'PROFILE');
    } finally {
      if (!silent) loadingDistricts.value = false;
    }
  }

  Future<void> loadAssemblies({bool silent = false}) async {
    final id = districtId.value;
    if (id == null) {
      assemblies.clear();
      return;
    }
    if (!silent) loadingAssemblies.value = true;
    try {
      final res = await api.get('/geo/assemblies', query: {'districtId': id});
      assemblies.assignAll(_options(res, 'assemblies'));
      if (assemblyId.value != null && !assemblies.any((a) => a.id == assemblyId.value)) {
        assemblyId.value = null;
        boothId.value = null;
      }
    } catch (e, stack) {
      AppLog.error('profile loadAssemblies failed', error: e, stack: stack, tag: 'PROFILE');
    } finally {
      if (!silent) loadingAssemblies.value = false;
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

  void onPincodeChanged(String value) {
    lookupStateFromPincode(value);
  }

  Future<void> lookupStateFromPincode(String value, {bool announce = true}) async {
    final pin = value.trim();
    final token = ++_pinLookup;
    if (pin.length != 6) return;
    lookingUpPin.value = true;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (token != _pinLookup) return;
      final hit = await lookupPincode(pin);
      if (token != _pinLookup) return;
      final id = pincodeStateId(hit);
      final name = pincodeStateName(hit);
      if (id == null) {
        if (announce) {
          flash('Error', name.isEmpty ? 'pincode_invalid'.tr : 'pincode_state_unknown'.trParams({'state': name}));
        }
        return;
      }
      if (!states.any((s) => s.id == id) && name.isNotEmpty) {
        states.add(_GeoOption(id: id, name: name));
      }
      if (states.any((s) => s.id == id) && stateId.value != id) {
        await onStateChanged(id);
      }
    } catch (e, stack) {
      if (token != _pinLookup) return;
      AppLog.error('profile pincode lookup failed', error: e, stack: stack, tag: 'PROFILE');
      if (announce) flash('Error', apiErrorMessage(e));
    } finally {
      if (token == _pinLookup) lookingUpPin.value = false;
    }
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
      flash('Error', 'enter_name'.tr);
      return;
    }
    final epic = voterId.text.trim().toUpperCase();
    if (epic.isNotEmpty && !RegExp(r'^[A-Z]{3}[0-9]{7}$').hasMatch(epic)) {
      flash('Error', 'voter_id_invalid'.trFallback('Enter a valid voter ID card number'));
      return;
    }
    if (!isValidDob(dob.text)) {
      flash('Error', 'dob_invalid'.tr);
      return;
    }
    final pin = pincode.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
      flash('Error', 'pincode_invalid'.tr);
      return;
    }
    if (stateId.value == null) {
      flash('Error', 'select_state'.tr);
      return;
    }
    if (assemblyId.value == null) {
      flash('Error', 'select_assembly'.tr);
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
        'voterId': epic,
        'stateId': stateId.value,
        if (assemblyId.value != null) 'assemblyId': assemblyId.value,
        if (boothId.value != null) 'boothId': boothId.value,
        if (session.lat.value != null && session.lng.value != null) 'latitude': session.lat.value,
        if (session.lat.value != null && session.lng.value != null) 'longitude': session.lng.value,
      });
      if (openProfileAfterSave) {
        // Incomplete-profile gate opened edit without overview underneath.
        Get.offNamed(Routes.profile);
      } else {
        // Came from overview (or elsewhere with a screen to return to).
        Get.back();
      }
      flash(
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
      flash('Error', apiErrorMessage(e));
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
