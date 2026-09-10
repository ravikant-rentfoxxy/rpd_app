class HomeFeedItem {
  const HomeFeedItem({
    required this.title,
    required this.url,
    required this.source,
    this.imageUrl,
    this.video = false,
  });

  final String title;
  final String url;
  final String source;
  final String? imageUrl;
  final bool video;

  String? get youtubeId => youtubeVideoId(url);

  Map<String, dynamic> toJson() => {
        'title': title,
        'url': url,
        'source': source,
        'imageUrl': imageUrl,
        'place': source,
        'video': video,
      };

  factory HomeFeedItem.fromJson(Map<String, dynamic> json) {
    return HomeFeedItem(
      title: '${json['title'] ?? ''}',
      url: '${json['url'] ?? ''}',
      source: '${json['source'] ?? json['place'] ?? ''}',
      imageUrl: (json['imageUrl'] as String?)?.trim().isEmpty == true ? null : json['imageUrl'] as String?,
      video: json['video'] == true,
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

const recentVideos = [
  HomeFeedItem(
    title: 'NUBC की राष्ट्रीय बैठक, पूर्व सांसद डी. पी. यादव का जन्मदिन मनाया',
    url: 'https://youtu.be/vV7fZd9a7NQ?si=-A5YMTTInzR4XS7y',
    source: 'TN24 News',
    imageUrl: 'https://i.ytimg.com/vi/vV7fZd9a7NQ/hqdefault.jpg',
    video: true,
  ),
  HomeFeedItem(
    title: 'NUBC Central Executive Meeting 2026 · Constitution Club Delhi',
    url: 'https://www.youtube.com/watch?v=YtkL3YBZCq0',
    source: 'Bharat Plus Tv',
    imageUrl: 'https://i.ytimg.com/vi/YtkL3YBZCq0/hqdefault.jpg',
    video: true,
  ),
  HomeFeedItem(
    title: 'पूर्व सांसद डी. पी. यादव का जन्मदिन एवं राष्ट्रीय पिछड़ा वर्ग अधिवेशन',
    url: 'https://youtu.be/gtoDNLfEucE',
    source: 'TEZ SAMACHAR',
    imageUrl: 'https://i.ytimg.com/vi/gtoDNLfEucE/hqdefault.jpg',
    video: true,
  ),
  HomeFeedItem(
    title: 'IRO booth committee orientation · field briefing',
    url: 'https://www.youtube.com/watch?v=YtkL3YBZCq0',
    source: 'IRO Media',
    imageUrl: 'https://i.ytimg.com/vi/YtkL3YBZCq0/hqdefault.jpg',
    video: true,
  ),
  HomeFeedItem(
    title: 'Membership drive update · district coordination',
    url: 'https://youtu.be/gtoDNLfEucE',
    source: 'IRO Desk',
    imageUrl: 'https://i.ytimg.com/vi/gtoDNLfEucE/hqdefault.jpg',
    video: true,
  ),
];

const recentBlogs = [
  HomeFeedItem(
    title: 'उत्कृष्ट कार्य के लिए महिलाओं को किया गया सम्मानित',
    url: 'https://www.viraatvaibhav.com/news/latest-news/105867.html',
    source: 'Viraat Vaibhav',
  ),
  HomeFeedItem(
    title: 'कॉन्स्टिट्यूशन क्लब नई दिल्ली में NUBC कार्यकारिणी की बैठक',
    url: 'https://dhunt.in/1548np',
    source: 'Dailyhunt',
  ),
  HomeFeedItem(
    title: 'NUBC बैठक · कार्यक्रम रील',
    url: 'https://www.facebook.com/reel/1489043533249151',
    source: 'Facebook',
    video: true,
  ),
  HomeFeedItem(
    title: 'Booth-level outreach playbook',
    url: 'https://www.viraatvaibhav.com/news/latest-news/105867.html',
    source: '4 MIN READ',
  ),
  HomeFeedItem(
    title: 'Griha sampark: what counts as verified',
    url: 'https://dhunt.in/1548np',
    source: '6 MIN READ',
  ),
];

const dummyNearbyActivities = [
  HomeFeedItem(
    title: 'Booth meeting',
    url: '',
    source: 'Near your booth',
    imageUrl: 'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?auto=format&fit=crop&w=800&q=60',
  ),
  HomeFeedItem(
    title: 'Griha sampark',
    url: '',
    source: 'Ward walk',
    imageUrl: 'https://images.unsplash.com/photo-1469571486292-0ba58a3f068b?auto=format&fit=crop&w=800&q=60',
  ),
  HomeFeedItem(
    title: 'Public programme',
    url: '',
    source: 'Community hall',
    imageUrl: 'https://images.unsplash.com/photo-1517048676732-d65bc937f952?auto=format&fit=crop&w=800&q=60',
  ),
  HomeFeedItem(
    title: 'Training session',
    url: '',
    source: 'Mandal office',
    imageUrl: 'https://images.unsplash.com/photo-1524178232363-1fb2b075b655?auto=format&fit=crop&w=800&q=60',
  ),
  HomeFeedItem(
    title: 'Membership desk',
    url: '',
    source: 'Ward 7',
    imageUrl: 'https://images.unsplash.com/photo-1531482615713-2afd69097998?auto=format&fit=crop&w=800&q=60',
  ),
];

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
    );
  }
}

