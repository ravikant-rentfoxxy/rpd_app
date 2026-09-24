/// The recruiting code a member hands out.
///
/// It is derived from the membership number rather than stored, so it can be
/// worked out on the phone with nothing from the server — the backend computes
/// the same eight characters the same way when someone enters it. Two screens
/// show it, the membership card and the refer card, and they have to agree: a
/// second copy of this that drifted would send people a code that credits
/// nobody.
library;

/// No I, O, 0 or 1 — these get read off a card and typed by hand.
const _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

/// Eight characters from the membership number, or the id when a member has no
/// number yet. Empty when there is nothing to derive one from, which the caller
/// shows as a dash rather than an empty box.
String inviteCodeOf(Map<String, dynamic>? member) {
  if (member == null) return '';
  final stored = '${member['inviteCode'] ?? ''}'.trim();
  if (stored.isNotEmpty) return stored;

  final number = '${member['membershipNumber'] ?? ''}'.trim();
  final source = number.isNotEmpty ? number : '${member['id'] ?? ''}'.trim();
  if (source.isEmpty) return '';

  var hash = 0;
  for (final unit in source.codeUnits) {
    hash = (hash * 31 + unit) & 0xFFFFFFFF;
  }
  final chars = StringBuffer();
  for (var i = 0; i < 8; i += 1) {
    chars.write(_alphabet[hash % _alphabet.length]);
    hash = (hash * 1664525 + 1013904223) & 0xFFFFFFFF;
  }
  return chars.toString();
}
