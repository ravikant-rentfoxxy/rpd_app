import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../constants/endpoints.dart';
import '../theme/app_colors.dart';
import 'iro_ui.dart';

/// A real map of the member's patch, drawn from OpenStreetMap tiles with a pin
/// for every issue post and event that carries a fix.

/// One thing to stand on the map.
class IroMapPin {
  const IroMapPin({
    required this.latitude,
    required this.longitude,
    required this.tone,
    this.icon = Icons.location_on_rounded,
    this.label = '',
    this.onTap,
  });

  final double latitude;
  final double longitude;
  final Color tone;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  LatLng get point => LatLng(latitude, longitude);
}

/// Pulls a pin out of anything carrying `latitude`/`longitude`, which is the
/// shape both serialized posts and serialized events arrive in. Returns null
/// when either is missing, or when the pair is outside the globe — a row with
/// no fix is left off rather than dropped at (0, 0) in the Atlantic.
IroMapPin? pinFrom(
  Object? latitude,
  Object? longitude, {
  required Color tone,
  IconData icon = Icons.location_on_rounded,
  String label = '',
  VoidCallback? onTap,
}) {
  final lat = latitude is num ? latitude.toDouble() : double.tryParse('${latitude ?? ''}');
  final lng = longitude is num ? longitude.toDouble() : double.tryParse('${longitude ?? ''}');
  if (lat == null || lng == null) return null;
  if (lat.abs() > 90 || lng.abs() > 180) return null;
  if (lat == 0 && lng == 0) return null;
  return IroMapPin(latitude: lat, longitude: lng, tone: tone, icon: icon, label: label, onTap: onTap);
}

/// Reads the `{latitude, longitude}` the home payload sends for the member's
/// district. Null when the server could not place it, which leaves the map on
/// its own country-wide fallback.
LatLng? districtCentreFrom(Object? raw) {
  if (raw is! Map) return null;
  final pin = pinFrom(raw['latitude'], raw['longitude'], tone: Iro.green);
  return pin?.point;
}

/// The map panel. Sizes itself to [height], rounds its corners, and lays the
/// caller's chrome over the tiles.
class IroMap extends StatefulWidget {
  const IroMap({
    super.key,
    required this.height,
    this.pins = const [],
    this.overlay = const [],
    this.radius = 16,
    this.fallbackCentre,
    this.fallbackZoom = 11,
    this.allowPan = false,
    this.onTap,
  });

  final double height;
  final List<IroMapPin> pins;

  /// Chips and controls drawn over the tiles, positioned by the caller.
  final List<Widget> overlay;
  final double radius;

  /// Where to look when nothing has a fix yet — the member's own district.
  /// Only if that is unknown too does it fall back to the country.
  final LatLng? fallbackCentre;
  final double fallbackZoom;

  /// False inside a scrolling page, where a drag has to scroll rather than pan.
  /// True on a screen of its own.
  final bool allowPan;

  /// Tapping the panel, for a small map that opens into a big one. Pins keep
  /// their own taps; this is for the space between them.
  final VoidCallback? onTap;

  @override
  State<IroMap> createState() => _IroMapState();
}

class _IroMapState extends State<IroMap> {
  final _controller = MapController();

  /// The box every pin fits inside, or null when there is nothing to frame.
  LatLngBounds? get _bounds {
    if (widget.pins.isEmpty) return null;
    final points = widget.pins.map((p) => p.point).toList();
    if (points.length == 1) return null;
    return LatLngBounds.fromPoints(points);
  }

  @override
  void didUpdateWidget(IroMap old) {
    super.didUpdateWidget(old);
    // Switching between issues and events reframes the map on the new set.
    if (widget.pins.length != old.pins.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _frame());
    }
  }

  void _frame() {
    if (!mounted) return;
    final bounds = _bounds;
    if (bounds == null) {
      final only = widget.pins.isEmpty ? null : widget.pins.first.point;
      if (only != null) _controller.move(only, 14);
      return;
    }
    _controller.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(38), maxZoom: 15),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bounds = _bounds;
    // Pins win when there are any; otherwise the district, and only then the
    // country — a member should never open the map on the whole of India.
    final centre = widget.pins.isEmpty
        ? (widget.fallbackCentre ?? const LatLng(22.9734, 78.6569))
        : widget.pins.first.point;
    final emptyZoom = widget.fallbackCentre == null ? 4.5 : widget.fallbackZoom;

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FlutterMap(
              mapController: _controller,
              options: MapOptions(
                initialCenter: centre,
                initialZoom: widget.pins.isEmpty ? emptyZoom : 13,
                initialCameraFit: bounds == null
                    ? null
                    : CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(38), maxZoom: 15),
                // The panel sits inside a scrolling page, so a drag should move
                // the page unless the member is pinching the map itself.
                interactionOptions: InteractionOptions(
                  flags: widget.allowPan
                      ? InteractiveFlag.all & ~InteractiveFlag.rotate
                      : InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom,
                ),
                onTap: widget.onTap == null ? null : (_, _) => widget.onTap!(),
              ),
              children: [
                TileLayer(
                  urlTemplate: MapTiles.url,
                  maxZoom: 19,
                  userAgentPackageName: MapTiles.userAgent,
                ),
                MarkerLayer(
                  markers: [
                    for (final pin in widget.pins)
                      Marker(
                        point: pin.point,
                        width: 40,
                        height: 40,
                        alignment: Alignment.topCenter,
                        child: _Pin(pin: pin),
                      ),
                  ],
                ),
              ],
            ),
            ...widget.overlay,
          ],
        ),
      ),
    );
  }
}

/// A pin drawn so it reads against map tiles: a white-ringed disc in the pin's
/// own colour, not a bare glyph that vanishes over a park.
class _Pin extends StatelessWidget {
  const _Pin({required this.pin});
  final IroMapPin pin;

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: pin.tone,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: Color(0x400C3320), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Icon(pin.icon, size: 15, color: Colors.white),
    );
    if (pin.onTap == null) return dot;
    return GestureDetector(
      onTap: pin.onTap,
      behavior: HitTestBehavior.opaque,
      child: Tooltip(message: pin.label, child: dot),
    );
  }
}

/// The attribution OpenStreetMap's tile usage policy requires. Sits in the
/// panel's overlay, bottom-right by default.
class IroMapCredit extends StatelessWidget {
  const IroMapCredit({super.key});

  @override
  Widget build(BuildContext context) {
    return IroChip(
      MapTiles.attribution,
      dense: true,
      size: 8,
      fg: Iro.ink2,
      bg: const Color(0xCCFFFFFF),
    );
  }
}
