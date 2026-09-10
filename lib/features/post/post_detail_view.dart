import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/constants/post_issues.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/local_image.dart';
import '../../core/utils/relative_time.dart';
import '../join/join_chrome.dart';
import 'post_media.dart';
import 'post_views.dart';

class PostDetailView extends StatelessWidget {
  const PostDetailView({super.key});

  Map<String, dynamic> get post {
    final raw = Get.arguments;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  @override
  Widget build(BuildContext context) {
    final data = post;
    final type = '${data['mediaType'] ?? 'image'}'.toLowerCase();
    final raw = data['mediaUrl'] ?? data['mediaPath'] ?? data['photoPath'];
    final path = resolveMediaUrl(raw) ?? localPhotoPath(raw);
    final thumb = data['thumbnailUrl'] ?? data['thumbnailPath'] ?? data['thumbnailKey'];
    final description = '${data['description'] ?? ''}'.trim();
    final author = '${data['authorName'] ?? ''}'.trim();
    final issue = issueLabelOf(data);
    final region = '${data['regionLabel'] ?? ''}'.trim();
    final pending = data['pending'] == true;
    return Scaffold(
      backgroundColor: HomeColors.paper,
      appBar: AppBar(
        backgroundColor: HomeColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('post_details'.trFallback('Post')),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: HomeColors.navy,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: HomeColors.border, width: 0.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (path != null && path.isNotEmpty)
                  _DetailMedia(type: type, path: path, thumbnail: thumb),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (issue.isNotEmpty) ...[
                        IssueChip(label: issue, priority: issuePriorityOf(data)),
                        const SizedBox(height: 12),
                      ],
                      if (description.isNotEmpty) ...[
                        Text(
                          description,
                          style: const TextStyle(fontSize: 16, height: 1.45, color: HomeColors.ink),
                        ),
                        const SizedBox(height: 14),
                      ],
                      if (author.isNotEmpty)
                        Text(author, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: HomeColors.ink)),
                      const SizedBox(height: 4),
                      Text(
                        [
                          lastActiveWhen(data['createdAt']),
                          if (region.isNotEmpty) region,
                          if (pending) 'post_saved_offline'.trFallback('Saved on this phone'),
                        ].join(' · '),
                        style: const TextStyle(fontSize: 13, color: HomeColors.muted),
                      ),
                    ],
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

class _DetailMedia extends StatelessWidget {
  const _DetailMedia({required this.type, required this.path, this.thumbnail});
  final String type;
  final String? path;
  final Object? thumbnail;

  @override
  Widget build(BuildContext context) {
    if (path == null || path!.isEmpty) {
      return const ColoredBox(color: HomeColors.navy, child: SizedBox(height: 220, width: double.infinity));
    }
    if (type == 'audio') return AudioListenBar(path: path!);
    if (type == 'video') {
      return VideoThumbTile(
        videoPath: path!,
        thumbnail: thumbnail,
        height: 240,
        onTap: () => Get.toNamed(Routes.postVideo, arguments: {'path': path}),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: localOrNetworkPhoto(
        raw: path,
        fit: BoxFit.cover,
        fallback: const ColoredBox(color: HomeColors.navy, child: SizedBox(height: 220)),
      ),
    );
  }
}
