import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/org_hierarchy.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_log.dart';
import '../../core/utils/invite_code.dart';
import '../../core/utils/local_image.dart';
import '../session/session_controller.dart';
import '../../core/widgets/flash.dart';

/// The card carries its own palette rather than the app's.
///
/// It is a printed object — a member shows it, photographs it and shares it —
/// so it stayed purple and orange when the rest of the app went green. The back
/// was drawn with the shared VerifyColors names instead, which the retint
/// pointed at the greens, and the two sides stopped matching.
const _cardPurple = Color(0xFF4A1878);
const _cardOrange = Color(0xFFE88224);
const _cardCream = Color(0xFFFBF6EE);
const _cardInk = Color(0xFF1B1740);

/// The middle stop of the band across the top of the back, between the spine
/// purple and the slant orange the front uses.
const _cardPurpleSoft = Color(0xFF7A3BA8);
const _cardOrangeSoft = Color(0xFFF3A961);

/// Small-caps labels and the hairline between rows, both matching the front.
const _cardMuted = Color(0xFF9A96A8);
const _cardLine = Color(0xFFE7E1D6);

Future<void> showMembershipCardOverlay() async {
  final session = Get.find<SessionController>();
  if (!session.guardMemberActions()) return;
  session.refreshMe();
  await Get.dialog(
    const MembershipCardOverlay(),
    barrierColor: const Color(0xB3120C1A),
    barrierDismissible: true,
  );
}

class MembershipCardView extends StatelessWidget {
  const MembershipCardView({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isDialogOpen == true) return;
      Get.back();
      showMembershipCardOverlay();
    });
    return const SizedBox.shrink();
  }
}

class MembershipCardOverlay extends StatefulWidget {
  const MembershipCardOverlay({super.key});

  @override
  State<MembershipCardOverlay> createState() => _MembershipCardOverlayState();
}

class _MembershipCardOverlayState extends State<MembershipCardOverlay> with SingleTickerProviderStateMixin {
  final _frontKey = GlobalKey();
  final _backKey = GlobalKey();
  bool _sharing = false;
  late final AnimationController _flip;

  @override
  void initState() {
    super.initState();
    _flip = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  }

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  bool get _showingBack => _flip.value > 0.5;

  void _toggleFace() {
    if (_flip.isAnimating) return;
    _showingBack ? _flip.reverse() : _flip.forward();
  }

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionController>();
    return Obx(() {
      final m = session.member ?? {};
      final photoUrl = memberPhotoRef(m);
      return SafeArea(
        child: Center(
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: Get.back,
                      style: IconButton.styleFrom(foregroundColor: Colors.white),
                      icon: const Icon(Icons.close_rounded),
                    ),
                    Expanded(
                      child: Text(
                        'membership_card'.tr,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ),
                    TextButton(
                      onPressed: _sharing ? null : () => _shareCardImage(photoUrl),
                      style: TextButton.styleFrom(foregroundColor: Colors.white),
                      child: Text(_sharing ? '…' : 'share'.tr),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.28), blurRadius: 22, offset: const Offset(0, 10)),
                    ],
                  ),
                  child: GestureDetector(
                    onTap: _toggleFace,
                    child: AnimatedBuilder(
                      animation: _flip,
                      builder: (context, _) {
                        final angle = _flip.value * math.pi;
                        final back = _flip.value > 0.5;
                        return Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.0012)
                            ..rotateY(angle),
                          child: back
                              ? Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.identity()..rotateY(math.pi),
                                  child: RepaintBoundary(
                                    key: _backKey,
                                    child: MembershipCardBack(member: m),
                                  ),
                                )
                              : RepaintBoundary(
                                  key: _frontKey,
                                  child: MembershipCardFace(member: m),
                                ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                AnimatedBuilder(
                  animation: _flip,
                  builder: (context, _) => Text(
                    _showingBack
                        ? _t('card_flip_front', 'Tap the card to see front')
                        : _t('card_flip_hint', 'Tap the card to see address'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
        ),
      );
    });
  }

  Future<void> _shareCardImage(Object? photoUrl) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    OverlayEntry? entry;
    try {
      final provider = localOrNetworkImage(photoUrl);
      if (provider != null && mounted) {
        await precacheImage(provider, context);
      }
      final member = Map<String, dynamic>.from(Get.find<SessionController>().member ?? {});
      final shareKey = GlobalKey();
      entry = OverlayEntry(
        builder: (_) => IgnorePointer(
          child: Opacity(
            opacity: 0.01,
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 420,
                child: Material(
                  color: Colors.transparent,
                  child: RepaintBoundary(
                    key: shareKey,
                    child: _BothSidesSharePage(member: member),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      Overlay.of(context).insert(entry);
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 80));
      final boundary = shareKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/membership_card.png');
      await file.writeAsBytes(bytes.buffer.asUint8List());
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png', name: 'membership_card.png')],
          subject: 'membership_card'.tr,
          sharePositionOrigin: box == null ? Rect.zero : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (e, stack) {
      AppLog.error('Share card image failed', error: e, stack: stack, tag: 'CARD');
      flash('Error', e.toString());
    } finally {
      entry?.remove();
      if (mounted) setState(() => _sharing = false);
    }
  }
}

class _BothSidesSharePage extends StatelessWidget {
  const _BothSidesSharePage({required this.member});
  final Map<String, dynamic> member;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF7F1E8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _t('party_full_name', 'राष्ट्रीय परिवर्तन दल'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _cardInk,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _t('card_title', 'Membership card').toUpperCase(),
              style: const TextStyle(
                color: _cardOrange,
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 16),
            MembershipCardFace(member: member),
            const _ShareFoldDottedLine(),
            MembershipCardBack(member: member),
          ],
        ),
      ),
    );
  }
}

