import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/dob.dart';
import '../../core/utils/local_image.dart';
import '../../core/widgets/ui.dart';
import '../card/membership_card_view.dart';
import '../join/join_chrome.dart';
import '../session/session_controller.dart';

class ProfileOverviewView extends StatelessWidget {
  const ProfileOverviewView({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionController>();
    return Scaffold(
      backgroundColor: HomeColors.paper,
      appBar: OrganicAppBar(
        title: 'profile'.trFallback('Profile'),
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
        final member = session.member ?? {};
        final name = '${member['fullName'] ?? ''}'.trim();
        final initials = _initials(name);
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          children: [
            Center(
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
                      raw: memberPhotoRef(member),
                      fallback: Center(
                        child: Text(
                          initials,
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
                          color: const Color(0xFFE53935),
                          shape: BoxShape.circle,
                          border: Border.all(color: HomeColors.paper, width: 3),
                        ),
                        child: const Icon(Icons.priority_high_rounded, size: 14, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              name.isEmpty ? '—' : name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: HomeColors.ink),
            ),
            const SizedBox(height: 18),
            Material(
              color: Colors.white,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _Row(
                    icon: Icons.person_outline_rounded,
                    wash: const Color(0xFFE8F1FF),
                    tint: const Color(0xFF4A7DFF),
                    label: 'full_name'.tr,
                    value: name,
                  ),
                  _Row(
                    icon: Icons.work_outline_rounded,
                    wash: const Color(0xFFEEE8FF),
                    tint: const Color(0xFF6B5CE7),
                    label: 'card_member_id'.trFallback('Member ID'),
                    value: displayMemberId(member),
                  ),
                  _Row(
                    icon: Icons.phone_outlined,
                    wash: const Color(0xFFE6F6F0),
                    tint: const Color(0xFF1B7A5A),
                    label: 'mobile_number'.tr,
                    value: _mobile(member['mobile']),
                  ),
                  _Row(
                    icon: Icons.calendar_today_outlined,
                    wash: const Color(0xFFFFE8F0),
                    tint: const Color(0xFFE85A8C),
                    label: 'dob'.tr,
                    value: formatDobDisplay('${member['dateOfBirth'] ?? ''}'),
                  ),
                  _Row(
                    icon: Icons.groups_outlined,
                    wash: const Color(0xFFE6F7F4),
                    tint: const Color(0xFF2A9B8A),
                    label: 'gender'.tr,
                    value: _genderLabel(member['gender']),
                  ),
                  _Row(
                    icon: Icons.work_outline_rounded,
                    wash: const Color(0xFFFFF6E0),
                    tint: const Color(0xFFD4A017),
                    label: 'voter_id'.trFallback('Voter ID card number'),
                    value: '${member['voterId'] ?? ''}',
                  ),
                  _Row(
                    icon: Icons.credit_card_outlined,
                    wash: const Color(0xFFEEE8FF),
                    tint: const Color(0xFF6B5CE7),
                    label: 'pincode'.tr,
                    value: '${member['pincode'] ?? ''}',
                  ),
                  _Row(
                    icon: Icons.map_outlined,
                    wash: const Color(0xFFE8F4FF),
                    tint: const Color(0xFF4A90D9),
                    label: 'state'.tr,
                    value: '${member['stateName'] ?? ''}',
                  ),
                  _Row(
                    icon: Icons.apartment_outlined,
                    wash: const Color(0xFFF3EDE6),
                    tint: const Color(0xFF8B7355),
                    label: 'district'.tr,
                    value: '${member['districtName'] ?? ''}',
                  ),
                  _Row(
                    icon: Icons.home_outlined,
                    wash: const Color(0xFFFDECEC),
                    tint: const Color(0xFFC75B5B),
                    label: 'assembly'.tr,
                    value: '${member['assemblyName'] ?? ''}',
                  ),
                  _Row(
                    icon: Icons.home_outlined,
                    wash: const Color(0xFFFFF3E8),
                    tint: const Color(0xFFE08A4A),
                    label: 'address'.tr,
                    value: '${member['address'] ?? ''}',
                    showDivider: false,
                  ),
                ],
              ),
            ),
          ],
        );
      }),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: HomeColors.orange.withValues(alpha: 0.28),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SizedBox(
            height: 54,
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => Get.toNamed(
                Routes.profileEdit,
                arguments: {'openProfileAfterSave': false},
              ),
              style: FilledButton.styleFrom(
                backgroundColor: HomeColors.orange,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              ),
              icon: const Icon(Icons.edit_outlined, size: 20),
              label: Text(
                'edit_profile'.trFallback('Edit Profile'),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _initials(String source) {
    if (source.isEmpty) return 'RP';
    final parts = source.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.length == 1) return parts.first.substring(0, parts.first.length.clamp(0, 2)).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String _mobile(Object? raw) {
    final digits = '${raw ?? ''}'.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';
    final last10 = digits.length > 10 ? digits.substring(digits.length - 10) : digits;
    return '+91 $last10';
  }

  String _genderLabel(Object? raw) {
    return switch ('$raw') {
      'FEMALE' => 'female'.tr,
      'OTHER' => 'other'.tr,
      'MALE' => 'male'.tr,
      _ => '',
    };
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.wash,
    required this.tint,
    required this.label,
    required this.value,
    this.showDivider = true,
  });
  final IconData icon;
  final Color wash;
  final Color tint;
  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final text = value.trim().isEmpty ? '—' : value.trim();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: wash, shape: BoxShape.circle),
                child: Icon(icon, size: 20, color: tint),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: HomeColors.muted, height: 1.2),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      text,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: HomeColors.ink, height: 1.25),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1, thickness: 0.6, color: Color(0xFFF0EBE3), indent: 18, endIndent: 18),
      ],
    );
  }
}
