import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/open_url.dart';
import '../../data/models/home_feed.dart';
import 'home_widgets.dart';

/// Reads a blog written in the admin portal. Link-only blogs never reach here —
/// [openHomeFeedItem] sends those straight to the browser.
class BlogArticleView extends StatelessWidget {
  const BlogArticleView({super.key, this.item});

  final HomeFeedItem? item;

  @override
  Widget build(BuildContext context) {
    final blog = item ?? (Get.arguments is HomeFeedItem ? Get.arguments as HomeFeedItem : null);
    if (blog == null) return const SizedBox.shrink();
    final hasLink = blog.url.trim().isNotEmpty;
    return Scaffold(
      backgroundColor: HomeColors.paper,
      appBar: AppBar(
        backgroundColor: HomeColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('recent_blogs'.tr, style: const TextStyle(fontWeight: FontWeight.w500)),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: HomeColors.navy,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          if (blog.imageUrl != null)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                blog.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const ColoredBox(color: HomeColors.navy),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(blog.title, style: homeTitleStyle(size: 22)),
                if (blog.source.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(blog.source, style: const TextStyle(fontSize: 12, color: HomeColors.muted)),
                ],
                if (blog.description.trim().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    blog.description,
                    style: const TextStyle(fontSize: 15, height: 1.45, color: HomeColors.ink, fontWeight: FontWeight.w500),
                  ),
                ],
                const SizedBox(height: 16),
                Text(blog.body, style: const TextStyle(fontSize: 15, height: 1.6, color: HomeColors.ink)),
                if (hasLink) ...[
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () => openExternalUrl(blog.url),
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: Text('open_link'.tr),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
