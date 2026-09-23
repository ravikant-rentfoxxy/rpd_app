import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../features/session/session_controller.dart';
import '../theme/app_colors.dart';

const _languages = [
  ('hi', 'HI'),
  ('en', 'EN'),
  ('bho', 'BHO'),
];

class LanguageDropdown extends StatelessWidget {
  const LanguageDropdown({super.key, this.onDark = false, this.pill = false});
  final bool onDark;
  final bool pill;

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionController>();
    if (pill) return _Pill(session: session, onDark: onDark);
    final fg = onDark ? Colors.white : AppColors.ink2;
    return Container(
      padding: const EdgeInsets.only(left: 8, right: 4),
      decoration: BoxDecoration(
        color: onDark ? Colors.black.withValues(alpha: 0.35) : AppColors.card,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: onDark ? Colors.white.withValues(alpha: 0.4) : AppColors.rule2),
      ),
      child: Obx(
        () => DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selected(session.localeCode.value),
            isDense: true,
            dropdownColor: onDark ? const Color(0xFF1B1630) : AppColors.card,
            icon: Icon(Icons.expand_more, color: fg, size: 18),
            style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w700),
            selectedItemBuilder: (context) => [
              for (final (_, label) in _languages)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.language, color: fg, size: 16),
                    const SizedBox(width: 6),
                    Text(label, style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w700)),
                  ],
                ),
            ],
            items: [
              for (final (code, label) in _languages)
                DropdownMenuItem(
                  value: code,
                  child: Row(
                    children: [
                      Icon(Icons.language, size: 16, color: onDark ? Colors.white : AppColors.brand),
                      const SizedBox(width: 8),
                      Text(label, style: TextStyle(color: onDark ? Colors.white : AppColors.ink, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
            ],
            onChanged: (code) {
              if (code != null) session.applyLocale(code);
            },
          ),
        ),
      ),
    );
  }

  String _selected(String? locale) {
    if (locale == 'hi' || locale == 'en' || locale == 'bho') return locale!;
    return 'en';
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.session, this.onDark = true});
  final SessionController session;

  /// The pill sits on the navy hero by default; the white app bar needs ink.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final current = _languages.firstWhere(
        (e) => e.$1 == session.localeCode.value,
        orElse: () => _languages[1],
      );
      return PopupMenuButton<String>(
        tooltip: 'choose_language'.tr,
        onSelected: session.applyLocale,
        color: Colors.white,
        offset: const Offset(0, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        itemBuilder: (context) => [
          for (final (code, label) in _languages)
            PopupMenuItem(
              value: code,
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: HomeColors.ink)),
            ),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            border: Border.all(color: onDark ? HomeColors.navyLine : HomeColors.border),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.language_rounded, size: 13, color: onDark ? Colors.white : HomeColors.muted),
              const SizedBox(width: 4),
              Text(
                current.$2,
                style: TextStyle(
                  color: onDark ? Colors.white : HomeColors.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
