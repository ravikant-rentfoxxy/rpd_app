class HomeFeedItem {
  const HomeFeedItem({
    required this.title,
    required this.url,
    required this.source,
    this.imageUrl,
    this.video = false,
    this.id = '',
    this.description = '',
    this.body = '',
    this.kind = '',
    this.likes = 0,
    this.dislikes = 0,
    this.myVote = '',
    this.videoSource = 'LINK',
    this.mediaKey,
    this.externalUrl = '',
  });

  final String title;
  final String url;
  final String source;
  final String? imageUrl;
  final bool video;
  final String id;
  final String description;

  /// Article text written in the admin portal. Blogs that carry it are read
  /// inside the app; the rest open [url] in a browser.
  final String body;

  /// 'VIDEO' or 'BLOG' — which endpoint a vote on this item goes to. A blog can
  /// carry [video] true (a linked reel), so the flag cannot stand in for it.
  final String kind;
  final int likes;
  final int dislikes;

  /// 'LIKE', 'DISLIKE', or empty when this member has not voted.
  final String myVote;

  /// 'UPLOAD' for a file put through the portal, 'LINK' for a URL pasted into
  /// it. The portal accepts one or the other, never both.
  final String videoSource;

  /// The Bunny Stream key behind an upload, which the in-app player needs.
  final String? mediaKey;

  /// The pasted URL behind a link. [url] already resolves to whichever applies,
  /// but knowing the original matters when deciding where to send a tap.
  final String externalUrl;

  /// True when the video was uploaded here, so it plays in the app rather than
  /// being handed to the browser.
  bool get isUploadedVideo => video && videoSource == 'UPLOAD' && (mediaKey ?? '').isNotEmpty;

  bool get readInApp => body.trim().isNotEmpty;

  /// The path segment the vote endpoint expects, falling back to what the card
  /// looks like when an older payload carried no kind.
  String get voteKind => kind.isNotEmpty ? kind.toLowerCase() : (video ? 'video' : 'blog');

  HomeFeedItem withVote({required int likes, required int dislikes, required String myVote}) {
    return HomeFeedItem(
      title: title,
      url: url,
      source: source,
      imageUrl: imageUrl,
      video: video,
      id: id,
      description: description,
      body: body,
      kind: kind,
      likes: likes,
      dislikes: dislikes,
      myVote: myVote,
      videoSource: videoSource,
      mediaKey: mediaKey,
      externalUrl: externalUrl,
    );
  }

  String? get youtubeId => youtubeVideoId(url);

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'url': url,
        'source': source,
        'imageUrl': imageUrl,
        'place': source,
        'video': video,
        'description': description,
        'body': body,
        'kind': kind,
        'likes': likes,
        'dislikes': dislikes,
        'myVote': myVote,
        'videoSource': videoSource,
        'mediaKey': mediaKey,
        'externalUrl': externalUrl,
      };

  factory HomeFeedItem.fromJson(Map<String, dynamic> json) {
    return HomeFeedItem(
      title: '${json['title'] ?? ''}',
      url: '${json['url'] ?? ''}',
      source: '${json['source'] ?? json['place'] ?? ''}',
      imageUrl: (json['imageUrl'] as String?)?.trim().isEmpty == true ? null : json['imageUrl'] as String?,
      video: json['video'] == true,
      id: '${json['id'] ?? ''}',
      description: '${json['description'] ?? ''}',
      body: '${json['body'] ?? ''}',
      kind: '${json['kind'] ?? ''}'.toUpperCase(),
      likes: (json['likes'] as num?)?.round() ?? 0,
      dislikes: (json['dislikes'] as num?)?.round() ?? 0,
      myVote: '${json['myVote'] ?? ''}'.toUpperCase(),
      videoSource: '${json['videoSource'] ?? 'LINK'}'.toUpperCase(),
      mediaKey: (json['mediaKey'] as String?)?.trim().isEmpty == true ? null : json['mediaKey'] as String?,
      externalUrl: '${json['externalUrl'] ?? ''}',
    );
  }
}

String? youtubeVideoId(String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null) return null;
  final host = uri.host.replaceFirst(RegExp(r'^www\.'), '');
  if (host == 'youtu.be') {
    return uri.pathSegments.isEmpty ? null : uri.pathSegments.first;
  }
  if (host.endsWith('youtube.com')) {
    final watchId = uri.queryParameters['v'];
    if (watchId != null && watchId.isNotEmpty) return watchId;
    final parts = uri.pathSegments;
    for (final marker in ['embed', 'shorts', 'live', 'v']) {
      final index = parts.indexOf(marker);
      if (index >= 0 && index + 1 < parts.length) return parts[index + 1];
    }
  }
  return null;
}

