import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/constants/api.dart';
import '../../core/constants/endpoints.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/flash.dart';
import '../../core/widgets/iro_ui.dart';
import '../../core/widgets/ui.dart';

/// What this build talks to. Read-only: the address comes from [AppEnv], fixed
/// when the build was made, so there is nothing here to change on the device.
class ApiSettingsView extends StatelessWidget {
  const ApiSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final resolved = ApiConfig.resolved() ?? '—';
    return Scaffold(
      backgroundColor: Iro.mint,
      appBar: OrganicAppBar(title: 'api_url'.tr),
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.screen),
        children: [
          Text('api_url_help'.tr, style: const TextStyle(color: AppColors.ink3, fontSize: 13)),
          const SizedBox(height: 14),
          IroCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Environment', style: iroLabel(size: 11.5))),
                    IroChip(
                      ApiConfig.env.name.toUpperCase(),
                      dense: true,
                      size: 9.5,
                      fg: ApiConfig.env == AppEnv.prod ? Iro.alert : Iro.greenMid,
                      bg: ApiConfig.env == AppEnv.prod ? Iro.alertWash : Iro.wash,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Base URL', style: iroLabel(size: 11.5)),
                const SizedBox(height: 4),
                SelectableText(
                  '$resolved${ApiConfig.prefix}',
                  style: iroLabel(size: 13, color: Iro.ink, weight: FontWeight.w700),
                ),
                const SizedBox(height: 14),
                IroGhostButton(
                  label: 'Copy',
                  icon: Icons.copy_rounded,
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: '$resolved${ApiConfig.prefix}'));
                    flash('OK', 'Copied');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Set with --dart-define=APP_ENV=local|dev|prod when building. '
            'On a new network, pass --dart-define=LAN_HOST=http://192.168.x.x:4000.',
            style: iroLabel(size: 11.5, color: Iro.muted, weight: FontWeight.w500).copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}
