/// The seven figures the home sector panel and its 2x2 grid are drawn from.
/// The server computes them over the member's own district; a member the server
/// has not answered for yet gets zeros rather than an empty screen.
class DistrictSnapshot {
  const DistrictSnapshot({
    this.members = 0,
    this.joinedToday = 0,
    this.groundActive = 0,
    this.urgentIssues = 0,
    this.resolutionRate = 0,
    this.plottedIncidents = 0,
    this.verifiedNearby = 0,
  });

  final int members;
  final int joinedToday;
  final int groundActive;
  final int urgentIssues;
  final int resolutionRate;
  final int plottedIncidents;
  final int verifiedNearby;

  static int _int(Object? raw) {
    if (raw is num) return raw.round();
    return int.tryParse('${raw ?? ''}') ?? 0;
  }

  factory DistrictSnapshot.fromJson(Object? raw) {
    if (raw is! Map) return const DistrictSnapshot();
    final json = Map<String, dynamic>.from(raw);
    return DistrictSnapshot(
      members: _int(json['members']),
      joinedToday: _int(json['joinedToday']),
      groundActive: _int(json['groundActive']),
      urgentIssues: _int(json['urgentIssues']),
      resolutionRate: _int(json['resolutionRate']),
      plottedIncidents: _int(json['plottedIncidents']),
      verifiedNearby: _int(json['verifiedNearby']),
    );
  }
}

/// 1284 written 1,284 — field staff read the Indian separator, and the grid has
/// to stay legible at a glance.
String groupIndian(int value) {
  final digits = value.abs().toString();
  final sign = value < 0 ? '-' : '';
  if (digits.length <= 3) return '$sign$digits';
  final last3 = digits.substring(digits.length - 3);
  var rest = digits.substring(0, digits.length - 3);
  final chunks = <String>[];
  while (rest.length > 2) {
    chunks.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) chunks.insert(0, rest);
  return '$sign${chunks.join(',')},$last3';
}
