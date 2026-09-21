import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/api_error.dart';
import '../../core/utils/app_log.dart';
import '../../core/utils/local_image.dart';
import '../../core/widgets/place_field.dart';
import '../../core/widgets/ui.dart';
import '../../data/local/hive_service.dart';
import '../../data/remote/api_client.dart';
import '../session/session_controller.dart';
import '../../core/widgets/flash.dart';

class ActivityCaptureController extends GetxController {
  ActivityCaptureController(this.type);
  final String type;

  final hive = Get.find<HiveService>();
  final session = Get.find<SessionController>();
  final place = TextEditingController();
  /// Coordinates of the address picked from suggestions (the member's own GPS is sent separately).
  double? placeLat;
  double? placeLng;
  final photoPath = Rxn<String>();
  final capturedAt = DateTime.now().obs;
  final locating = false.obs;
  final submitting = false.obs;

  String get purposeLabel => 'activity_$type'.tr;

  @override
  void onInit() {
    super.onInit();
    refreshLocation();
  }

  @override
  void onClose() {
    place.dispose();
    super.onClose();
  }

  void onPlacePicked(PlaceSuggestion place) {
    placeLat = place.latitude;
    placeLng = place.longitude;
  }

  Future<void> refreshLocation() async {
    locating.value = true;
    capturedAt.value = DateTime.now();
    await session.captureLocation();
    locating.value = false;
  }

  Future<void> addPhoto(ImageSource source) async {
    try {
      final path = await pickImageToAppDir(source, prefix: 'rpd_activity');
      if (path == null) return;
      photoPath.value = path;
      capturedAt.value = DateTime.now();
    } catch (e, stack) {
      AppLog.error('Activity photo failed', error: e, stack: stack, tag: 'ACTIVITY');
      flash('Error', apiErrorMessage(e));
    }
  }

  void removePhoto() {
    photoPath.value = null;
  }

  Future<void> submit() async {
    if (photoPath.value == null) {
      flash('Error', 'photo_required_activity'.tr);
      return;
    }
    if (place.text.trim().length < 2) {
      flash('Error', 'place_name_required'.tr);
      return;
    }
    submitting.value = true;
    try {
      if (session.lat.value == null || session.lng.value == null) {
        await refreshLocation();
      }
      final id = const Uuid().v4();
      final booth = session.member?['booth'] as Map?;
      final boothId = booth?['id'] ?? hive.draft.get('boothId');
      final row = {
        'id': id,
        'clientUuid': id,
        'type': type,
        'title': purposeLabel,
        'placeName': place.text.trim(),
        if (placeLat != null) 'placeLatitude': placeLat,
        if (placeLng != null) 'placeLongitude': placeLng,
        'notes': place.text.trim(),
        'photoPaths': [photoPath.value],
        'photoPath': photoPath.value,
        'createdAt': capturedAt.value.toIso8601String(),
        'occurredAt': capturedAt.value.toUtc().toIso8601String(),
        'latitude': session.lat.value,
        'longitude': session.lng.value,
        if (boothId != null) 'boothId': boothId,
        'status': 'SAVED_LOCAL',
      };
      await hive.enqueueSync(row);
      session.syncCount.value = hive.pendingSync().length;
      try {
        await Get.find<ApiClient>().post('/activities', data: {
          'clientUuid': id,
          'type': type,
          if (boothId != null) 'boothId': boothId,
          'occurredAt': capturedAt.value.toUtc().toIso8601String(),
          'notes': place.text.trim(),
          if (session.lat.value != null) 'latitude': session.lat.value,
          if (session.lng.value != null) 'longitude': session.lng.value,
        });
        await hive.removeSync(id);
        session.syncCount.value = hive.pendingSync().length;
      } catch (e, stack) {
        AppLog.error('Activity upload failed, kept in sync queue', error: e, stack: stack, tag: 'ACTIVITY');
        flash('Error', apiErrorMessage(e));
      }
      await session.loadHome();
      Get.offNamed(Routes.activitySaved);
      Future<void>.delayed(const Duration(milliseconds: 250), () {
        flash(
          'activity_saved'.tr,
          'activity_saved_sub'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.ok,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 10,
        );
      });
    } catch (e, stack) {
      AppLog.error('Activity save failed', error: e, stack: stack, tag: 'ACTIVITY');
      flash('Error', apiErrorMessage(e));
    } finally {
      submitting.value = false;
    }
  }
}

class ActivityDetailsView extends StatefulWidget {
  const ActivityDetailsView({super.key});

