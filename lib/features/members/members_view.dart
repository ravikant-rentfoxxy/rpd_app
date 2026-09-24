import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/language_dropdown.dart';
import '../../core/utils/api_error.dart';
import '../../core/utils/app_log.dart';
import '../../core/widgets/empty_card.dart';
import '../../core/widgets/iro_ui.dart';
import '../../core/widgets/ui.dart';
import '../../data/local/hive_service.dart';
import '../../data/remote/api_client.dart';
import '../../data/remote/pincode_api.dart';
import '../join/join_chrome.dart';
import '../session/session_controller.dart';
import '../../core/widgets/flash.dart';

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
      backgroundColor: Iro.mint,
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            Row(
              children: [
                _Count(
                  value: '${counts['verified'] ?? 0}',
                  label: 'verified'.tr,
                  tone: Iro.green,
                  icon: Icons.verified_rounded,
                ),
                const SizedBox(width: 10),
                _Count(
                  value: '${counts['pending'] ?? 0}',
                  label: 'pending'.tr,
                  tone: Iro.gold,
                  icon: Icons.hourglass_empty_rounded,
                ),
                const SizedBox(width: 10),
                _Count(
                  value: '${counts['rejected'] ?? 0}',
                  label: 'rejected'.tr,
                  tone: Iro.alert,
                  icon: Icons.block_rounded,
                ),
              ],
            ),
            const SizedBox(height: 14),
            // The one thing this screen exists to do.
            IroActionButton(
              label: 'add_member'.tr,
              icon: Icons.person_add_alt_1_rounded,
              onTap: () {
                if (!Get.find<SessionController>().guardMemberActions()) return;
                Get.toNamed(Routes.addMember);
              },
            ),
            const SizedBox(height: 18),
            if (list.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 12),
                child: AppEmptyCard(
                  icon: Icons.person_add_alt_1_outlined,
                  title: 'members'.tr,
                  sub: 'members_more_sub'.tr,
                ),
              )
            else ...[
              IroSectionHeading(
                'my_recruits'.tr,
                top: 0,
                trailing: 'recruits_count'.trParams({'n': '${list.length}'}),
              ),
              for (final e in list) RecruitCard(member: Map<String, dynamic>.from(e as Map)),
            ],
          ],
        );
      }),
    );
  }
}

/// One of the three figures across the top.
class _Count extends StatelessWidget {
  const _Count({required this.value, required this.label, required this.tone, required this.icon});
  final String value;
  final String label;
  final Color tone;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: IroCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: tone),
            const SizedBox(height: 7),
            Text(value, style: iroDisplay(size: 22, color: tone)),
            const SizedBox(height: 1),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: iroLabel(size: 11, color: Iro.muted, weight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

/// A member this recruiter signed up.
class RecruitCard extends StatelessWidget {
  const RecruitCard({super.key, required this.member});
  final Map<String, dynamic> member;

  @override
  Widget build(BuildContext context) {
    final name = '${member['fullName'] ?? ''}'.trim();
    final status = '${member['status'] ?? 'PENDING'}'.toUpperCase();
    final number = '${member['membershipNumber'] ?? ''}'.trim();
    final booth = '${(member['booth'] as Map?)?['name'] ?? ''}'.trim();
    final place = [
      if (booth.isNotEmpty) booth,
      '${member['districtName'] ?? (member['district'] as Map?)?['name'] ?? ''}'.trim(),
    ].where((e) => e.isNotEmpty).join(' · ');

    final (tone, wash, label) = switch (status) {
      'VERIFIED' => (Iro.green, Iro.wash, 'verified'.tr),
      'REJECTED' => (Iro.alert, Iro.alertWash, 'rejected'.tr),
      _ => (Iro.gold, Iro.goldWash, 'pending'.tr),
    };

    return IroCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      child: Row(
        children: [
          AvatarCircle(
            name.isEmpty ? '?' : name.split(RegExp(r'\s+')).take(2).map((p) => p[0]).join().toUpperCase(),
            imageUrl: member['photoUrl'] as String?,
            radius: 20,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name.isEmpty ? '—' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: iroDisplay(size: 14.5),
                ),
                // The membership number, or where they are — never the status,
                // which the pill beside it already says.
                if (number.isNotEmpty || place.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    number.isNotEmpty ? number : place,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: iroLabel(size: 11, color: Iro.muted, weight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          IroChip(label, dense: true, size: 9.5, dot: true, fg: tone, bg: wash),
        ],
      ),
    );
  }
}

class AddMemberView extends StatelessWidget {
  const AddMemberView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.find<SessionController>().guardMemberActions()) {
      return Scaffold(appBar: OrganicAppBar(title: 'add_member'.tr), body: const SizedBox.shrink());
    }
    final mobile = TextEditingController();
    final exists = Rxn<Map<String, dynamic>>();
    return Scaffold(
      appBar: OrganicAppBar(title: 'add_member'.tr),
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
            icon: Icons.smartphone_outlined,
            verifyStyle: true,
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
              flash('Error', err.toString());
            }
          }),
        ],
      ),
    );
  }
}

