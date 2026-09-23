import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../features/session/session_controller.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';
import '../utils/local_image.dart';
import 'iro_ui.dart';

/// The header carries no field of its own — it sits on the same mint as the
/// page, so the two read as one surface. Kept as a name because the bell badge
/// and the avatar dot ring themselves in whatever the bar is sitting on.
const iroHeaderSurface = Iro.mint;

/// The bar is light, so the status bar above it carries dark icons.
const iroOverlay = SystemUiOverlayStyle(
  statusBarColor: iroHeaderSurface,
  statusBarIconBrightness: Brightness.dark,
  statusBarBrightness: Brightness.light,
);

/// The chrome every header shares. No hairline: a rule across a continuous
/// field would only draw attention to a join that is not there.
BoxDecoration _headerField() => const BoxDecoration(color: iroHeaderSurface);

/// The organisation mark: the app logo in a disc, no ring. The artwork is a
/// full-bleed square, so the disc crops its corners and nothing else.
///
/// Deliberately no border. A border on the background decoration would make
/// Container inset the child by the border's width, leaving the square artwork
/// short of the circle clipping it — which showed as pale gaps at the top,
/// bottom and sides. If a ring is ever wanted again it belongs on
/// `foregroundDecoration`, which paints over the mark without moving it.
class IroMark extends StatelessWidget {
  const IroMark({super.key, this.size = 36});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      // The wash only ever shows if the artwork fails to load.
      decoration: const BoxDecoration(shape: BoxShape.circle, color: Iro.wash),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/images/app_logo.png',
        fit: BoxFit.cover,
        // A mark that will not load must not take the whole header with it.
        errorBuilder: (_, _, _) => Icon(Icons.eco_rounded, size: size * 0.52, color: Iro.forest),
      ),
    );
  }
}

/// The header every tab opens with: the mark, the organisation's name and the
/// section it is showing, the member's region, and the two things they reach
/// for most — notifications and their own profile. Dark type on a pale field,
/// so it reads as part of the page rather than a band clamped over it.
class IroTopBar extends StatelessWidget {
  const IroTopBar({super.key, required this.section});

  final String section;

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionController>();
    return Obx(() {
      session.profile.value;
      final member = session.member ?? {};
      return Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 11),
        decoration: _headerField(),
        child: Row(
          children: [
            const IroMark(size: 42),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text('app_name'.tr, style: iroDisplay(size: 21, color: Iro.forest)),
                      const SizedBox(width: 8),
                      Flexible(child: IroSectionChip(section)),
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    iroRegionLine(member),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: iroLabel(size: 11.5, color: Iro.greenMid, weight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _BellButton(unread: session.unreadNotifications.value),
            const SizedBox(width: 10),
            _HeaderAvatar(member: member, verified: !session.needsVerification),
          ],
        ),
      );
    });
  }
}

/// The quiet capsule beside the name that says which section is open.
class IroSectionChip extends StatelessWidget {
  const IroSectionChip(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Iro.wash, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: iroLabel(size: 10, color: Iro.ink2, weight: FontWeight.w800).copyWith(letterSpacing: 0.6),
      ),
    );
  }
}

/// A back bar for anything opened on top of a tab. Same field, one title.
class IroPageBar extends StatelessWidget {
  const IroPageBar({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.onBack,
    this.showBack = true,
  });

  final String title;
  final String? subtitle;
  final Widget? action;
  final VoidCallback? onBack;

  /// False on a screen reached by replacing the stack, where there is nothing
  /// to go back to.
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final session = Get.isRegistered<SessionController>() ? Get.find<SessionController>() : null;
    final line = subtitle ?? iroRegionLine(session?.member ?? {});
    return Container(
      padding: EdgeInsets.fromLTRB(showBack ? 4 : 14, 10, 14, 11),
      decoration: _headerField(),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              onPressed: onBack ?? Get.back,
              icon: const Icon(Icons.arrow_back_rounded, color: Iro.forest, size: 21),
              visualDensity: VisualDensity.compact,
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: iroDisplay(size: 19, color: Iro.forest),
                ),
                if (line.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    line,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: iroLabel(size: 11.5, color: Iro.greenMid, weight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

/// "District • state", as short as the profile allows. An unverified member has
/// no region yet, so the organisation's own line stands in.
String iroRegionLine(Map<String, dynamic> member) {
  final booth = member['booth'] is Map ? Map<String, dynamic>.from(member['booth'] as Map) : const {};
  final district = '${member['districtName'] ?? booth['districtName'] ?? ''}'.trim();
  final state = '${member['stateName'] ?? booth['stateName'] ?? ''}'.trim();
  final parts = [
    if (district.isNotEmpty) '$district ${'district'.tr}',
    if (state.isNotEmpty) state,
  ];
  if (parts.isEmpty) return 'app_tag'.tr;
  return parts.join(' • ');
}

class _BellButton extends StatelessWidget {
  const _BellButton({required this.unread});
  final int unread;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.toNamed(Routes.notifications),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 34,
        height: 34,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.notifications_none_rounded, color: Iro.forest, size: 23),
            if (unread > 0)
              Positioned(
                right: 0,
                top: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  constraints: const BoxConstraints(minWidth: 16),
                  decoration: BoxDecoration(
                    color: Iro.green,
                    borderRadius: BorderRadius.circular(999),
                    // Ringed in the bar's own colour so the badge reads as
                    // sitting on top of the bell, not merged into it.
                    border: Border.all(color: iroHeaderSurface, width: 1.5),
                  ),
                  child: Text(
                    '$unread',
                    textAlign: TextAlign.center,
                    style: iroLabel(size: 8.5, color: Colors.white, weight: FontWeight.w800),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HeaderAvatar extends StatelessWidget {
  const _HeaderAvatar({required this.member, required this.verified});
  final Map<String, dynamic> member;
  final bool verified;

  String get _initials {
    final name = '${member['fullName'] ?? ''}'.trim();
    if (name.isEmpty) return 'IR';
    final parts = name.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.length == 1) return parts.first.substring(0, parts.first.length.clamp(0, 2)).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.toNamed(Routes.profile),
      child: SizedBox(
        width: 38,
        height: 38,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Iro.wash,
                border: Border.all(color: Iro.line, width: 1.5),
              ),
              clipBehavior: Clip.antiAlias,
              child: localOrNetworkPhoto(
                raw: memberPhotoRef(member),
                fallback: Center(
                  child: Text(_initials, style: iroLabel(size: 12.5, color: Iro.green, weight: FontWeight.w800)),
                ),
              ),
            ),
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: verified ? Iro.green : Iro.goldBright,
                  border: Border.all(color: iroHeaderSurface, width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
