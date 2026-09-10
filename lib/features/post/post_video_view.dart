import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_log.dart';
import '../../core/utils/local_image.dart';
import '../../core/utils/relative_time.dart';
import '../join/join_chrome.dart';

class PostVideoPlayerView extends StatefulWidget {
  const PostVideoPlayerView({super.key});

  @override
  State<PostVideoPlayerView> createState() => _PostVideoPlayerViewState();
}

class _PostVideoPlayerViewState extends State<PostVideoPlayerView> {
  VideoPlayerController? _controller;
  var _ready = false;
  var _playing = false;

  Map<String, dynamic> get args {
    final raw = Get.arguments;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String) return {'path': raw};
    return {};
  }

  @override
  void initState() {
    super.initState();
    _load('${args['path'] ?? ''}');
  }

  Future<void> _load(String path) async {
    if (path.isEmpty) return;
    final url = resolveMediaUrl(path);
    final controller = url != null
        ? VideoPlayerController.networkUrl(Uri.parse(url))
        : VideoPlayerController.file(File(localPhotoPath(path) ?? path));
    try {
      await controller.initialize();
      controller.setLooping(true);
      await controller.play();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      controller.addListener(_onTick);
      setState(() {
        _controller = controller;
        _ready = true;
        _playing = true;
      });
    } catch (e, stack) {
      await controller.dispose();
      AppLog.error('Post video play failed', error: e, stack: stack, tag: 'POST');
    }
  }

  void _onTick() {
    final controller = _controller;
    if (!mounted || controller == null) return;
    final playing = controller.value.isPlaying;
    if (playing != _playing) setState(() => _playing = playing);
  }

  Future<void> _toggle() async {
    final controller = _controller;
    if (controller == null || !_ready) return;
    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }
    if (mounted) setState(() => _playing = controller.value.isPlaying);
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final author = '${args['author'] ?? ''}'.trim();
    final when = lastActiveWhen(args['createdAt']);
    final description = '${args['description'] ?? ''}'.trim();
    final controller = _controller;
    final progress = !_ready || controller == null || controller.value.duration.inMilliseconds <= 0
        ? 0.0
        : (controller.value.position.inMilliseconds / controller.value.duration.inMilliseconds).clamp(0.0, 1.0);
    final ratio = _ready && controller != null && controller.value.size.height > 0
        ? controller.value.aspectRatio
        : 16 / 9;
    return Scaffold(
      backgroundColor: HomeColors.paper,
      appBar: AppBar(
        backgroundColor: HomeColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(author.isEmpty ? 'post_media_video'.trFallback('Video') : author),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: HomeColors.navy,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      body: ListView(
        children: [
          ColoredBox(
            color: Colors.black,
            child: GestureDetector(
              onTap: _toggle,
              child: AspectRatio(
                aspectRatio: ratio,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_ready && controller != null)
                      SizedBox.expand(child: VideoPlayer(controller))
                    else
                      const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    if (_ready && !_playing)
                      const Material(
                        color: Colors.black45,
                        shape: CircleBorder(),
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 42),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (_ready && controller != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 3,
                  backgroundColor: const Color(0xFFE4DCD0),
                  color: HomeColors.orange,
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
                Text(
                  [author, when].where((e) => e.isNotEmpty).join(' · '),
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
