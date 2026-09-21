import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/post_issues.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/api_error.dart';
import '../../core/utils/app_log.dart';
import '../../core/utils/local_image.dart';
import '../../core/utils/network.dart';
import '../../core/utils/relative_time.dart';
import '../../core/widgets/empty_card.dart';
import '../../core/widgets/ui.dart';
import '../../data/local/hive_service.dart';
import '../join/join_chrome.dart';
import '../session/complete_profile_dialog.dart';
import '../session/session_controller.dart';
import 'post_api.dart';
import 'post_done_celebration.dart';
import 'post_issue_sheet.dart';
import 'post_media.dart';
import '../../core/widgets/flash.dart';

enum _PostMediaKind { image, audio, video }

class PostsListView extends StatefulWidget {
  const PostsListView({super.key});

  @override
  State<PostsListView> createState() => _PostsListViewState();
}

class _PostsListViewState extends State<PostsListView> with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    final session = Get.find<SessionController>();
    session.syncPendingPosts();
    session.refreshRegionPosts();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionController>();
    return Scaffold(
      backgroundColor: HomeColors.paper,
      appBar: AppBar(
        backgroundColor: HomeColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('region_posts'.tr),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: HomeColors.navy,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        ),
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: HomeColors.orange,
          indicatorWeight: 3,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xB3FFFFFF),
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          tabs: [
            Tab(text: 'my_posts'.trFallback('My posts')),
            Tab(text: 'other_posts'.trFallback('Other posts')),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: const _CreatePostButton(),
      body: Obx(() {
        session.postsTick.value;
        return TabBarView(
          controller: _tabs,
          children: [
            _PostsPane(posts: session.myPosts(), emptyKey: 'my_posts_empty'),
            _PostsPane(posts: session.otherPosts(), emptyKey: 'other_posts_empty'),
          ],
        );
      }),
    );
  }
}

class _PostsPane extends StatelessWidget {
  const _PostsPane({required this.posts, required this.emptyKey});
  final List<Map<String, dynamic>> posts;
  final String emptyKey;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AppEmptyCard(
            icon: Icons.forum_outlined,
            title: emptyKey == 'my_posts_empty'
                ? 'my_posts_empty'.trFallback('You have not shared any posts yet. Tap + to create one.')
                : 'other_posts_empty'.trFallback('No posts from others in your region yet.'),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: posts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) => RegionPostCard(post: posts[index]),
    );
  }
}

class _CreatePostButton extends StatelessWidget {
  const _CreatePostButton();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Color(0x73F07E1D), blurRadius: 22, offset: Offset(0, 8)),
        ],
      ),
      child: Material(
        color: HomeColors.orange,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const CircleBorder(),
          splashColor: const Color(0xA3FFE7C2),
          highlightColor: const Color(0x66FFFFFF),
          splashFactory: InkSparkle.splashFactory,
          onTap: () {
            if (!Get.find<SessionController>().guardCreatePost()) return;
            Get.toNamed(Routes.createPost);
          },
          child: const SizedBox(
            width: 64,
            height: 64,
            child: Icon(Icons.post_add_rounded, color: Colors.white, size: 30),
          ),
        ),
      ),
    );
  }
}

class CreatePostView extends StatefulWidget {
  const CreatePostView({super.key});

  @override
  State<CreatePostView> createState() => _CreatePostViewState();
}

class _CreatePostViewState extends State<CreatePostView> {
  final description = TextEditingController();
  final mediaKind = _PostMediaKind.image.obs;
  final mediaPath = Rxn<String>();
  final thumbPath = Rxn<String>();
  final documentPath = Rxn<String>();
  final addingDocument = false.obs;
  final recording = false.obs;
  final submitting = false.obs;
  final online = true.obs;
  final issues = <Map<String, dynamic>>[].obs;
  final selectedIssue = Rxn<Map<String, dynamic>>();
  final selectedSubIssue = Rxn<Map<String, dynamic>>();
  StreamSubscription<bool>? _networkSub;
  bool _openedIssueSheet = false;
  late final bool _openedFromPosts;

