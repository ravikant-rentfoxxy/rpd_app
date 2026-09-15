import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_log.dart';
import '../widgets/flash.dart';

Future<void> openExternalUrl(String url, {bool preferExternal = false}) async {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme) {
    flash('Error', 'open_link_failed'.tr);
    return;
  }

  final modes = [
    if (preferExternal) LaunchMode.externalApplication,
    LaunchMode.platformDefault,
    LaunchMode.inAppBrowserView,
    if (!preferExternal) LaunchMode.externalApplication,
    LaunchMode.inAppWebView,
  ];

  for (final mode in modes) {
    try {
      if (await launchUrl(uri, mode: mode)) return;
    } catch (e, stack) {
      AppLog.error('open $url with $mode failed', error: e, stack: stack, tag: 'LINK');
    }
  }
  flash('Error', 'open_link_failed'.tr);
}
