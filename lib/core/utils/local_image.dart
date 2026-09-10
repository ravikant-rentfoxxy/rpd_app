import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../constants/api.dart';

String? localPhotoPath(Object? raw) {
  final value = raw?.toString().trim() ?? '';
  if (value.isEmpty) return null;
  return value.startsWith('file://') ? value.replaceFirst('file://', '') : value;
}

bool isHttpUrl(String? value) {
  final text = value?.trim() ?? '';
  return text.startsWith('http://') || text.startsWith('https://');
}

bool isLocalPhotoPath(String? value) {
  if (value == null || value.isEmpty || isHttpUrl(value)) return false;
  final path = localPhotoPath(value)!;
  return path.startsWith('/') || File(path).existsSync();
}

/// Prefer the API `photoUrl` (media URL or storage key), then a local file.
String? memberPhotoRef(Map<String, dynamic>? member) {
  if (member == null) return null;
  final url = member['photoUrl']?.toString().trim();
  if (url != null && url.isNotEmpty) return url;
  final path = member['photoPath']?.toString().trim();
  if (path != null && path.isNotEmpty) return path;
  return null;
}

String? resolveMediaUrl(Object? raw) {
  final value = raw?.toString().trim() ?? '';
  if (value.isEmpty) return null;
  if (isHttpUrl(value)) return ApiConfig.adjustForPlatform(value);
  if (value.startsWith('members/') || value.startsWith('posts/') || value.startsWith('events/')) {
    final base = ApiConfig.resolved();
    if (base == null) return null;
    return ApiConfig.adjustForPlatform('$base${ApiConfig.prefix}/media/$value');
  }
  return null;
}

ImageProvider? localOrNetworkImage(Object? raw) {
  final media = resolveMediaUrl(raw);
  if (media != null) return NetworkImage(media);
  final path = localPhotoPath(raw);
  if (path != null && File(path).existsSync()) return FileImage(File(path));
  return null;
}

Widget localOrNetworkPhoto({
  required Object? raw,
  required Widget fallback,
  BoxFit fit = BoxFit.cover,
}) {
  final provider = localOrNetworkImage(raw);
  if (provider == null) return fallback;
  return Image(image: provider, fit: fit, errorBuilder: (_, _, _) => fallback);
}

Future<String?> pickImageToAppDir(
  ImageSource source, {
  String prefix = 'rpd_file',
  int maxEdge = 1400,
  int quality = 70,
}) async {
  final picked = await ImagePicker().pickImage(source: source, imageQuality: 80);
  if (picked == null) return null;
  final dir = await getApplicationDocumentsDirectory();
  final target = '${dir.path}/${prefix}_${DateTime.now().millisecondsSinceEpoch}.jpg';
  final compressed = await FlutterImageCompress.compressAndGetFile(
    picked.path,
    target,
    quality: quality,
    minWidth: maxEdge,
    minHeight: maxEdge,
    format: CompressFormat.jpeg,
  );
  var filePath = compressed?.path ?? picked.path;
  if (!filePath.startsWith(dir.path)) {
    await File(filePath).copy(target);
    filePath = target;
  }
  return filePath;
}

Future<String?> copyFileToAppDir(String path, {String prefix = 'rpd_file'}) async {
  final source = File(path);
  if (!source.existsSync()) return null;
  final ext = path.split('.').last.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
  final suffix = ext.isEmpty ? 'bin' : ext.toLowerCase();
  final dir = await getApplicationDocumentsDirectory();
  final target = '${dir.path}/${prefix}_${DateTime.now().millisecondsSinceEpoch}.$suffix';
  if (path == target) return path;
  await source.copy(target);
  return target;
}
