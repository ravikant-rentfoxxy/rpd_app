import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class PartyMark extends StatelessWidget {
  const PartyMark({super.key, this.size = 62, this.onBrand = false});
  final double size;
  final bool onBrand;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.24),
      child: Image.asset(
        'assets/images/app_logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.tone = CardTone.plain,
    this.onTap,
    this.margin,
  });
  final Widget child;
  final CardTone tone;
  final VoidCallback? onTap;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    final Color bg = switch (tone) {
      CardTone.plain => AppColors.card,
      CardTone.flat => AppColors.sunk,
      CardTone.brand => AppColors.brandWash,
      CardTone.ok => AppColors.okBg,
      CardTone.warn => AppColors.warnBg,
      CardTone.bad => AppColors.badBg,
    };
    return Padding(
      padding: margin ?? const EdgeInsets.only(bottom: 10),
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpace.cardRadius)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpace.cardRadius),
          child: Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 14), child: child),
        ),
      ),
    );
  }
}

enum CardTone { plain, flat, brand, ok, warn, bad }

class CardTitle extends StatelessWidget {
  const CardTitle(this.title, {super.key, this.sub});
  final String title;
  final String? sub;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, height: 1.35)),
        if (sub != null) ...[
          const SizedBox(height: 2),
          Text(sub!, style: const TextStyle(fontSize: 12, color: AppColors.ink3, height: 1.4)),
        ],
      ],
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton(this.label, {super.key, required this.onTap, this.enabled = true, this.ghost = false});
  final String label;
  final VoidCallback? onTap;
  final bool enabled;
  final bool ghost;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ghost
          ? OutlinedButton(
              onPressed: enabled ? onTap : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.ink2,
                side: const BorderSide(color: AppColors.rule2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              ),
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            )
          : FilledButton(
              onPressed: enabled ? onTap : null,
              style: FilledButton.styleFrom(
                backgroundColor: enabled ? HomeColors.orange : AppColors.rule2,
                foregroundColor: enabled ? Colors.white : AppColors.ink4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              ),
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
    );
  }
}

/// Full-screen scrim with a spinner, for screens that must block input while a
/// request runs.
///
/// Goes last in the screen's root [Stack], which must use [StackFit.expand].
/// It deliberately avoids [Positioned]: call sites wrap this in an `Obx`, and a
/// positioned widget has to be a direct child of the Stack to lay out at all.
class ScreenLoader extends StatelessWidget {
  const ScreenLoader({super.key, this.visible = true, this.message, this.onDark = true});
  final bool visible;
  final String? message;

