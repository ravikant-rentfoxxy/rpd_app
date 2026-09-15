import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/api_error.dart';
import '../../core/utils/app_log.dart';
import '../../core/widgets/empty_card.dart';
import '../../core/widgets/ui.dart';
import '../../data/remote/api_client.dart';
import '../join/join_chrome.dart';
import '../session/session_controller.dart';
import '../../core/widgets/flash.dart';

Future<Map<String, dynamic>?> createBoothMeetingRecord({
  required String title,
  required String venue,
  String agenda = '',
  DateTime? startsAt,
  double? latitude,
  double? longitude,
}) async {
  final session = Get.find<SessionController>();
  if (!session.canCreateOrgEvents) return null;
  try {
    var lat = latitude;
    var lng = longitude;
    if (lat == null || lng == null) {
      final ok = await session.captureLocation();
      if (!ok || session.lat.value == null || session.lng.value == null) {
        flash('Error', 'location_needed'.trFallback('Turn on location to create the meeting'));
        return null;
      }
      lat = session.lat.value;
      lng = session.lng.value;
    }
    final member = session.member ?? {};
    final booth = member['booth'] is Map ? Map<String, dynamic>.from(member['booth'] as Map) : <String, dynamic>{};
    final agendaText = agenda.trim();
    final res = await Get.find<ApiClient>().post(
      '/meetings',
      data: {
        'title': title,
        'venue': venue,
        'agenda': agendaText.length >= 2 ? agendaText : title,
        'startsAt': (startsAt ?? DateTime.now()).toUtc().toIso8601String(),
        'latitude': lat,
        'longitude': lng,
        if ('${member['boothId'] ?? booth['id'] ?? ''}'.isNotEmpty) 'boothId': member['boothId'] ?? booth['id'],
      },
    );
    return Map<String, dynamic>.from((res['data'] as Map)['meeting'] as Map);
  } catch (e, stack) {
    AppLog.error('Create meeting failed', error: e, stack: stack, tag: 'MEETING');
    flash('Error', apiErrorMessage(e));
    return null;
  }
}

class MeetingDetailView extends StatefulWidget {
  const MeetingDetailView({super.key});

  @override
  State<MeetingDetailView> createState() => _MeetingDetailViewState();
}

class _MeetingDetailViewState extends State<MeetingDetailView> {
  final meetings = <Map<String, dynamic>>[].obs;
  final loading = false.obs;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    loading.value = true;
    try {
      final res = await Get.find<ApiClient>().get('/meetings');
      final items = (res['data']?['meetings'] as List?) ?? [];
      meetings.assignAll(items.whereType<Map>().map((e) => Map<String, dynamic>.from(e)));
    } catch (e, stack) {
      AppLog.error('Load meetings failed', error: e, stack: stack, tag: 'MEETING');
      flash('Error', apiErrorMessage(e));
    } finally {
      loading.value = false;
    }
  }

  Map<String, dynamic>? get _current => meetings.isEmpty ? null : meetings.first;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeColors.paper,
      appBar: OrganicAppBar(title: 'booth_meeting'.tr),
      body: Obx(() {
        if (loading.value && meetings.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: HomeColors.orange));
        }
        final meeting = _current;
        if (meeting == null) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
            children: [
              AppEmptyCard(
                icon: Icons.groups_outlined,
                title: 'no_meetings'.trFallback('No meeting yet'),
                sub: 'no_meetings_sub'.trFallback('Scan the host QR at the venue to join.'),
                actionLabel: 'join_meeting'.trFallback('Scan QR to join'),
                onAction: () => Get.toNamed(Routes.checkIn),
              ),
            ],
          );
        }
        final checkIns = (meeting['checkIns'] as List?) ?? [];
        final invitees = (meeting['invitees'] as List?) ?? [];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppCard(
              tone: CardTone.brand,
              child: CardTitle(
                meeting['title'] as String? ?? 'booth_meeting'.tr,
                sub: '${meeting['venue'] ?? ''} · ${checkIns.length} ${'checked_in'.trFallback('checked in')}',
              ),
            ),
            AppCard(
              child: Column(
                children: [
                  Text(
                    'meeting_id'.trFallback('Meeting ID'),
                    style: const TextStyle(color: HomeColors.muted, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${meeting['code'] ?? ''}',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: HomeColors.navy),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: QrImageView(
                      data: meetingQrPayload(meeting),
                      size: 200,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'scan_to_join_hint'.trFallback('Members scan this QR at the venue to join'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: HomeColors.muted, fontSize: 13),
                  ),
                ],
              ),
            ),
            if ('${meeting['agenda'] ?? ''}'.trim().isNotEmpty)
              AppCard(child: CardTitle('agenda'.trFallback('Agenda'), sub: '${meeting['agenda']}')),
            PrimaryButton('join_meeting'.trFallback('Scan QR to join'), onTap: () => Get.toNamed(Routes.checkIn)),
            if (invitees.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('invited'.tr, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink3)),
              ...invitees.map((e) {
                final i = Map<String, dynamic>.from(e as Map);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const AvatarCircle('M'),
                  title: Text(i['postLabel'] as String? ?? ''),
                );
              }),
            ],
          ],
        );
      }),
    );
  }
}

class CheckInView extends StatefulWidget {
  const CheckInView({super.key});

  @override
  State<CheckInView> createState() => _CheckInViewState();
}

