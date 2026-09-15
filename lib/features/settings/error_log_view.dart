import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/utils/app_log.dart';
import '../../core/widgets/empty_card.dart';
import '../../core/widgets/ui.dart';
import '../../core/widgets/flash.dart';

class ErrorLogView extends StatelessWidget {
  const ErrorLogView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('error_log'.tr),
        actions: [
          TextButton(
            onPressed: () {
              final text = AppLog.entries.map((e) => e.detail).join('\n---\n');
              Clipboard.setData(ClipboardData(text: text));
              flash('OK', 'Copied');
            },
            child: const Text('Copy'),
          ),
          TextButton(onPressed: AppLog.clear, child: const Text('Clear')),
        ],
      ),
      body: Obx(() {
        if (AppLog.entries.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: AppEmptyCard(icon: Icons.notes_rounded, title: 'No logs yet'),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: AppLog.entries.length,
          itemBuilder: (_, i) {
            final e = AppLog.entries[i];
            final tone = switch (e.level) {
              'ERROR' => CardTone.bad,
              'WARN' => CardTone.warn,
              _ => CardTone.plain,
            };
            return AppCard(
              tone: tone,
              onTap: () => Get.dialog(
                AlertDialog(
                  title: Text(e.title, style: const TextStyle(fontSize: 14)),
                  content: SingleChildScrollView(child: SelectableText(e.detail)),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: e.detail));
                        Get.back();
                      },
                      child: const Text('Copy'),
                    ),
                    TextButton(onPressed: Get.back, child: const Text('Close')),
                  ],
                ),
              ),
              child: CardTitle(e.title, sub: e.at.toLocal().toString()),
            );
          },
        );
      }),
    );
  }
}