class _ShareFoldDottedLine extends StatelessWidget {
  const _ShareFoldDottedLine();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: SizedBox(
        height: 10,
        width: double.infinity,
        child: CustomPaint(painter: _DottedLinePainter()),
      ),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF6B6680)
      ..style = PaintingStyle.fill;
    const radius = 1.35;
    const gap = 6.0;
    final y = size.height / 2;
    var x = radius;
    while (x <= size.width - radius) {
      canvas.drawCircle(Offset(x, y), radius, paint);
      x += gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MembershipCardFace extends StatelessWidget {
  const MembershipCardFace({super.key, required this.member});
  final Map<String, dynamic> member;

  @override
  Widget build(BuildContext context) {
    final booth = member['booth'] as Map?;
    final card = member['card'] as Map?;
    final photoUrl = memberPhotoRef(member);
    final name = _text(member['fullName']);
    final id = displayMemberId(member);
    final mobile = _mobileNumber(member['mobile']);
    // The helper returns empty when there is nothing to derive a code from;
    // the card has always shown a dash there rather than a blank field.
    final referral = inviteCodeOf(member).isEmpty ? '—' : inviteCodeOf(member);
    final post = postLabelKey(member['post'] as String?).tr;
    final boothCode = _text(booth?['code']);
    final area = [_firstText([member['districtName'], booth?['districtName']]), _text(booth?['mandalName'])].where((e) => e.isNotEmpty).join(', ');
    final validThru = _validThru(card?['validTo'] ?? member['validTo']);

    return _CardShell(
      spine: _t('card_member', 'MEMBER'),
      footerLeft: _t('card_valid_thru', 'VALID THRU @date').replaceAll('@date', validThru),
      footerRight: _t('card_official', 'Official member').toUpperCase(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardPhoto(url: photoUrl),
          const SizedBox(width: 10),
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) {
                return FittedBox(
                  alignment: Alignment.topLeft,
                  fit: BoxFit.scaleDown,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: box.maxWidth),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Field(label: _t('card_member_name', 'Member name'), value: name),
                        _Field(label: _t('card_member_id', 'Member ID'), value: id, valueColor: _cardPurple),
                        _Field(label: _t('mobile', 'Mobile'), value: mobile, valueColor: _cardPurple),
                        _Field(label: _t('card_referral', 'Referral code'), value: referral, valueColor: _cardPurple),
                        if (post.isNotEmpty || boothCode.isNotEmpty)
                          _MetaLine([post, boothCode].where((e) => e.isNotEmpty).join(' · ')),
                        if (area.isNotEmpty) _MetaLine(area),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class MembershipCardBack extends StatelessWidget {
  const MembershipCardBack({super.key, required this.member});
  final Map<String, dynamic> member;

  @override
  Widget build(BuildContext context) {
    final booth = member['booth'] as Map?;
    final address = _text(member['address']);
    final pincode = _text(member['pincode']);
    final state = _firstText([member['stateName'], booth?['stateName']]);
    final district = _firstText([member['districtName'], booth?['districtName']]);
    final assembly = _cleanAssembly(_firstText([member['assemblyName'], booth?['assemblyName']]));
    final issued = _issuedOn(member['card'] is Map ? (member['card'] as Map)['issuedAt'] : null, member['createdAt']);

    return AspectRatio(
      aspectRatio: 1.62,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ColoredBox(
          color: _cardCream,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 6,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [_cardPurple, _cardPurpleSoft, _cardOrange]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _cardOrange, width: 1.5),
                      ),
                      child: ClipOval(child: Image.asset('assets/images/app_logo.png', fit: BoxFit.cover)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: _t('party_full_name', 'राष्ट्रीय परिवर्तन दल'),
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: _cardInk),
                          children: [
                            TextSpan(
                              text: ' · ${_t('card_title', 'Membership card').toUpperCase()}',
                              style: const TextStyle(color: _cardOrange, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Expanded(child: _BackRow(label: _t('address', 'Address'), value: address.isEmpty ? '—' : address)),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(child: _BackRow(label: _t('pincode', 'Pincode'), value: pincode.isEmpty ? '—' : pincode)),
                            const SizedBox(width: 16),
                            Expanded(child: _BackRow(label: _t('state', 'State'), value: state.isEmpty ? '—' : state)),
                          ],
                        ),
                      ),
                      Expanded(child: _BackRow(label: _t('district', 'District'), value: district.isEmpty ? '—' : district)),
                      Expanded(child: _BackRow(label: _t('assembly', 'Assembly constituency'), value: assembly.isEmpty ? '—' : assembly)),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _t('card_issued_on', 'Issued on').toUpperCase(),
                        style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: _cardMuted),
                      ),
                      Text(
                        issued,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _cardInk),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 7, 16, 7),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [_cardOrange, _cardOrangeSoft]),
                ),
                child: Text(
                  _t('card_property', 'Property of राष्ट्रीय परिवर्तन दल. Report loss to your local unit office.'),
                  style: const TextStyle(color: Colors.white, fontSize: 7.5, fontWeight: FontWeight.w600, height: 1.35),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _issuedOn(Object? issuedAt, Object? createdAt) {
    final parsed = DateTime.tryParse(issuedAt?.toString() ?? '') ?? DateTime.tryParse(createdAt?.toString() ?? '');
    if (parsed == null) return '—';
    return '${parsed.day.toString().padLeft(2, '0')}-${parsed.month.toString().padLeft(2, '0')}-${parsed.year}';
  }
}

class _BackRow extends StatelessWidget {
  const _BackRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(top: 2, bottom: 3),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _cardLine))),
      child: FittedBox(
        alignment: Alignment.centerLeft,
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: _cardMuted, height: 1.1),
            ),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _cardInk, height: 1.15),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({
    required this.spine,
    required this.footerLeft,
    required this.footerRight,
    required this.child,
  });

  final String spine;
  final String footerLeft;
  final String footerRight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.62,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: CustomPaint(
          painter: _CardBackgroundPainter(),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 36,
                width: 46,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    const _CardLogo(),
                    Expanded(
                      child: Center(
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: Text(
                            spine.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              letterSpacing: 2.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 86,
                right: 14,
                top: 10,
                child: Column(
                  children: [
                    Text(
                      _t('party_full_name', 'राष्ट्रीय परिवर्तन दल'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _cardInk,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _t('card_title', 'Membership card').toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _cardOrange,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned.fill(
                left: 52,
                top: 52,
                bottom: 36,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 14, 8),
                  child: child,
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 0,
                height: 36,
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        footerLeft,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 0.4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      footerRight,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 0.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Color(0xFF5C5870), fontSize: 10.5, fontWeight: FontWeight.w600, height: 1.25),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value, this.valueColor = _cardInk, this.maxLines = 1});
  final String label;
  final String value;
  final Color valueColor;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(color: Color(0xFF9A96A8), fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 0.4),
          ),
          Text(
            value,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: valueColor, fontSize: 12.5, fontWeight: FontWeight.w800, height: 1.25),
          ),
        ],
      ),
    );
  }
}

