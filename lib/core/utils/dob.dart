import 'package:flutter/services.dart';

String _pad2(int n) => n.toString().padLeft(2, '0');

String dateToIso(DateTime date) => '${date.year}-${_pad2(date.month)}-${_pad2(date.day)}';

String dateToDisplay(DateTime date) => '${_pad2(date.day)}-${_pad2(date.month)}-${date.year}';

String dobToIso(String raw) {
  final value = raw.trim();
  if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return value;
  final dmy = RegExp(r'^(\d{2})-(\d{2})-(\d{4})$').firstMatch(value);
  if (dmy != null) return '${dmy.group(3)}-${dmy.group(2)}-${dmy.group(1)}';
  return formatDobInput(value);
}

String formatDobDisplay(String raw) {
  final iso = dobToIso(raw);
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(iso);
  if (match == null) return raw.trim();
  return '${match.group(3)}-${match.group(2)}-${match.group(1)}';
}

String formatDobInput(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  final clipped = digits.length > 8 ? digits.substring(0, 8) : digits;
  final buffer = StringBuffer();
  for (var i = 0; i < clipped.length; i++) {
    if (i == 4 || i == 6) buffer.write('-');
    buffer.write(clipped[i]);
  }
  return buffer.toString();
}

DateTime dobLastSelectableDate([DateTime? now]) {
  final n = now ?? DateTime.now();
  return DateTime(n.year - 18, n.month, n.day);
}

DateTime dobFirstSelectableDate([DateTime? now]) {
  final n = now ?? DateTime.now();
  return DateTime(n.year - 120, n.month, n.day);
}

DateTime dobInitialDate(String raw) {
  final last = dobLastSelectableDate();
  final first = dobFirstSelectableDate();
  final parsed = parseDobDate(raw);
  if (parsed != null && !parsed.isAfter(last) && !parsed.isBefore(first)) return parsed;
  return DateTime(last.year - 7, last.month, last.day);
}

bool isValidDob(String value) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(dobToIso(value));
  if (match == null) return false;
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  final date = DateTime(year, month, day);
  if (date.year != year || date.month != month || date.day != day) return false;
  if (date.isAfter(dobLastSelectableDate())) return false;
  if (date.isBefore(dobFirstSelectableDate())) return false;
  return true;
}

DateTime? parseDobDate(String raw) {
  if (!isValidDob(raw)) return null;
  final parts = dobToIso(raw).split('-');
  return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
}

class DobInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = formatDobInput(newValue.text);
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}
