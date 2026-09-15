import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rpd_app/features/join/join_chrome.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/api_error.dart';
import '../../core/utils/open_url.dart';
import '../../core/widgets/flash.dart';
import 'summary_loading.dart';

const _xLimit = 280;
const _aiViolet = Color(0xFF7B5CF0);
const _aiWash = Color(0xFFF1ECFF);
final _tokenPattern = RegExp(r'[@#][A-Za-z0-9_]+');

Future<void> showPostSummarySheet({
  required BuildContext context,
  required String summary,
  Future<String> Function()? onRegenerate,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: HomeColors.navyDeep.withValues(alpha: 0.45),
    builder: (context) => _PostSummarySheet(summary: summary, onRegenerate: onRegenerate),
  );
}

class _PostSummarySheet extends StatefulWidget {
  const _PostSummarySheet({required this.summary, this.onRegenerate});
  final String summary;
  final Future<String> Function()? onRegenerate;

  @override
  State<_PostSummarySheet> createState() => _PostSummarySheetState();
}

class _PostSummarySheetState extends State<_PostSummarySheet> with TickerProviderStateMixin {
  late String _summary = widget.summary;
  var _regenerating = false;
  var _copied = false;
  Timer? _copiedTimer;
  late final AnimationController _reveal = AnimationController(vsync: this);
  late final AnimationController _shimmer =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1300));

  @override
  void initState() {
    super.initState();
    _startReveal();
  }

  @override
  void dispose() {
    _copiedTimer?.cancel();
    _reveal.dispose();
    _shimmer.dispose();
    super.dispose();
  }

  void _startReveal() {
    _reveal.duration = Duration(milliseconds: (_summary.length * 8).clamp(300, 1400));
    _reveal.forward(from: 0);
  }

  Future<void> _regenerate() async {
    final regenerate = widget.onRegenerate;
    if (regenerate == null || _regenerating) return;
    HapticFeedback.selectionClick();
    setState(() => _regenerating = true);
    _shimmer.repeat();
    try {
      final next = await regenerate();
      if (!mounted) return;
      if (next.isEmpty) {
        flash('Error', 'summary_empty'.trFallback('Could not create a summary'));
        return;
      }
      setState(() => _summary = next);
      _startReveal();
    } catch (e) {
      flash('Error', apiErrorMessage(e));
    } finally {
      _shimmer.stop();
      if (mounted) setState(() => _regenerating = false);
    }
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _summary));
    HapticFeedback.lightImpact();
    if (!mounted) return;
    setState(() => _copied = true);
    _copiedTimer?.cancel();
    _copiedTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _share(BuildContext buttonContext) async {
    final box = buttonContext.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        text: _summary,
        subject: 'get_summary'.trFallback('Summary by AI'),
        sharePositionOrigin: box == null ? Rect.zero : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  Future<void> _postOnX() {
    return openExternalUrl(
      'https://x.com/intent/post?text=${Uri.encodeComponent(_summary)}',
      preferExternal: true,
    );
  }

  List<InlineSpan> _spans(String text, {required bool caret}) {
    final spans = <InlineSpan>[];
    var start = 0;
    for (final m in _tokenPattern.allMatches(text)) {
      if (m.start > start) spans.add(TextSpan(text: text.substring(start, m.start)));
      spans.add(TextSpan(
        text: m.group(0),
        style: const TextStyle(color: HomeColors.navyMid, fontWeight: FontWeight.w700),
      ));
      start = m.end;
    }
    if (start < text.length) spans.add(TextSpan(text: text.substring(start)));
    if (caret) {
      spans.add(const TextSpan(text: ' ▍', style: TextStyle(color: _aiViolet, fontWeight: FontWeight.w400)));
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: DecoratedBox(
          decoration: const BoxDecoration(color: Colors.white),
          child: Stack(
            children: [
              const Positioned(top: 0, left: 0, right: 0, height: 200, child: _AuroraWash()),
              Padding(
                padding: EdgeInsets.fromLTRB(20, 10, 20, 16 + bottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: HomeColors.navy.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _topBar(context),
                    const SizedBox(height: 14),
                    Text(
                      'summary_title'.trFallback('Ready to post on X'),
                      style: const TextStyle(
                        fontSize: 22,
                        height: 1.2,
                        letterSpacing: -0.4,
                        fontWeight: FontWeight.w900,
                        color: HomeColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'summary_x_hint'.trFallback('Written from this grievance and tagged to the responsible departments.'),
                      style: const TextStyle(fontSize: 13.5, height: 1.4, color: HomeColors.muted),
                    ),
                    const SizedBox(height: 18),
                    _postCard(context),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shield_outlined, size: 13, color: HomeColors.muted2),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            'summary_disclaimer'.trFallback('AI can make mistakes. Review before posting.'),
                            style: const TextStyle(fontSize: 12, color: HomeColors.muted2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _primaryAction(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(8, 5, 11, 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: _aiViolet.withValues(alpha: 0.22)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AiSparkleIcon(size: 15, animating: _regenerating),
              const SizedBox(width: 6),
              Text(
                'get_summary'.trFallback('Summary by AI').toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w800,
                  color: _aiViolet,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Material(
          color: Colors.white.withValues(alpha: 0.8),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => Navigator.of(context).pop(),
            child: const SizedBox(
              width: 34,
              height: 34,
              child: Icon(Icons.close_rounded, size: 19, color: HomeColors.muted),
            ),
          ),
        ),
      ],
    );
  }

  Widget _postCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: HomeColors.border),
        boxShadow: [
          BoxShadow(color: _aiViolet.withValues(alpha: 0.08), blurRadius: 28, offset: const Offset(0, 10)),
          BoxShadow(color: HomeColors.ink.withValues(alpha: 0.03), blurRadius: 2, offset: const Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: 110,
              maxHeight: MediaQuery.sizeOf(context).height * 0.38,
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              child: _regenerating ? _skeleton() : _postText(),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: HomeColors.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 4, 14, 4),
            child: Row(
              children: [
                _CardAction(
                  icon: _copied ? Icons.check_rounded : Icons.copy_rounded,
                  label: _copied ? 'summary_copied_short'.trFallback('Copied') : 'copy_summary'.trFallback('Copy'),
                  color: _copied ? AppColors.ok : HomeColors.navy,
                  onTap: _regenerating ? null : _copy,
                ),
                if (widget.onRegenerate != null)
                  _CardAction(
                    icon: Icons.refresh_rounded,
                    label: 'summary_rewrite'.trFallback('Rewrite'),
                    color: HomeColors.navy,
                    onTap: _regenerating ? null : _regenerate,
                  ),
                Builder(
                  builder: (buttonContext) => _CardAction(
                    icon: Icons.ios_share_rounded,
                    color: HomeColors.navy,
                    onTap: _regenerating ? null : () => _share(buttonContext),
                  ),
                ),
                const Spacer(),
                if (!_regenerating) _CharCounter(length: _summary.characters.length),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _postText() {
    return SingleChildScrollView(
      key: ValueKey(_summary),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: AnimatedBuilder(
        animation: _reveal,
        builder: (context, _) {
          final chars = _summary.characters;
          final shown = chars.take((chars.length * _reveal.value).ceil()).toString();
          return SelectableText.rich(
            TextSpan(
              style: const TextStyle(fontSize: 16, height: 1.55, color: HomeColors.ink),
              children: _spans(shown, caret: _reveal.isAnimating),
            ),
          );
        },
      ),
    );
  }

  Widget _skeleton() {
    const widths = [1.0, 0.93, 0.97, 0.58];
    return Padding(
      key: const ValueKey('skeleton'),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      child: AnimatedBuilder(
        animation: _shimmer,
        builder: (context, _) {
          final t = _shimmer.value;
          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (rect) => LinearGradient(
              begin: Alignment(-3 + 4 * t, 0),
              end: Alignment(-1 + 4 * t, 0),
              colors: const [AppColors.sunk, _aiWash, Color(0xFFFFE9D4), AppColors.sunk],
              stops: const [0, 0.4, 0.6, 1],
            ).createShader(rect),
            child: LayoutBuilder(
              builder: (context, box) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final w in widths)
                    Container(
                      width: box.maxWidth * w,
                      height: 12,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: AppColors.sunk, borderRadius: BorderRadius.circular(6)),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _primaryAction() {
    return SizedBox(
      height: 54,
      child: FilledButton(
        onPressed: _regenerating ? null : _postOnX,
        style: FilledButton.styleFrom(
          backgroundColor: HomeColors.ink,
          foregroundColor: Colors.white,
          disabledBackgroundColor: HomeColors.ink.withValues(alpha: 0.35),
          disabledForegroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('𝕏', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(width: 10),
            Text(
              'summary_post_x'.trFallback('Post on X'),
              style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

/// Soft violet/peach glow at the top of the sheet that signals AI content.
class _AuroraWash extends StatelessWidget {
  const _AuroraWash();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_aiWash, Colors.white],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.95, -1.1),
                radius: 0.9,
                colors: [HomeColors.orange.withValues(alpha: 0.16), Colors.transparent],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardAction extends StatelessWidget {
  const _CardAction({required this.icon, required this.color, this.label, this.onTap});
  final IconData icon;
  final Color color;
  final String? label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = onTap == null ? HomeColors.muted2 : color;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Row(
            key: ValueKey('$icon$label'),
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: c),
              if (label != null) ...[
                const SizedBox(width: 6),
                Text(label!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// X-style counter: a ring that fills up, showing the remaining count near the limit.
class _CharCounter extends StatelessWidget {
  const _CharCounter({required this.length});
  final int length;

  @override
  Widget build(BuildContext context) {
    final remaining = _xLimit - length;
    final near = remaining <= 20;
    final color = remaining < 0
        ? AppColors.bad
        : near
            ? HomeColors.orange
            : _aiViolet;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (near) ...[
          Text(
            '$remaining',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(width: 6),
        ],
        SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            value: (length / _xLimit).clamp(0.0, 1.0),
            strokeWidth: 2.4,
            backgroundColor: AppColors.sunk,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}
