import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/local_image.dart';
import '../../core/utils/relative_time.dart';
import '../join/join_chrome.dart';
import '../../core/widgets/ui.dart';

class PostVideoPlayerView extends StatefulWidget {
  const PostVideoPlayerView({super.key});

  @override
  State<PostVideoPlayerView> createState() => _PostVideoPlayerViewState();
}

class _PostVideoPlayerViewState extends State<PostVideoPlayerView> {
  WebViewController? _controller;
  var _loading = true;
  var _failed = false;

  Map<String, dynamic> get args {
    final raw = Get.arguments;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String) return {'path': raw};
    return {};
  }

  String? get _embedUrl {
    return postStreamEmbedUrl(args) ??
        resolveStreamEmbedUrl(args['path'] ?? args['mediaUrl'] ?? args['mediaKey'] ?? args['mediaPath']);
  }

  @override
  void initState() {
    super.initState();
    _open();
  }

  void _open() {
    final url = _embedUrl;
    if (url == null || url.isEmpty) {
      setState(() {
        _failed = true;
        _loading = false;
      });
      return;
    }

    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onNavigationRequest: (request) {
            final host = Uri.tryParse(request.url)?.host ?? '';
            final allowed = host.contains('mediadelivery.net') ||
                host.contains('b-cdn.net') ||
                host.contains('bunnycdn.com') ||
                host.contains('iframe.mediadelivery.net');
            return allowed ? NavigationDecision.navigate : NavigationDecision.prevent;
          },
        ),
      );

    final platform = controller.platform;
    if (platform is AndroidWebViewController) {
      platform.setMediaPlaybackRequiresUserGesture(false);
    }

    setState(() {
      _controller = controller;
      _loading = true;
      _failed = false;
    });
    controller.loadRequest(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    final when = lastActiveWhen(args['createdAt']);
    final description = '${args['description'] ?? ''}'.trim();
    return Scaffold(
      backgroundColor: HomeColors.paper,
      appBar: OrganicAppBar(title: 'post_media_video'.trFallback('Video')),
      body: ListView(
        children: [
          ColoredBox(
            color: Colors.black,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_controller != null) WebViewWidget(controller: _controller!),
                  if (_failed)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'post_video_processing'.trFallback('Bunny is still encoding this video. Try again in a minute.'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, height: 1.4),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: _open,
                            child: Text('retry'.trFallback('Retry'), style: const TextStyle(color: HomeColors.orange)),
                          ),
                        ],
                      ),
                    )
                  else if (_loading)
                    const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (description.isNotEmpty) ...[
                  Text(
                    description,
                    style: const TextStyle(color: HomeColors.ink, fontSize: 15, height: 1.4),
                  ),
                  const SizedBox(height: 8),
                ],
                if (when.isNotEmpty)
                  Text(
                    when,
                    style: const TextStyle(color: HomeColors.muted, fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
