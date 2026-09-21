import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/remote/api_client.dart';
import '../theme/app_colors.dart';
import '../utils/app_log.dart';

class PlaceSuggestion {
  const PlaceSuggestion({
    required this.name,
    required this.displayName,
    required this.latitude,
    required this.longitude,
    this.kind,
  });

  final String name;
  final String displayName;
  final double latitude;
  final double longitude;
  final String? kind;

  static PlaceSuggestion? fromJson(Map<String, dynamic> json) {
    final lat = (json['latitude'] as num?)?.toDouble();
    final lng = (json['longitude'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;
    final display = '${json['displayName'] ?? ''}'.trim();
    if (display.isEmpty) return null;
    return PlaceSuggestion(
      name: '${json['name'] ?? ''}'.trim().isEmpty ? display.split(',').first.trim() : '${json['name']}',
      displayName: display,
      latitude: lat,
      longitude: lng,
      kind: json['kind'] as String?,
    );
  }

  /// Everything after the first part of the address, used as the row subtitle.
  String get area {
    final parts = displayName.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
    return parts.length <= 1 ? '' : parts.sublist(1).join(', ');
  }
}

Future<List<PlaceSuggestion>> searchPlaces(String query, {int limit = 10}) async {
  final res = await Get.find<ApiClient>().get('/geo/places', query: {'q': query.trim(), 'limit': limit});
  final items = ((res['data'] as Map?)?['places'] as List?) ?? [];
  return items
      .whereType<Map>()
      .map((e) => PlaceSuggestion.fromJson(Map<String, dynamic>.from(e)))
      .whereType<PlaceSuggestion>()
      .toList();
}

/// Wraps an address [child] text field and shows place suggestions below it as the
/// member types. Suggestions come from the backend (`/geo/places`, max 10 rows).
class PlaceSuggestionsField extends StatefulWidget {
  const PlaceSuggestionsField({
    super.key,
    required this.controller,
    required this.child,
    required this.onSelected,
    this.minChars = 3,
    this.limit = 10,
  });

  final TextEditingController controller;
  final Widget child;
  final ValueChanged<PlaceSuggestion> onSelected;
  final int minChars;
  final int limit;

  @override
  State<PlaceSuggestionsField> createState() => _PlaceSuggestionsFieldState();
}

class _PlaceSuggestionsFieldState extends State<PlaceSuggestionsField> {
  static const _debounce = Duration(milliseconds: 450);

  Timer? _timer;
  var _requestId = 0;
  var _suggestions = <PlaceSuggestion>[];
  var _loading = false;
  String? _chosen;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _timer?.cancel();
    super.dispose();
  }

  void _onChanged() {
    final query = widget.controller.text.trim();
    _timer?.cancel();
    if (query == _chosen) return;
    if (query.length < widget.minChars) {
      if (_suggestions.isNotEmpty || _loading) setState(() { _suggestions = []; _loading = false; });
      return;
    }
    _timer = Timer(_debounce, () => _search(query));
  }

  Future<void> _search(String query) async {
    final id = ++_requestId;
    setState(() => _loading = true);
    try {
      final results = await searchPlaces(query, limit: widget.limit);
      if (!mounted || id != _requestId) return;
      setState(() {
        _suggestions = results;
        _loading = false;
      });
    } catch (e, stack) {
      AppLog.error('Place search failed', error: e, stack: stack, tag: 'GEO');
      if (!mounted || id != _requestId) return;
      setState(() {
        _suggestions = [];
        _loading = false;
      });
    }
  }

  void _select(PlaceSuggestion place) {
    _timer?.cancel();
    _requestId++;
    _chosen = place.displayName;
    widget.controller.value = TextEditingValue(
      text: place.displayName,
      selection: TextSelection.collapsed(offset: place.displayName.length),
    );
    setState(() {
      _suggestions = [];
      _loading = false;
    });
    FocusScope.of(context).unfocus();
    widget.onSelected(place);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        widget.child,
        if (_loading || _suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            constraints: const BoxConstraints(maxHeight: 260),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.rule),
              boxShadow: [
                BoxShadow(color: AppColors.ink.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 6)),
              ],
            ),
            child: _loading && _suggestions.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _suggestions.length,
                    separatorBuilder: (_, _) => const Divider(height: 1, thickness: 1, color: AppColors.rule),
                    itemBuilder: (context, index) {
                      final place = _suggestions[index];
                      return InkWell(
                        onTap: () => _select(place),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 1),
                                child: Icon(Icons.place_outlined, size: 17, color: AppColors.accent),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      place.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                    if (place.area.isNotEmpty) ...[
                                      const SizedBox(height: 1),
                                      Text(
                                        place.area,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12, color: AppColors.ink3, height: 1.3),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
      ],
    );
  }
}
