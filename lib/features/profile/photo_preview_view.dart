import 'package:flutter/material.dart';
import 'package:rpd_app/features/join/join_chrome.dart';
import '../../core/theme/app_colors.dart';

/// Shows the member's photo in a dialog with pinch-to-zoom.
Future<void> showProfilePhotoPreview(BuildContext context, {required ImageProvider image}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.8),
    builder: (context) => _PhotoPreviewDialog(image: image),
  );
}

class _PhotoPreviewDialog extends StatelessWidget {
  const _PhotoPreviewDialog({required this.image});
  final ImageProvider image;

  @override
  Widget build(BuildContext context) {
    final maxImageHeight = MediaQuery.sizeOf(context).height * 0.6;
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 6, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'profile_photo'.trFallback('Profile photo'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: HomeColors.ink),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: HomeColors.muted),
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxImageHeight),
            child: ColoredBox(
              color: HomeColors.navyDeep,
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Image(
                  image: image,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  errorBuilder: (_, _, _) => const SizedBox(
                    height: 200,
                    child: Center(child: Icon(Icons.broken_image_outlined, color: Colors.white54, size: 44)),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              'photo_zoom_hint'.trFallback('Pinch to zoom'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.ink3),
            ),
          ),
        ],
      ),
    );
  }
}
