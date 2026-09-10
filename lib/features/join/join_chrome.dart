import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/ui.dart';

class VerifyPage extends StatelessWidget {
  const VerifyPage({
    super.key,
    required this.step,
    required this.total,
    required this.eyebrow,
    required this.title,
    required this.lede,
    required this.children,
    this.onBack,
    this.onSaveExit,
  });

  final int step;
  final int total;
  final String eyebrow;
  final String title;
  final String lede;
  final List<Widget> children;
  final VoidCallback? onBack;
  final VoidCallback? onSaveExit;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VerifyColors.cream,
      resizeToAvoidBottomInset: true,
      appBar: VerificationAppBar(
        title: 'verification_title'.trFallback('Verification'),
        step: 'step_of'.trParams({'current': '$step', 'total': '$total'}),
        onBack: onBack ?? (step > 1 ? Get.back : null),
        actions: [
          if (onSaveExit != null)
            TextButton(
              onPressed: onSaveExit,
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: Text('save_exit'.trFallback('Save & exit'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          StepBar(total: total, current: step, verification: true),
          const SizedBox(height: 18),
          Text(
            eyebrow.toUpperCase(),
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: VerifyColors.orange,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: VerifyColors.ink,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            lede,
            style: const TextStyle(fontSize: 12.5, color: VerifyColors.gray, height: 1.4),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}

class VerifyButton extends StatelessWidget {
  const VerifyButton(this.label, {super.key, required this.onTap, this.enabled = true, this.orange = false});
  final String label;
  final VoidCallback? onTap;
  final bool enabled;
  final bool orange;

  @override
  Widget build(BuildContext context) {
    final colors = orange
        ? const [VerifyColors.orange, VerifyColors.orangeSoft]
        : const [VerifyColors.purple, VerifyColors.deep];
    final shadow = orange ? const Color(0x59F2760F) : const Color(0x596C2FA0);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            height: 50,
            decoration: BoxDecoration(
              gradient: enabled ? LinearGradient(colors: colors) : null,
              color: enabled ? null : VerifyColors.line,
              borderRadius: BorderRadius.circular(14),
              boxShadow: enabled ? [BoxShadow(color: shadow, blurRadius: 18, offset: const Offset(0, 8))] : null,
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: enabled ? Colors.white : VerifyColors.gray,
                  fontWeight: FontWeight.w800,
                  fontSize: 14.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class VerifyCheckCard extends StatelessWidget {
  const VerifyCheckCard({
    super.key,
    required this.label,
    required this.checked,
    required this.onTap,
    this.tag,
  });

  final String label;
  final bool checked;
  final VoidCallback onTap;
  final String? tag;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: VerifyColors.line, width: 1.5),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 19,
                  height: 19,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(
                    color: checked ? VerifyColors.purple : Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: checked ? VerifyColors.purple : VerifyColors.soft, width: 2),
                  ),
                  child: checked ? const Icon(Icons.check_rounded, size: 13, color: Colors.white) : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: const TextStyle(fontSize: 12.5, color: VerifyColors.ink, height: 1.4)),
                      if (tag != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(tag!, style: const TextStyle(fontSize: 9.5, color: VerifyColors.gray)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class VerifyInfoBox extends StatelessWidget {
  const VerifyInfoBox({super.key, required this.title, required this.paragraphs});
  final String title;
  final List<String> paragraphs;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: const Border.fromBorderSide(BorderSide(color: VerifyColors.line, width: 1.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: VerifyColors.ink)),
          const SizedBox(height: 8),
          for (var i = 0; i < paragraphs.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == paragraphs.length - 1 ? 0 : 10),
              child: Text(paragraphs[i], style: const TextStyle(fontSize: 11.5, color: VerifyColors.gray, height: 1.55)),
            ),
        ],
      ),
    );
  }
}

extension VerifyTr on String {
  String trFallback(String fallback) {
    final value = tr;
    return value == this ? fallback : value;
  }
}