  @override
  State<ActivityDetailsView> createState() => _ActivityDetailsViewState();
}

class _ActivityDetailsViewState extends State<ActivityDetailsView> {
  late final ActivityCaptureController c;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<ActivityCaptureController>()) {
      Get.delete<ActivityCaptureController>(force: true);
    }
    c = Get.put(ActivityCaptureController((Get.arguments as String?) ?? 'MEETING'));
  }

  @override
  void dispose() {
    if (Get.isRegistered<ActivityCaptureController>()) {
      Get.delete<ActivityCaptureController>(force: true);
    }
    super.dispose();
  }

  void _openPhotoSheet({bool replace = false}) {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          decoration: const BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: AppColors.rule2, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: DisplayText(replace ? 'replace'.tr : 'add_activity_photo'.tr, size: 17),
              ),
              const SizedBox(height: 12),
              _SourceRow(
                icon: Icons.photo_camera_outlined,
                color: const Color(0xFF1B8A6A),
                wash: AppColors.okBg,
                title: 'camera'.tr,
                subtitle: 'camera_sub'.tr,
                onTap: () {
                  Get.back();
                  c.addPhoto(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
              _SourceRow(
                icon: Icons.photo_library_outlined,
                color: const Color(0xFFE8792E),
                wash: AppColors.warnBg,
                title: 'gallery'.tr,
                subtitle: 'gallery_sub'.tr,
                onTap: () {
                  Get.back();
                  c.addPhoto(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!Get.find<SessionController>().guardVerifiedAccess()) {
      return Scaffold(appBar: AppBar(title: Text('what_did_you'.tr)), body: const SizedBox.shrink());
    }
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: HomeColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(c.purposeLabel),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: HomeColors.navy,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          AppCard(
            tone: CardTone.brand,
            child: CardTitle('activity_purpose'.tr, sub: c.purposeLabel),
          ),
          Obx(() {
            final path = c.photoPath.value;
            return AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CardTitle('add_activity_photo'.tr, sub: 'add_activity_photo_sub'.tr),
                  const SizedBox(height: 10),
                  if (path == null)
                    InkWell(
                      onTap: _openPhotoSheet,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 168,
                        width: double.infinity,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.brandWash,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.rule2),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add_a_photo_outlined, color: AppColors.brand, size: 30),
                            const SizedBox(height: 8),
                            Text('add_activity_photo'.tr, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(File(path), height: 200, width: double.infinity, fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => _openPhotoSheet(replace: true),
                          icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                          label: Text('replace'.tr),
                        ),
                        TextButton.icon(
                          onPressed: c.removePhoto,
                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: HomeColors.orange),
                          label: Text('remove'.tr, style: const TextStyle(color: HomeColors.orange)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }),
          Obx(
            () => AppCard(
              child: CardTitle(
                'captured_at'.tr,
                sub: DateFormat('dd MMM yyyy · hh:mm a').format(c.capturedAt.value.toLocal()),
              ),
            ),
          ),
          Obx(() {
            final lat = c.session.lat.value;
            final lng = c.session.lng.value;
            final denied = c.session.locationDenied.value;
            final locating = c.locating.value;
            final sub = locating
                ? 'location_waiting'.tr
                : denied || lat == null || lng == null
                    ? 'location_denied'.tr
                    : 'lat_lng'.trParams({
                        'lat': lat.toStringAsFixed(6),
                        'lng': lng.toStringAsFixed(6),
                      });
            return AppCard(
              onTap: c.refreshLocation,
              child: CardTitle('location_label'.tr, sub: sub),
            );
          }),
          PlaceSuggestionsField(
            controller: c.place,
            onSelected: c.onPlacePicked,
            child: AppField(
              label: 'place_name'.tr,
              controller: c.place,
              hint: 'place_name_hint'.tr,
              icon: Icons.place_outlined,
            ),
          ),
          Obx(
            () => PrimaryButton(
              c.submitting.value ? '…' : 'submit_activity'.tr,
              enabled: !c.submitting.value,
              onTap: c.submit,
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({
    required this.icon,
    required this.color,
    required this.wash,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final Color wash;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card2,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.rule),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: wash, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    Text(subtitle, style: const TextStyle(color: AppColors.ink3, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }
}

class ActivityConfirmView extends StatelessWidget {
  const ActivityConfirmView({super.key});

  @override
  Widget build(BuildContext context) {
    final args = (Get.arguments as Map?) ?? {};
    final session = Get.find<SessionController>();
    final booth = session.member?['booth'] as Map?;
    return Scaffold(
      appBar: AppBar(title: Text('booth_meeting'.tr)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const StepBar(total: 3, current: 3),
          Container(
            height: 110,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: AppColors.sunk, borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Icon(Icons.place, color: AppColors.brandLight, size: 32)),
          ),
          AppCard(tone: CardTone.ok, child: CardTitle('● 180 m from ${booth?['code'] ?? 'B045'}', sub: 'Within the normal range for this booth.')),
          AppCard(child: CardTitle('Who was there · 14', sub: '12 chosen from your booth list, 2 added by name')),
          AppCard(tone: CardTone.flat, child: CardTitle('2 photos attached', sub: 'Wide shot and selfie · 620 KB total')),
          PrimaryButton('save_meeting'.tr, onTap: () async {
            final hive = Get.find<HiveService>();
            final id = const Uuid().v4();
            final item = {
              'id': id,
              'type': args['type'] ?? 'MEETING',
              'title': 'Booth meeting',
              'createdAt': DateTime.now().toIso8601String(),
              'size': '620 KB',
            };
            await hive.enqueueSync(item);
            session.syncCount.value = hive.pendingSync().length;
            try {
              final boothId = booth?['id'] ?? hive.draft.get('boothId');
              await Get.find<ApiClient>().post('/activities', data: {
                'clientUuid': id,
                'type': args['type'] ?? 'MEETING',
                if (boothId != null) 'boothId': boothId,
                'occurredAt': DateTime.now().toUtc().toIso8601String(),
                'notes': args['notes'],
                if (session.lat.value != null) 'latitude': session.lat.value,
                if (session.lng.value != null) 'longitude': session.lng.value,
                'attendeeNames': ['Guest 1', 'Guest 2'],
              });
              await session.loadHome();
              await hive.removeSync(id);
              session.syncCount.value = hive.pendingSync().length;
            } catch (e, stack) {
              AppLog.error('Activity upload failed, kept in sync queue', error: e, stack: stack, tag: 'ACTIVITY');
              flash('Error', apiErrorMessage(e));
            }
            Get.offNamed(Routes.activitySaved);
          }),
          const SizedBox(height: 8),
          Text('saved_phone'.tr, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.ink3, fontSize: 12)),
        ],
      ),
    );
  }
}

class ActivitySavedView extends StatelessWidget {
  const ActivitySavedView({super.key});

  @override
  Widget build(BuildContext context) {
    final n = Get.find<SessionController>().syncCount.value;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(color: AppColors.okBg, shape: BoxShape.circle),
              child: const Icon(Icons.check, color: AppColors.ok, size: 32),
            ),
            const SizedBox(height: 16),
            DisplayText('activity_saved'.tr, center: true),
            const SizedBox(height: 8),
            Text('activity_saved_sub'.tr, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.ink3)),
            const SizedBox(height: 16),
            AppCard(child: CardTitle('waiting_upload'.tr, sub: '$n items in the queue')),
            AppCard(tone: CardTone.flat, child: CardTitle('25 points pending', sub: 'Added once your Mandal President verifies this meeting.')),
            PrimaryButton('record_else'.tr, onTap: () => Get.offAllNamed(Routes.shell)),
            const SizedBox(height: 8),
            PrimaryButton('back_home'.tr, ghost: true, onTap: () => Get.offAllNamed(Routes.shell)),
          ],
        ),
      ),
    );
  }
}

class ActivityRejectedView extends StatelessWidget {
  const ActivityRejectedView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('booth_meeting'.tr)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(tone: CardTone.bad, child: CardTitle('▲ ${'not_verified'.tr}', sub: 'Your Mandal President could not accept this one.')),
          const AppCard(
            child: CardTitle(
              'Reason given',
              sub:
                  '"This photograph was also submitted for the meeting on 22 August. Please attach a photo from this meeting."\n— Rajesh Sharma, Mandal President, 29 Aug',
            ),
          ),
          AppCard(tone: CardTone.flat, child: CardTitle('No points were deducted', sub: 'Deductions apply only to repeated cases. Correct it and resubmit.')),
          PrimaryButton('add_correct_photo'.tr, onTap: () => Get.toNamed(Routes.activityDetails)),
          const SizedBox(height: 8),
          PrimaryButton('i_disagree'.tr, ghost: true, onTap: () {}),
        ],
      ),
    );
  }
}
