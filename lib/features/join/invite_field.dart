import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/ui.dart';
import '../../data/local/hive_service.dart';
import '../../data/remote/api_client.dart';
import 'join_chrome.dart';

/// The referral box on the verification flow.
///
/// One field takes both kinds of code a member might have been given: the
/// recruiting code off someone's membership card, which only credits them, and
/// an invite cut for a post in the hierarchy, which hands the member that post
/// the moment they submit. The member is not asked which they hold — the
/// backend tells them apart by shape — so the only job here is to say, before
/// they commit, what the code they typed is actually going to do.

/// What the server says a typed code carries.
class InviteLookup {
  const InviteLookup({
    required this.code,
    this.valid = false,
    this.state = 'NONE',
    this.reason,
    this.postTitle = '',
    this.where = '',
    this.issuedByName = '',
  });

  final String code;

  /// A post invite that can still be spent.
  final bool valid;

  /// 'OPEN', 'REDEEMED', 'REVOKED', 'EXPIRED', or 'NONE' when no invite is
  /// attached — which is the ordinary case for a recruiting code.
  final String state;
  final String? reason;
  final String postTitle;
  final String where;
  final String issuedByName;

  /// No post attached. Not an error: it may still be a recruiting code, which
  /// this endpoint knows nothing about.
  bool get noPost => state == 'NONE';

  /// A real invite that has been used, cancelled or has run out.
  bool get spent => !valid && !noPost;

  factory InviteLookup.fromJson(String code, Map<String, dynamic> json) {
    return InviteLookup(
      code: '${json['code'] ?? code}',
      valid: json['valid'] == true,
      state: '${json['state'] ?? 'NONE'}',
      reason: json['reason'] as String?,
      postTitle: '${json['postTitle'] ?? ''}',
      where: '${json['where'] ?? ''}',
      issuedByName: '${json['issuedByName'] ?? ''}',
    );
  }
}

Future<InviteLookup> lookupInvite(String code) async {
  final res = await Get.find<ApiClient>().get('/invites/lookup', query: {'code': code});
  return InviteLookup.fromJson(code, Map<String, dynamic>.from(res['data'] as Map));
}

/// Reads back what the join flow saved, for the step that submits it.
String inviteCodeFromDraft(HiveService hive) =>
    ((hive.draft.get('inviteCode') as String?) ?? '').trim();

class InviteCodeField extends StatefulWidget {
  const InviteCodeField({super.key});

  @override
  State<InviteCodeField> createState() => _InviteCodeFieldState();
}

class _InviteCodeFieldState extends State<InviteCodeField> {
  final hive = Get.find<HiveService>();
  late final code = TextEditingController(text: inviteCodeFromDraft(hive));
  late bool open = code.text.isNotEmpty;
  Timer? debounce;
  bool checking = false;
  InviteLookup? result;

  @override
  void initState() {
    super.initState();
    // A code carried over from an earlier attempt is checked once on the way
    // in, so the member does not have to retype it to see what it does.
    if (code.text.isNotEmpty) check(code.text);
  }

  @override
  void dispose() {
    debounce?.cancel();
    code.dispose();
    super.dispose();
  }

  /// A post invite is ten characters; anything shorter is still being typed or
  /// is a recruiting code, neither of which is worth a round trip.
  Future<void> check(String raw) async {
    final value = raw.trim().toUpperCase();
    if (value.length < 10) {
      if (mounted) setState(() => result = null);
      return;
    }
    setState(() => checking = true);
    try {
      final found = await lookupInvite(value);
      if (mounted && code.text.trim().toUpperCase() == value) {
        setState(() => result = found);
      }
    } catch (_) {
      // Offline or the endpoint is down: say nothing rather than something
      // wrong. The code still travels with the form and is judged on submit.
      if (mounted) setState(() => result = null);
    } finally {
      if (mounted) setState(() => checking = false);
    }
  }

  void onChanged(String value) {
    hive.draft.put('inviteCode', value.trim().toUpperCase());
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 450), () => check(value));
  }

  @override
  Widget build(BuildContext context) {
    if (!open) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: GestureDetector(
          onTap: () => setState(() => open = true),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: const Border.fromBorderSide(BorderSide(color: VerifyColors.line, width: 1.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.card_giftcard_outlined, size: 18, color: VerifyColors.purple),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'have_referral'.tr,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: VerifyColors.ink),
                  ),
                ),
                const Icon(Icons.add_rounded, size: 18, color: VerifyColors.gray),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppField(
          label: 'referral_or_invite'.trFallback('Referral or invite code'),
          controller: code,
          hint: 'referral_hint'.tr,
          icon: Icons.card_giftcard_outlined,
          verifyStyle: true,
          maxLength: 12,
          formatters: [UpperCaseTextFormatter()],
          suffix: checking
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: VerifyColors.purple),
                )
              : null,
          onChanged: onChanged,
        ),
        _InviteResult(result: result),
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Text(
            'referral_help'.tr,
            style: const TextStyle(fontSize: 11, color: VerifyColors.gray, height: 1.45),
          ),
        ),
      ],
    );
  }
}

/// Says what the typed code will do. Nothing at all while there is nothing
/// useful to say — an empty box and a half-typed code both look the same.
/// Exposed under a second name so a test can build it on its own; the field
/// itself always goes through [_InviteResult].
typedef InviteResultForTest = _InviteResult;

class _InviteResult extends StatelessWidget {
  const _InviteResult({required this.result});
  final InviteLookup? result;

  @override
  Widget build(BuildContext context) {
    final found = result;
    if (found == null || found.noPost) return const SizedBox.shrink();

    final good = found.valid;
    final colour = good ? Iro.green : Iro.alert;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: good ? Iro.wash2 : const Color(0xFFFDEDED),
        borderRadius: BorderRadius.circular(14),
        border: Border.fromBorderSide(BorderSide(color: colour.withValues(alpha: 0.35), width: 1.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(good ? Icons.verified_rounded : Icons.error_outline_rounded, size: 18, color: colour),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  good ? 'invite_grants'.trFallback('This code makes you') : 'invite_unusable'.trFallback('This code cannot be used'),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: colour),
                ),
                const SizedBox(height: 3),
                Text(
                  good ? found.postTitle : (found.reason ?? ''),
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: VerifyColors.ink),
                ),
                if (good && found.where.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(found.where, style: const TextStyle(fontSize: 11.5, color: VerifyColors.gray)),
                ],
                if (good && found.issuedByName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'invite_from'.trParams({'name': found.issuedByName}),
                    style: const TextStyle(fontSize: 11, color: VerifyColors.gray),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Codes are handed round on paper and in WhatsApp forwards, where case is
/// never kept. The field settles it rather than the member.
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue next) =>
      next.copyWith(text: next.text.toUpperCase());
}