class RecruitConsentView extends StatefulWidget {
  const RecruitConsentView({super.key});

  @override
  State<RecruitConsentView> createState() => _RecruitConsentViewState();
}

class _RecruitConsentViewState extends State<RecruitConsentView> {
  final agreed = false.obs;
  final submitting = false.obs;
  final formTick = 0.obs;
  final states = <SearchOption>[].obs;
  final stateId = RxnString();
  final loadingStates = false.obs;
  /// Where the recruit lives. Filled in from the pincode, and changeable —
  /// the postal district does not always match one the party has on file.
  final districts = <SearchOption>[].obs;
  final districtId = RxnString();
  final loadingDistricts = false.obs;
  final lookingUpPin = false.obs;
  var _pinLookup = 0;
  final name = TextEditingController();
  final pincode = TextEditingController();
  final otp = TextEditingController();

  late final String mobile;
  late final SessionController session;
  late final HiveService hive;

  @override
  void initState() {
    super.initState();
    session = Get.find<SessionController>();
    hive = Get.find<HiveService>();
    final args = Get.arguments;
    final rawMobile = args is Map ? args['mobile'] : args;
    mobile = (rawMobile as String? ?? '').replaceAll(RegExp(r'\D'), '');
    _loadStates();
  }

  @override
  void dispose() {
    name.dispose();
    pincode.dispose();
    otp.dispose();
    super.dispose();
  }

  void tick() => formTick.value++;

  Future<void> _loadStates() async {
    loadingStates.value = true;
    try {
      final res = await Get.find<ApiClient>().get('/geo/states');
      final data = res['data'] is Map ? Map<String, dynamic>.from(res['data'] as Map) : res;
      states.assignAll(
        ((data['states'] as List?) ?? [])
            .whereType<Map>()
            .map((e) => SearchOption(id: '${e['id']}', name: '${e['name'] ?? ''}'))
            .where((e) => e.id.isNotEmpty && e.name.isNotEmpty)
            .toList(),
      );
      if (stateId.value != null && !states.any((s) => s.id == stateId.value)) {
        stateId.value = null;
      }
    } catch (e, stack) {
      AppLog.error('Recruit loadStates failed', error: e, stack: stack, tag: 'MEMBERS');
    } finally {
      loadingStates.value = false;
    }
  }

