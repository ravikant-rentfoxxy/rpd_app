import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/api_error.dart';
import '../../core/utils/app_log.dart';
import '../../core/utils/local_image.dart';
import '../../core/widgets/ui.dart';
import '../join/join_chrome.dart';
import '../session/session_controller.dart';
import 'event_api.dart';
import 'event_datetime_sheet.dart';

const _cream = Color(0xFFFAF6F0);
const _navy = Color(0xFF1B1340);
const _navyMute = Color(0xFFB3A9D6);
const _section = Color(0xFFA6957A);
const _cardLine = Color(0xFFEFE4D6);
const _rowLine = Color(0xFFF3EBDE);
const _peach = Color(0xFFFDEBDA);
const _peachDash = Color(0xFFF0AC6B);
const _orange = Color(0xFFC2600F);
const _muted = Color(0xFF8A7F6E);
const _hint = Color(0xFFC6BBA8);
const _publish = Color(0xFFF5821F);

class CreateEventView extends StatefulWidget {
  const CreateEventView({super.key});

  @override
  State<CreateEventView> createState() => _CreateEventViewState();
}

class _CreateEventViewState extends State<CreateEventView> {
  late final String type;
  final venue = TextEditingController();
  final notes = TextEditingController();
  String? photoPath;
  DateTime startsAt = DateTime.now().add(const Duration(hours: 2));
  bool submitting = false;

  String get typeLabel => 'activity_$type'.trFallback(type);

  @override
  void initState() {
    super.initState();
    type = (Get.arguments as String?) ?? 'MEETING';
  }

  @override
  void dispose() {
    venue.dispose();
    notes.dispose();
    super.dispose();
  }

  Future<void> _addPhoto(ImageSource source) async {
    try {
      final path = await pickImageToAppDir(source, prefix: 'rpd_event');
      if (path == null) return;
      setState(() => photoPath = path);
    } catch (e, stack) {
      AppLog.error('Event photo failed', error: e, stack: stack, tag: 'EVENT');
      Get.snackbar('Error', apiErrorMessage(e));
    }
  }