  @override
  void initState() {
    super.initState();
    _openedFromPosts = Get.previousRoute == Routes.posts;
    Get.find<SessionController>().captureLocation();
    _networkSub = watchNetwork().listen((value) => online.value = value);
    _loadIssues();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!Get.find<SessionController>().canUseMemberActions) {
        Get.back();
        showCompleteProfileDialog();
        return;
      }
      _pickIssue(auto: true);
    });
  }

  Future<void> _loadIssues() async {
    issues.assignAll(localPostIssues());
    final current = selectedIssue.value;
    if (current != null && issues.every((issue) => issueKey(issue) != issueKey(current))) {
      selectedIssue.value = null;
      selectedSubIssue.value = null;
    }
  }

  Future<void> _pickIssue({bool auto = false}) async {
    if (!mounted || issues.isEmpty) return;
    if (auto && (_openedIssueSheet || selectedSubIssue.value != null)) return;
    _openedIssueSheet = true;
    final picked = await showIssueSelectSheet(
      context: context,
      issues: issues,
      selectedId: selectedIssue.value == null ? null : issueKey(selectedIssue.value!),
      selectedSubId: selectedSubIssue.value == null ? null : issueKey(selectedSubIssue.value!),
    );
    if (!mounted || picked == null) return;
    selectedIssue.value = picked.issue;
    selectedSubIssue.value = picked.subIssue;
    _showMediaInfo();
  }

  void _showMediaInfo() {
    if (!mounted) return;
    flash(
      'media_info_title'.tr,
      'media_info_snack'.tr,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: HomeColors.navy,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 10,
      duration: const Duration(seconds: 4),
    );
  }

  Map<String, dynamic>? get _selectedIssue => selectedIssue.value;
  Map<String, dynamic>? get _selectedSubIssue => selectedSubIssue.value;

  @override
  void dispose() {
    _networkSub?.cancel();
    description.dispose();
    super.dispose();
  }

  Future<void> _showOfflineMessage() async {
    if (Get.isDialogOpen == true) return;
    await Get.dialog(
      const _OfflineInfoDialog(),
      barrierDismissible: true,
      barrierColor: Colors.black54,
    );
  }

  Future<bool> _requireNetwork() async {
    final connected = await hasNetwork();
    online.value = connected;
    if (connected) return true;
    await _showOfflineMessage();
    return false;
  }

  void _useKind(_PostMediaKind kind) {
    if (mediaKind.value != kind) {
      mediaPath.value = null;
      thumbPath.value = null;
    }
    mediaKind.value = kind;
    recording.value = false;
  }

  Future<void> _openMediaPicker() async {
    if (Get.isBottomSheetOpen == true) Get.back();
    await Get.bottomSheet(
      _MediaChoiceSheet(
        onCameraPhoto: () {
          _useKind(_PostMediaKind.image);
          _pickImage(ImageSource.camera);
        },
        onCameraVideo: () {
          _useKind(_PostMediaKind.video);
          _pickVideo(ImageSource.camera);
        },
        onRecord: () {
          _useKind(_PostMediaKind.audio);
          _startAudioRecord();
        },
        onGalleryImage: () {
          _useKind(_PostMediaKind.image);
          _pickImage(ImageSource.gallery);
        },
        onGalleryVideo: () {
          _useKind(_PostMediaKind.video);
          _pickVideo(ImageSource.gallery);
        },
        onGalleryAudio: () {
          _useKind(_PostMediaKind.audio);
          _pickAudio();
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Future<void> _openReplace() async {
    final kind = mediaKind.value;
    if (kind == _PostMediaKind.audio || kind == _PostMediaKind.video) {
      if (!await _requireNetwork()) return;
    }
    recording.value = false;
    await _openMediaPicker();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final path = await pickImageToAppDir(source, prefix: 'rpd_post', maxEdge: 1400, quality: 72);
      if (path != null) {
        mediaPath.value = path;
        recording.value = false;
      }
    } catch (e, stack) {
      AppLog.error('Post photo failed', error: e, stack: stack, tag: 'POST');
      flash('Error', apiErrorMessage(e));
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    if (!await hasNetwork()) {
      online.value = false;
      await _showOfflineMessage();
      return;
    }
    try {
      final picked = await ImagePicker().pickVideo(
        source: source,
        maxDuration: maxPostMediaDuration,
      );
      if (picked == null) return;
      final tooLong = await postMediaDurationError(picked.path, video: true);
      if (tooLong != null) {
        flash('Error', tooLong);
        return;
      }
      mediaPath.value = picked.path;
      thumbPath.value = await generateVideoThumbnail(picked.path);
      recording.value = false;
    } catch (e, stack) {
      AppLog.error('Post video failed', error: e, stack: stack, tag: 'POST');
      flash('Error', apiErrorMessage(e));
    }
  }

  Future<void> _startAudioRecord() async {
    if (!await _requireNetwork()) return;
    recording.value = true;
  }

  Future<void> _pickDocument() async {
    try {
      final picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'webp'],
      );
      final path = picked?.path;
      if (path == null || path.isEmpty) return;
      documentPath.value = path;
      addingDocument.value = false;
    } catch (e, stack) {
      AppLog.error('Post document failed', error: e, stack: stack, tag: 'POST');
      flash('Error', apiErrorMessage(e));
    }
  }

  Future<void> _pickAudio() async {
    if (!await hasNetwork()) {
      online.value = false;
      await _showOfflineMessage();
      return;
    }
    try {
      final picked = await FilePicker.pickFile(type: FileType.audio);
      final path = picked?.path;
      if (path == null || path.isEmpty) return;
      final tooLong = await postMediaDurationError(path, video: false);
      if (tooLong != null) {
        flash('Error', tooLong);
        return;
      }
      mediaPath.value = path;
      recording.value = false;
    } catch (e, stack) {
      AppLog.error('Post audio failed', error: e, stack: stack, tag: 'POST');
      flash('Error', apiErrorMessage(e));
    }
  }

  Future<void> submit() async {
    final kind = mediaKind.value;
    final issue = _selectedIssue;
    final subIssue = _selectedSubIssue;
    if (issue == null) {
      flash('Error', 'post_issue_required'.trFallback('Select an issue'));
      return;
    }
    if (subIssue == null) {
      flash('Error', 'post_sub_issue_required'.trFallback('Select a sub-issue'));
      return;
    }
    final localPath = mediaPath.value;
    final hasMedia = localPath != null && localPath.isNotEmpty;
    final hasText = description.text.trim().isNotEmpty;
    if (!hasMedia && !hasText) {
      flash('Error', 'post_content_required'.trFallback('Add a photo, audio or video, or write a description'));
      return;
    }
    if (hasMedia && (kind == _PostMediaKind.video || kind == _PostMediaKind.audio)) {
      final tooLong = await postMediaDurationError(localPath, video: kind == _PostMediaKind.video);
      if (tooLong != null) {
        flash('Error', tooLong);
        return;
      }
    }
    final connected = await hasNetwork();
    online.value = connected;
    if (!connected && (kind != _PostMediaKind.image || !hasMedia || documentPath.value != null)) {
      await _showOfflineMessage();
      return;
    }
    submitting.value = true;
    try {
      final session = Get.find<SessionController>();
      final hive = Get.find<HiveService>();
      if (session.lat.value == null || session.lng.value == null) {
        await session.captureLocation();
      }
      final member = session.member ?? {};
      final booth = member['booth'] is Map ? Map<String, dynamic>.from(member['booth'] as Map) : <String, dynamic>{};
      final type = hasMedia ? kind.name : 'image';
      final id = const Uuid().v4();
      var thumbnail = hasMedia ? thumbPath.value : null;
      if (hasMedia && kind == _PostMediaKind.video && (thumbnail == null || !File(thumbnail).existsSync())) {
        thumbnail = await generateVideoThumbnail(localPath!);
        thumbPath.value = thumbnail;
      }
      final issueId = '${issue['id'] ?? ''}';
      final issueCode = '${issue['code'] ?? ''}';
      final subIssueId = '${subIssue['id'] ?? ''}';
      final subIssueCode = '${subIssue['code'] ?? ''}';
      final row = {
        'id': id,
        'clientUuid': id,
        'description': description.text.trim(),
        'mediaType': type,
        'issueId': issueId,
        'issueCode': issueCode,
        'issueName': issue['name'],
        'issueNameHi': issue['nameHi'],
        'issueNameBho': issue['nameBho'],
        'issuePriority': issue['priority'],
        'issueBand': issue['band'],
        'issue': issue,
        'subIssueId': subIssueId,
        'subIssueCode': subIssueCode,
        'subIssueName': subIssue['name'],
        'subIssueNameHi': subIssue['nameHi'],
        'subIssueNameBho': subIssue['nameBho'],
        'subIssue': subIssue,
        'mediaPath': localPath,
        'photoPath': hasMedia && kind == _PostMediaKind.image ? localPath : null,
        'thumbnailPath': thumbnail,
        'createdAt': DateTime.now().toIso8601String(),
        'latitude': session.lat.value,
        'longitude': session.lng.value,
        'authorId': member['id'],
        'authorName': (member['fullName'] as String?)?.trim().isNotEmpty == true ? member['fullName'] : 'Karyakarta',
        'authorMobile': hive.currentMobile ?? member['mobile'],
        'districtId': member['districtId'] ?? booth['districtId'],
        'assemblyId': member['assemblyId'] ?? booth['assemblyId'],
        'boothId': member['boothId'] ?? booth['id'],
        'regionLabel': booth['village'] ?? booth['name'] ?? member['districtName'] ?? '',
      };
      if (connected) {
        final uploaded = await uploadRegionPost(
          clientUuid: id,
          mediaType: type,
          filePath: localPath,
          description: row['description'] as String,
          issueId: issueId.isEmpty ? null : issueId,
          issueCode: issueCode.isEmpty ? null : issueCode,
          subIssueId: subIssueId.isEmpty ? null : subIssueId,
          subIssueCode: subIssueCode.isEmpty ? null : subIssueCode,
          latitude: session.lat.value,
          longitude: session.lng.value,
          districtId: row['districtId'],
          assemblyId: row['assemblyId'],
          boothId: row['boothId'],
          regionLabel: row['regionLabel'] as String?,
          authorName: row['authorName'] as String?,
          authorMobile: row['authorMobile'],
          thumbnailPath: thumbnail,
          documentPath: documentPath.value,
        );
        await persistUploadedPost(
          uploaded,
          localPath: localPath,
          thumbnailPath: thumbnail,
          documentPath: documentPath.value,
        );
        session.upsertRegionPost(uploaded);
      } else {
        await hive.savePost({...row, 'pending': true, 'mediaType': 'image'});
        await hive.enqueueSync({...row, 'type': 'REGION_POST', 'title': 'post_saved_offline'.tr});
        session.syncCount.value = hive.pendingSync().length;
      }
      session.postsTick.value++;
      unawaited(session.refreshRegionPosts());
      submitting.value = false;
      if (!mounted) return;
      await showPostDoneCelebration(context, offline: !connected);
      if (mounted) _openRegionPosts();
    } catch (e, stack) {
      AppLog.error('Post save failed', error: e, stack: stack, tag: 'POST');
      submitting.value = false;
      flash('Error', apiErrorMessage(e));
    }
  }

  void _openRegionPosts() {
    if (_openedFromPosts) {
      closeFlash();
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
        return;
      }
      if (Get.key.currentState?.canPop() ?? false) {
        Get.back();
        return;
      }
    }
    Get.offNamed(Routes.posts);
  }

  @override
  Widget build(BuildContext context) {
    const cream = Color(0xFFF8F4E9);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || submitting.value) return;
        _openRegionPosts();
      },
      child: Scaffold(
      backgroundColor: cream,
      appBar: OrganicAppBar(
        title: 'create_post'.trFallback('Create post'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (submitting.value) return;
            _openRegionPosts();
          },
        ),
      ),
      body: Stack(
        children: [
          ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          Text(
            'sharing_title'.trFallback('What are you sharing?'),
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF1A1325), height: 1.15),
          ),
          const SizedBox(height: 8),
          Text(
            'create_post_issue_first'.trFallback('Select the issue first. Then add media.'),
            style: const TextStyle(color: Color(0xFF7A746C), fontSize: 13.5, height: 1.4),
          ),
          const SizedBox(height: 18),
          Obx(
            () => _IssueDropdown(
              issue: selectedIssue.value,
              subIssue: selectedSubIssue.value,
              onTap: _pickIssue,
            ),
          ),
          const SizedBox(height: 16),
          Obx(() {
            if (recording.value) {
              return AudioRecordPanel(
                onDone: (path) async {
                  // The panel stops itself at a minute; confirm the file agrees.
                  final tooLong = await postMediaDurationError(path, video: false);
                  if (tooLong != null) {
                    recording.value = false;
                    flash('Error', tooLong);
                    return;
                  }
                  mediaPath.value = path;
                  recording.value = false;
                },
                onCancel: () {
                  recording.value = false;
                },
              );
            }
            if (mediaPath.value == null) {
              return _AddMediaTile(onTap: _openMediaPicker);
            }
            return _ComposerMedia(
              kind: mediaKind.value,
              path: mediaPath.value,
              offline: !online.value,
              onReplace: _openReplace,
              onRemove: () {
                mediaPath.value = null;
                documentPath.value = null;
                addingDocument.value = false;
              },
            );
          }),
          Obx(() {
            if (mediaPath.value == null) return const SizedBox.shrink();
            if (documentPath.value != null) {
              return Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _DocumentChip(
                  path: documentPath.value!,
                  onRemove: () {
                    documentPath.value = null;
                    addingDocument.value = false;
                  },
                ),
              );
            }
            if (addingDocument.value) {
              return Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _AddDocumentTile(onTap: _pickDocument),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => addingDocument.value = true,
                  icon: const Icon(Icons.attach_file_rounded, size: 18, color: HomeColors.orange),
                  label: Text(
                    'add_extra_document'.trFallback('Add extra document'),
                    style: const TextStyle(color: HomeColors.orange, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 22),
          Text(
            '${'post_description'.trFallback('Description')} (${'optional'.trFallback('optional')})',
            style: const TextStyle(color: Color(0xFF1A1325), fontWeight: FontWeight.w700, fontSize: 13),
          ),
          TextField(
            controller: description,
            minLines: 1,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            cursorColor: HomeColors.orange,
            decoration: InputDecoration(
              hintText: 'post_description_hint'.trFallback('Write a short update if you want'),
              hintStyle: const TextStyle(color: Color(0xFFB0A89C), fontSize: 14),
              border: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD8D0C4))),
              enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD8D0C4))),
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: HomeColors.orange, width: 1.4)),
            ),
          ),
          const SizedBox(height: 28),
          Obx(
            () => _PostUpdateButton(
              label: submitting.value ? 'posting'.trFallback('Posting…') : 'publish_post'.trFallback('Post update'),
              enabled: !submitting.value,
              loading: submitting.value,
              onTap: submit,
            ),
          ),
        ],
      ),
          Obx(() {
            if (!submitting.value) return const SizedBox.shrink();
            return const Positioned.fill(child: _PostSubmittingOverlay());
          }),
        ],
      ),
      ),
    );
  }
}

