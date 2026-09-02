import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import '../../core/constants/api.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/ui.dart';
import '../../data/local/hive_service.dart';
import '../../data/remote/api_client.dart';

class ApiSettingsView extends StatelessWidget {
  const ApiSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final current = ApiConfig.resolved() ?? '';
    final controller = TextEditingController(text: current);
    return Scaffold(
      appBar: AppBar(title: Text('api_url'.tr)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.screen),
        children: [
          Text('api_url_help'.tr, style: const TextStyle(color: AppColors.ink3, fontSize: 13)),
          const SizedBox(height: 16),
          AppField(label: 'api_url'.tr, controller: controller, keyboard: TextInputType.url, mono: true),
          PrimaryButton('save_api'.tr, onTap: () async {
            final url = controller.text.trim().replaceAll(RegExp(r'/$'), '');
            final parsed = Uri.tryParse(url);
            if (parsed == null || !parsed.hasScheme || parsed.host.isEmpty) {
              Get.snackbar('Error', 'Enter a valid URL, e.g. http://127.0.0.1:4000');
              return;
            }
            dotenv.env['API_BASE_URL'] = url;
            await Get.find<HiveService>().setApiBaseUrl(url);
            if (Get.isRegistered<ApiClient>()) {
              Get.find<ApiClient>().applyBaseUrl(url);
            }
            Get.snackbar('OK', ApiConfig.adjustForPlatform(url));
            if (Get.routing.previous.isNotEmpty) {
              Get.back();
            }
          }),
        ],
      ),
    );
  }
}
