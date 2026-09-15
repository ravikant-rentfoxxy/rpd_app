import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rpd_app/features/join/join_chrome.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/flash.dart';

Future<void> showPostSummarySheet({
  required BuildContext context,
  required String summary,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _PostSummarySheet(summary: summary),
  );
}

class _PostSummarySheet extends StatelessWidget {
  const _PostSummarySheet({required this.summary});
  final String summary;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: summary));
    flash('OK', 'summary_copied'.trFallback('Summary copied'));
  }

  Future<void> _share(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        text: summary,
        subject: 'post_summary'.trFallback('X post draft'),
        sharePositionOrigin: box == null ? Rect.zero : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + inset),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: const Color(0xFFD8D0C4), borderRadius: BorderRadius.circular(99)),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'post_summary'.trFallback('X post draft'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: HomeColors.ink),
                ),
                const SizedBox(height: 6),
                Text(
                  'summary_x_hint'.trFallback('Ready to copy or share on X with department tags.'),
                  style: const TextStyle(fontSize: 13, color: HomeColors.muted),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.45),
                  child: SingleChildScrollView(
                    child: Text(
                      summary,
                      style: const TextStyle(fontSize: 15, height: 1.45, color: HomeColors.ink),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _copy(context),
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: Text('copy_summary'.trFallback('Copy')),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: HomeColors.navy,
                          side: const BorderSide(color: HomeColors.border),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _share(context),
                        icon: const Icon(Icons.ios_share_rounded, size: 18),
                        label: Text('share_summary'.trFallback('Share')),
                        style: FilledButton.styleFrom(
                          backgroundColor: HomeColors.orange,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