class CreatePostEntry extends StatelessWidget {
  const CreatePostEntry({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap ??
            () {
              if (!Get.find<SessionController>().guardCreatePost()) return;
              Get.toNamed(Routes.createPost);
            },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: HomeColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: HomeColors.peach2, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.add, color: HomeColors.orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'start_post'.trFallback('Create a post'),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: HomeColors.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'start_post_hint'.trFallback('Add a photo, audio or video and share it with your region.'),
                      style: const TextStyle(color: HomeColors.muted, fontSize: 12, height: 1.3),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: HomeColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _IssueDropdown extends StatelessWidget {
  const _IssueDropdown({required this.issue, required this.subIssue, required this.onTap});
  final Map<String, dynamic>? issue;
  final Map<String, dynamic>? subIssue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final filled = issue != null && subIssue != null;
    final label = issuePathLabelOf(issue, subIssue);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 44,
          padding: const EdgeInsets.fromLTRB(12, 0, 8, 0),
          decoration: BoxDecoration(
            color: filled ? const Color(0xFFFFF7EC) : const Color(0xFFFFF1E0),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: HomeColors.orange, width: 1.2),
          ),
          child: Row(
            children: [
              Text(
                '${'post_issue'.trFallback('Issue')} *',
                style: const TextStyle(
                  color: HomeColors.orange,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label.isEmpty ? 'post_issue_hint'.trFallback('Select issue and sub-issue') : label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: filled ? const Color(0xFF1A1325) : const Color(0xFF9A6A3A),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded, color: HomeColors.orange, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class IssueChip extends StatelessWidget {
  const IssueChip({super.key, required this.label, required this.priority});
  final String label;
  final int priority;

  @override
  Widget build(BuildContext context) {
    final color = switch (priority) {
      <= 5 => const Color(0xFFC62828),
      <= 9 => const Color(0xFFE65100),
      <= 12 => const Color(0xFFB8860B),
      _ => const Color(0xFF6D6775),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _AddDocumentTile extends StatelessWidget {
  const _AddDocumentTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF3EEE6),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 132,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE4DCD0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.insert_drive_file_outlined, color: HomeColors.orange, size: 30),
              const SizedBox(height: 8),
              Text('add_document'.trFallback('Add document'), style: const TextStyle(color: Color(0xFF1A1325), fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                'add_document_hint'.trFallback('PDF, Word or a photo of the document'),
                style: const TextStyle(color: Color(0xFF8A847A), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentChip extends StatelessWidget {
  const _DocumentChip({required this.path, required this.onRemove});
  final String path;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final name = path.split(RegExp(r'[/\\]')).last;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE4DCD0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.attach_file_rounded, color: HomeColors.orange, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1A1325)),
              ),
            ),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.close_rounded, size: 18, color: HomeColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddMediaTile extends StatelessWidget {
  const _AddMediaTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF3EEE6),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 168,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE4DCD0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_photo_alternate_outlined, color: HomeColors.orange, size: 32),
              const SizedBox(height: 8),
              Text('add_media'.trFallback('Add media'), style: const TextStyle(color: Color(0xFF1A1325), fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                'add_media_hint'.trFallback('Camera, record or gallery'),
                style: const TextStyle(color: Color(0xFF8A847A), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _MediaSheetPage { root, camera, gallery }

class _MediaChoiceSheet extends StatefulWidget {
  const _MediaChoiceSheet({
    required this.onCameraPhoto,
    required this.onCameraVideo,
    required this.onRecord,
    required this.onGalleryImage,
    required this.onGalleryVideo,
    required this.onGalleryAudio,
  });

  final VoidCallback onCameraPhoto;
  final VoidCallback onCameraVideo;
  final VoidCallback onRecord;
  final VoidCallback onGalleryImage;
  final VoidCallback onGalleryVideo;
  final VoidCallback onGalleryAudio;

  @override
  State<_MediaChoiceSheet> createState() => _MediaChoiceSheetState();
}

class _MediaChoiceSheetState extends State<_MediaChoiceSheet> {
  _MediaSheetPage page = _MediaSheetPage.root;

  Future<void> _run(VoidCallback action) async {
    Navigator.of(context).maybePop();
    await Future<void>.delayed(const Duration(milliseconds: 220));
    action();
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (page) {
      _MediaSheetPage.root => 'add_media'.trFallback('Add media'),
      _MediaSheetPage.camera => 'media_camera'.trFallback('Camera'),
      _MediaSheetPage.gallery => 'media_gallery'.trFallback('Gallery'),
    };
    final options = switch (page) {
      _MediaSheetPage.root => [
        (
          Icons.photo_camera_outlined,
          'media_camera'.trFallback('Camera'),
          'media_camera_sub'.trFallback('Take a photo or video'),
          () => setState(() => page = _MediaSheetPage.camera),
        ),
        (
          Icons.mic_none_rounded,
          'media_record'.trFallback('Record'),
          'media_record_sub'.trFallback('Record audio'),
          () => _run(widget.onRecord),
        ),
        (
          Icons.photo_library_outlined,
          'media_gallery'.trFallback('Gallery'),
          'media_gallery_sub'.trFallback('Choose image, video or audio'),
          () => setState(() => page = _MediaSheetPage.gallery),
        ),
      ],
      _MediaSheetPage.camera => [
        (
          Icons.photo_camera_outlined,
          'media_photo'.trFallback('Photo'),
          'camera_sub'.trFallback('Take a new photo'),
          () => _run(widget.onCameraPhoto),
        ),
        (
          Icons.videocam_outlined,
          'media_video'.trFallback('Video'),
          'camera_video_sub'.trFallback('Record a video'),
          () => _run(widget.onCameraVideo),
        ),
      ],
      _MediaSheetPage.gallery => [
        (
          Icons.image_outlined,
          'media_image'.trFallback('Image'),
          'gallery_sub'.trFallback('Choose from this phone'),
          () => _run(widget.onGalleryImage),
        ),
        (
          Icons.videocam_outlined,
          'media_video'.trFallback('Video'),
          'gallery_video_sub'.trFallback('Choose from this phone'),
          () => _run(widget.onGalleryVideo),
        ),
        (
          Icons.audiotrack_outlined,
          'media_audio'.trFallback('Audio'),
          'upload_audio_sub'.trFallback('Choose an audio file from this phone'),
          () => _run(widget.onGalleryAudio),
        ),
      ],
    };

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: const Color(0xFFE4DCD0), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (page != _MediaSheetPage.root)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => setState(() => page = _MediaSheetPage.root),
                    icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1325)),
                  ),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1A1325)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            for (final option in options)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(color: HomeColors.peach2, borderRadius: BorderRadius.circular(12)),
                  child: Icon(option.$1, color: HomeColors.orange),
                ),
                title: Text(option.$2, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(option.$3, style: const TextStyle(fontSize: 12, color: Color(0xFF8A847A))),
                onTap: option.$4,
              ),
          ],
        ),
      ),
    );
  }
}

class RegionPostCard extends StatelessWidget {
  const RegionPostCard({super.key, required this.post, this.compact = false, this.onTap});
  final Map<String, dynamic> post;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final type = isVideoPost(post) ? 'video' : '${post['mediaType'] ?? 'image'}'.toLowerCase();
    final raw = post['mediaUrl'] ?? post['mediaPath'] ?? post['photoPath'] ?? post['mediaKey'];
    final path = switch (type) {
      'video' => postVideoUrl(post) ?? postImageUrl(post) ?? localPhotoPath(raw),
      'audio' => postAudioUrl(post) ?? localPhotoPath(raw),
      _ => postImageUrl(post) ?? localPhotoPath(raw),
    };
    final thumb = post['thumbnailUrl'] ?? post['thumbnailPath'] ?? post['thumbnailKey'] ?? resolveStreamThumbnailUrl(raw) ?? postImageUrl(post);
    final description = '${post['description'] ?? ''}';
    final issue = issueLabelOf(post);
    final height = compact ? 110.0 : 148.0;
    final hasMedia = type == 'video' || (path != null && path.isNotEmpty);
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: HomeColors.border, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap ?? () => Get.toNamed(Routes.postDetail, arguments: post),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasMedia)
            _PostMediaTile(type: type, path: path, thumbnail: thumb, height: height),
          ColoredBox(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (issue.isNotEmpty) ...[
                    IssueChip(label: issue, priority: issuePriorityOf(post)),
                    const SizedBox(height: 8),
                  ],
                  if (description.isNotEmpty) ...[
                    Text(
                      description,
                      maxLines: compact ? 2 : 6,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, height: 1.4, color: HomeColors.ink),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastActiveWhen(post['createdAt']),
                          style: const TextStyle(fontSize: 12, color: HomeColors.muted),
                        ),
                      ),
                      if ('${post['status'] ?? ''}'.toUpperCase() == 'RESOLVED')
                        Text(
                          'resolve_resolved'.trFallback('Resolved'),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: HomeColors.teal),
                        ),
                    ],
                  ),
                  if ('${post['authorName'] ?? ''}'.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${'posted_by'.trFallback('Posted by')} ${post['authorName']}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: HomeColors.ink),
                    ),
                  ],
                  if (post['isAssignedToMe'] == true) ...[
                    if ('${post['assignedByName'] ?? ''}'.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${'post_assigned_by'.trFallback('Assigned by')} ${post['assignedByName']}'
                        '${'${post['assignedByPostLabel'] ?? ''}'.trim().isEmpty ? '' : ' · ${post['assignedByPostLabel']}'}',
                        style: const TextStyle(fontSize: 12, color: HomeColors.ink),
                      ),
                    ],
                  ] else if ('${post['assigneeName'] ?? ''}'.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${'assigned_to'.trFallback('Assigned to')} ${post['assigneeName']}'
                      '${'${post['assigneePostLabel'] ?? ''}'.trim().isEmpty ? '' : ' · ${post['assigneePostLabel']}'}',
                      style: const TextStyle(fontSize: 12, color: HomeColors.ink),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}

