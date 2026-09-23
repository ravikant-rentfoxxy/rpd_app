import 'package:flutter_test/flutter_test.dart';
import 'package:rpd_app/core/utils/media_url.dart';

void main() {
  const imageUrl =
      'https://rentfoxxy-media.b-cdn.net/posts/03523303-892c-4aac-8ca1-14f1ebb95f3a/d3457a98-1208-463c-a707-7269fc173ba1.jpg';
  const imageKey = 'posts/03523303-892c-4aac-8ca1-14f1ebb95f3a/d3457a98-1208-463c-a707-7269fc173ba1.jpg';
  const videoId = '8f1c3d2a-4b5e-6789-abcd-ef0123456789';

  test('storage image URLs are not treated as stream videos', () {
    expect(streamVideoId(imageUrl), isNull);
    expect(streamVideoId(imageKey), isNull);
    expect(resolveStorageUrl(imageUrl), imageUrl);
    expect(resolveStorageUrl(imageKey), 'https://rentfoxxy-media.b-cdn.net/$imageKey');
  });

  test('postImageUrl uses the Bunny storage image', () {
    expect(
      postImageUrl({
        'mediaType': 'image',
        'mediaUrl': imageUrl,
        'mediaKey': imageKey,
      }),
      imageUrl,
    );
  });

  test('stream video ids still resolve', () {
    expect(streamVideoId('stream/$videoId'), videoId);
    expect(streamVideoId('https://vz-8625e1d3-3b3.b-cdn.net/$videoId/playlist.m3u8'), videoId);
  });

  test('stream embed url uses Bunny iframe player', () {
    expect(
      resolveStreamEmbedUrl('stream/$videoId'),
      'https://iframe.mediadelivery.net/embed/750289/$videoId?autoplay=true&preload=true&responsive=true',
    );
    expect(
      postStreamEmbedUrl({
        'videoId': videoId,
        'mediaKey': 'stream/$videoId',
      }),
      'https://iframe.mediadelivery.net/embed/750289/$videoId?autoplay=true&preload=true&responsive=true',
    );
  });
}
