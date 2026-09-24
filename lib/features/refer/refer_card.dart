import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/endpoints.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/invite_code.dart';
import '../../core/widgets/flash.dart';
import '../../core/widgets/iro_ui.dart';
import '../card/membership_card_view.dart';
import '../join/join_chrome.dart';
import '../session/session_controller.dart';

/// "Bring someone in" — on Community and on the profile screen.
///
/// The code is worked out on the phone from the membership number already in
/// Hive — nothing is asked of the server for this. Whoever types it into the
/// join screen credits this member with the recruit.
///
/// It stays hidden until the member's own profile is complete. A half-finished
/// member handing out a code would be crediting recruits to a record that is
/// not yet placed in a state, district or constituency.

/// The member behind the widgets here: the one passed in, or the session's.
Map<String, dynamic>? _resolve(Map<String, dynamic>? member) =>
    member ?? (Get.isRegistered<SessionController>() ? Get.find<SessionController>().member : null);

/// Whether this member has anything to hand out. Nothing without a membership
/// number, and nothing worth handing out until their own record is finished —
/// the server's own `profileComplete`: a name, a state, a district and a
/// constituency.
bool referralVisible(Map<String, dynamic>? member) {
  final resolved = _resolve(member);
  return resolved?['profileComplete'] == true && inviteCodeOf(resolved).isNotEmpty;
}

/// What gets shared: what the app is, the code, and where to get it.
String referralShareText(String code) {
  final lines = [
    'refer_share_intro'.trFallback('Join me on RPD Sangathan.'),
    if (code.isNotEmpty) 'refer_share_code'.trParams({'code': code}),
    ExternalLinks.playStore,
  ];
  return lines.join('\n\n');
}

Future<void> _share(BuildContext context, String code) async {
  // Positions the sheet over the widget on iPad, where a share sheet without an
  // origin throws.
  final box = context.findRenderObject() as RenderBox?;
  await SharePlus.instance.share(
    ShareParams(
      text: referralShareText(code),
      subject: 'refer_friend'.trFallback('Refer a friend'),
      sharePositionOrigin: box == null ? Rect.zero : box.localToGlobal(Offset.zero) & box.size,
    ),
  );
}

Future<void> _copy(String code) async {
  await Clipboard.setData(ClipboardData(text: code));
  flash('ok', 'refer_copied'.trFallback('Code copied'));
}

/// The compact prompt on Community: badge, code and Share on one line.
class ReferFriendCard extends StatelessWidget {
  const ReferFriendCard({super.key, this.member});

  /// Left null in the app; passed in tests so the card can be built without a
  /// session behind it.
  final Map<String, dynamic>? member;

  Map<String, dynamic>? get _member => _resolve(member);

  static String shareText(String code) => referralShareText(code);

  @override
  Widget build(BuildContext context) {
    if (!referralVisible(_member)) return const SizedBox.shrink();
    final code = inviteCodeOf(_member);

    return IroCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Row(
        children: [
          // The colour lives in a badge rather than a banner across the top —
          // the card is a prompt, not a section of its own.
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: Iro.headerGradient,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.volunteer_activism_rounded, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'refer_friend'.trFallback('Refer a friend'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: iroDisplay(size: 13),
                ),
                const SizedBox(height: 1),
                _CodeBox(code: code, onTap: () => _copy(code)),
              ],
            ),
          ),
          const SizedBox(width: 9),
          IroActionButton(
            label: 'share'.trFallback('Share'),
            icon: Icons.ios_share_rounded,
            height: 34,
            wide: false,
            onTap: () => _share(context, code),
          ),
        ],
      ),
    );
  }
}

/// The profile screen's version: the membership number and the code side by
/// side, as one row inside that screen's own section card.
///
/// The two belong together — both are the member's own identifiers, one to
/// quote and one to hand out — and reading across is how people compare them
/// against a card they are holding.
class ReferralRow extends StatelessWidget {
  const ReferralRow({super.key, this.member});

  final Map<String, dynamic>? member;

  @override
  Widget build(BuildContext context) {
    final resolved = _resolve(member) ?? const <String, dynamic>{};
    final code = inviteCodeOf(resolved);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: _Pair(
              label: 'card_member_id'.trFallback('Member ID'),
              value: displayMemberId(resolved),
            ),
          ),
          // The same hairline that separates the rows of the cards above,
          // stood on its end.
          Container(
            width: 1,
            height: 32,
            margin: const EdgeInsets.symmetric(horizontal: 11),
            color: HomeColors.border,
          ),
          Expanded(
            flex: 5,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _copy(code),
              child: _Pair(
                label: 'card_referral'.trFallback('Referral code'),
                value: code,
                valueColor: Iro.green,
                trailing: Icons.copy_rounded,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The share pill that sits beside the section heading. Out of the row itself,
/// where it left the membership number and the code too little width to print
/// in full.
class ReferralShareButton extends StatelessWidget {
  const ReferralShareButton({super.key, this.member});

  final Map<String, dynamic>? member;

  @override
  Widget build(BuildContext context) {
    return IroActionButton(
      label: 'share'.trFallback('Share'),
      icon: Icons.ios_share_rounded,
      height: 34,
      wide: false,
      onTap: () => _share(context, inviteCodeOf(_resolve(member))),
    );
  }
}

/// A muted label over a strong value, the shape every row on the profile
/// screen already uses.
class _Pair extends StatelessWidget {
  const _Pair({required this.label, required this.value, this.valueColor = HomeColors.ink, this.trailing});

  final String label;
  final String value;
  final Color valueColor;
  final IconData? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: HomeColors.muted, height: 1.2),
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            Flexible(
              child: Text(
                value.trim().isEmpty ? '—' : value.trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: valueColor,
                  height: 1.25,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 5),
              Icon(trailing, size: 13, color: Iro.muted),
            ],
          ],
        ),
      ],
    );
  }
}

/// The code itself, tappable to copy. Spaced out because it gets read aloud and
/// typed by hand as often as it gets shared.
class _CodeBox extends StatelessWidget {
  const _CodeBox({required this.code, required this.onTap});
  final String code;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(7),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                code.split('').join(' '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: iroLabel(size: 11.5, color: Iro.green, weight: FontWeight.w800)
                    .copyWith(letterSpacing: 0.2),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.copy_rounded, size: 13, color: Iro.muted),
          ],
        ),
      ),
    );
  }
}
