import 'dart:math';

int haversineMetres(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371000.0;
  final dLat = _rad(lat2 - lat1);
  final dLng = _rad(lng2 - lng1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
  return (2 * r * asin(min(1, sqrt(a)))).round();
}

double _rad(double d) => d * pi / 180;

String formatMetres(int? metres) {
  if (metres == null) return '';
  if (metres < 1000) return '$metres m';
  return '${(metres / 1000).toStringAsFixed(1)} km';
}
