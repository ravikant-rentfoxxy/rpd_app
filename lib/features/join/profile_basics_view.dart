import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/api.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/api_error.dart';
import '../../core/utils/app_log.dart';
import '../../core/widgets/flash.dart';
import '../../core/widgets/ui.dart';
import '../../data/local/hive_service.dart';
import '../../data/remote/api_client.dart';
import '../../data/remote/pincode_api.dart';
import '../session/profile_photo_sheet.dart';
import '../session/session_controller.dart';
import 'join_chrome.dart';

class _GeoOption {
  const _GeoOption({required this.id, required this.name});
  final String id;
  final String name;
}

class ProfileBasicsView extends StatefulWidget {
  const ProfileBasicsView({super.key});

  @override
  State<ProfileBasicsView> createState() => _ProfileBasicsViewState();
}

class _ProfileBasicsViewState extends State<ProfileBasicsView> {
  late final _ProfileBasicsController c;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<_ProfileBasicsController>()) {
      Get.delete<_ProfileBasicsController>(force: true);
    }
    c = Get.put(_ProfileBasicsController());
  }

  @override
  void dispose() {
    if (Get.isRegistered<_ProfileBasicsController>()) {
      Get.delete<_ProfileBasicsController>(force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => PopScope(
        canPop: !c.saving.value,
        child: Scaffold(
          backgroundColor: HomeColors.paper,
          appBar: OrganicAppBar(title: 'verification_title'.trFallback('Verification')),
          body: Stack(
            children: [
              ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          Center(
            child: Obx(() {
              final provider = c.photoProvider();
              return GestureDetector(
                onTap: provider == null ? c.openPhotoSheet : () => c.openPhotoViewer(provider),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 38,
                      backgroundColor: VerifyColors.pale,
                      backgroundImage: provider,
                      child: provider == null
                          ? const Icon(Icons.person_outline_rounded, size: 34, color: VerifyColors.purple)
                          : null,
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: GestureDetector(
                        onTap: c.openPhotoSheet,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: VerifyColors.orange,
                            shape: BoxShape.circle,
                            border: Border.all(color: HomeColors.paper, width: 2.5),
                          ),
                          child: const Icon(Icons.photo_camera_outlined, size: 13, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Obx(
            () => Text(
              c.photoProvider() == null ? 'photo_help'.tr : 'photo_view'.trFallback('Tap photo to view'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: HomeColors.muted, fontSize: 11.5),
            ),
          ),
          const SizedBox(height: 14),
          AppField(
            label: '${'full_name'.tr} *',
            controller: c.name,
            hint: 'enter_name'.tr,
            icon: Icons.person_outline_rounded,
            verifyStyle: true,
          ),
          // The number they just signed in with; it identifies them, so it is
          // shown for confirmation but cannot be edited here.
          AppField(
            label: 'mobile_number'.tr,
            controller: c.mobile,
            icon: Icons.phone_outlined,
            readOnly: true,
            verifyStyle: true,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: AppField(
                  label: 'pincode'.tr,
                  controller: c.pincode,
                  hint: 'pincode_hint'.tr,
                  icon: Icons.credit_card_outlined,
                  keyboard: TextInputType.number,
                  digitsOnly: true,
                  maxLength: 6,
                  onChanged: c.onPincodeChanged,
                  verifyStyle: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 6,
                child: Obx(
                  () => AppSearchSelect(
                    label: '${'state'.tr} *',
                    hint: 'select_state'.tr,
                    searchHint: 'search_state'.tr,
                    emptyHint: 'no_matches'.tr,
                    icon: Icons.map_outlined,
                    value: c.states.any((s) => s.id == c.stateId.value) ? c.stateId.value : null,
                    options: c.states.map((s) => SearchOption(id: s.id, name: s.name)).toList(),
                    // Spins through the pincode lookup too, which is about to
                    // set this for them.
                    loading: c.loadingStates.value || c.lookingUpPin.value,
                    onChanged: (id) => c.onStateChanged(id),
                    verifyStyle: true,
                  ),
                ),
              ),
            ],
          ),
          Obx(
            () => AppSearchSelect(
              label: '${'district'.tr} *',
              hint: 'select_district'.tr,
              searchHint: 'search_district'.tr,
              emptyHint: 'no_matches'.tr,
              icon: Icons.location_city_outlined,
              value: c.districts.any((d) => d.id == c.districtId.value) ? c.districtId.value : null,
              options: c.districts.map((d) => SearchOption(id: d.id, name: d.name)).toList(),
              loading: c.loadingDistricts.value || c.lookingUpPin.value,
              // Districts belong to a state, so there is nothing to show until one is picked.
              enabled: c.stateId.value != null,
              onChanged: (id) => c.onDistrictChanged(id),
              verifyStyle: true,
            ),
          ),
          if (c.showReferral)
            AppField(
              label: 'card_referral'.tr,
              controller: c.referral,
              hint: 'referral_hint'.tr,
              icon: Icons.card_giftcard_outlined,
              maxLength: 32,
              verifyStyle: true,
            ),
          const SizedBox(height: 4),
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
              checked: c.acceptedConsent.value,
              onTap: c.acceptedConsent.toggle,
            ),
          ),
          Obx(
            () => VerifyCheckCard(
              label: 'pledge_updates'.tr,
              checked: c.pledgeUpdates.value,
              onTap: c.pledgeUpdates.toggle,
            ),
          ),
          Obx(
            () => PrimaryButton(
              c.saving.value ? '…' : 'continue'.tr,
              // A pincode lookup in flight is about to set state and district.
              enabled: !c.saving.value && !c.lookingUpPin.value && c.acceptedConsent.value,
              onTap: c.submit,
            ),
          ),
              Text(
                'submit_footnote'.trFallback('By submitting, you confirm the details above are accurate.'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, color: HomeColors.muted),
              ),
            ],
          ),
              if (c.saving.value)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Color(0xCCFCFAF6),
                    child: Center(
                      child: CircularProgressIndicator(color: HomeColors.orange),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String _displayMobile(Object? raw) {
  final digits = '${raw ?? ''}'.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return '';
  final last10 = digits.length > 10 ? digits.substring(digits.length - 10) : digits;
  if (last10.length != 10) return '+91 $last10';
  return '+91 ${last10.substring(0, 5)} ${last10.substring(5)}';
}

class _ProfileBasicsController extends GetxController {
  final api = Get.find<ApiClient>();
  final session = Get.find<SessionController>();
  final hive = Get.find<HiveService>();

  late final TextEditingController name;
  late final TextEditingController mobile;
  late final TextEditingController pincode;
  final referral = TextEditingController();
  final states = <_GeoOption>[].obs;
  final districts = <_GeoOption>[].obs;
  final stateId = RxnString();
  final districtId = RxnString();
  final photoPath = Rxn<String>();
  final photoUrl = Rxn<String>();
  final loadingStates = false.obs;
  final loadingDistricts = false.obs;
  final lookingUpPin = false.obs;

  /// Guards against an earlier lookup landing after a later one.
  int _pinLookup = 0;
  final saving = false.obs;
  final acceptedConsent = false.obs;
  final pledgeUpdates = false.obs;

  Map<String, dynamic> get member => session.member ?? {};

  /// Referral only counts once, before the member finishes joining.
  late final bool showReferral = '${member['referralCode'] ?? ''}'.trim().isEmpty;

  @override
  void onInit() {
    super.onInit();
    final draftName = (hive.draft.get('fullName') as String?)?.trim() ?? '';
    final memberName = '${member['fullName'] ?? ''}'.trim();
    name = TextEditingController(text: draftName.isNotEmpty ? draftName : memberName);
    mobile = TextEditingController(text: _displayMobile(member['mobile'] ?? hive.draft.get('mobile')));
    final draftPin = (hive.draft.get('pincode') as String?)?.trim() ?? '';
    final memberPin = '${member['pincode'] ?? ''}'.trim();
    pincode = TextEditingController(text: draftPin.isNotEmpty ? draftPin : memberPin);
    final draftState = (hive.draft.get('stateId') as String?)?.trim() ?? '';
    final memberState = '${member['stateId'] ?? ''}'.trim();
    stateId.value = draftState.isNotEmpty ? draftState : (memberState.isEmpty ? null : memberState);
    final draftDistrict = (hive.draft.get('districtId') as String?)?.trim() ?? '';
    final memberDistrict = '${member['districtId'] ?? ''}'.trim();
    districtId.value = draftDistrict.isNotEmpty ? draftDistrict : (memberDistrict.isEmpty ? null : memberDistrict);
    final draftPhoto = (hive.draft.get('photoPath') as String?)?.trim() ?? '';
    photoPath.value = draftPhoto.isEmpty ? null : draftPhoto;
    final url = '${member['photoUrl'] ?? hive.draft.get('photoUrl') ?? ''}'.trim();
    photoUrl.value = url.isEmpty ? null : url;
    acceptedConsent.value = hive.draft.get('acceptedConsent') == true;
    pledgeUpdates.value = hive.draft.get('pledgeUpdates') != false && member['whatsappOptIn'] != false;
    loadStates();
    session.captureLocation();
  }

  @override
  void onClose() {
    name.dispose();
    mobile.dispose();
    pincode.dispose();
    referral.dispose();
    super.onClose();
  }

  ImageProvider? photoProvider() {
    final path = photoPath.value;
    if (path != null && File(path).existsSync()) return FileImage(File(path));
    final url = photoUrl.value;
    if (url != null && url.isNotEmpty) return NetworkImage(ApiConfig.adjustForPlatform(url));
    return null;
  }

  void openPhotoSheet() {
    showProfilePhotoSheet(
      onUploaded: (path, url) {
        photoPath.value = path;
        photoUrl.value = url;
        hive.draft.put('photoPath', path);
        hive.draft.put('photoUrl', url);
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

  Future<void> loadStates() async {
    loadingStates.value = true;
    try {
      final res = await api.get('/geo/states');
      final data = res['data'] is Map ? Map<String, dynamic>.from(res['data'] as Map) : res;
      states.assignAll(
        ((data['states'] as List?) ?? [])
            .whereType<Map>()
            .map((e) => _GeoOption(id: '${e['id']}', name: '${e['name'] ?? ''}'))
            .where((e) => e.id.isNotEmpty && e.name.isNotEmpty)
            .toList(),
      );
      if (stateId.value != null && !states.any((s) => s.id == stateId.value)) {
        stateId.value = null;
        districtId.value = null;
      }
    } catch (e, stack) {
      AppLog.error('basics loadStates failed', error: e, stack: stack, tag: 'JOIN');
    } finally {
      loadingStates.value = false;
    }
    if (stateId.value != null) await loadDistricts();
  }

  Future<void> loadDistricts() async {
    final id = stateId.value;
    if (id == null || id.isEmpty) {
      districts.clear();
      return;
    }
    loadingDistricts.value = true;
    try {
      final res = await api.get('/geo/districts', query: {'stateId': id});
      final data = res['data'] is Map ? Map<String, dynamic>.from(res['data'] as Map) : res;
      districts.assignAll(
        ((data['districts'] as List?) ?? [])
            .whereType<Map>()
            .map((e) => _GeoOption(id: '${e['id']}', name: '${e['name'] ?? ''}'))
            .where((e) => e.id.isNotEmpty && e.name.isNotEmpty)
            .toList(),
      );
      if (districtId.value != null && !districts.any((d) => d.id == districtId.value)) {
        districtId.value = null;
      }
    } catch (e, stack) {
      AppLog.error('basics loadDistricts failed', error: e, stack: stack, tag: 'JOIN');
    } finally {
      loadingDistricts.value = false;
    }
  }

  /// [fromPincode] marks the lookup setting this itself; a hand-picked state
  /// means the pincode on screen no longer describes where they are, so it goes
  /// with the district rather than being submitted alongside a contradiction.
  Future<void> onStateChanged(String? id, {bool fromPincode = false}) async {
    if (stateId.value == id) return;
    stateId.value = id;
    if (!fromPincode && pincode.text.isNotEmpty) {
      pincode.clear();
      // Drop any lookup still in flight, or its reply would refill all three.
      _pinLookup++;
      lookingUpPin.value = false;
    }
    // The old district belongs to the old state.
    districtId.value = null;
    districts.clear();
    await loadDistricts();
  }

  /// Same reasoning as [onStateChanged]: a pincode names one district, so
  /// choosing a different one by hand leaves the pincode contradicting it.
  void onDistrictChanged(String? id, {bool fromPincode = false}) {
    if (districtId.value == id) return;
    districtId.value = id;
    if (!fromPincode && pincode.text.isNotEmpty) {
      pincode.clear();
      _pinLookup++;
      lookingUpPin.value = false;
    }
  }

  void onPincodeChanged(String value) {
    lookupStateFromPincode(value);
  }

  Future<void> lookupStateFromPincode(String value) async {
    final pin = value.trim();
    final token = ++_pinLookup;
    if (pin.length != 6) return;
    lookingUpPin.value = true;
    try {
      // Let them finish typing before asking the server.
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (token != _pinLookup) return;
      final hit = await lookupPincode(pin);
      if (token != _pinLookup) return;
      final id = pincodeStateId(hit);
      final name = pincodeStateName(hit);
      if (id == null) {
        flash(
          'Error',
          name.isEmpty ? 'pincode_invalid'.tr : 'pincode_state_unknown'.trParams({'state': name}),
        );
        return;
      }
      if (!states.any((s) => s.id == id) && name.isNotEmpty) {
        states.add(_GeoOption(id: id, name: name));
      }
      if (states.any((s) => s.id == id) && stateId.value != id) {
        await onStateChanged(id, fromPincode: true);
      }
      if (token != _pinLookup) return;
      final districtHit = pincodeDistrictId(hit);
      final districtName = pincodeDistrictName(hit);
      if (districtHit == null || !districts.any((d) => d.id == districtHit)) {
        if (districtName.isNotEmpty) {
          flash('Error', 'pincode_district_unknown'.trParams({'district': districtName}));
        }
        return;
      }
      onDistrictChanged(districtHit, fromPincode: true);
    } catch (e, stack) {
      if (token != _pinLookup) return;
      AppLog.error('basics pincode lookup failed', error: e, stack: stack, tag: 'JOIN');
      flash('Error', apiErrorMessage(e));
    } finally {
      if (token == _pinLookup) lookingUpPin.value = false;
    }
  }

  Future<void> submit() async {
    final fullName = name.text.trim();
    if (fullName.length < 2) {
      flash('Error', 'enter_name'.tr);
      return;
    }
    if (stateId.value == null) {
      flash('Error', 'select_state'.tr);
      return;
    }
    if (districtId.value == null) {
      flash('Error', 'select_district'.tr);
      return;
    }
    final pin = pincode.text.trim();
    if (pin.isNotEmpty && !RegExp(r'^\d{6}$').hasMatch(pin)) {
      flash('Error', 'pincode_invalid'.tr);
      return;
    }
    if (!acceptedConsent.value) {
      flash('Error', 'i_agree'.tr);
      return;
    }
    saving.value = true;
    try {
      await session.captureLocation();
      final selected = states.where((s) => s.id == stateId.value).firstOrNull;
      final selectedDistrict = districts.where((d) => d.id == districtId.value).firstOrNull;
      hive.draft.put('fullName', fullName);
      hive.draft.put('stateId', stateId.value);
      hive.draft.put('stateName', selected?.name);
      hive.draft.put('districtId', districtId.value);
      hive.draft.put('districtName', selectedDistrict?.name);
      hive.draft.put('pincode', pin);
      hive.draft.put('acceptedConsent', true);
      hive.draft.put('pledgeUpdates', pledgeUpdates.value);
      await session.updateProfile({
        'fullName': fullName,
        'stateId': stateId.value,
        'districtId': districtId.value,
        'pincode': pin,
        'acceptedRequiredConsent': true,
        'whatsappOptIn': pledgeUpdates.value,
        if (showReferral && referral.text.trim().isNotEmpty) 'referralCode': referral.text.trim(),
        if (session.lat.value != null && session.lng.value != null) 'latitude': session.lat.value,
        if (session.lat.value != null && session.lng.value != null) 'longitude': session.lng.value,
      });
      session.openHome();
    } catch (e, stack) {
      AppLog.error('save profile basics failed', error: e, stack: stack, tag: 'JOIN');
      flash('Error', apiErrorMessage(e));
    } finally {
      saving.value = false;
    }
  }
}
