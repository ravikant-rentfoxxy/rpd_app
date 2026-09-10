import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:rpd_app/features/join/join_chrome.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/api_error.dart';
import '../../core/widgets/ui.dart';
import '../session/session_controller.dart';
import 'task_api.dart';

const _cream = Color(0xFFFAF6F0);
const _navy = Color(0xFF1B1340);

class CreateTaskView extends StatefulWidget {
  const CreateTaskView({super.key});

  @override
  State<CreateTaskView> createState() => _CreateTaskViewState();
}

class _CreateTaskViewState extends State<CreateTaskView> {
  final title = TextEditingController();
  final description = TextEditingController();
  bool submitting = false;

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (title.text.trim().length < 2) {
      Get.snackbar('Error', 'task_name_required'.trFallback('Enter a task name'));
      return;
    }
    setState(() => submitting = true);
    try {
      await createOrgTask(title: title.text.trim(), description: description.text.trim());
      await Get.find<SessionController>().loadHome();
      if (mounted) Get.back();
      Future<void>.delayed(const Duration(milliseconds: 250), () {
        Get.snackbar(
          'task_created'.trFallback('Task created'),
          'task_created_sub'.trFallback('Members in your region can see this in My tasks.'),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.ok,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 10,
        );
      });
    } catch (e) {
      Get.snackbar('Error', apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionController>();
    if (!session.guardVerifiedAccess() || !session.canCreateOrgEvents) {
      return Scaffold(appBar: AppBar(title: Text('create_task'.trFallback('Create task'))), body: const SizedBox.shrink());
    }
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: _navy,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _cream,
        appBar: AppBar(
          backgroundColor: _navy,
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text('create_task'.trFallback('Create task')),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: PrimaryButton(
              submitting ? '…' : 'create_task'.trFallback('Create task'),
              onTap: submitting ? () {} : _submit,
              enabled: !submitting,
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            Text(
              'create_task_sub'.trFallback('Members in your region will see this task.'),
              style: const TextStyle(fontSize: 13, color: HomeColors.muted, height: 1.4),
            ),
            const SizedBox(height: 18),
            AppField(
              label: 'task_name'.trFallback('Task name'),
              controller: title,
              hint: 'task_name_hint'.trFallback('What should they do?'),
              icon: Icons.assignment_outlined,
              maxLength: 200,
            ),
            AppField(
              label: 'task_description'.trFallback('Description'),
              controller: description,
              hint: 'task_description_hint'.trFallback('Extra detail (optional)'),
              icon: Icons.notes_rounded,
              maxLines: 5,
              maxLength: 2000,
            ),
          ],
        ),
      ),
    );
  }
}
