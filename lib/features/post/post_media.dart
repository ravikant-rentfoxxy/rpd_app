import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/api_error.dart';
import '../../core/utils/app_log.dart';
import '../../core/utils/local_image.dart';
import '../join/join_chrome.dart';
import '../../core/widgets/flash.dart';

Source _audioSource(String path) {
  final url = resolveStorageUrl(path) ?? resolveMediaUrl(path, kind: 'audio');
  if (url != null) return UrlSource(url);
  return DeviceFileSource(path);
}

Future<VideoPlayerController> openVideoController(String path) async {
  final hls = resolveVideoHlsUrl(path);
  if (hls != null) return _openHlsController(hls);
  final url = resolveMediaUrl(path);
  if (url != null) {
    if (isHlsUrl(url)) return _openHlsController(url);
    return VideoPlayerController.networkUrl(Uri.parse(url));
  }
  return VideoPlayerController.file(File(localPhotoPath(path) ?? path));
}

Future<VideoPlayerController> _openHlsController(String url) async {
  Object? last;
  for (var attempt = 0; attempt < 8; attempt++) {
    final controller = VideoPlayerController.networkUrl(Uri.parse(url), formatHint: VideoFormat.hls);
    try {
      await controller.initialize();
      return controller;
    } catch (e) {
      last = e;
      await controller.dispose();
      if (attempt < 7) await Future<void>.delayed(Duration(seconds: 3 + attempt));
    }
  }
  throw last ?? StateError('Video is not ready yet');
}

Future<void> initializeVideo(VideoPlayerController controller) async {
  if (controller.value.isInitialized) return;
  Object? last;
  for (var attempt = 0; attempt < 4; attempt++) {
    try {
      await controller.initialize();
      return;
    } catch (e) {
      last = e;
      if (attempt < 3) await Future<void>.delayed(Duration(seconds: 2 + attempt));
    }
  }
  throw last ?? StateError('Video is not ready yet');
}

const maxPostMediaDuration = Duration(minutes: 1);

/// Cameras round a 60-second clip up a little, so allow one second of slack.
const _postMediaDurationLimit = Duration(seconds: 61);

enum PostMediaDuration { ok, tooLong, unknown }

PostMediaDuration checkPostMediaDuration(Duration? duration) {
  // A null or zero reading means the file could not be probed, not that it is short.
  if (duration == null || duration == Duration.zero) return PostMediaDuration.unknown;
  return duration > _postMediaDurationLimit ? PostMediaDuration.tooLong : PostMediaDuration.ok;
}

/// Reads a clip's length and returns why it cannot be posted, or null when it is fine.
///
/// A file whose length cannot be read is refused rather than uploaded blind —
/// otherwise a long clip with an unreadable header slips past the limit.
Future<String?> postMediaDurationError(String path, {required bool video}) async {
  final duration = video ? await videoFileDuration(path) : await audioFileDuration(path);
  return switch (checkPostMediaDuration(duration)) {
    PostMediaDuration.ok => null,
    PostMediaDuration.tooLong => 'media_max_duration'.trFallback('Video and audio can be up to 1 minute.'),
    PostMediaDuration.unknown => 'media_duration_unknown'
        .trFallback('The length of this file could not be read. Pick another video or audio clip.'),
  };
}

Future<Duration?> videoFileDuration(String path) async {
  VideoPlayerController? controller;
  try {
    controller = await openVideoController(path);
    return controller.value.duration;
  } catch (_) {
    return null;
  } finally {
    await controller?.dispose();
  }
}

Future<Duration?> audioFileDuration(String path) async {
  final player = AudioPlayer();
  try {
    await player.setSource(_audioSource(path));
    return await player.getDuration();
  } catch (_) {
    return null;
  } finally {
    await player.dispose();
  }
}

class AudioRecordPanel extends StatefulWidget {
  const AudioRecordPanel({super.key, required this.onDone, this.onCancel});
  final ValueChanged<String> onDone;
  final VoidCallback? onCancel;

  @override
  State<AudioRecordPanel> createState() => _AudioRecordPanelState();
}