class _CardLogo extends StatelessWidget {
  const _CardLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: ClipOval(
        child: Image.asset('assets/images/app_logo.png', fit: BoxFit.cover),
      ),
    );
  }
}

class _CardPhoto extends StatelessWidget {
  const _CardPhoto({this.url});
  final Object? url;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _cardOrange, width: 2.5),
        boxShadow: [
          BoxShadow(color: _cardOrange.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: ClipOval(
        child: ColoredBox(
          color: AppColors.sunk,
          child: localOrNetworkPhoto(
            raw: url,
            fallback: const Center(child: Icon(Icons.person, color: AppColors.ink4, size: 32)),
          ),
        ),
      ),
    );
  }
}

class _CardBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _cardCream);

    final purpleW = size.width * 0.145;
    canvas.drawRect(Rect.fromLTWH(0, 0, purpleW, size.height), Paint()..color = _cardPurple);

    final slant = Path()
      ..moveTo(purpleW - 6, 0)
      ..lineTo(size.width * 0.34, 0)
      ..lineTo(size.width * 0.22, size.height)
      ..lineTo(purpleW - 18, size.height)
      ..close();
    canvas.drawPath(slant, Paint()..color = _cardOrange);

    canvas.drawRect(Rect.fromLTWH(0, size.height - 36, size.width, 36), Paint()..color = _cardOrange);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

