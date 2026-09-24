import 'package:flutter_test/flutter_test.dart';
import 'package:rpd_app/features/leaders/invite_api.dart';

/// The leaders screen places each offerable post on the right rung, and takes
/// the area to scope it to from the sharer's own profile — the ids `/auth/me`
/// already put in Hive. Neither needs anything added to /members/leaders.

void main() {
  group('which rung a post sits on', () {
    test('matches the server ladder', () {
      expect(levelOfPost('NATIONAL_PRESIDENT'), 'NATIONAL');
      expect(levelOfPost('NATIONAL_GENERAL_SECRETARY'), 'NATIONAL');
      expect(levelOfPost('STATE_PRESIDENT'), 'STATE');
      expect(levelOfPost('STATE_GENERAL_SECRETARY'), 'STATE');
      expect(levelOfPost('REGIONAL_PRESIDENT'), 'REGION');
      expect(levelOfPost('DISTRICT_PRESIDENT'), 'DISTRICT');
      expect(levelOfPost('DISTRICT_GENERAL_SECRETARY'), 'DISTRICT');
      expect(levelOfPost('DISTRICT_SECRETARY'), 'DISTRICT');
      expect(levelOfPost('ASSEMBLY_IN_CHARGE'), 'ASSEMBLY');
      expect(levelOfPost('MANDAL_PRESIDENT'), 'MANDAL');
      expect(levelOfPost('BOOTH_ADHYAKSH'), 'BOOTH');
      expect(levelOfPost('PANNA_PRAMUKH'), 'BOOTH');
      expect(levelOfPost('MEMBER'), 'BOOTH');
    });

    test('every post the server can offer lands somewhere', () {
      const all = [
        'NATIONAL_PRESIDENT', 'NATIONAL_GENERAL_SECRETARY',
        'STATE_PRESIDENT', 'STATE_GENERAL_SECRETARY', 'REGIONAL_PRESIDENT',
        'DISTRICT_PRESIDENT', 'DISTRICT_GENERAL_SECRETARY', 'DISTRICT_SECRETARY',
        'ASSEMBLY_IN_CHARGE', 'MANDAL_PRESIDENT', 'BOOTH_ADHYAKSH',
        'PANNA_PRAMUKH', 'MEMBER',
      ];
      const rungs = {'NATIONAL', 'STATE', 'REGION', 'DISTRICT', 'ASSEMBLY', 'MANDAL', 'BOOTH'};
      for (final post in all) {
        expect(rungs, contains(levelOfPost(post)), reason: '$post has nowhere to go');
      }
    });
  });

  group('what is offered', () {
    // The server still returns these; the app drops them before they reach a
    // level row, because no member carries a mandal or booth id to scope one.
    test('a mandal or booth post is not offered', () {
      const dropped = {'mandalId', 'boothId'};
      for (final requires in dropped) {
        expect(
          unscopedInApp(requires),
          isTrue,
          reason: '\$requires would put a button on screen that can only fail',
        );
      }
    });

    test('everything the profile can scope is still offered', () {
      for (final requires in ['stateId', 'regionId', 'districtId', 'assemblyId', null]) {
        expect(unscopedInApp(requires), isFalse, reason: '\$requires should still be offered');
      }
    });
  });

  group('the area comes from the profile', () {
    const profile = {
      'stateId': 's-1',
      'regionId': null,
      'districtId': 'd-1',
      'assemblyId': 'a-1',
      'mandalId': null,
      'boothId': null,
    };

    test('reads the field the server asked for', () {
      expect(areaIdFor(profile, 'districtId'), 'd-1');
      expect(areaIdFor(profile, 'assemblyId'), 'a-1');
      expect(areaIdFor(profile, 'stateId'), 's-1');
    });

    test('is null when the post needs no area', () {
      expect(areaIdFor(profile, null), isNull);
    });

    test('is null when the profile has no such id, so the screen can say so', () {
      // The member has no booth, which is why the mint must not be attempted.
      expect(areaIdFor(profile, 'boothId'), isNull);
      expect(areaIdFor(profile, 'mandalId'), isNull);
    });

    test('a missing profile does not throw', () {
      expect(areaIdFor(null, 'districtId'), isNull);
      expect(areaIdFor(const {}, 'districtId'), isNull);
    });
  });
}
