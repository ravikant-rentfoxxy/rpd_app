import 'package:flutter/material.dart';
import 'package:rpd_app/features/join/join_chrome.dart';
import '../../core/theme/app_colors.dart';

Future<T> runWithSummaryLoading<T>(BuildContext context, Future<T> Function() action) async {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    builder: (_) => PopScope(
      canPop: false,
      child: Center(
        child: Material(
          color: Colors.white,
          borderRadius: const BorderRadius.all(Radius.circular(18)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(strokeWidth: 3, color: HomeColors.orange),
                ),
                const SizedBox(height: 16),
                Text(
                  'summary_loading'.trFallback('Creating summary…'),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: HomeColors.ink),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  try {
    return await action();
  } finally {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}
