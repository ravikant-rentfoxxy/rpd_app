import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/language_dropdown.dart';
import '../../core/utils/api_error.dart';
import '../../core/utils/app_log.dart';
import '../../core/utils/dob.dart';
import '../../core/widgets/empty_card.dart';
import '../../core/widgets/ui.dart';
import '../../data/local/hive_service.dart';
import '../../data/remote/api_client.dart';
import '../../data/remote/pincode_api.dart';
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
                if (!Get.find<SessionController>().guardMemberActions()) return;
                Get.toNamed(Routes.addMember);
              },
            ),
            const SizedBox(height: 8),
            if (list.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 12),
                child: AppEmptyCard(
                  icon: Icons.person_add_alt_1_outlined,
                  title: 'members'.tr,
                  sub: 'members_more_sub'.tr,
                ),
              ),
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
    if (!Get.find<SessionController>().guardMemberActions()) {
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
  final gender = 'MALE'.obs;
  final states = <SearchOption>[].obs;
  final stateId = RxnString();
  final loadingStates = false.obs;
  final lookingUpPin = false.obs;
  var _pinLookup = 0;
  final name = TextEditingController();
  final dob = TextEditingController();
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
    dob.dispose();
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
      if (id == null) {
        flash('Error', name.isEmpty ? 'pincode_invalid'.tr : 'pincode_state_unknown'.trParams({'state': name}));
        return;
      }
      if (!states.any((s) => s.id == id) && name.isNotEmpty) {
        states.add(SearchOption(id: id, name: name));
      }
      if (states.any((s) => s.id == id)) {
        stateId.value = id;
        tick();
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
    final dobValue = dobToIso(dob.text);
    final pin = pincode.text.trim();
    if (fullName.length < 2 || !isValidDob(dobValue)) {
      flash('Error', !isValidDob(dobValue) ? 'dob_invalid'.tr : 'complete_steps'.tr);
      return;
    }
    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
      flash('Error', 'pincode_invalid'.tr);
      return;
    }
    if (stateId.value == null) {
      flash('Error', 'select_state'.tr);
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
        'pincode': pin,
        'stateId': stateId.value,
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
      appBar: AppBar(title: Text('add_member'.tr)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          const StepBar(total: 2, current: 2),
          AppCard(tone: CardTone.brand, child: CardTitle('hand_phone'.tr, sub: 'must_agree'.tr)),
          AppField(label: '${'full_name'.tr} *', controller: name, hint: 'enter_name'.tr, onChanged: (_) => tick()),
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
          AppField(
            label: '${'pincode'.tr} *',
            controller: pincode,
            hint: 'pincode_hint'.tr,
            icon: Icons.credit_card_outlined,
            keyboard: TextInputType.number,
            digitsOnly: true,
            maxLength: 6,
            onChanged: (value) {
              tick();
              _lookupStateFromPincode(value);
            },
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
              enabled: false,
              onChanged: (id) {
                stateId.value = id;
                tick();
              },
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
                RegExp(r'^\d{6}$').hasMatch(pincode.text.trim()) &&
                stateId.value != null &&
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