  void _openPhotoSheet({bool replace = false}) {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: _cardLine, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: DisplayText(replace ? 'replace'.tr : 'add_activity_photo'.tr, size: 17),
              ),
              const SizedBox(height: 12),
              _SourceRow(
                icon: Icons.photo_camera_outlined,
                color: const Color(0xFF1B8A6A),
                wash: AppColors.okBg,
                title: 'camera'.tr,
                subtitle: 'camera_sub'.tr,
                onTap: () {
                  Get.back();
                  _addPhoto(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
              _SourceRow(
                icon: Icons.photo_library_outlined,
                color: _publish,
                wash: _peach,
                title: 'gallery'.tr,
                subtitle: 'gallery_sub'.tr,
                onTap: () {
                  Get.back();
                  _addPhoto(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
    );
  }

  Future<void> _pickDateTime() async {
    final picked = await showEventDateTimeSheet(initial: startsAt);
    if (!mounted || picked == null) return;
    setState(() => startsAt = picked);
  }

  void _viewPhoto() {
    final path = photoPath;
    if (path == null) return;
    Get.to(() => _EventPhotoViewer(path: path));
  }

  Future<void> _submit() async {
    if (venue.text.trim().length < 2) {
      Get.snackbar('Error', 'place_name_required'.tr);
      return;
    }
    if (startsAt.isBefore(DateTime.now())) {
      Get.snackbar('Error', 'event_future_required'.trFallback('Pick a future date and time'));
      return;
    }
    setState(() => submitting = true);
    try {
      await createOrgEvent(
        type: type,
        title: typeLabel,
        startsAt: startsAt,
        venue: venue.text.trim(),
        description: notes.text.trim(),
        imagePath: photoPath,
      );
      await Get.find<SessionController>().loadHome();
      if (mounted) Get.back();
      Future<void>.delayed(const Duration(milliseconds: 250), () {
        Get.snackbar(
          'event_created'.trFallback('Event created'),
          'event_created_sub'.trFallback('It now appears in Upcoming events for members below you in this region.'),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.ok,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 10,
        );
      });
    } catch (e, stack) {
      AppLog.error('Create event failed', error: e, stack: stack, tag: 'EVENT');
      Get.snackbar('Error', apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionController>();
    if (!session.guardVerifiedAccess() || !session.canCreateOrgEvents) {
      return Scaffold(appBar: AppBar(title: Text(typeLabel)), body: const SizedBox.shrink());
    }
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: _navy,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _cream,
        body: Column(
          children: [
            _Header(title: typeLabel, onBack: () => Get.back()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 22),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  _SectionLabel('photo_section'.trFallback('PHOTO')),
                  _PhotoCard(
                    path: photoPath,
                    onAdd: () => _openPhotoSheet(),
                    onReplace: () => _openPhotoSheet(replace: true),
                    onRemove: () => setState(() => photoPath = null),
                    onView: _viewPhoto,
                  ),
                  const SizedBox(height: 24),
                  _SectionLabel('event_details'.trFallback('EVENT DETAILS')),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _cardLine, width: 0.5),
                    ),
                    child: Column(
                      children: [
                        _FieldRow(
                          mark: const Icon(Icons.schedule_rounded, size: 16, color: _orange),
                          label: 'event_when'.trFallback('Date and time'),
                          onTap: _pickDateTime,
                          child: Text(
                            DateFormat('dd MMM yyyy · hh:mm a').format(startsAt),
                            style: _valueStyle,
                          ),
                        ),
                        const Divider(height: 1, thickness: 0.5, color: _rowLine),
                        _FieldRow(
                          mark: const Icon(Icons.place_outlined, size: 16, color: _orange),
                          label: 'place_name'.tr,
                          child: TextField(
                            controller: venue,
                            style: _valueStyle,
                            decoration: _inputDecoration('place_name_hint'.tr),
                          ),
                        ),
                        const Divider(height: 1, thickness: 0.5, color: _rowLine),
                        _FieldRow(
                          mark: const Icon(Icons.notes_rounded, size: 16, color: _orange),
                          label: 'event_notes'.trFallback('Notes'),
                          child: TextField(
                            controller: notes,
                            minLines: 1,
                            maxLines: 4,
                            style: _valueStyle,
                            decoration: _inputDecoration('event_notes_hint'.trFallback('Agenda or extra detail (optional)')),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ColoredBox(
              color: Colors.white,
              child: SafeArea(
                top: false,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                  decoration: const BoxDecoration(border: Border(top: BorderSide(color: _cardLine, width: 0.5))),
                  child: SizedBox(
                    height: 50,
                    child: FilledButton(
                      onPressed: submitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: _publish,
                        disabledBackgroundColor: _hint,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        elevation: 0,
                      ),
                      child: Text(
                        submitting ? '…' : 'publish_event'.trFallback('Publish event'),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final _valueStyle = GoogleFonts.ibmPlexMono(fontSize: 14, height: 1.35, color: _navy, fontWeight: FontWeight.w500);

InputDecoration _inputDecoration(String hint) {
  return InputDecoration(
    isDense: true,
    border: InputBorder.none,
    hintText: hint,
    hintStyle: GoogleFonts.ibmPlexMono(fontSize: 14, color: _hint),
    contentPadding: EdgeInsets.zero,
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onBack});
  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return ColoredBox(
      color: _navy,
      child: Padding(
        padding: EdgeInsets.fromLTRB(10, top + 8, 18, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                ),
                Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: Colors.white)),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                'create_event_eyebrow'.trFallback('CREATE UPCOMING EVENT'),
                style: const TextStyle(fontSize: 11, color: _navyMute, letterSpacing: 0.3, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(title, style: GoogleFonts.ibmPlexMono(fontSize: 15, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _section, letterSpacing: 0.2),
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({
    required this.path,
    required this.onAdd,
    required this.onReplace,
    required this.onRemove,
    required this.onView,
  });
  final String? path;
  final VoidCallback onAdd;
  final VoidCallback onReplace;
  final VoidCallback onRemove;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: _cardLine, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: path == null
          ? InkWell(
              onTap: onAdd,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: _peach,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _peachDash),
                      ),
                      child: const Icon(Icons.add_a_photo_outlined, size: 20, color: _orange),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'event_photo_hint'.trFallback('Take or choose a photo. Time and location save with it automatically.'),
                        style: const TextStyle(fontSize: 12.5, height: 1.5, color: _muted),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: onView,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(File(path!), height: 200, width: double.infinity, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _PhotoAction(icon: Icons.swap_horiz_rounded, label: 'replace'.tr, onTap: onReplace),
                      Container(width: 1, height: 16, color: const Color(0xFFD8D0C4)),
                      _PhotoAction(icon: Icons.delete_outline_rounded, label: 'remove'.tr, color: _orange, onTap: onRemove),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class _PhotoAction extends StatelessWidget {
  const _PhotoAction({required this.icon, required this.label, required this.onTap, this.color = _navy});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: color),
      label: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _EventPhotoViewer extends StatelessWidget {
  const _EventPhotoViewer({required this.path});
  final String path;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('add_activity_photo'.trFallback('Photo')),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Image.file(File(path), fit: BoxFit.contain),
        ),
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.mark, required this.label, required this.child, this.onTap});
  final Widget mark;
  final String label;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: _peach, borderRadius: BorderRadius.circular(10)),
            child: mark,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: _muted)),
                const SizedBox(height: 2),
                child,
              ],
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return row;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, child: row),
    );
  }
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({
    required this.icon,
    required this.color,
    required this.wash,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final Color wash;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _cream,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _cardLine),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: wash, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    Text(subtitle, style: const TextStyle(color: _muted, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }
}