class _OfflineInfoDialog extends StatelessWidget {
  const _OfflineInfoDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpace.cardRadius)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.info_outline_rounded, color: HomeColors.orange, size: 36),
            const SizedBox(height: 12),
            Text(
              'no_internet'.trFallback('No internet connectivity'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink),
            ),
            const SizedBox(height: 8),
            Text(
              'post_needs_network'.trFallback('Connect to the internet to add audio or video.'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, height: 1.4, color: AppColors.ink2),
            ),
            const SizedBox(height: 20),
            PrimaryButton('got_it'.trFallback('OK'), onTap: Get.back),
          ],
        ),
      ),
    );
  }
}

class _ComposerMedia extends StatelessWidget {
  const _ComposerMedia({
    required this.kind,
    required this.path,
    required this.offline,
    required this.onReplace,
    required this.onRemove,
  });

  final _PostMediaKind kind;
  final String? path;
  final bool offline;
  final VoidCallback onReplace;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    if (path == null) {
      final label = switch (kind) {
        _PostMediaKind.image => 'add_post_photo'.trFallback('Add photo'),
        _PostMediaKind.audio => 'add_post_audio'.trFallback('Add audio'),
        _PostMediaKind.video => 'add_post_video'.trFallback('Add video'),
      };
      final icon = switch (kind) {
        _PostMediaKind.image => Icons.add_a_photo_outlined,
        _PostMediaKind.audio => Icons.mic_none_rounded,
        _PostMediaKind.video => Icons.videocam_outlined,
      };
      return InkWell(
        onTap: onReplace,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 168,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFF3EEE6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE4DCD0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: HomeColors.orange, size: 30),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(color: Color(0xFF1A1325), fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      );
    }
    final replaceLabel = 'replace'.trFallback('Replace');
    final replaceIcon = Icons.swap_horiz_rounded;
    return Column(
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: switch (kind) {
                _PostMediaKind.image => Image.file(File(path!), height: 200, width: double.infinity, fit: BoxFit.cover),
                _PostMediaKind.video => VideoPreviewBox(path: path!, height: 200, showDuration: true),
                _PostMediaKind.audio => ComposerAudioCard(path: path!),
              },
            ),
            if (kind == _PostMediaKind.image && offline)
              const Positioned(right: 10, top: 10, child: _SavedOfflineBadge()),
            if (kind != _PostMediaKind.image)
              Positioned(
                right: 10,
                top: 10,
                child: _NeedsSignalBadge(muted: !offline),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _TextAction(
              icon: replaceIcon,
              label: replaceLabel,
              onTap: onReplace,
            ),
            const SizedBox(width: 8),
            Container(width: 1, height: 16, color: const Color(0xFFD8D0C4)),
            const SizedBox(width: 8),
            _TextAction(
              icon: Icons.delete_outline_rounded,
              label: 'remove'.trFallback('Remove'),
              color: HomeColors.orange,
              onTap: onRemove,
            ),
          ],
        ),
      ],
    );
  }
}

