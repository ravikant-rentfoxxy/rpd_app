import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/api_error.dart';
import '../../core/widgets/ui.dart';
import '../session/session_controller.dart';

Future<void> showContributeDialog() {
  return Get.dialog(
    const ContributeDialog(),
    barrierDismissible: false,
    barrierColor: Colors.black54,
  );
}

class ContributeDialog extends StatefulWidget {
  const ContributeDialog({super.key});

  @override
  State<ContributeDialog> createState() => _ContributeDialogState();
}

class _ContributeDialogState extends State<ContributeDialog> {
  final type = 'PRIMARY_MEMBER'.obs;
  final volunteerMode = RxnString();
  final referral = TextEditingController();
  final hours = TextEditingController();
  final submitting = false.obs;

  @override
  void dispose() {
    referral.dispose();
    hours.dispose();
    super.dispose();
  }

  Future<void> _finish({required bool save}) async {
    if (submitting.value) return;
    if (save) {
      if (type.value == 'VOLUNTEER') {
        if (volunteerMode.value == null) {
          Get.snackbar('Error', 'volunteer_mode_required'.tr);
          return;
        }
        final n = int.tryParse(hours.text.trim());
        if (n == null || n < 3 || n > 40) {
          Get.snackbar('Error', 'volunteer_hours_invalid'.tr);
          return;
        }
      }
      submitting.value = true;
      try {
        final session = Get.find<SessionController>();
        await session.saveContribution({
          'type': type.value,
          if (type.value == 'PRIMARY_MEMBER' && referral.text.trim().isNotEmpty) 'referralCode': referral.text.trim(),
          if (type.value == 'VOLUNTEER') 'volunteerMode': volunteerMode.value,
          if (type.value == 'VOLUNTEER') 'weeklyHours': int.parse(hours.text.trim()),
        });
      } catch (e) {
        submitting.value = false;
        Get.snackbar('Error', apiErrorMessage(e));
        return;
      }
      submitting.value = false;
    }
    if (Get.isDialogOpen == true) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpace.cardRadius)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.86),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Header(onClose: () => _finish(save: false)),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                child: Obx(
                  () => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'contribute_title'.tr,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, height: 1.25, color: AppColors.ink),
                      ),
                      const SizedBox(height: 14),
                      _Option(
                        label: 'contribute_member'.tr,
                        selected: type.value == 'PRIMARY_MEMBER',
                        onTap: () => type.value = 'PRIMARY_MEMBER',
                        child: type.value == 'PRIMARY_MEMBER'
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('referral_help'.tr, style: const TextStyle(fontSize: 12, color: AppColors.ink3, height: 1.35)),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: referral,
                                    keyboardType: TextInputType.text,
                                    decoration: _fieldDecoration('referral_hint'.tr),
                                  ),
                                ],
                              )
                            : null,
                      ),
                      _Option(
                        label: 'contribute_volunteer'.tr,
                        selected: type.value == 'VOLUNTEER',
                        onTap: () => type.value = 'VOLUNTEER',
                        showDivider: false,
                        child: type.value == 'VOLUNTEER'
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('volunteer_how'.tr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink2)),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _ModeChip(
                                          label: 'volunteer_online'.tr,
                                          selected: volunteerMode.value == 'ONLINE',
                                          onTap: () => volunteerMode.value = 'ONLINE',
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _ModeChip(
                                          label: 'volunteer_offline'.tr,
                                          selected: volunteerMode.value == 'OFFLINE',
                                          onTap: () => volunteerMode.value = 'OFFLINE',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text('volunteer_hours'.tr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink2)),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: hours,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    decoration: _fieldDecoration('volunteer_hours_hint'.tr),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
              child: Obx(
                () => PrimaryButton(
                  submitting.value ? '…' : 'next'.tr,
                  enabled: !submitting.value,
                  onTap: () => _finish(save: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.ink4, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.rule2)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.rule2)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.brand)),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 14),
      decoration: const BoxDecoration(
        color: AppColors.brandWash,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpace.cardRadius)),
      ),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(color: AppColors.brand, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: AppColors.brandOn, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                'congrats_registered'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.brand, fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ],
          ),
          Positioned(
            right: 0,
            top: 0,
            child: IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close, size: 20, color: AppColors.ink3),
            ),
          ),
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.label,
    required this.selected,
    required this.onTap,
    this.child,
    this.showDivider = true,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? child;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                _Radio(selected: selected),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
                ),
              ],
            ),
          ),
        ),
        if (child != null) Padding(padding: const EdgeInsets.only(left: 30, bottom: 10), child: child),
        if (showDivider)
          const DottedDivider(),
      ],
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: selected ? AppColors.brand : AppColors.ink4, width: 2),
        color: selected ? AppColors.brand : Colors.white,
      ),
      child: selected ? const Icon(Icons.circle, size: 8, color: Colors.white) : null,
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.brandWash : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpace.controlRadius),
        side: BorderSide(color: selected ? AppColors.brand : AppColors.rule2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpace.controlRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Row(
            children: [
              _Radio(selected: selected),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: selected ? AppColors.brand : AppColors.ink)),
            ],
          ),
        ),
      ),
    );
  }
}

class DottedDivider extends StatelessWidget {
  const DottedDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dash = 4.0;
        const gap = 3.0;
        final n = (constraints.maxWidth / (dash + gap)).floor();
        return Row(
          children: List.generate(
            n,
            (_) => Container(
              width: dash,
              height: 1,
              margin: const EdgeInsets.only(right: gap),
              color: AppColors.rule2,
            ),
          ),
        );
      },
    );
  }
}
