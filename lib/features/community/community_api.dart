import 'package:get/get.dart';
import '../../data/remote/api_client.dart';

/// Community's own endpoint: where the district stands, the stories coming off
/// the ground, and the work that was handed to someone to fix.

int _int(Object? raw) {
  if (raw is num) return raw.round();
  return int.tryParse('${raw ?? ''}') ?? 0;
}

double _double(Object? raw) {
  if (raw is num) return raw.toDouble();
  return double.tryParse('${raw ?? ''}') ?? 0;
}

/// The dark band across the top: the district's name and how it is doing.
class CommunityBanner {
  const CommunityBanner({
    this.districtName = '',
    this.stateName = '',
    this.members = 0,
    this.groundActive = 0,
    this.stateRank = 0,
    this.districtsInState = 0,
    this.civicScore = 0,
    this.memberRank = 0,
    this.membersInState = 0,
  });

  final String districtName;
  final String stateName;
  final int members;
  final int groundActive;

  /// Position among the districts of the state, by share of issues closed.
  final int stateRank;
  final int districtsInState;

  /// That same share, as a percentage.
  final double civicScore;

  /// Where this member stands among everyone in the state, ordered the way the
  /// leaderboard orders it. 0 when they are not placed on a board yet.
  final int memberRank;
  final int membersInState;

  bool get hasRank => memberRank > 0;

  factory CommunityBanner.fromJson(Object? raw) {
    if (raw is! Map) return const CommunityBanner();
    final json = Map<String, dynamic>.from(raw);
    return CommunityBanner(
      districtName: '${json['districtName'] ?? ''}',
      stateName: '${json['stateName'] ?? ''}',
      members: _int(json['members']),
      groundActive: _int(json['groundActive']),
      stateRank: _int(json['stateRank']),
      districtsInState: _int(json['districtsInState']),
      civicScore: _double(json['civicScore']),
      memberRank: _int(json['memberRank']),
      membersInState: _int(json['membersInState']),
    );
  }
}

/// One highlight in the ring: a picture, the place it came from, and the
/// account that opens when it is tapped.
class DistrictStory {
  const DistrictStory({
    required this.id,
    this.title = '',
    this.place = '',
    this.body = '',
    this.imageUrl,
    this.live = false,
    this.seen = false,
    this.authorName = '',
    this.createdAt,
  });

  final String id;
  final String title;

  /// The name shown under the avatar.
  final String place;
  final String body;
  final String? imageUrl;

  /// Gold ring: happening now rather than a record of something past.
  final bool live;

  /// Dims the ring once this member has opened it.
  final bool seen;
  final String authorName;
  final DateTime? createdAt;

  DistrictStory asSeen() => DistrictStory(
        id: id,
        title: title,
        place: place,
        body: body,
        imageUrl: imageUrl,
        live: live,
        seen: true,
        authorName: authorName,
        createdAt: createdAt,
      );

  factory DistrictStory.fromJson(Map<String, dynamic> json) {
    return DistrictStory(
      id: '${json['id'] ?? ''}',
      title: '${json['title'] ?? ''}',
      place: '${json['place'] ?? ''}',
      body: '${json['body'] ?? ''}',
      imageUrl: (json['imageUrl'] as String?)?.trim().isEmpty == true ? null : json['imageUrl'] as String?,
      live: json['live'] == true,
      seen: json['seen'] == true,
      authorName: '${json['authorName'] ?? ''}',
      createdAt: DateTime.tryParse('${json['createdAt'] ?? ''}')?.toLocal(),
    );
  }
}

/// An issue post that was handed to someone. Nothing here is unassigned, so it
/// is either being worked on or closed.
class Dispatch {
  const Dispatch({
    required this.id,
    this.status = 'IN_PROGRESS',
    this.title = '',
    this.description = '',
    this.place = '',
    this.imageUrl,
    this.assigneeName = '',
    this.assigneeVerified = false,
    this.assignedAt,
    this.resolvedAt,
    this.raw = const {},
  });

  final String id;

  /// 'IN_PROGRESS' or 'RESOLVED'.
  final String status;
  final String title;
  final String description;
  final String place;
  final String? imageUrl;
  final String assigneeName;
  final bool assigneeVerified;
  final DateTime? assignedAt;
  final DateTime? resolvedAt;

  /// The row as it arrived, for the localised issue name helpers and for
  /// handing on to the post detail screen.
  final Map<String, dynamic> raw;

  bool get resolved => status == 'RESOLVED';

  /// When this last moved — closed if it is closed, handed over if not.
  DateTime? get movedAt => resolvedAt ?? assignedAt;

  factory Dispatch.fromJson(Map<String, dynamic> json) {
    return Dispatch(
      id: '${json['id'] ?? ''}',
      status: '${json['status'] ?? 'IN_PROGRESS'}'.toUpperCase(),
      title: '${json['title'] ?? ''}',
      description: '${json['description'] ?? ''}',
      place: '${json['place'] ?? ''}',
      imageUrl: (json['imageUrl'] as String?)?.trim().isEmpty == true ? null : json['imageUrl'] as String?,
      assigneeName: '${json['assigneeName'] ?? ''}',
      assigneeVerified: json['assigneeVerified'] == true,
      assignedAt: DateTime.tryParse('${json['assignedAt'] ?? ''}')?.toLocal(),
      resolvedAt: DateTime.tryParse('${json['resolvedAt'] ?? ''}')?.toLocal(),
      raw: json,
    );
  }
}

class CommunityBoard {
  const CommunityBoard({
    this.banner = const CommunityBanner(),
    this.stories = const [],
    this.grassroots = const [],
  });

  final CommunityBanner banner;
  final List<DistrictStory> stories;
  final List<Dispatch> grassroots;

  CommunityBoard withStories(List<DistrictStory> next) =>
      CommunityBoard(banner: banner, stories: next, grassroots: grassroots);

  static List<Map<String, dynamic>> _rows(Object? raw) {
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  factory CommunityBoard.fromJson(Map<String, dynamic> json) {
    return CommunityBoard(
      banner: CommunityBanner.fromJson(json['banner']),
      stories: _rows(json['stories']).map(DistrictStory.fromJson).toList(),
      grassroots: _rows(json['grassroots']).map(Dispatch.fromJson).toList(),
    );
  }
}

Future<CommunityBoard> fetchCommunityBoard() async {
  final res = await Get.find<ApiClient>().get('/community');
  return CommunityBoard.fromJson(Map<String, dynamic>.from(res['data'] as Map));
}

Future<DistrictStory> fetchStory(String id) async {
  final res = await Get.find<ApiClient>().get('/community/stories/$id');
  return DistrictStory.fromJson(Map<String, dynamic>.from((res['data'] as Map)['story'] as Map));
}

/// Dim the ring. Best effort — a story that was read still reads fine if this
/// never lands.
Future<void> markStorySeen(String id) async {
  await Get.find<ApiClient>().post('/community/stories/$id/seen');
}
