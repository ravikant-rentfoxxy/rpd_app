import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/home_feed.dart';

class YoutubePlayerView extends StatefulWidget {
  const YoutubePlayerView({super.key});

  @override
  State<YoutubePlayerView> createState() => _YoutubePlayerViewState();
}

class _YoutubePlayerViewState extends State<YoutubePlayerView> {
  late final HomeFeedItem item;
  late final WebViewController controller;
  final loading = true.obs;

  @override
  void initState() {
    super.initState();
    item = Get.arguments as HomeFeedItem;
    final videoId = item.youtubeId ?? '';

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => loading.value = false,
          onWebResourceError: (_) => loading.value = false,
        ),
      );

    if (videoId.isEmpty) {
      loading.value = false;
    } else {
      controller.loadRequest(Uri.parse('https://www.youtube.com/embed/$videoId'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final videoId = item.youtubeId;
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: Text(item.source)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ColoredBox(
              color: Colors.black,
              child: videoId == null || videoId.isEmpty
                  ? Center(child: Text('open_link_failed'.tr, style: const TextStyle(color: Colors.white)))
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        WebViewWidget(controller: controller),
                        Obx(
                          () => loading.value
                              ? const Center(child: CircularProgressIndicator(color: Colors.white))
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, height: 1.35),
                ),
                const SizedBox(height: 6),
                Text(item.source, style: const TextStyle(color: AppColors.ink3, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
