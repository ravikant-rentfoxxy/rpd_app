import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rpd_app/core/translations/app_translations.dart';
import 'package:rpd_app/data/models/home_feed.dart';

/// Community lists joined events by reading the endpoint the tasks screen
/// already uses. Nothing was added on the server, so what matters is that what
/// `serializeOrgEvent` sends parses into the card's model without loss.

/// A row exactly as `GET /events/joined` sends it.
const joinedRow = <String, dynamic>{
  'kind': 'EVENT',
  'id': 'evt-1',
  'type': 'PUBLIC_PROGRAMME',
  'title': 'Ward 4 cleanliness drive',
  'description': 'Meet at the school gate.',
  'when': '24 Sep · 9:00 AM',
  'startsAt': '2026-09-24T03:30:00.000Z',
  'endsAt': '2026-09-24T06:30:00.000Z',
  'durationMinutes': 180,
  'place': 'Govt School, Ward 4',
  'venue': 'Govt School, Ward 4',
  'latitude': 27.1752554,
  'longitude': 78.0098161,
  'imageUrl': 'https://rentfoxxy-media.b-cdn.net/events/1.jpg',
  'joining': 12,
  'checkedInCount': 3,
  'joined': true,
  'checkedIn': false,
  'checkedInAt': null,
  'hostId': 'm-1',
  'hostName': 'Ravi Kant',
  'createdAt': '2026-09-20T10:00:00.000Z',
  'hostPost': 'DISTRICT_PRESIDENT',
  'joiners': [
    {'id': 'm-2', 'fullName': 'Sreekala R', 'photoUrl': null},
  ],
};

void main() {
  test('a joined event parses into the card model', () {
    final event = UpcomingEvent.fromJson(joinedRow);
    expect(event.id, 'evt-1');
    expect(event.title, 'Ward 4 cleanliness drive');
    // The card leans on these; a blank one leaves a hole where the time goes.
    expect(event.when, '24 Sep · 9:00 AM');
    expect(event.place, 'Govt School, Ward 4');
    expect(event.joining, 12);
    expect(event.joined, isTrue, reason: 'everything on this endpoint is already joined');
    expect(event.hostName, 'Ravi Kant');
    expect(event.joiners, hasLength(1));
    expect(event.startsAt, isNotNull);
    expect(event.kind, 'EVENT');
    expect(event.latitude, closeTo(27.175, 0.01));
  });

  test('a row with no venue still parses rather than throwing', () {
    final sparse = Map<String, dynamic>.from(joinedRow)
      ..remove('place')
      ..remove('venue')
      ..remove('imageUrl')
      ..remove('joiners');
    final event = UpcomingEvent.fromJson(sparse);
    expect(event.place, isEmpty);
    expect(event.joiners, isEmpty);
    expect(event.title, 'Ward 4 cleanliness drive');
  });

  test('every locale has the joined-events copy', () {
    final keys = AppTranslations().keys;
    for (final locale in ['en_US', 'hi_IN', 'bho_IN']) {
      for (final key in ['joined_events', 'no_joined_events', 'my_tasks']) {
        expect(keys[locale]![key], isNotNull, reason: '$locale is missing $key');
        expect(keys[locale]![key]!.trim(), isNotEmpty, reason: '$locale $key is blank');
      }
    }
  });

  test('the locales do not share one string', () {
    final keys = AppTranslations().keys;
    final headings = ['en_US', 'hi_IN', 'bho_IN'].map((l) => keys[l]!['joined_events']).toSet();
    expect(headings.length, 3, reason: 'a locale is falling back to another');
  });

  test('the labels resolve rather than coming back as keys', () {
    Get.addTranslations(AppTranslations().keys);
    for (final locale in [const Locale('en', 'US'), const Locale('hi', 'IN'), const Locale('bho', 'IN')]) {
      Get.locale = locale;
      expect('joined_events'.tr, isNot('joined_events'));
      expect('no_joined_events'.tr, isNot('no_joined_events'));
    }
  });
}
