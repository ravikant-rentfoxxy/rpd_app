class OrgPost {
  const OrgPost({required this.code, required this.title});
  final String code;
  final String title;
}

class OrgLevel {
  const OrgLevel({required this.code, required this.name, required this.posts});
  final String code;
  final String name;
  final List<OrgPost> posts;
}

/// Party office hierarchy. Members are mapped onto a post at one of these levels later.
const orgHierarchy = [
  OrgLevel(
    code: 'NATIONAL',
    name: 'National',
    posts: [
      OrgPost(code: 'NATIONAL_PRESIDENT', title: 'National President'),
      OrgPost(code: 'NATIONAL_GENERAL_SECRETARY', title: 'General Secretary'),
    ],
  ),
  OrgLevel(
    code: 'STATE',
    name: 'State',
    posts: [
      OrgPost(code: 'STATE_PRESIDENT', title: 'State President'),
      OrgPost(code: 'STATE_GENERAL_SECRETARY', title: 'State General Secretary'),
    ],
  ),
  OrgLevel(
    code: 'REGION',
    name: 'Region / Zone',
    posts: [OrgPost(code: 'REGIONAL_PRESIDENT', title: 'Regional President')],
  ),
  OrgLevel(
    code: 'DISTRICT',
    name: 'District',
    posts: [
      OrgPost(code: 'DISTRICT_PRESIDENT', title: 'District President'),
      OrgPost(code: 'DISTRICT_GENERAL_SECRETARY', title: 'District General Secretary'),
    ],
  ),
  OrgLevel(
    code: 'ASSEMBLY',
    name: 'Assembly Constituency',
    posts: [OrgPost(code: 'ASSEMBLY_IN_CHARGE', title: 'Assembly In-charge')],
  ),
  OrgLevel(
    code: 'MANDAL',
    name: 'Mandal / Block',
    posts: [OrgPost(code: 'MANDAL_PRESIDENT', title: 'Mandal President')],
  ),
];

const verificationPosts = {
  'SUPER_ADMIN',
  'BOOTH_ADHYAKSH',
  'MANDAL_PRESIDENT',
  'ASSEMBLY_IN_CHARGE',
  'DISTRICT_SECRETARY',
  'DISTRICT_GENERAL_SECRETARY',
  'DISTRICT_PRESIDENT',
  'REGIONAL_PRESIDENT',
  'STATE_GENERAL_SECRETARY',
  'STATE_PRESIDENT',
  'NATIONAL_GENERAL_SECRETARY',
  'NATIONAL_PRESIDENT',
};

String postLabelKey(String? post) => 'post_${post ?? 'MEMBER'}';

const postRanks = {
  'SUPER_ADMIN': 1000,
  'NATIONAL_PRESIDENT': 100,
  'NATIONAL_GENERAL_SECRETARY': 95,
  'STATE_PRESIDENT': 90,
  'STATE_GENERAL_SECRETARY': 85,
  'REGIONAL_PRESIDENT': 80,
  'DISTRICT_PRESIDENT': 70,
  'DISTRICT_GENERAL_SECRETARY': 65,
  'DISTRICT_SECRETARY': 60,
  'ASSEMBLY_IN_CHARGE': 50,
  'MANDAL_PRESIDENT': 40,
  'BOOTH_ADHYAKSH': 30,
  'PANNA_PRAMUKH': 20,
  'MEMBER': 10,
};

int postRankOf(String? post) => postRanks[post] ?? postRanks['MEMBER']!;

bool officerCanCreateOrgEvents(String? post, {bool isSuperAdmin = false}) {
  if (isSuperAdmin || post == 'SUPER_ADMIN') return true;
  return postRankOf(post) > postRankOf('MEMBER');
}
