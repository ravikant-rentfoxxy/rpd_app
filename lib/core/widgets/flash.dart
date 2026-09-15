import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_colors.dart';

Flushbar<dynamic>? _active;

Future<void> closeFlash() async {
  await _active?.dismiss();
  _active = null;
  if (Get.isSnackbarOpen) Get.closeAllSnackbars();
}

void flash(
  String title,
  String message, {
  SnackPosition? snackPosition,
  Color? backgroundColor,
  Color? colorText,
  EdgeInsets? margin,
  double? borderRadius,
  Duration? duration,
}) {
  final ctx = Get.overlayContext ?? Get.context;
  if (ctx == null) return;

  final error = title.toLowerCase() == 'error' || backgroundColor == AppColors.bad;
  final success = backgroundColor == AppColors.ok || title.toLowerCase() == 'ok';
  final bg = backgroundColor ?? (error ? AppColors.bad : success ? AppColors.ok : HomeColors.navy);
  final fg = colorText ?? Colors.white;
  final icon = error
      ? Icons.error_outline_rounded
      : success
          ? Icons.check_circle_outline_rounded
          : Icons.info_outline_rounded;

  closeFlash();
  _active = Flushbar<dynamic>(
    titleText: title.trim().isEmpty
        ? null
        : Text(
            title,
            style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 14, height: 1.2),
          ),
    messageText: Text(
      message,
      style: TextStyle(color: fg.withValues(alpha: 0.94), fontWeight: FontWeight.w600, fontSize: 13, height: 1.35),
    ),
    icon: Icon(icon, color: fg, size: 26),
    shouldIconPulse: true,
    flushbarPosition: FlushbarPosition.TOP,
    flushbarStyle: FlushbarStyle.FLOATING,
    backgroundColor: bg,
    margin: margin ?? const EdgeInsets.fromLTRB(12, 10, 12, 0),
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
    borderRadius: BorderRadius.circular(borderRadius ?? 14),
    duration: duration ?? const Duration(seconds: 3),
    animationDuration: const Duration(milliseconds: 340),
    forwardAnimationCurve: Curves.easeOutCubic,
    reverseAnimationCurve: Curves.easeInCubic,
    isDismissible: true,
    dismissDirection: FlushbarDismissDirection.HORIZONTAL,
    boxShadows: [
      BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 18, offset: const Offset(0, 8)),
    ],
  )..show(ctx);
}
