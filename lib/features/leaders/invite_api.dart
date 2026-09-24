import 'package:get/get.dart';

import '../../data/remote/api_client.dart';

/// The post-invite endpoints, as the leaders screen uses them.
///
/// A code carries a post in the hierarchy. The server only mints one for a post
/// below the caller's own and inside the area they run, so the app does not
/// enforce that itself — it only asks what it is allowed to offer.

/// A post this member may hand out, and what pinning it down requires.
class AssignablePost {
  const AssignablePost({required this.post, required this.title, this.requires});

  final String post;
  final String title;

  /// The scope field the server insists on: 'assemblyId', 'boothId' and so on.
  /// Null for posts that need nothing beyond the issuer's own area.
  final String? requires;

  factory AssignablePost.fromJson(Map<String, dynamic> json) => AssignablePost(
        post: '${json['post'] ?? ''}',
        title: '${json['title'] ?? ''}',
        requires: (json['requires'] as String?)?.trim().isEmpty == true ? null : json['requires'] as String?,
      );
}

/// A minted code, with the post and place it carries.
class PostInvite {
  const PostInvite({
    required this.code,
    this.post = '',
    this.postTitle = '',
    this.where = '',
    this.expiresAt,
  });

  final String code;
  final String post;
  final String postTitle;
  final String where;
  final DateTime? expiresAt;

  factory PostInvite.fromJson(Map<String, dynamic> json) => PostInvite(
        code: '${json['code'] ?? ''}',
        post: '${json['post'] ?? ''}',
        postTitle: '${json['postTitle'] ?? ''}',
        where: '${json['where'] ?? ''}',
        expiresAt: DateTime.tryParse('${json['expiresAt'] ?? ''}')?.toLocal(),
      );
}

/// Which rung of the ladder a post sits on.
///
/// Read off the post's own name, the same convention the server's `scopeForPost`
/// uses. Deliberately not a table: a local copy of the ladder is one more thing
/// to keep in step, and the app already has one that has drifted.
String levelOfPost(String post) {
  if (post.startsWith('NATIONAL_')) return 'NATIONAL';
  if (post.startsWith('STATE_')) return 'STATE';
  if (post.startsWith('REGIONAL_')) return 'REGION';
  if (post.startsWith('DISTRICT_')) return 'DISTRICT';
  if (post == 'ASSEMBLY_IN_CHARGE') return 'ASSEMBLY';
  if (post == 'MANDAL_PRESIDENT') return 'MANDAL';
  // Booth adhyaksh, panna pramukh and plain members all sit at the booth.
  return 'BOOTH';
}

/// The area id a post has to be pinned to, taken from the sharer's own profile.
///
/// The ladder on this screen is the member's own chain, so their profile is
/// where it comes from — the same ids `/auth/me` already put in Hive. Null when
/// the post needs nothing, or when the member's record has no such id.
String? areaIdFor(Map<String, dynamic>? member, String? scopeField) {
  if (member == null || scopeField == null) return null;
  final value = '${member[scopeField] ?? ''}'.trim();
  return value.isEmpty ? null : value;
}

/// Scopes the app cannot fill in, so it does not offer posts that need them.
///
/// A mandal or booth code has to name one, and no member carries either id —
/// there are no booths on the register at all. Offering the post would put a
/// button on screen whose only outcome is an error.
const _unscopedFields = {'mandalId', 'boothId'};

/// Whether a post asking for this scope is dropped before it reaches a level.
bool unscopedInApp(String? requires) => _unscopedFields.contains(requires);

/// Which posts this member may issue a code for. An ordinary member gets an
/// empty list, which is what keeps the action off their screen.
Future<List<AssignablePost>> fetchAssignablePosts() async {
  final res = await Get.find<ApiClient>().get('/invites/assignable');
  final rows = ((res['data'] as Map?)?['posts'] as List?) ?? const [];
  return rows
      .whereType<Map>()
      .map((e) => AssignablePost.fromJson(Map<String, dynamic>.from(e)))
      .where((p) => p.post.isNotEmpty && !_unscopedFields.contains(p.requires))
      .toList();
}

/// Mints a fresh code. [scopeField] and [areaId] pin it to a place — an
/// assembly in-charge code has to say which assembly.
Future<PostInvite> createPostInvite({
  required String post,
  String? scopeField,
  String? areaId,
}) async {
  final res = await Get.find<ApiClient>().post('/invites', data: {
    'post': post,
    if (scopeField != null && areaId != null) scopeField: areaId,
  });
  return PostInvite.fromJson(Map<String, dynamic>.from((res['data'] as Map)['invite'] as Map));
}
