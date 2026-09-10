import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/api_error.dart';
import '../../core/utils/app_log.dart';
import '../../core/widgets/ui.dart';
import 'session_controller.dart';

void showProfilePhotoSheet({void Function(String path, String url)? onUploaded}) {
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
            Row(
              children: [
                DisplayText('add_photo'.tr, size: 17),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 2),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'photo_help'.tr,
                style: const TextStyle(color: AppColors.ink3, fontSize: 12, height: 1.3),
              ),
            ),
            const SizedBox(height: 12),
            _PhotoSourceTile(
              icon: Icons.photo_camera_outlined,
              color: const Color(0xFF1B8A6A),
              wash: AppColors.okBg,
              title: 'camera'.tr,
              subtitle: 'camera_sub'.tr,
              onTap: () => _pick(ImageSource.camera, onUploaded),
            ),
            const SizedBox(height: 8),
            _PhotoSourceTile(
              icon: Icons.photo_library_outlined,
              color: const Color(0xFFE8792E),
              wash: AppColors.warnBg,
              title: 'gallery'.tr,
              subtitle: 'gallery_sub'.tr,
              onTap: () => _pick(ImageSource.gallery, onUploaded),
            ),
          ],
        ),
      ),
    ),
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
  );
}

class _PhotoSourceTile extends StatelessWidget {
  const _PhotoSourceTile({
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

Future<void> _pick(ImageSource source, void Function(String path, String url)? onUploaded) async {
  Get.back();
  final picked = await ImagePicker().pickImage(source: source, imageQuality: 85);
  if (picked == null) return;
  try {
    final dir = await getApplicationDocumentsDirectory();
    final target = '${dir.path}/rpd_profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final compressed = await FlutterImageCompress.compressAndGetFile(
      picked.path,
      target,
      quality: 70,
      minWidth: 1024,
      minHeight: 1024,
      format: CompressFormat.jpeg,
    );
    var filePath = compressed?.path ?? picked.path;
    if (!filePath.startsWith(dir.path)) {
      await File(filePath).copy(target);
      filePath = target;
    }
    final url = await Get.find<SessionController>().uploadProfilePhoto(filePath);
    if (url.isNotEmpty) onUploaded?.call(filePath, url);
  } catch (e, stack) {
    AppLog.error('Profile photo upload failed', error: e, stack: stack, tag: 'PHOTO');
    Get.snackbar('Error', apiErrorMessage(e));
  }
}