class _SavedOfflineBadge extends StatelessWidget {
  const _SavedOfflineBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 74,
      height: 74,
      decoration: const BoxDecoration(color: HomeColors.orange, shape: BoxShape.circle),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sync_rounded, color: Colors.white, size: 20),
          const SizedBox(height: 2),
          Text(
            'saved_offline'.trFallback('SAVED\nOFFLINE'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800, height: 1.15),
          ),
        ],
      ),
    );
  }
}

class _NeedsSignalBadge extends StatelessWidget {
  const _NeedsSignalBadge({this.muted = false});
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: muted ? const Color(0xFFE8E4DC) : const Color(0xFFE8E4DC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule_rounded, size: 13, color: muted ? const Color(0xFF7A746C) : const Color(0xFF5C564E)),
          const SizedBox(width: 4),
          Text(
            'needs_signal'.trFallback('NEEDS SIGNAL'),
            style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 0.3, color: Color(0xFF5C564E)),
          ),
        ],
      ),
    );
  }
}

class _TextAction extends StatelessWidget {
  const _TextAction({required this.icon, required this.label, required this.onTap, this.color});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? const Color(0xFF1A1325);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          children: [
            Icon(icon, size: 16, color: tint),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: tint)),
          ],
        ),
      ),
    );
  }
}

