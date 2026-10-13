import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/iro_ui.dart';
import '../../core/widgets/language_dropdown.dart';
import '../../core/widgets/ui.dart';
import '../join/join_chrome.dart';
import '../session/logout_dialog.dart';

/// Account-level controls, reached from More: the app language, signing out,
/// and deleting the account.
class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: OrganicAppBar(title: 'settings'.tr),
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.md),
        children: [
          _SectionLabel('settings_preferences'.trFallback('Preferences')),
          IroCard(
            padding: EdgeInsets.zero,
            child: _SettingsRow(
              icon: Icons.translate_rounded,
              title: 'language'.tr,
              trailing: const LanguageDropdown(),
            ),
          ),
          const SizedBox(height: 6),
          _SectionLabel('settings_account'.trFallback('Account')),
          IroCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SettingsRow(
                  icon: Icons.logout_rounded,
                  title: 'sign_out'.tr,
                  onTap: showLogoutDialog,
                ),
                const Divider(height: 1, thickness: 1, indent: 64, color: AppColors.rule),
                _SettingsRow(
                  icon: Icons.delete_outline_rounded,
                  title: 'delete_account'.trFallback('Delete account'),
                  subtitle: 'delete_account_row_sub'.trFallback('Permanently remove your account and data'),
                  danger: true,
                  onTap: () => Get.toNamed(Routes.deleteAccount),
                ),
              ],
            ),
          ),
        ],
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
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(text.toUpperCase(), style: iroLabel(size: 11.5, weight: FontWeight.w700).copyWith(letterSpacing: 0.8)),
    );
  }
}

/// One line in a settings card: a tinted icon, a title, and either a control
/// on the right or a chevron when the row opens something.
class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final fg = danger ? AppColors.bad : AppColors.brand;
    final bg = danger ? AppColors.badBg : AppColors.brandWash;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(11)),
                child: Icon(icon, size: 19, color: fg),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: danger ? AppColors.bad : AppColors.ink,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: iroLabel(size: 12, weight: FontWeight.w500)),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else if (onTap != null)
                Icon(Icons.chevron_right_rounded, color: danger ? AppColors.bad : AppColors.ink4),
            ],
          ),
        ),
      ),
    );
  }
}
