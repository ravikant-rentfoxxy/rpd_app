import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/api_error.dart';
import '../../core/utils/app_log.dart';
import '../../core/widgets/iro_ui.dart';
import '../../core/widgets/ui.dart';
import 'community_api.dart';

/// One district story, opened from the ring on Community. Arrives with the row
/// the rail already had, then refetches so a story opened from a stale list
/// still shows its current text.
class StoryDetailView extends StatefulWidget {
  const StoryDetailView({super.key, this.story});
  final DistrictStory? story;

  @override
  State<StoryDetailView> createState() => _StoryDetailViewState();
}

class _StoryDetailViewState extends State<StoryDetailView> {
  late final Rxn<DistrictStory> story = Rxn<DistrictStory>(
    widget.story ?? (Get.arguments is DistrictStory ? Get.arguments as DistrictStory : null),
  );
  final loading = false.obs;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final id = story.value?.id ?? '';
    if (id.isEmpty) return;
    loading.value = true;
    try {
      story.value = await fetchStory(id);
    } catch (e, stack) {
      AppLog.error('story failed', error: e, stack: stack, tag: 'COMMUNITY');
      // The row handed over by the rail is enough to read; only say so when
      // there was nothing to fall back on.
      if (story.value == null && mounted) Get.snackbar('Error', apiErrorMessage(e));
    } finally {
      loading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Iro.mint,
      appBar: OrganicAppBar(title: 'district_stories'.tr, subtitle: story.value?.place),
      body: Obx(() {
        final data = story.value;
        if (data == null) {
          return Center(
            child: loading.value
                ? const CircularProgressIndicator(color: Iro.bright)
                : Text('no_updates_yet'.tr, style: iroLabel(size: 13)),
          );
        }
        return RefreshIndicator(
          color: Iro.bright,
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 32),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  height: 230,
                  width: double.infinity,
                  child: IroPhoto(
                    url: data.imageUrl,
                    icon: Icons.auto_awesome_rounded,
                    seed: data.title.length,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  if (data.live) ...[
                    IroChip('live_updates'.tr, dot: true, size: 9.5, dense: true, fg: Iro.gold, bg: Iro.goldWash),
                    const SizedBox(width: 8),
                  ],
                  const Icon(Icons.place_outlined, size: 14, color: Iro.greenMid),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      data.place,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: iroLabel(size: 11.5, color: Iro.greenMid, weight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(data.title, style: iroDisplay(size: 21).copyWith(height: 1.25)),
              if (data.createdAt != null || data.authorName.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  [
                    if (data.authorName.isNotEmpty) data.authorName,
                    if (data.createdAt != null) DateFormat('dd MMM yyyy · h:mm a').format(data.createdAt!),
                  ].join(' • '),
                  style: iroLabel(size: 11, color: Iro.muted, weight: FontWeight.w500),
                ),
              ],
              if (data.body.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  data.body,
                  style: iroLabel(size: 14, color: Iro.ink2, weight: FontWeight.w500).copyWith(height: 1.6),
                ),
              ],
            ],
          ),
        );
      }),
    );
  }
}