class UpcomingEvent {
  const UpcomingEvent({
    this.id = '',
    required this.title,
    required this.when,
    required this.place,
    required this.imageUrl,
    this.joining = 0,
    this.joined = false,
    this.type = '',
    this.hostName = '',
    this.description = '',
    this.joiners = const [],
    this.createdAt,
    this.startsAt,
    this.kind = 'EVENT',
    this.latitude,
    this.longitude,
  });

  final String id;
  final String title;
  final String when;
  final String place;
  final String imageUrl;
  final int joining;
  final bool joined;
  final String type;
  final String hostName;
  final String description;
  final List<Map<String, dynamic>> joiners;
  final DateTime? createdAt;
  final DateTime? startsAt;

  /// 'EVENT' for an org event, 'MEETING' for a booth meeting or sabha. The two
  /// share a card but not their actions: a meeting is joined by invitation, so
  /// its card offers no Join.
  final String kind;

  /// Where it is being held, when the host recorded a fix. Null for anything
  /// entered without one, which the map simply leaves off.
  final double? latitude;
  final double? longitude;

  UpcomingEvent copyWith({int? joining, bool? joined, List<Map<String, dynamic>>? joiners}) {
    return UpcomingEvent(
      id: id,
      title: title,
      when: when,
      place: place,
      imageUrl: imageUrl,
      joining: joining ?? this.joining,
      joined: joined ?? this.joined,
      type: type,
      hostName: hostName,
      description: description,
      joiners: joiners ?? this.joiners,
      createdAt: createdAt,
      startsAt: startsAt,
      kind: kind,
      latitude: latitude,
      longitude: longitude,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'when': when,
        'place': place,
        'imageUrl': imageUrl,
        'joining': joining,
        'joined': joined,
        'type': type,
        'hostName': hostName,
        'description': description,
        'kind': kind,
        'latitude': latitude,
        'longitude': longitude,
        'joiners': joiners,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (startsAt != null) 'startsAt': startsAt!.toIso8601String(),
      };

  factory UpcomingEvent.fromJson(Map<String, dynamic> json) {
    final rawJoiners = json['joiners'];
    return UpcomingEvent(
      id: '${json['id'] ?? ''}',
      title: '${json['title'] ?? ''}',
      when: '${json['when'] ?? ''}',
      place: '${json['place'] ?? json['venue'] ?? ''}',
      imageUrl: '${json['imageUrl'] ?? ''}',
      joining: (json['joining'] as num?)?.toInt() ?? 0,
      joined: json['joined'] == true,
      type: '${json['type'] ?? ''}',
      hostName: '${json['hostName'] ?? ''}',
      description: '${json['description'] ?? ''}',
      joiners: rawJoiners is List
          ? rawJoiners.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
          : const [],
      createdAt: DateTime.tryParse('${json['createdAt'] ?? ''}'),
      startsAt: DateTime.tryParse('${json['startsAt'] ?? ''}'),
      kind: '${json['kind'] ?? 'EVENT'}'.toUpperCase(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}

List<HomeFeedItem> feedItemsFrom(List? raw) {
  return (raw ?? [])
      .whereType<Map>()
      .map((e) => HomeFeedItem.fromJson(Map<String, dynamic>.from(e)))
      .where((e) => e.title.trim().isNotEmpty || (e.imageUrl ?? '').isNotEmpty || e.readInApp)
      .toList();
}

List<HomeFeedItem> nearbyActivitiesFrom(List? raw) => feedItemsFrom(raw);

List<UpcomingEvent> upcomingEventsFrom(List? raw, {int? limit}) {
  final items = (raw ?? [])
      .whereType<Map>()
      .map((e) => UpcomingEvent.fromJson(Map<String, dynamic>.from(e)))
      .where((e) => e.title.trim().isNotEmpty)
      .toList();
  items.sort((a, b) {
    final aStamp = a.createdAt ?? a.startsAt;
    final bStamp = b.createdAt ?? b.startsAt;
    if (aStamp != null && bStamp != null) return bStamp.compareTo(aStamp);
    return 0;
  });
  return limit == null ? items : items.take(limit).toList();
}