  /// Light spinner and text, for the navy login screens.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    final fg = onDark ? Colors.white : AppColors.ink;
    // Swallows every tap underneath while the request runs.
    return AbsorbPointer(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: onDark ? 0.55 : 0.35),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 42,
                height: 42,
                child: CircularProgressIndicator(strokeWidth: 3, color: fg),
              ),
              if (message != null && message!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: fg, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class AppField extends StatelessWidget {
  const AppField({
    super.key,
    required this.label,
    required this.controller,
    this.keyboard,
    this.hint,
    this.mono = false,
    this.prefix,
    this.icon,
    this.suffix,
    this.maxLength,
    this.digitsOnly = false,
    this.formatters,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.maxLines,
    this.verifyStyle = false,
  });
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboard;
  final String? hint;
  final bool mono;
  final String? prefix;
  final IconData? icon;
  final Widget? suffix;
  final int? maxLength;
  final bool digitsOnly;
  final List<TextInputFormatter>? formatters;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final int? maxLines;
  final bool verifyStyle;

  @override
  Widget build(BuildContext context) {
    final textStyle = mono
        ? GoogleFonts.ibmPlexMono(fontSize: 16, color: AppColors.ink)
        : TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: verifyStyle ? VerifyColors.ink : AppColors.ink);
    return Container(
      margin: EdgeInsets.only(bottom: verifyStyle ? 8 : 12),
      padding: EdgeInsets.fromLTRB(12, verifyStyle ? 6 : 10, 12, verifyStyle ? 6 : 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(verifyStyle ? 14 : 12),
        border: Border.all(color: verifyStyle ? VerifyColors.line : AppColors.rule2, width: verifyStyle ? 1.5 : 1),
        boxShadow: verifyStyle
            ? const []
            : const [
                BoxShadow(color: Color(0x0A191424), blurRadius: 8, offset: Offset(0, 2)),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            _FieldIcon(icon!, verifyStyle: verifyStyle),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FieldLabel(
                  verifyStyle ? label.toUpperCase() : label,
                  style: TextStyle(
                    fontSize: verifyStyle ? 10 : 11,
                    fontWeight: FontWeight.w700,
                    color: verifyStyle ? VerifyColors.gray : AppColors.ink3,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (prefix != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.brandWash,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          prefix!.trim(),
                          style: GoogleFonts.ibmPlexMono(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: HomeColors.orange,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: TextField(
                        controller: controller,
                        readOnly: readOnly,
                        onTap: onTap,
                        keyboardType: keyboard ??
                            (maxLines != null && maxLines! > 1
                                ? TextInputType.multiline
                                : (digitsOnly ? TextInputType.number : null)),
                        maxLines: maxLines ?? 1,
                        minLines: maxLines != null && maxLines! > 1 ? 2 : 1,
                        maxLength: maxLength,
                        inputFormatters: [
                          if (digitsOnly) FilteringTextInputFormatter.digitsOnly,
                          if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
                          ...?formatters,
                        ],
                        onChanged: onChanged,
                        style: textStyle,
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          counterText: '',
                          hintText: hint,
                          hintStyle: TextStyle(color: verifyStyle ? const Color(0xFFB3ACB8) : AppColors.ink4, fontWeight: FontWeight.w400),
                        ),
                      ),
                    ),
                    if (suffix != null) ...[
                      const SizedBox(width: 8),
                      GestureDetector(onTap: onTap, child: suffix!),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldIcon extends StatelessWidget {
  const _FieldIcon(this.icon, {this.verifyStyle = false});
  final IconData icon;
  final bool verifyStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: verifyStyle ? 26 : 32,
      height: verifyStyle ? 26 : 32,
      margin: EdgeInsets.only(top: verifyStyle ? 0 : 2),
      decoration: BoxDecoration(
        color: verifyStyle ? VerifyColors.pale : AppColors.brandWash,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, size: verifyStyle ? 14 : 16, color: verifyStyle ? VerifyColors.purple : AppColors.brand),
    );
  }
}

class AppSelect<T> extends StatelessWidget {
  const AppSelect({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
    this.icon,
    this.enabled = true,
    this.loading = false,
    this.verifyStyle = false,
  });

  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? hint;
  final IconData? icon;
  final bool enabled;
  final bool loading;
  final bool verifyStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: verifyStyle ? 8 : 12),
      padding: EdgeInsets.fromLTRB(12, verifyStyle ? 5 : 10, 12, verifyStyle ? 4 : 6),
      decoration: BoxDecoration(
        color: enabled ? AppColors.card : (verifyStyle ? const Color(0xFFF6F1F8) : AppColors.sunk),
        borderRadius: BorderRadius.circular(verifyStyle ? 14 : 12),
        border: Border.all(color: verifyStyle ? VerifyColors.line : AppColors.rule2, width: verifyStyle ? 1.5 : 1),
        boxShadow: verifyStyle
            ? const []
            : const [
                BoxShadow(color: Color(0x0A191424), blurRadius: 8, offset: Offset(0, 2)),
              ],
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            _FieldIcon(icon!, verifyStyle: verifyStyle),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FieldLabel(
                  verifyStyle ? label.toUpperCase() : label,
                  style: TextStyle(
                    fontSize: verifyStyle ? 10 : 11,
                    fontWeight: FontWeight.w700,
                    color: verifyStyle ? VerifyColors.gray : AppColors.ink3,
                  ),
                ),
                DropdownButtonHideUnderline(
                  child: Theme(
                    data: Theme.of(context).copyWith(disabledColor: AppColors.ink),
                    child: DropdownButton<T>(
                      value: value,
                      isExpanded: true,
                      isDense: true,
                      hint: hint == null
                          ? null
                          : Text(hint!, style: TextStyle(color: verifyStyle ? const Color(0xFFB3ACB8) : AppColors.ink4, fontSize: 14)),
                      icon: loading
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: verifyStyle ? VerifyColors.purple : AppColors.brand),
                            )
                          : Icon(Icons.keyboard_arrow_down_rounded, color: verifyStyle ? VerifyColors.gray : AppColors.ink3),
                      items: items,
                      onChanged: enabled && !loading ? onChanged : null,
                      style: const TextStyle(fontSize: 16, color: AppColors.ink),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SearchOption {
  const SearchOption({required this.id, required this.name});
  final String id;
  final String name;
}

class AppSearchSelect extends StatelessWidget {
  const AppSearchSelect({
    super.key,
    required this.label,
    required this.options,
    required this.onChanged,
    this.value,
    this.hint,
    this.searchHint,
    this.emptyHint,
    this.icon,
    this.enabled = true,
    this.loading = false,
    this.verifyStyle = false,
  });

  final String label;
  final List<SearchOption> options;
  final ValueChanged<String?> onChanged;
  final String? value;
  final String? hint;
  final String? searchHint;
  final String? emptyHint;
  final IconData? icon;
  final bool enabled;
  final bool loading;
  final bool verifyStyle;

  String? get _selectedName {
    for (final option in options) {
      if (option.id == value) return option.name;
    }
    return null;
  }

  Future<void> _open(BuildContext context) async {
    if (!enabled || loading) return;
    final picked = await showSearchSelectSheet(
      context: context,
      title: label,
      searchHint: searchHint ?? hint ?? label,
      emptyHint: emptyHint ?? 'No matches',
      options: options,
      selectedId: value,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final name = _selectedName;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled && !loading ? () => _open(context) : null,
        borderRadius: BorderRadius.circular(verifyStyle ? 14 : 12),
        child: Container(
          margin: EdgeInsets.only(bottom: verifyStyle ? 8 : 12),
          padding: EdgeInsets.fromLTRB(12, verifyStyle ? 10 : 12, 12, verifyStyle ? 10 : 12),
          decoration: BoxDecoration(
            color: enabled ? AppColors.card : (verifyStyle ? const Color(0xFFF6F1F8) : AppColors.sunk),
            borderRadius: BorderRadius.circular(verifyStyle ? 14 : 12),
            border: Border.all(color: verifyStyle ? VerifyColors.line : AppColors.rule2, width: verifyStyle ? 1.5 : 1),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                _FieldIcon(icon!, verifyStyle: verifyStyle),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel(
                      verifyStyle ? label.toUpperCase() : label,
                      style: TextStyle(
                        fontSize: verifyStyle ? 10 : 11,
                        fontWeight: FontWeight.w700,
                        color: verifyStyle ? VerifyColors.gray : AppColors.ink3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name ?? hint ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        color: name == null ? (verifyStyle ? const Color(0xFFB3ACB8) : AppColors.ink4) : AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              if (loading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: verifyStyle ? VerifyColors.purple : AppColors.brand),
                )
              else
                Icon(Icons.keyboard_arrow_down_rounded, color: verifyStyle ? VerifyColors.gray : AppColors.ink3),
            ],
          ),
        ),
      ),
    );
  }
}

Future<String?> showSearchSelectSheet({
  required BuildContext context,
  required String title,
  required String searchHint,
  required List<SearchOption> options,
  String? selectedId,
  String emptyHint = 'No matches',
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _SearchSelectSheet(
      title: title,
      searchHint: searchHint,
      emptyHint: emptyHint,
      options: options,
      selectedId: selectedId,
    ),
  );
}

class _SearchSelectSheet extends StatefulWidget {
  const _SearchSelectSheet({
    required this.title,
    required this.searchHint,
    required this.emptyHint,
    required this.options,
    this.selectedId,
  });

  final String title;
  final String searchHint;
  final String emptyHint;
  final List<SearchOption> options;
  final String? selectedId;

  @override
  State<_SearchSelectSheet> createState() => _SearchSelectSheetState();
}

class _SearchSelectSheetState extends State<_SearchSelectSheet> {
  final query = TextEditingController();

  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  List<SearchOption> get _filtered {
    final q = query.text.trim().toLowerCase();
    if (q.isEmpty) return widget.options;
    return widget.options.where((option) => option.name.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    // Sit right on top of the keyboard and take the whole space above it, so the
    // list keeps its room instead of being squeezed into what is left.
    final available = media.size.height - media.padding.top - 12 - keyboard;
    final height = keyboard > 0 ? available : math.min(media.size.height * 0.72, available);
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: AppColors.rule2, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: VerifyColors.ink),
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: query,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                cursorColor: VerifyColors.purple,
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  hintStyle: const TextStyle(color: Color(0xFFB3ACB8)),
                  prefixIcon: const Icon(Icons.search_rounded, color: VerifyColors.purple),
                  filled: true,
                  fillColor: VerifyColors.pale,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        widget.emptyHint,
                        style: const TextStyle(color: AppColors.ink3, fontWeight: FontWeight.w600),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const Divider(height: 1, color: VerifyColors.line),
                      itemBuilder: (context, index) {
                        final option = filtered[index];
                        final selected = option.id == widget.selectedId;
                        return ListTile(
                          title: Text(
                            option.name,
                            style: TextStyle(
                              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                              color: selected ? VerifyColors.purple : AppColors.ink,
                            ),
                          ),
                          trailing: selected ? const Icon(Icons.check_rounded, color: VerifyColors.purple) : null,
                          onTap: () => Navigator.pop(context, option.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppChoiceField extends StatelessWidget {
  const AppChoiceField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.icon,
  });

  final String label;
  final String value;
  final List<(String value, String label)> options;
  final ValueChanged<String> onChanged;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.rule2),
        boxShadow: const [
          BoxShadow(color: Color(0x0A191424), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            _FieldIcon(icon!),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FieldLabel(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.ink3)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (var i = 0; i < options.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(
                        child: _ChoiceChip(
                          label: options[i].$2,
                          selected: options[i].$1 == value,
                          onTap: () => onChanged(options[i].$1),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.brand : AppColors.sunk,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.ink2,
            ),
          ),
        ),
      ),
    );
  }
}

class LoginMobileField extends StatefulWidget {
  const LoginMobileField({
    super.key,
    required this.controller,
    this.readOnly = false,
    this.onChanged,
  });
  final TextEditingController controller;
  final bool readOnly;
  final ValueChanged<String>? onChanged;

  @override
  State<LoginMobileField> createState() => _LoginMobileFieldState();
}

class _LoginMobileFieldState extends State<LoginMobileField> {
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode()..addListener(_rebuild);
    widget.controller.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    _focus.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final digits = widget.controller.text.replaceAll(RegExp(r'\D'), '');
    final remaining = List.filled((10 - digits.length).clamp(0, 10), '•').join();
    return GestureDetector(
      onTap: widget.readOnly ? null : () => _focus.requestFocus(),
      child: Container(
        height: 56,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: Alignment.centerLeft,
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.1,
                  height: 1,
                ),
                children: [
                  const TextSpan(text: '+91 ', style: TextStyle(color: AppColors.ink, letterSpacing: 0.4)),
                  TextSpan(text: digits, style: const TextStyle(color: AppColors.ink)),
                  TextSpan(text: remaining, style: const TextStyle(color: Color(0xFFC8C2B8), fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Positioned.fill(
              child: Opacity(
                opacity: 0,
                child: TextField(
                  focusNode: _focus,
                  controller: widget.controller,
                  readOnly: widget.readOnly,
                  enabled: !widget.readOnly,
                  autofocus: !widget.readOnly,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  onChanged: widget.onChanged,
                  decoration: const InputDecoration(border: InputBorder.none, counterText: ''),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OtpBoxes extends StatefulWidget {
  const OtpBoxes({
    super.key,
    required this.controller,
    this.length = 6,
    this.onChanged,
  });
  final TextEditingController controller;
  final int length;
  final ValueChanged<String>? onChanged;

  @override
  State<OtpBoxes> createState() => _OtpBoxesState();
}

class _OtpBoxesState extends State<OtpBoxes> {
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode()..addListener(_rebuild);
    widget.controller.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    _focus.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final value = widget.controller.text.replaceAll(RegExp(r'\D'), '');
    final active = _focus.hasFocus ? value.length.clamp(0, widget.length - 1) : -1;
    return GestureDetector(
      onTap: () => _focus.requestFocus(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gap = 10.0;
          final size = ((constraints.maxWidth - gap * (widget.length - 1)) / widget.length).clamp(44.0, 56.0);
          return Stack(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(widget.length, (index) {
                  final digit = index < value.length ? value[index] : '';
                  final isActive = index == active;
                  return Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isActive ? HomeColors.orange : Colors.white,
                        width: isActive ? 2 : 0,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      digit,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                        height: 1,
                      ),
                    ),
                  );
                }),
              ),
              Positioned.fill(
                child: Opacity(
                  opacity: 0,
                  child: TextField(
                    focusNode: _focus,
                    controller: widget.controller,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    maxLength: widget.length,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(widget.length),
                    ],
                    onChanged: widget.onChanged,
                    decoration: const InputDecoration(border: InputBorder.none, counterText: ''),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class StepBar extends StatelessWidget {
  const StepBar({super.key, required this.total, required this.current, this.verification = false});
  final int total;
  final int current;
  final bool verification;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: verification ? 0 : 12),
      child: Row(
        children: List.generate(total, (i) {
          final Color color;
          if (verification) {
            if (i < current - 1) {
              color = VerifyColors.orange;
            } else if (i == current - 1) {
              color = VerifyColors.purple;
            } else {
              color = VerifyColors.line;
            }
          } else {
            color = i < current ? AppColors.brandLight : AppColors.rule2;
          }
          return Expanded(
            child: Container(
              height: verification ? 4 : 3,
              margin: EdgeInsets.only(right: i == total - 1 ? 0 : (verification ? 5 : 3)),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class Pill extends StatelessWidget {
  const Pill(this.label, {super.key, this.tone = PillTone.neutral});
  final String label;
  final PillTone tone;
  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (tone) {
      PillTone.ok => (AppColors.okBg, AppColors.ok),
      PillTone.warn => (AppColors.warnBg, AppColors.warn),
      PillTone.bad => (AppColors.badBg, AppColors.bad),
      PillTone.brand => (AppColors.brandWash, AppColors.brandLight),
      PillTone.neutral => (AppColors.sunk, AppColors.ink3),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

enum PillTone { ok, warn, bad, brand, neutral }

class DisplayText extends StatelessWidget {
  const DisplayText(this.text, {super.key, this.size = 19, this.color, this.center = false});
  final String text;
  final double size;
  final Color? color;
  final bool center;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: center ? TextAlign.center : TextAlign.start,
      style: GoogleFonts.bricolageGrotesque(
        fontWeight: FontWeight.w800,
        fontSize: size,
        letterSpacing: -0.6,
        color: color ?? AppColors.ink,
        height: 1.18,
      ),
    );
  }
}

class OrganicAppBar extends StatelessWidget implements PreferredSizeWidget {
  const OrganicAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
  });

  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 8);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: HomeColors.navy,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: automaticallyImplyLeading,
        leading: leading,
        title: Text(
          title,
          style: GoogleFonts.bricolageGrotesque(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        actions: actions,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: HomeColors.navy,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
    );
  }
}

class MonoText extends StatelessWidget {
  const MonoText(this.text, {super.key, this.size = 12, this.color});
  final String text;
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    return Text(text, style: GoogleFonts.ibmPlexMono(fontSize: size, color: color ?? AppColors.ink3));
  }
}

class ScoreBar extends StatelessWidget {
  const ScoreBar({super.key, required this.value, this.color = AppColors.brandLight});
  final double value;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 5,
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(color: AppColors.rule2, borderRadius: BorderRadius.circular(3)),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: value.clamp(0, 1),
        child: DecoratedBox(
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
      ),
    );
  }
}

class AvatarCircle extends StatelessWidget {
  const AvatarCircle(
    this.initials, {
    super.key,
    this.color,
    this.bg,
    this.imageUrl,
    this.radius = 16,
    this.fallbackIcon = false,
  });
  final String initials;
  final Color? color;
  final Color? bg;
  final String? imageUrl;
  final double radius;
  final bool fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final fg = color ?? AppColors.brandLight;
    final fallback = fallbackIcon
        ? Icon(Icons.person, size: radius + 6, color: fg)
        : Text(
            initials,
            style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: radius * 0.7),
          );
    final url = imageUrl?.trim();
    return ClipOval(
      child: ColoredBox(
        color: bg ?? AppColors.brandWash,
        child: SizedBox(
          width: radius * 2,
          height: radius * 2,
          child: url == null || url.isEmpty
              ? Center(child: fallback)
              : Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Center(child: fallback),
                ),
        ),
      ),
    );
  }
}

class VerificationAppBar extends StatelessWidget implements PreferredSizeWidget {
  const VerificationAppBar({
    super.key,
    required this.title,
    this.step,
    this.actions,
    this.onBack,
  });

  final String title;
  final String? step;
  final List<Widget>? actions;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => Size.fromHeight(step == null ? kToolbarHeight : 72);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: VerifyColors.deep,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: step == null ? kToolbarHeight : 72,
      iconTheme: const IconThemeData(color: Colors.white),
      actionsIconTheme: const IconThemeData(color: Colors.white),
      automaticallyImplyLeading: onBack == null,
      leading: onBack == null
          ? null
          : IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'Back',
              onPressed: onBack,
            ),
      title: step == null
          ? Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
                const SizedBox(height: 2),
                Text(
                  step!,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.65)),
                ),
              ],
            ),
      titleSpacing: 4,
      actions: actions,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: VerifyColors.deep,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
  }
}

/// Field label that paints a trailing required marker (" *") in red.
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {required this.style});
  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final trimmed = text.trimRight();
    if (!trimmed.endsWith('*')) return Text(text, style: style);
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: trimmed.substring(0, trimmed.length - 1).trimRight()),
          const TextSpan(text: ' *', style: TextStyle(color: AppColors.bad)),
        ],
      ),
    );
  }
}
