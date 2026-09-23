import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:upgrader/upgrader.dart';

import '../utils/app_log.dart';

/// The "a newer version is out" prompt.
///
/// It sits on Home rather than on the app's root, so a member meets it once
/// they are actually in the app — not over the login screen, where they cannot
/// act on it and have not yet said who they are.

/// Wraps Home so the prompt has somewhere to appear.
///
/// [Upgrader] talks to the Play Store and the App Store, neither of which knows
/// about a debug build, so nothing shows in development unless
/// `debugDisplayAlways` is turned on below.
class AppUpgradeGate extends StatelessWidget {
  const AppUpgradeGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return UpgradeAlert(
      upgrader: Upgrader(
        messages: appUpgradeMessages,
        // Asked once, then left alone for three days. A prompt that returns on
        // every launch gets dismissed without being read.
        durationUntilAlertAgain: const Duration(days: 3),
        willDisplayUpgrade: ({
          required bool display,
          String? installedVersion,
          UpgraderVersionInfo? versionInfo,
        }) {
          if (!display) return;
          AppLog.info(
            'update available: $installedVersion -> ${versionInfo?.appStoreVersion}',
            tag: 'UPGRADE',
          );
        },
      ),
      // Dismissible by tapping outside as well as by the buttons: an optional
      // update should never feel like a wall.
      barrierDismissible: true,
      showIgnore: false,
      showReleaseNotes: false,
      child: child,
    );
  }
}

/// The one instance, exposed so the copy can be read without building a widget.
final appUpgradeMessages = AppUpgradeMessages();

/// The prompt in the member's own language, read from the app's translations
/// rather than the package's, so it matches everything around it and covers
/// Bhojpuri, which the package has never heard of.
class AppUpgradeMessages extends UpgraderMessages {
  @override
  String? message(UpgraderMessage messageKey) {
    final key = switch (messageKey) {
      UpgraderMessage.title => 'update_title',
      UpgraderMessage.body => 'update_body',
      UpgraderMessage.prompt => 'update_prompt',
      UpgraderMessage.buttonTitleUpdate => 'update_now',
      UpgraderMessage.buttonTitleLater => 'update_later',
      UpgraderMessage.buttonTitleIgnore => 'update_ignore',
      UpgraderMessage.releaseNotes => 'update_notes',
    };
    final value = key.tr;
    // A key with no translation comes back as itself; the package's own
    // wording is better than showing a member the key.
    return value == key ? super.message(messageKey) : value;
  }
}