class AudioListenBar extends StatefulWidget {
  const AudioListenBar({super.key, required this.path, this.onChange, this.onRemove, this.compact = false});
  final String path;
  final VoidCallback? onChange;
  final VoidCallback? onRemove;
  final bool compact;

  @override
  State<AudioListenBar> createState() => _AudioListenBarState();
}

class _AudioListenBarState extends State<AudioListenBar> {
  final _player = AudioPlayer();
  var _playing = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  StreamSubscription<void>? _complete;
  StreamSubscription<Duration>? _pos;
  StreamSubscription<Duration>? _dur;

  @override
  void initState() {
    super.initState();
    _player.setSource(_audioSource(widget.path));
    _complete = _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _playing = false;
        _position = Duration.zero;
      });
    });
    _pos = _player.onPositionChanged.listen((value) {
      if (mounted) setState(() => _position = value);
    });
    _dur = _player.onDurationChanged.listen((value) {
      if (mounted) setState(() => _duration = value);
    });
  }

  @override
  void didUpdateWidget(covariant AudioListenBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _player.stop();
      _player.setSource(_audioSource(widget.path));
      _playing = false;
      _position = Duration.zero;
      _duration = Duration.zero;
    }
  }

  @override
  void dispose() {
    _complete?.cancel();
    _pos?.cancel();
    _dur?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _player.pause();
      setState(() => _playing = false);
      return;
    }
    await _player.play(_audioSource(widget.path));
    if (mounted) setState(() => _playing = true);
  }

  @override
  Widget build(BuildContext context) {
    final total = _duration.inMilliseconds <= 0 ? 1.0 : _duration.inMilliseconds.toDouble();
    return Container(
      height: widget.compact ? 120 : 140,
      width: double.infinity,
      color: HomeColors.navy,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: _toggle,
                  iconSize: widget.compact ? 36 : 44,
                  color: Colors.white,
                  icon: Icon(_playing ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded),
                ),
                Text(
                  _playing ? _formatDuration(_position) : 'tap_to_listen'.trFallback('Tap to listen'),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: (_position.inMilliseconds / total).clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: Colors.white24,
                    color: HomeColors.orange,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: MediaCornerActions(onChange: widget.onChange, onRemove: widget.onRemove),
          ),
        ],
      ),
    );
  }
}

class ComposerAudioCard extends StatefulWidget {
  const ComposerAudioCard({super.key, required this.path});
  final String path;

  @override
  State<ComposerAudioCard> createState() => _ComposerAudioCardState();
}

class _ComposerAudioCardState extends State<ComposerAudioCard> {
  final _player = AudioPlayer();
  var _playing = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  StreamSubscription<void>? _complete;
  StreamSubscription<Duration>? _pos;
  StreamSubscription<Duration>? _dur;

  @override
  void initState() {
    super.initState();
    _player.setSource(_audioSource(widget.path));
    _complete = _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _playing = false;
        _position = Duration.zero;
      });
    });
    _pos = _player.onPositionChanged.listen((value) {
      if (mounted) setState(() => _position = value);
    });
    _dur = _player.onDurationChanged.listen((value) {
      if (mounted) setState(() => _duration = value);
    });
  }

  @override
  void didUpdateWidget(covariant ComposerAudioCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _player.stop();
      _player.setSource(_audioSource(widget.path));
      _playing = false;
      _position = Duration.zero;
      _duration = Duration.zero;
    }
  }

  @override
  void dispose() {
    _complete?.cancel();
    _pos?.cancel();
    _dur?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _player.pause();
      setState(() => _playing = false);
      return;
    }
    await _player.play(_audioSource(widget.path));
    if (mounted) setState(() => _playing = true);
  }

  @override
  Widget build(BuildContext context) {
    final bars = _waveBars(widget.path);
    final progress = _duration.inMilliseconds <= 0 ? 0.0 : (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0);
    return Container(
      height: 118,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EEE6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4DCD0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Material(
                color: HomeColors.navy,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _toggle,
                  child: SizedBox(
                    width: 42,
                    height: 42,
                    child: Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < bars.length; i++)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 1),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 80),
                              height: 8 + bars[i] * 28,
                              decoration: BoxDecoration(
                                color: i / bars.length <= progress ? HomeColors.orange : const Color(0xFFC9C2B6),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _formatDuration(_duration == Duration.zero ? _position : (_playing ? _position : _duration)),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: HomeColors.ink),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'voice_recording'.trFallback('Voice recording'),
            style: const TextStyle(color: AppColors.ink3, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

List<double> _waveBars(String path) {
  var hash = path.hashCode;
  return List.generate(26, (index) {
    hash = 0x7fffffff & (hash * 1664525 + 1013904223 + index);
    return 0.22 + (hash % 78) / 100;
  });
}

Future<String?> generateVideoThumbnail(String videoPath) async {
  try {
    final bytes = await VideoThumbnail.thumbnailData(
      video: videoPath,
      imageFormat: ImageFormat.JPEG,
      maxWidth: 720,
      quality: 70,
    );
    if (bytes == null || bytes.isEmpty) return null;
    final dir = await getApplicationDocumentsDirectory();
    final dest = File('${dir.path}/rpd_thumb_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await dest.writeAsBytes(bytes, flush: true);
    return dest.path;
  } catch (e, stack) {
    AppLog.error('Video thumbnail failed', error: e, stack: stack, tag: 'POST');
    return null;
  }
}

class VideoPlayBadge extends StatelessWidget {
  const VideoPlayBadge({super.key, this.size = 56});
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xE6000000),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 8)],
          ),
          child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: size * 0.62),
        ),
      ),
    );
  }
}

