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
                style: const TextStyle(color: Iro.green, fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
      body: Obx(() {
        session.profile.value;
        final member = session.member ?? {};
        final name = '${member['fullName'] ?? ''}'.trim();
        final memberId = displayMemberId(member);
        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
          children: [
            Center(child: _Avatar(member: member, complete: session.canUseMemberActions)),
            const SizedBox(height: 12),
            DisplayText(name.isEmpty ? '—' : name, size: 20, center: true),
            if (memberId.trim().isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                memberId,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: HomeColors.muted),
              ),
            ],
            const SizedBox(height: 20),
            const _SectionTitle('profile_details', fallback: 'Your details'),
            _InfoCard(
              children: [
                _Row(
                  icon: Icons.person_outline_rounded,
                  group: _RowGroup.identity,
                  label: 'full_name'.tr,
                  value: name,
                ),
                _Row(
                  icon: Icons.badge_outlined,
                  group: _RowGroup.identity,
                  label: 'card_member_id'.trFallback('Member ID'),
                  value: memberId,
                ),
                _Row(
                  icon: Icons.phone_outlined,
                  group: _RowGroup.identity,
                  label: 'mobile_number'.tr,
                  value: _mobile(member['mobile']),
                ),
                _Row(
                  icon: Icons.calendar_today_outlined,
                  group: _RowGroup.identity,
                  label: 'dob'.tr,
                  value: formatDobDisplay('${member['dateOfBirth'] ?? ''}'),
                ),
                _Row(
                  icon: Icons.groups_outlined,
                  group: _RowGroup.identity,
                  label: 'gender'.tr,
                  value: _genderLabel(member['gender']),
                ),
                _Row(
                  icon: Icons.how_to_vote_outlined,
                  group: _RowGroup.identity,
                  label: 'voter_id'.trFallback('Voter ID card number'),
                  value: '${member['voterId'] ?? ''}',
                  showDivider: false,
                ),
              ],
            ),
            const SizedBox(height: 18),
            const _SectionTitle('profile_region', fallback: 'Your region'),
            _InfoCard(
              children: [
                _Row(
                  icon: Icons.credit_card_outlined,
                  group: _RowGroup.region,
                  label: 'pincode'.tr,
                  value: '${member['pincode'] ?? ''}',
                ),
                _Row(
                  icon: Icons.map_outlined,
                  group: _RowGroup.region,
                  label: 'state'.tr,
                  value: '${member['stateName'] ?? ''}',
                ),
                _Row(
                  icon: Icons.apartment_outlined,
                  group: _RowGroup.region,
                  label: 'district'.tr,
                  value: '${member['districtName'] ?? ''}',
                ),
                _Row(
                  icon: Icons.account_balance_outlined,
                  group: _RowGroup.region,
                  label: 'assembly'.tr,
                  value: '${member['assemblyName'] ?? ''}',
                ),
                _Row(
                  icon: Icons.home_outlined,
                  group: _RowGroup.region,
                  label: 'address'.tr,
                  value: '${member['address'] ?? ''}',
                  showDivider: false,
                ),
              ],
            ),
          ],
        );
      }),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            // The same gradient pill the home screen uses for its one action.
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [HomeColors.orange, HomeColors.orangeDark],
            ),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: HomeColors.orange.withValues(alpha: 0.28),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => Get.toNamed(
                Routes.profileEdit,
                arguments: {'openProfileAfterSave': false},
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.edit_outlined, size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'edit_profile'.trFallback('Edit Profile'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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

class _Avatar extends StatelessWidget {
  const _Avatar({required this.member, required this.complete});
  final Map<String, dynamic> member;
  final bool complete;

  String get _initials {
    final source = '${member['fullName'] ?? ''}'.trim();
    if (source.isEmpty) return 'RP';
    final parts = source.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length.clamp(0, 2)).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    // The ring carries the same signal as the one in the home bar: red while
    // the profile is unusable, green once it is good.
    return Container(
      width: 96,
      height: 96,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: complete ? HomeColors.tealMid : AppColors.bad, width: 2.5),
      ),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [HomeColors.peach2, HomeColors.peach],
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: localOrNetworkPhoto(
          raw: memberPhotoRef(member),
          fallback: Center(
            child: Text(
              _initials,
              style: const TextStyle(
                color: HomeColors.orangeDark,
                fontWeight: FontWeight.w800,
                fontSize: 26,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.translationKey, {required this.fallback});
  final String translationKey;
  final String fallback;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 10),
      child: DisplayText(translationKey.trFallback(fallback), size: 17),
    );
  }
}

/// The card shape the home screen settled on: white, a light hairline, and the
/// same two-layer shadow.
class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: DecoratedBox(
        decoration: BoxDecoration(borderRadius: radius, boxShadow: homeCardShadow),
        child: Material(
          color: HomeColors.surface,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: const BorderSide(color: HomeColors.border, width: 1.5),
          ),
          child: Column(children: children),
        ),
      ),
    );
  }
}

/// Which family a row's icon is tinted from. One hue per card rather than a
/// different colour per line, so the two groups read apart at a glance.
enum _RowGroup { identity, region }

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.group,
    required this.label,
    required this.value,
    this.showDivider = true,
  });
  final IconData icon;
  final _RowGroup group;
  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final text = value.trim().isEmpty ? '—' : value.trim();
    final (wash, tint) = switch (group) {
      _RowGroup.identity => (AppColors.brandWash, HomeColors.navy),
      _RowGroup.region => (HomeColors.peach2, HomeColors.orange),
    };
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: wash, shape: BoxShape.circle),
                child: Icon(icon, size: 17, color: tint),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: HomeColors.muted,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      text,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: HomeColors.ink,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, thickness: 1, color: HomeColors.border, indent: 14, endIndent: 14),
      ],
    );
  }
}