String displayMemberId(Map<String, dynamic> member) {
  final stored = _text(member['membershipNumber']);
  if (RegExp(r'^RPD-[A-Z0-9]+-\d+$').hasMatch(stored) || RegExp(r'^RPD-\d+$').hasMatch(stored)) {
    return stored;
  }
  final row = member['rowId'] ?? member['row_id'];
  final state = _text(member['stateCode']).toUpperCase();
  if (row != null && '$row'.trim().isNotEmpty && '$row' != 'null') {
    return state.isNotEmpty ? 'RPD-$state-$row' : 'RPD-$row';
  }
  return stored.isNotEmpty ? stored : '—';
}

String _text(Object? raw) => raw?.toString().trim() ?? '';

String _mobileNumber(Object? raw) {
  final digits = _text(raw).replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return '';
  return digits.length > 10 ? digits.substring(digits.length - 10) : digits;
}


String _cleanAssembly(String raw) {
  final text = raw.trim();
  final space = text.indexOf(' ');
  if (space <= 0) return text;
  final prefix = text.substring(0, space).toUpperCase();
  final rest = text.substring(space + 1);
  final slug = rest.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  if (prefix.isNotEmpty && slug.startsWith(prefix)) return rest;
  return text;
}

String _firstText(Iterable<Object?> values) {
  for (final value in values) {
    final text = _text(value);
    if (text.isNotEmpty) return text;
  }
  return '';
}

String _t(String key, String fallback) {
  final value = key.tr;
  return value == key ? fallback : value;
}

String _validThru(Object? raw) {
  final parsed = DateTime.tryParse(raw?.toString() ?? '');
  final date = parsed ?? DateTime(2028, 3, 31);
  return '${date.month.toString().padLeft(2, '0')}/${date.year}';
}
