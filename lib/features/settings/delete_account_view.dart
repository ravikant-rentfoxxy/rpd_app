import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/api_error.dart';
import '../../core/widgets/flash.dart';
import '../../core/widgets/iro_ui.dart';
import '../../core/widgets/ui.dart';
import '../join/join_chrome.dart';
import '../session/session_controller.dart';

/// Where a member deletes their own account: what goes with it, why they are
/// leaving (required by the API), and the button that does it.
class DeleteAccountView extends StatefulWidget {
  const DeleteAccountView({super.key});

  @override
  State<DeleteAccountView> createState() => _DeleteAccountViewState();
}

class _DeleteAccountViewState extends State<DeleteAccountView> {
  /// The server asks for at least this much reason.
  static const _minReason = 3;
  static const _maxReason = 1000;

  final _reason = TextEditingController();
  bool _busy = false;

  bool get _canSubmit => !_busy && _reason.text.trim().length >= _minReason;

  @override
  void initState() {
    super.initState();
    _reason.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      // Signing out replaces every route, this screen included.
      await Get.find<SessionController>().deleteAccount(_reason.text.trim());
      flash('OK', 'delete_account_done'.trFallback('Your account has been deleted.'));
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      flash('Error', apiErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: OrganicAppBar(title: 'delete_account'.trFallback('Delete account')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.md, AppSpace.md, AppSpace.lg),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            const _WarningCard(),
            IroCard(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'delete_account_removed_title'.trFallback('What will be removed'),
                    style: iroDisplay(size: 15),
                  ),
                  const SizedBox(height: 12),
                  _RemovedRow(
                    icon: Icons.badge_outlined,
                    text: 'delete_account_removed_profile'.trFallback('Your profile and membership card'),
                  ),
                  _RemovedRow(
                    icon: Icons.emoji_events_outlined,
                    text: 'delete_account_removed_points'.trFallback('Your points and rank'),
                  ),
                  _RemovedRow(
                    icon: Icons.article_outlined,
                    text: 'delete_account_removed_posts'.trFallback('Posts, grievances and stories you shared'),
                  ),
                  _RemovedRow(
                    icon: Icons.event_outlined,
                    text: 'delete_account_removed_events'.trFallback('Events, meetings and tasks you created'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text.rich(
              TextSpan(
                text: 'delete_account_reason'.trFallback('Why are you deleting your account?'),
                children: const [TextSpan(text: ' *', style: TextStyle(color: AppColors.bad))],
              ),
              style: iroDisplay(size: 15),
            ),
            const SizedBox(height: 4),
            Text(
              'delete_account_reason_help'.trFallback('Your feedback helps us improve the app.'),
              style: iroLabel(size: 12.5, weight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _reason,
              enabled: !_busy,
              minLines: 4,
              maxLines: 6,
              maxLength: _maxReason,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(fontSize: 14.5, height: 1.4, color: AppColors.ink),
              decoration: InputDecoration(
                hintText: 'delete_account_reason_hint'.trFallback('Write your comment here'),
                hintStyle: const TextStyle(fontSize: 14.5, color: AppColors.ink4),
                filled: true,
                fillColor: AppColors.card,
                contentPadding: const EdgeInsets.all(14),
                counterStyle: iroLabel(size: 11),
                border: _border(AppColors.rule2),
                enabledBorder: _border(AppColors.rule2),
                disabledBorder: _border(AppColors.rule),
                focusedBorder: _border(AppColors.bad, width: 1.5),
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.xs, AppSpace.md, AppSpace.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _canSubmit ? _delete : null,
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                        )
                      : const Icon(Icons.delete_forever_rounded, size: 20),
                  label: Text(
                    'delete_account_submit'.trFallback('Delete my account'),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.bad,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _busy ? AppColors.bad : AppColors.rule,
                    disabledForegroundColor: _busy ? Colors.white : AppColors.ink4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: _busy ? null : () => Get.back(),
                style: TextButton.styleFrom(foregroundColor: AppColors.ink2),
                child: Text(
                  'delete_account_keep'.trFallback('Keep my account'),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static OutlineInputBorder _border(Color color, {double width = 1}) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpace.controlRadius),
        borderSide: BorderSide(color: color, width: width),
      );
}

class _WarningCard extends StatelessWidget {
  const _WarningCard();

  @override
  Widget build(BuildContext context) {
    return IroCard(
      color: AppColors.badBg,
      border: AppColors.bad.withValues(alpha: 0.25),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: AppColors.bad.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: const Icon(Icons.warning_amber_rounded, color: AppColors.bad, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'delete_account_warning_title'.trFallback('This cannot be undone'),
                  style: iroDisplay(size: 16, color: AppColors.bad),
                ),
                const SizedBox(height: 4),
                Text(
                  'delete_account_warning_body'.trFallback(
                    'Once deleted, your account will no longer exist and all its data will be permanently removed.',
                  ),
                  style: const TextStyle(fontSize: 13.5, height: 1.45, color: AppColors.ink2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RemovedRow extends StatelessWidget {
  const _RemovedRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: AppColors.badBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: AppColors.bad),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 14, height: 1.35, color: AppColors.ink)),
          ),
        ],
      ),
    );
  }
}
