import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/local_image.dart';
import '../../core/widgets/iro_ui.dart';
import '../join/join_chrome.dart';
import 'post_media.dart';

/// Opening a post's media without leaving the post.
///
/// The detail screen shows the media small — a tall photo used to push
/// everything else off the screen — and tapping it lifts the same pixels into a
/// dialog over a blurred page. The Hero is what makes the two feel like one
/// thing rather than two screens.

/// How much of the screen the thumbnail takes on the detail screen.
const postMediaThumbFraction = 0.30;

/// And how much the opened view takes.
const postMediaViewerFraction = 0.50;

/// One tag per post per kind, so two posts on screen never fight over a flight.
String postMediaHeroTag(Map<String, dynamic> post, String kind) {
  final id = '${post['clientUuid'] ?? post['serverId'] ?? post['id'] ?? identityHashCode(post)}';
  return 'post-media-$kind-$id';
}

/// The media over a blurred page. Tapping anywhere outside closes it, and so
/// does the corner button — a dialog with no visible way out is a trap on a
/// phone with gesture navigation.
Future<void> showPostMediaViewer(
  BuildContext context, {
  required String heroTag,
  required Widget child,
}) {
  return showGeneralDialog<void>(
    context: context,
    // The scrim is drawn below rather than handed to the barrier, because it
    // has to be blurred as well as darkened.
    barrierColor: Colors.transparent,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (context, animation, _) {
      final height = MediaQuery.sizeOf(context).height * postMediaViewerFraction;
      return _ViewerScaffold(animation: animation, heroTag: heroTag, height: height, child: child);
    },
    transitionBuilder: (context, animation, _, page) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: page,
      );
    },
  );
}

class _ViewerScaffold extends StatelessWidget {
  const _ViewerScaffold({
    required this.animation,
    required this.heroTag,
    required this.height,
    required this.child,
  });

  final Animation<double> animation;
  final String heroTag;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // The page behind, blurred and dimmed together so the media reads as
        // lifted off it rather than pasted over it.
        Positioned.fill(
          child: GestureDetector(
            onTap: Navigator.of(context).pop,
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, _) => BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 14 * animation.value, sigmaY: 14 * animation.value),
                child: ColoredBox(color: Colors.black.withValues(alpha: 0.62 * animation.value)),
              ),
            ),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Absorbs the tap so pressing the media itself does not close it.
                GestureDetector(
                  onTap: () {},
                  child: Hero(
                    tag: heroTag,
                    child: Material(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(18),
                      clipBehavior: Clip.antiAlias,
                      child: SizedBox(
                        height: height,
                        width: double.infinity,
                        child: child,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _CloseButton(onTap: Navigator.of(context).pop),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0x33FFFFFF),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: const SizedBox(
          width: 46,
          height: 46,
          child: Icon(Icons.close_rounded, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}

/// A photo on the detail screen: capped so a portrait shot cannot take the
/// whole page, and tappable to see it properly.
class PostImageThumb extends StatelessWidget {
  const PostImageThumb({super.key, required this.post, required this.raw, required this.height});

  final Map<String, dynamic> post;
  final Object? raw;
  final double height;

  @override
  Widget build(BuildContext context) {
    final tag = postMediaHeroTag(post, 'image');
    return GestureDetector(
      onTap: () => showPostMediaViewer(
        context,
        heroTag: tag,
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: localOrNetworkPhoto(
            raw: raw,
            // Contained rather than cropped: the point of opening it is to see
            // all of it.
            fit: BoxFit.contain,
            fallback: const PostMediaPlaceholder(kind: PostPlaceholderKind.image),
          ),
        ),
      ),
      child: Hero(
        tag: tag,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              localOrNetworkPhoto(
                raw: raw,
                fit: BoxFit.cover,
                fallback: PostMediaPlaceholder(kind: PostPlaceholderKind.image, height: height),
              ),
              const Positioned(right: 10, bottom: 10, child: _ExpandHint(icon: Icons.open_in_full_rounded)),
            ],
          ),
        ),
      ),
    );
  }
}

/// A video on the detail screen: the still frame with a play badge, opening
/// into the player over the blurred page.
class PostVideoThumb extends StatelessWidget {
  const PostVideoThumb({
    super.key,
    required this.post,
    required this.videoPath,
    required this.thumbnail,
    required this.height,
  });

  final Map<String, dynamic> post;
  final String videoPath;
  final Object? thumbnail;
  final double height;

  Object? get _still => resolveStorageUrl(thumbnail) ?? resolveStreamThumbnailUrl(videoPath) ?? thumbnail;

  @override
  Widget build(BuildContext context) {
    final tag = postMediaHeroTag(post, 'video');
    return GestureDetector(
      onTap: () => showPostMediaViewer(
        context,
        heroTag: tag,
        child: PostVideoSurface(post: post, videoPath: videoPath, still: _still),
      ),
      child: Hero(
        tag: tag,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              localOrNetworkPhoto(
                raw: _still,
                fit: BoxFit.cover,
                fallback: const ColoredBox(color: HomeColors.navy),
              ),
              const ColoredBox(color: Color(0x40000000)),
              VideoPlayBadge(size: height < 130 ? 44 : 56),
            ],
          ),
        ),
      ),
    );
  }
}

/// The corner glyph that says the media opens.
class _ExpandHint extends StatelessWidget {
  const _ExpandHint({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: const BoxDecoration(color: Color(0xB3000000), shape: BoxShape.circle),
      child: Icon(icon, size: 15, color: Colors.white),
    );
  }
}

/// The Bunny player, with the still frame under it.
///
/// The webview is mounted a beat after the dialog opens rather than with it: a
/// platform view inside a Hero flight stutters, and the still frame covers the
/// gap so nothing looks empty while it waits.
class PostVideoSurface extends StatefulWidget {
  const PostVideoSurface({super.key, required this.post, required this.videoPath, this.still});

  final Map<String, dynamic> post;
  final String videoPath;
  final Object? still;

  @override
  State<PostVideoSurface> createState() => _PostVideoSurfaceState();
}

class _PostVideoSurfaceState extends State<PostVideoSurface> {
  WebViewController? _controller;
  var _mounted = false;
  var _loading = true;
  var _failed = false;

  String? get _embedUrl =>
      postStreamEmbedUrl(widget.post) ?? resolveStreamEmbedUrl(widget.videoPath);

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 320), () {
      if (!mounted) return;
      setState(() => _mounted = true);
      _open();
    });
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
          // Only Bunny's own hosts; anything else a page tries to open is
          // refused rather than followed inside the player.
          onNavigationRequest: (request) {
            final host = Uri.tryParse(request.url)?.host ?? '';
            final allowed = host.contains('mediadelivery.net') ||
                host.contains('b-cdn.net') ||
                host.contains('bunnycdn.com');
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
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (widget.still != null)
            localOrNetworkPhoto(
              raw: widget.still,
              fit: BoxFit.cover,
              fallback: const ColoredBox(color: Colors.black),
            ),
          if (_mounted && _controller != null) WebViewWidget(controller: _controller!),
          if (_failed)
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'post_video_processing'.trFallback(
                      'Bunny is still encoding this video. Try again in a minute.',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  IroGhostButton(
                    label: 'retry'.trFallback('Retry'),
                    icon: Icons.refresh_rounded,
                    onTap: _open,
                  ),
                ],
              ),
            )
          else if (_loading)
            const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
        ],
      ),
    );
  }
}