  Future<void> _loadDistricts(String? forStateId) async {
    districts.clear();
    districtId.value = null;
    if (forStateId == null || forStateId.isEmpty) return;
    loadingDistricts.value = true;
    try {
      final res = await Get.find<ApiClient>().get('/geo/districts', query: {'stateId': forStateId});
      final data = res['data'] is Map ? Map<String, dynamic>.from(res['data'] as Map) : res;
      districts.assignAll(
        ((data['districts'] as List?) ?? [])
            .whereType<Map>()
            .map((e) => SearchOption(id: '${e['id']}', name: '${e['name'] ?? ''}'))
            .where((e) => e.id.isNotEmpty && e.name.isNotEmpty)
            .toList(),
      );
    } catch (e, stack) {
      AppLog.error('Recruit loadDistricts failed', error: e, stack: stack, tag: 'MEMBERS');
    } finally {
      loadingDistricts.value = false;
    }
  }

  /// Picking a state clears whatever district was under the old one.
  Future<void> onStateChanged(String? id) async {
    stateId.value = id;
    tick();
    await _loadDistricts(id);
  }

  Future<void> _lookupStateFromPincode(String value) async {
    final pin = value.trim();
    final token = ++_pinLookup;
    if (pin.length != 6) return;
    lookingUpPin.value = true;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (token != _pinLookup || !mounted) return;
      final hit = await lookupPincode(pin);
      if (token != _pinLookup || !mounted) return;
      final id = pincodeStateId(hit);
      final name = pincodeStateName(hit);
      // A pincode the postal service does not recognise is no longer an error:
      // it is optional, and the recruiter has already named the area by hand.
      if (id == null) {
        AppLog.info('pincode $pin resolved no state${name.isEmpty ? '' : ' ($name)'}', tag: 'MEMBERS');
        return;
      }
      if (!states.any((s) => s.id == id) && name.isNotEmpty) {
        states.add(SearchOption(id: id, name: name));
      }
      // Only ever a suggestion: a recruiter who has already chosen keeps it.
      if (states.any((s) => s.id == id) && stateId.value == null) {
        stateId.value = id;
        tick();
        await _loadDistricts(id);
        if (token != _pinLookup || !mounted) return;
        // The postal lookup names a district too. Pick it when the party has
        // that district on file; otherwise leave the field for them to set.
        final district = pincodeDistrictId(hit);
        if (district != null && districtId.value == null && districts.any((d) => d.id == district)) {
          districtId.value = district;
          tick();
        }
      }
    } catch (e, stack) {
      if (token != _pinLookup) return;
      AppLog.error('Recruit pincode lookup failed', error: e, stack: stack, tag: 'MEMBERS');
      flash('Error', apiErrorMessage(e));
    } finally {
      if (token == _pinLookup) lookingUpPin.value = false;
    }
  }

  String? recruiterBoothId() {
    final direct = session.member?['boothId'];
    if (direct is String && direct.isNotEmpty) return direct;
    final nested = (session.member?['booth'] as Map?)?['id'];
    if (nested is String && nested.isNotEmpty) return nested;
    return null;
  }

  Future<void> submit() async {
    if (mobile.length != 10) {
      flash('Error', 'mobile_number'.tr);
      return;
    }
    final fullName = name.text.trim();
    final pin = pincode.text.trim();
    if (fullName.length < 2) {
      flash('Error', 'complete_steps'.tr);
      return;
    }
    // Optional, but a typo in one is still worth catching.
    if (pin.isNotEmpty && !RegExp(r'^\d{6}$').hasMatch(pin)) {
      flash('Error', 'pincode_invalid'.tr);
      return;
    }
    if (stateId.value == null) {
      flash('Error', 'select_state'.tr);
      return;
    }
    if (districtId.value == null) {
      flash('Error', 'select_district'.trFallback('Select district'));
      return;
    }
    submitting.value = true;
    try {
      final boothId = recruiterBoothId();
      final payload = await session.recruitMember({
        'mobile': mobile,
        'fullName': fullName,
        if (pin.isNotEmpty) 'pincode': pin,
        'stateId': stateId.value,
        if (districtId.value != null) 'districtId': districtId.value,
        if (boothId != null) 'boothId': boothId,
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
      Get.offNamedUntil(Routes.members, (route) => route.settings.name == Routes.shell);
      final points = payload['pointsAwarded'];
      flash(
        'member_added'.tr,
        points is num && points > 0 ? 'member_added_points'.tr : fullName,
      );
    } catch (err, stack) {
      AppLog.error('Recruit member failed', error: err, stack: stack, tag: 'MEMBERS');
      flash('Error', apiErrorMessage(err));
    } finally {
      submitting.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: OrganicAppBar(title: 'add_member'.tr),
      body: ListView(
        padding: const EdgeInsets.all(16),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          const StepBar(total: 2, current: 2),
          AppCard(tone: CardTone.brand, child: CardTitle('hand_phone'.tr, sub: 'must_agree'.tr)),
          AppField(
            label: '${'full_name'.tr} *',
            controller: name,
            hint: 'enter_name'.tr,
            icon: Icons.person_outline_rounded,
            verifyStyle: true,
            onChanged: (_) => tick(),
          ),
          Obx(
            () => AppSearchSelect(
              label: '${'state'.tr} *',
              hint: 'select_state'.tr,
              searchHint: 'search_state'.tr,
              emptyHint: 'no_matches'.tr,
              icon: Icons.map_outlined,
              value: states.any((s) => s.id == stateId.value) ? stateId.value : null,
              options: states.toList(),
              loading: loadingStates.value || lookingUpPin.value,
              verifyStyle: true,
              onChanged: onStateChanged,
            ),
          ),
          Obx(
            () => AppSearchSelect(
              label: '${'district'.tr} *',
              hint: 'select_district'.trFallback('Select district'),
              searchHint: 'search_district'.trFallback('Search district'),
              emptyHint: 'no_matches'.tr,
              icon: Icons.location_city_outlined,
              value: districts.any((d) => d.id == districtId.value) ? districtId.value : null,
              options: districts.toList(),
              loading: loadingDistricts.value || lookingUpPin.value,
              enabled: stateId.value != null,
              verifyStyle: true,
              onChanged: (id) {
                districtId.value = id;
                tick();
              },
            ),
          ),
          AppField(
            label: 'pincode'.tr,
            controller: pincode,
            hint: 'pincode_hint'.tr,
            icon: Icons.pin_outlined,
            keyboard: TextInputType.number,
            digitsOnly: true,
            maxLength: 6,
            verifyStyle: true,
            onChanged: (value) {
              tick();
              _lookupStateFromPincode(value);
            },
          ),
          const SizedBox(height: 4),
          VerifyInfoBox(
            title: 'consent_collect_title'.trFallback('What we collect, and why'),
            paragraphs: [
              'consent_collect_recruit_p1'.trFallback(
                'Their name, mobile number, pincode and state — so the party can maintain its membership register and assign them to a committee.',
              ),
              'consent_collect_recruit_p2'.trFallback('Activity they record in this app, with time and location.'),
              'consent_collect_p4'.trFallback(
                'We keep this while your membership is active, and for three years after. Grievance officer: privacy@party.in',
              ),
            ],
          ),
          Obx(
            () => VerifyCheckCard(
              label: 'i_agree'.tr,
              tag: 'required'.tr,
              checked: agreed.value,
              onTap: agreed.toggle,
            ),
          ),
          AppField(
            label: 'OTP',
            controller: otp,
            keyboard: TextInputType.number,
            mono: true,
            hint: '6-digit code',
            maxLength: 6,
            digitsOnly: true,
            icon: Icons.lock_outline_rounded,
            verifyStyle: true,
            onChanged: (_) => tick(),
          ),
          Obx(() {
            formTick.value;
            submitting.value;
            final pin = pincode.text.trim();
            final canSubmit = agreed.value &&
                otp.text.length == 6 &&
                name.text.trim().length >= 2 &&
                (pin.isEmpty || RegExp(r'^\d{6}$').hasMatch(pin)) &&
                stateId.value != null &&
                districtId.value != null &&
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
