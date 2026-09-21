import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/api_error.dart';
import '../../core/utils/app_log.dart';
import '../../core/widgets/flash.dart';
import '../join/join_chrome.dart';
import '../session/session_controller.dart';
import 'event_api.dart';

/// What a host's event QR carries. The id alone is enough — the server still
/// checks the scanner joined the event and is inside the venue radius.
String orgEventQrPayload(Map<String, dynamic> event) {
  return jsonEncode({'t': 'EVENT', 'id': event['id']});
}

/// Reads an event id back out of a scanned QR, or null when it is not one of ours.
String? orgEventIdFromQr(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return null;
  try {
    final decoded = jsonDecode(text);
    if (decoded is Map) {
      final type = '${decoded['t'] ?? decoded['type'] ?? ''}'.toUpperCase();
      if (type.isNotEmpty && type != 'EVENT') return null;
      final id = '${decoded['id'] ?? decoded['eventId'] ?? ''}'.trim();
      if (id.isNotEmpty) return id;
    }
  } catch (_) {
    // Not JSON — fall through to the plain-id forms below.
  }
  final uri = Uri.tryParse(text);
  if (uri != null && uri.host.toLowerCase() == 'event' && uri.pathSegments.isNotEmpty) {
    return uri.pathSegments.first;
  }
  if (RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(text)) {
    return text;
  }
  return null;
}

/// The QR a host shows at the venue. Members scan it from their event card.
Future<void> showEventQrSheet(BuildContext context, Map<String, dynamic> event) {
  final title = '${event['title'] ?? ''}'.trim();
  final venue = '${event['venue'] ?? event['place'] ?? ''}'.trim();
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: HomeColors.paper,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: HomeColors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title.isEmpty ? 'event_qr_title'.trFallback('Event QR') : title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: HomeColors.ink),
            ),
            if (venue.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                venue,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.5, color: HomeColors.muted),
              ),
            ],
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: QrImageView(
                data: orgEventQrPayload(event),
                size: 220,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'event_qr_hint'.trFallback('Show this at the venue. Members scan it to check in.'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: HomeColors.muted, height: 1.35),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Scans the host's QR for one event, then checks the member in.
///
/// The QR proves the member is at the right event; the server still confirms
/// they joined it, that it is running, and that they are inside the radius.
class EventScanCheckInView extends StatefulWidget {
  const EventScanCheckInView({super.key, required this.event});
  final Map<String, dynamic> event;

  @override
  State<EventScanCheckInView> createState() => _EventScanCheckInViewState();
}

class _EventScanCheckInViewState extends State<EventScanCheckInView> {
  final _scanner = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    formats: const [BarcodeFormat.qrCode],
  );
  var _busy = false;
  String? _lastRaw;

  String get _eventId => '${widget.event['id'] ?? ''}';

  @override
  void initState() {
    super.initState();
    // Ask early so the fix is ready by the time a QR is in frame.
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
      await _checkIn(raw);
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

  void _warn(String message) {
    flash(
      'event_check_in'.trFallback('Check in'),
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: HomeColors.navy,
      colorText: Colors.white,
    );
  }

  Future<void> _checkIn(String raw) async {
    final scanned = orgEventIdFromQr(raw);
    if (scanned == null) {
      _warn('event_qr_invalid'.trFallback('This is not an event QR'));
      return;
    }
    if (scanned != _eventId) {
      _warn('event_qr_mismatch'.trFallback('This QR is for a different event'));
      return;
    }
    final session = Get.find<SessionController>();
    final located = await session.captureLocation();
    final lat = session.lat.value;
    final lng = session.lng.value;
    if (!located || lat == null || lng == null) {
      _warn(
        session.locationDenied.value
            ? 'check_in_location_denied'.trFallback('Allow location access to check in')
            : 'check_in_location_off'.trFallback('Turn on location to check in'),
      );
      return;
    }
    try {
      final result = await checkInOrgEvent(_eventId, latitude: lat, longitude: lng);
      final updated = Map<String, dynamic>.from(result['event'] as Map);
      if (!mounted) return;
      Get.back(result: updated);
      flash(
        result['alreadyIn'] == true
            ? 'check_in_already'.trFallback('Already checked in')
            : 'event_checked_in'.trFallback('Checked in'),
        '${updated['title'] ?? ''}',
      );
    } catch (e, stack) {
      AppLog.error('Event QR check-in failed', error: e, stack: stack, tag: 'EVENTS');
      _warn(apiErrorMessage(e));
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
                  errorBuilder: (context, error) => _ScanError(error: error),
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
                                '${widget.event['title'] ?? ''}'.trim().isEmpty
                                    ? 'event_check_in'.trFallback('Check in')
                                    : '${widget.event['title']}',
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17),
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
                          'event_scan_hint'.trFallback("Scan the host's QR at the venue to check in"),
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

class _ScanError extends StatelessWidget {
  const _ScanError({required this.error});
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
                    ? 'camera_needed_event'.trFallback('Allow camera access to scan the event QR.')
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