class VideoThumbTile extends StatelessWidget {
  const VideoThumbTile({
    super.key,
    required this.videoPath,
    this.thumbnail,
    this.height = 148,
    this.onTap,
  });
  final String videoPath;
  final Object? thumbnail;
  final double height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: HomeColors.navy,
      child: InkWell(
        onTap: onTap ??
            () => Get.toNamed(Routes.postVideo, arguments: {
                  'path': videoPath,
                  'mediaUrl': resolveVideoHlsUrl(videoPath) ?? videoPath,
                  'mediaKey': streamVideoId(videoPath) == null ? null : 'stream/${streamVideoId(videoPath)}',
                  'videoId': streamVideoId(videoPath),
                }),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              localOrNetworkPhoto(
                raw: resolveStorageUrl(thumbnail) ?? resolveStreamThumbnailUrl(videoPath) ?? thumbnail,
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

class VideoPreviewBox extends StatefulWidget {
  const VideoPreviewBox({
    super.key,
    required this.path,
    this.onChange,
    this.onRemove,
    this.onOpen,
    this.height = 180,
    this.showDuration = false,
    this.fitCover = true,
  });
  final String path;
  final VoidCallback? onChange;
  final VoidCallback? onRemove;
  final VoidCallback? onOpen;
  final double height;
  final bool showDuration;
  final bool fitCover;

  @override
  State<VideoPreviewBox> createState() => _VideoPreviewBoxState();
}

class _VideoPreviewBoxState extends State<VideoPreviewBox> {
  VideoPlayerController? _controller;
  var _ready = false;

  @override
  void initState() {
    super.initState();
    _load(widget.path);
  }

  @override
  void didUpdateWidget(covariant VideoPreviewBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) _load(widget.path);
  }

  Future<void> _load(String path) async {
    await _controller?.dispose();
    _controller = null;
    _ready = false;
    if (mounted) setState(() {});
    final controller = await openVideoController(path);
    try {
      await initializeVideo(controller);
      controller.setLooping(true);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      _controller = controller;
      setState(() => _ready = true);
    } catch (e, stack) {
      await controller.dispose();
      AppLog.error('Video preview failed', error: e, stack: stack, tag: 'POST');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _toggle() {
    if (widget.onOpen != null) {
      widget.onOpen!();
      return;
    }
    final controller = _controller;
    if (controller == null || !_ready) return;
    setState(() {
      controller.value.isPlaying ? controller.pause() : controller.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final ratio = _ready && controller != null && controller.value.size.height > 0
        ? controller.value.aspectRatio.clamp(0.8, 1.78)
        : 16 / 9;
    final stage = ClipRect(
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          if (_ready && controller != null)
            FittedBox(
              fit: widget.fitCover ? BoxFit.cover : BoxFit.contain,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            )
          else
            const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
          Center(
            child: Material(
              color: const Color(0x99000000),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _toggle,
                child: SizedBox(
                  width: widget.onOpen != null ? 56 : 44,
                  height: widget.onOpen != null ? 56 : 44,
                  child: Icon(
                    widget.onOpen == null && _ready && controller?.value.isPlaying == true
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: widget.onOpen != null ? 34 : 26,
                  ),
                ),
              ),
            ),
          ),
          if (widget.showDuration && _ready && controller != null)
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                child: Text(
                  _formatDuration(controller.value.duration),
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          Positioned(
            right: 8,
            top: 8,
            child: MediaCornerActions(onChange: widget.onChange, onRemove: widget.onRemove),
          ),
        ],
      ),
    );
    return GestureDetector(
      onTap: widget.onOpen,
      child: ColoredBox(
        color: HomeColors.navy,
        child: widget.fitCover
            ? SizedBox(height: widget.height, width: double.infinity, child: stage)
            : AspectRatio(aspectRatio: ratio, child: stage),
      ),
    );
  }
}

class _AudioRecordPanelState extends State<AudioRecordPanel> {
  final _recorder = AudioRecorder();
  var _recording = false;
  var _seconds = 0;
  Timer? _ticker;

  @override
  void dispose() {
    _ticker?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_recording) {
      _ticker?.cancel();
      try {
        final path = await _recorder.stop();
        if (path != null && path.isNotEmpty) {
          widget.onDone(path);
          return;
        }
      } catch (e, stack) {
        AppLog.error('Stop audio failed', error: e, stack: stack, tag: 'POST');
        flash('Error', apiErrorMessage(e));
      }
      if (mounted) setState(() => _recording = false);
      return;
    }
    try {
      if (!await _recorder.hasPermission()) {
        flash('Error', 'mic_permission'.trFallback('Allow microphone access to record audio.'));
        return;
      }
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/rpd_post_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
      _seconds = 0;
      _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() => _seconds++);
        if (_seconds >= maxPostMediaDuration.inSeconds) {
          timer.cancel();
          _toggle();
        }
      });
      if (mounted) setState(() => _recording = true);
    } catch (e, stack) {
      AppLog.error('Record audio failed', error: e, stack: stack, tag: 'POST');
      flash('Error', apiErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4DCD0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('record_audio'.trFallback('Record'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          const SizedBox(height: 16),
            Text(
              _formatDuration(Duration(seconds: _seconds)),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.ink),
            ),
            const SizedBox(height: 8),
            Text(
              _recording ? 'recording'.trFallback('Recording…') : 'start_recording'.trFallback('Start recording'),
              style: const TextStyle(color: AppColors.ink3, fontSize: 13),
            ),
            const SizedBox(height: 18),
            Material(
              color: _recording ? AppColors.bad : AppColors.brand,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _toggle,
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: Icon(_recording ? Icons.stop_rounded : Icons.mic_rounded, color: Colors.white, size: 32),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _recording ? 'stop_recording'.trFallback('Stop') : 'media_max_duration'.trFallback('Video and audio can be up to 1 minute.'),
              style: const TextStyle(color: AppColors.ink3, fontSize: 12),
            ),
            if (widget.onCancel != null) ...[
              const SizedBox(height: 12),
              TextButton(onPressed: widget.onCancel, child: Text('cancel'.trFallback('Cancel'))),
            ],
          ],
        ),
    );
  }
}

class MediaCornerActions extends StatelessWidget {
  const MediaCornerActions({super.key, this.onChange, this.onRemove});
  final VoidCallback? onChange;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    if (onChange == null && onRemove == null) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onChange != null) _ActionBadge(icon: Icons.edit, onTap: onChange!),
        if (onChange != null && onRemove != null) const SizedBox(width: 6),
        if (onRemove != null) _ActionBadge(icon: Icons.close_rounded, onTap: onRemove!),
      ],
    );
  }
}

class _ActionBadge extends StatelessWidget {
  const _ActionBadge({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 16, color: Colors.white),
        ),
      ),
    );
  }
}

String _formatDuration(Duration value) {
  final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
