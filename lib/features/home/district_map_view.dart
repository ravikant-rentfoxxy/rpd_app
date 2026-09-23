import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/iro_map.dart';
import '../../core/widgets/iro_ui.dart';
import '../../core/widgets/ui.dart';

/// What the home panel opens into: the same pins with the whole screen to draw
/// them on, and panning turned on — the panel has it off so a drag scrolls the
/// page instead.
class DistrictMapArgs {
  const DistrictMapArgs({
    required this.issues,
    required this.events,
    this.centre,
    this.showEvents = false,
    this.title = '',
  });

  final List<IroMapPin> issues;
  final List<IroMapPin> events;
  final LatLng? centre;

  /// Which side the panel was showing when it was tapped, so the full screen
  /// opens on the same one.
  final bool showEvents;
  final String title;
}

class DistrictMapView extends StatefulWidget {
  const DistrictMapView({super.key, this.args});
  final DistrictMapArgs? args;

  @override
  State<DistrictMapView> createState() => _DistrictMapViewState();
}

class _DistrictMapViewState extends State<DistrictMapView> {
  late final DistrictMapArgs args =
      widget.args ?? (Get.arguments is DistrictMapArgs ? Get.arguments as DistrictMapArgs : const DistrictMapArgs(issues: [], events: []));
  late bool showEvents = args.showEvents;

  @override
  Widget build(BuildContext context) {
    final pins = showEvents ? args.events : args.issues;
    return Scaffold(
      backgroundColor: Iro.mint,
      appBar: OrganicAppBar(
        title: args.title.isEmpty ? 'your_district'.tr : args.title,
        subtitle: 'active_incidents'.trParams({'n': '${pins.length}'}),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: IroMap(
          // Fills whatever is left of the screen under the bar.
          height: double.infinity,
          pins: pins,
          fallbackCentre: args.centre,
          radius: 20,
          // A full screen has nothing to scroll behind it, so the map takes the
          // drag as well as the pinch.
          allowPan: true,
          overlay: [
            Positioned(
              left: 12,
              top: 12,
              child: IroChip(
                showEvents ? 'events'.tr : 'issues'.tr,
                dot: true,
                size: 10,
                fg: showEvents ? Iro.green : Iro.alert,
                bg: const Color(0xF2FFFFFF),
              ),
            ),
            const Positioned(left: 12, bottom: 12, child: IroMapCredit()),
            Positioned(
              right: 12,
              bottom: 12,
              child: _Toggle(
                showEvents: showEvents,
                onChanged: (value) => setState(() => showEvents = value),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.showEvents, required this.onChanged});
  final bool showEvents;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget seg(String label, bool on, VoidCallback tap) => Material(
          color: on ? Iro.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          child: InkWell(
            borderRadius: BorderRadius.circular(9),
            onTap: tap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              child: Text(
                label,
                style: iroLabel(size: 11.5, color: on ? Iro.ink : Colors.white, weight: FontWeight.w700),
              ),
            ),
          ),
        );

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: const Color(0xCC0C3320), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          seg('issues'.tr, !showEvents, () => onChanged(false)),
          seg('events'.tr, showEvents, () => onChanged(true)),
        ],
      ),
    );
  }
}