class _CheckInViewState extends State<CheckInView> {
  final _scanner = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    formats: const [BarcodeFormat.qrCode],
  );
  var _busy = false;
  String? _lastRaw;

  @override
  void initState() {
    super.initState();
    Get.find<SessionController>().captureLocation();
  }

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  Rect _windowFor(BoxConstraints box) {
    final side = (box.maxWidth * 0.74).clamp(240.0, 320.0);
    return Rect.fromCenter(
      center: Offset(box.maxWidth / 2, box.maxHeight * 0.42),
      width: side,
      height: side,
    );
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy) return;
    final raw = capture.barcodes
        .map((code) => code.rawValue?.trim() ?? '')
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');
    if (raw.isEmpty || raw == _lastRaw) return;
    _lastRaw = raw;
    _busy = true;
    try {
      await _scanner.stop();
      await _join(raw);
    } finally {
      if (mounted) {
        await Future<void>.delayed(const Duration(milliseconds: 900));
        _busy = false;
        _lastRaw = null;
        if (mounted) {
          try {
            await _scanner.start();
          } catch (_) {}
        }
      }
    }
  }

  Future<void> _join(String raw) async {
    final meetingRef = meetingRefFromQr(raw);
    if (meetingRef == null) {
      flash(
        'join_meeting'.trFallback('Join meeting'),
        'check_in_invalid'.trFallback('This is not a meeting QR'),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: HomeColors.navy,
        colorText: Colors.white,
      );
      return;
    }
    final session = Get.find<SessionController>();
    final located = await session.captureLocation();
    if (!located || session.lat.value == null || session.lng.value == null) {
      flash('Error', 'location_needed'.trFallback('Turn on location to join the meeting'));
      return;
    }
    try {
      final res = await Get.find<ApiClient>().post(
        '/meetings/$meetingRef/check-in',
        data: {
          'latitude': session.lat.value,
          'longitude': session.lng.value,
        },
      );
      final data = Map<String, dynamic>.from(res['data'] as Map? ?? {});
      final checkIn = Map<String, dynamic>.from(data['checkIn'] as Map? ?? {});
      final member = Map<String, dynamic>.from(checkIn['member'] as Map? ?? {});
      final name = '${member['fullName'] ?? ''}'.trim();
      final already = data['alreadyIn'] == true;
      flash(
        already ? 'check_in_already'.trFallback('Already checked in') : 'check_in_ok'.trFallback('Joined the meeting'),
        name.isEmpty ? meetingRef : name,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: HomeColors.navy,
        colorText: Colors.white,
      );
    } catch (e, stack) {
      AppLog.error('Meeting join failed', error: e, stack: stack, tag: 'MEETING');
      flash('Error', apiErrorMessage(e), snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final window = _windowFor(constraints);
            return Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(
                  controller: _scanner,
                  scanWindow: window,
                  onDetect: _onDetect,
                  errorBuilder: (context, error) => _ScannerError(error: error),
                  overlayBuilder: (context, _) => ScanWindowOverlay(
                    controller: _scanner,
                    scanWindow: window,
                    borderColor: HomeColors.orange,
                    borderRadius: BorderRadius.circular(22),
                    borderWidth: 3,
                    color: const Color(0x99000000),
                  ),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: Get.back,
                              icon: const Icon(Icons.close_rounded, color: Colors.white),
                            ),
                            Expanded(
                              child: Text(
                                'join_meeting'.trFallback('Join meeting'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                              ),
                            ),
                            ValueListenableBuilder(
                              valueListenable: _scanner,
                              builder: (context, state, _) {
                                final on = state.torchState == TorchState.on;
                                return IconButton(
                                  onPressed: state.torchState == TorchState.unavailable ? null : _scanner.toggleTorch,
                                  icon: Icon(on ? Icons.flash_on_rounded : Icons.flash_off_rounded, color: Colors.white),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                        child: Text(
                          'scan_meeting_qr'.trFallback('Scan the meeting QR to join'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ScannerError extends StatelessWidget {
  const _ScannerError({required this.error});
  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    return ColoredBox(
      color: Colors.black,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: Get.back,
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ),
              const Spacer(),
              const Icon(Icons.qr_code_scanner_rounded, color: Colors.white70, size: 48),
              const SizedBox(height: 16),
              Text(
                denied
                    ? 'camera_needed'.trFallback('Allow camera access to scan the meeting QR.')
                    : '${error.errorCode}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, height: 1.4),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

String meetingQrPayload(Map<String, dynamic> meeting) {
  return jsonEncode({
    't': 'MEETING',
    'id': meeting['id'],
    'code': meeting['code'],
  });
}

String? meetingRefFromQr(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map) {
      final type = '${decoded['t'] ?? decoded['type'] ?? ''}'.toUpperCase();
      if (type.isNotEmpty && type != 'MEETING') return null;
      final id = '${decoded['id'] ?? decoded['meetingId'] ?? ''}';
      final code = '${decoded['code'] ?? decoded['meetingCode'] ?? ''}';
      if (id.isNotEmpty) return id;
      if (code.isNotEmpty) return code.toUpperCase();
    }
  } catch (_) {}
  final uri = Uri.tryParse(raw);
  if (uri != null && uri.host.toLowerCase() == 'meeting') {
    final code = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
    if (code.isNotEmpty) return code.toUpperCase();
  }
  final text = raw.trim().toUpperCase();
  if (RegExp(r'^MTG-[A-Z0-9]{6}$').hasMatch(text)) return text;
  if (RegExp(r'^[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}$').hasMatch(text)) {
    return raw.trim();
  }
  return null;
}