class _PostUpdateButton extends StatelessWidget {
  const _PostUpdateButton({required this.label, required this.enabled, required this.onTap, this.loading = false});
  final String label;
  final bool enabled;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled || loading ? HomeColors.orange : const Color(0xFFE4DCD0),
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(28),
        child: SizedBox(
          height: 54,
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                  )
                : Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
          ),
        ),
      ),
    );
  }
}

class _PostSubmittingOverlay extends StatelessWidget {
  const _PostSubmittingOverlay();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0x99000000),
      child: Center(
        child: Container(
          width: 220,
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 10))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 42,
                height: 42,
                child: CircularProgressIndicator(strokeWidth: 3, color: HomeColors.orange),
              ),
              const SizedBox(height: 16),
              Text(
                'posting'.trFallback('Posting…'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: HomeColors.ink),
              ),
              const SizedBox(height: 6),
              Text(
                'posting_sub'.trFallback('Please wait while we send your update.'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: HomeColors.muted, height: 1.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostMediaTile extends StatelessWidget {
  const _PostMediaTile({required this.type, required this.path, required this.height, this.thumbnail});
  final String type;
  final String? path;
  final Object? thumbnail;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (type == 'video') {
      return VideoThumbTile(videoPath: path ?? '', thumbnail: thumbnail, height: height);
    }
    if (path == null || path!.isEmpty) {
      return ColoredBox(color: HomeColors.navy, child: SizedBox(height: height, width: double.infinity));
    }
    if (type == 'audio') return AudioListenBar(path: path!, compact: height < 150);
    return SizedBox(
      height: height,
      width: double.infinity,
      child: localOrNetworkPhoto(
        raw: path,
        fit: BoxFit.cover,
        fallback: const ColoredBox(color: HomeColors.navy),
      ),
    );
  }
}

