import '../constants/api.dart';
import '../constants/endpoints.dart';

final _uuid = RegExp(r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}');

bool isHttpUrl(String? value) {
  final text = value?.trim() ?? '';
  return text.startsWith('http://') || text.startsWith('https://');
}

bool isHlsUrl(String? value) {
  final text = value?.toLowerCase() ?? '';
  return text.contains('.m3u8');
}

String bunnyStorageCdn() => _trimSlash(Media.storageCdn);

String bunnyStreamCdn() => _trimSlash(Media.streamCdn);

String bunnyStreamEmbedOrigin() => _trimSlash(Media.streamEmbed);

String bunnyStreamLibraryId() => Media.streamLibraryId;

bool _isStorageObject(String value) {
  return value.contains('/posts/') ||
      value.contains('/members/') ||
      value.contains('/events/') ||
      value.startsWith('posts/') ||
      value.startsWith('members/') ||
      value.startsWith('events/');
}

bool _isStorageHost(String host) {
  final storage = Uri.tryParse(bunnyStorageCdn())?.host ?? '';
  return storage.isNotEmpty && host == storage;
}

bool _isStreamHost(String host) {
  final stream = Uri.tryParse(bunnyStreamCdn())?.host ?? '';
  if (stream.isNotEmpty && host == stream) return true;
  return host.startsWith('vz-') || host.contains('mediadelivery.net');
}

String? streamVideoId(Object? raw) {
  final value = raw?.toString().trim() ?? '';
  if (value.isEmpty || _isStorageObject(value)) return null;
  final streamKey = RegExp(r'(?:^|/)stream/([0-9a-fA-F-]{36})').firstMatch(value);
  if (streamKey != null) return streamKey.group(1);
  final uri = Uri.tryParse(value);
  if (uri != null && uri.host.isNotEmpty) {
    if (_isStorageHost(uri.host)) return null;
    final embed = RegExp(r'/embed/[^/]+/([0-9a-fA-F-]{36})').firstMatch(uri.path);
    if (embed != null) return embed.group(1);
    if (_isStreamHost(uri.host) || uri.path.contains('playlist.m3u8') || uri.path.contains('thumbnail.jpg')) {
      for (final part in uri.pathSegments) {
        if (_uuid.hasMatch(part)) return part;
      }
    }
  }
  if (value.startsWith('stream/')) {
    final parts = value.split('/');
    final id = parts.length > 1 ? parts[1] : '';
    return _uuid.hasMatch(id) ? id : null;
  }
  return null;
}

String? resolveStorageUrl(Object? raw) {
  final value = raw?.toString().trim() ?? '';
  if (value.isEmpty || isHlsUrl(value) || streamVideoId(value) != null) return null;
  if (isHttpUrl(value)) {
    final fromApi = _storageKeyFromApi(value);
    if (fromApi != null) return '${bunnyStorageCdn()}/$fromApi';
    return ApiConfig.adjustForPlatform(value);
  }
  final key = _storageKey(value);
  if (key != null) return '${bunnyStorageCdn()}/$key';
  return null;
}

String? resolveVideoHlsUrl(Object? raw) {
  final value = raw?.toString().trim() ?? '';
  if (value.isEmpty) return null;
  final id = streamVideoId(value);
  if (id != null) return '${bunnyStreamCdn()}/$id/playlist.m3u8';
  if (isHlsUrl(value)) return ApiConfig.adjustForPlatform(value);
  return null;
}

String? resolveStreamThumbnailUrl(Object? raw) {
  final id = streamVideoId(raw);
  if (id == null) return null;
  return '${bunnyStreamCdn()}/$id/thumbnail.jpg';
}

String? resolveStreamEmbedUrl(Object? raw) {
  final id = streamVideoId(raw);
  if (id == null) return null;
  return '${bunnyStreamEmbedOrigin()}/embed/${bunnyStreamLibraryId()}/$id?autoplay=true&preload=true&responsive=true';
}

String? postVideoId(Map<String, dynamic> post) {
  final direct = '${post['videoId'] ?? ''}'.trim();
  if (_uuid.hasMatch(direct)) return direct;
  return streamVideoId(post['mediaKey'] ?? post['mediaUrl'] ?? post['mediaPath'] ?? post['path']);
}

String? postStreamEmbedUrl(Map<String, dynamic> post) {
  final id = postVideoId(post);
  if (id == null) return null;
  return resolveStreamEmbedUrl('stream/$id');
}

String? resolveMediaUrl(Object? raw, {String? kind}) {
  final type = (kind ?? '').toLowerCase();
  if (type == 'video' || isHlsUrl(raw?.toString()) || streamVideoId(raw) != null) {
    return resolveVideoHlsUrl(raw);
  }
  final storage = resolveStorageUrl(raw);
  if (storage != null) return storage;
  final value = raw?.toString().trim() ?? '';
  if (value.isEmpty) return null;
  if (isHttpUrl(value)) return ApiConfig.adjustForPlatform(value);
  return null;
}

String? postImageUrl(Map<String, dynamic> post) {
  final type = '${post['mediaType'] ?? ''}'.toLowerCase();
  if (type == 'video') {
    return resolveStorageUrl(post['thumbnailUrl'] ?? post['thumbnailPath'] ?? post['thumbnailKey']) ??
        resolveStreamThumbnailUrl(post['mediaUrl'] ?? post['mediaKey'] ?? post['mediaPath']);
  }
  return resolveStorageUrl(
    post['mediaUrl'] ?? post['mediaPath'] ?? post['photoPath'] ?? post['mediaKey'] ?? post['thumbnailUrl'],
  );
}

String? postAudioUrl(Map<String, dynamic> post) {
  return resolveStorageUrl(post['mediaUrl'] ?? post['mediaPath'] ?? post['photoPath']);
}

String? postVideoUrl(Map<String, dynamic> post) {
  return resolveVideoHlsUrl(post['mediaUrl'] ?? post['mediaKey'] ?? post['mediaPath'] ?? post['path']);
}

bool isVideoPost(Map<String, dynamic> post) {
  final type = '${post['mediaType'] ?? ''}'.toLowerCase();
  if (type == 'video') return true;
  return postVideoId(post) != null || isHlsUrl('${post['mediaUrl'] ?? post['mediaPath'] ?? post['path'] ?? ''}');
}

String? _storageKey(String value) {
  if (value.startsWith('members/') || value.startsWith('posts/') || value.startsWith('events/')) {
    return value.replaceFirst(RegExp(r'^/+'), '');
  }
  return _storageKeyFromApi(value);
}

String? _storageKeyFromApi(String value) {
  final uri = Uri.tryParse(value);
  if (uri == null) return null;
  final match = RegExp(r'/media/(members|posts|events)/(.+)$').firstMatch(uri.path);
  if (match == null) return null;
  return '${match.group(1)}/${match.group(2)}';
}

String _trimSlash(String value) => value.endsWith('/') ? value.substring(0, value.length - 1) : value;