const upcomingEvents = [
  UpcomingEvent(
    title: 'Mandal executive meeting',
    when: '12 Sep · 11:00 AM',
    place: 'Constitution Club, Delhi',
    imageUrl: 'https://images.unsplash.com/photo-1517048676732-d65bc937f952?auto=format&fit=crop&w=800&q=60',
    joining: 38,
  ),
  UpcomingEvent(
    title: 'Booth committee orientation',
    when: '18 Sep · 4:00 PM',
    place: 'Primary School, Sihani',
    imageUrl: 'https://images.unsplash.com/photo-1524178232363-1fb2b075b655?auto=format&fit=crop&w=800&q=60',
    joining: 22,
  ),
  UpcomingEvent(
    title: 'Griha sampark drive',
    when: '21 Sep · 9:00 AM',
    place: 'Ward 4',
    imageUrl: 'https://images.unsplash.com/photo-1469571486292-0ba58a3f068b?auto=format&fit=crop&w=800&q=60',
    joining: 15,
  ),
];

List<HomeFeedItem> feedItemsFrom(List? raw, {List<HomeFeedItem> fallback = const []}) {
  final items = (raw ?? [])
      .whereType<Map>()
      .map((e) => HomeFeedItem.fromJson(Map<String, dynamic>.from(e)))
      .where((e) => e.title.trim().isNotEmpty || (e.imageUrl ?? '').isNotEmpty)
      .toList();
  return items.isEmpty ? fallback : items;
}

List<HomeFeedItem> nearbyActivitiesFrom(List? raw) {
  return feedItemsFrom(raw, fallback: dummyNearbyActivities);
}

List<UpcomingEvent> upcomingEventsFrom(List? raw, {bool useFallback = false, int? limit}) {
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
  if (items.isEmpty) {
    final fallback = useFallback ? upcomingEvents : const <UpcomingEvent>[];
    return limit == null ? fallback : fallback.take(limit).toList();
  }
  return limit == null ? items : items.take(limit).toList();
}

Map<String, dynamic> defaultHomeFeed() => {
      'recentVideos': recentVideos.map((e) => e.toJson()).toList(),
      'recentBlogs': recentBlogs.map((e) => e.toJson()).toList(),
      'upcomingEvents': upcomingEvents.map((e) => e.toJson()).toList(),
      'nearbyActivities': dummyNearbyActivities
          .map((e) => {'id': e.title, 'title': e.title, 'place': e.source, 'imageUrl': e.imageUrl})
          .toList(),
      'tasksDueToday': [
        {'id': 't1', 'title': 'Submit booth committee list', 'detail': 'From Mandal President', 'dueAt': DateTime.now().toIso8601String()},
        {'id': 't2', 'title': 'Griha sampark · 50 homes', 'detail': '30 done', 'dueAt': DateTime.now().toIso8601String()},
      ],
    };
