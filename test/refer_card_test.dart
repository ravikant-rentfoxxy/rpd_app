import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rpd_app/core/constants/endpoints.dart';
import 'package:rpd_app/core/theme/app_colors.dart';
import 'package:rpd_app/core/translations/app_translations.dart';
import 'package:rpd_app/core/utils/invite_code.dart';
import 'package:rpd_app/core/widgets/iro_ui.dart';
import 'package:rpd_app/features/refer/refer_card.dart';

/// The code is worked out on the phone from what Hive already holds — nothing
/// is asked of the server. The membership card derives it the same way, and the
/// two must agree or a member hands out a code that credits nobody.

const member = <String, dynamic>{
  'id': 'm-1',
  'fullName': 'Pankaj Yadav',
  'membershipNumber': 'RPD-UP-57',
  // The server's own verdict: a name, a state, a district and a constituency.
  'profileComplete': true,
};

Widget host(Widget child, {double width = 360, Locale locale = const Locale('en', 'US')}) {
  Get.locale = locale;
  Get.addTranslations(AppTranslations().keys);
  return GetMaterialApp(
    translations: AppTranslations(),
    locale: locale,
    fallbackLocale: const Locale('en', 'US'),
    home: Scaffold(
      backgroundColor: Iro.mint,
      body: Center(child: SizedBox(width: width, child: SingleChildScrollView(child: child))),
    ),
  );
}

void main() {
  // `.trParams` has no fallback — an unregistered key comes back as the key
  // itself — so the translations go in before anything reads one.
  setUpAll(() {
    Get.locale = const Locale('en', 'US');
    Get.addTranslations(AppTranslations().keys);
  });

  group('the code', () {
    test('is eight characters off the membership number', () {
      final code = inviteCodeOf(member);
      expect(code, hasLength(8));
      expect(RegExp(r'^[A-Z0-9]{8}$').hasMatch(code), isTrue);
    });

    test('is the same every time, so it can be printed and shared', () {
      expect(inviteCodeOf(member), inviteCodeOf({...member}));
    });

    test('two members do not share one', () {
      expect(inviteCodeOf(member), isNot(inviteCodeOf({...member, 'membershipNumber': 'RPD-UP-58'})));
    });

    test('avoids the letters that get misread by hand', () {
      // No I, O, 0 or 1 — these are read off a card and typed.
      for (final n in List.generate(60, (i) => 'RPD-UP-$i')) {
        expect(inviteCodeOf({'membershipNumber': n}), isNot(matches(RegExp('[IO01]'))));
      }
    });

    test('a stored code from the server wins over the derived one', () {
      expect(inviteCodeOf({...member, 'inviteCode': 'ZZZZZZZZ'}), 'ZZZZZZZZ');
    });

    test('is empty when there is nothing to derive it from', () {
      expect(inviteCodeOf(null), isEmpty);
      expect(inviteCodeOf(const {}), isEmpty);
    });
  });

  group('what gets shared', () {
    test('carries the code and the store link', () {
      final text = ReferFriendCard.shareText('K7M2XQ9P');
      expect(text, contains('K7M2XQ9P'));
      expect(text, contains(ExternalLinks.playStore));
      expect(ExternalLinks.playStore, contains('in.rpd.rpd_app'), reason: 'must match the Android applicationId');
    });

    test('still sends the link when there is no code', () {
      final text = ReferFriendCard.shareText('');
      expect(text, contains(ExternalLinks.playStore));
    });
  });

  group('the card', () {
    testWidgets('shows the code, spaced out to be read aloud', (tester) async {
      await tester.pumpWidget(host(const ReferFriendCard(member: member)));
      await tester.pump();
      expect(find.text('Refer a friend'), findsOneWidget);
      expect(find.text(inviteCodeOf(member).split('').join(' ')), findsOneWidget);
      expect(find.byType(IroActionButton), findsOneWidget);
    });

    testWidgets('stays out of the way when the member has no code yet', (tester) async {
      await tester.pumpWidget(host(const ReferFriendCard(member: {'profileComplete': true})));
      await tester.pump();
      expect(find.byType(IroCard), findsNothing);
      expect(find.text('Refer a friend'), findsNothing);
    });

    testWidgets('waits until the profile is complete', (tester) async {
      // A code can be derived from the membership number long before the member
      // has a state, district and constituency on their record. Handing it out
      // then would credit recruits to an unplaced member.
      const half = <String, dynamic>{
        'id': 'm-1',
        'fullName': 'Pankaj Yadav',
        'membershipNumber': 'RPD-UP-57',
        'profileComplete': false,
      };
      expect(inviteCodeOf(half), isNotEmpty, reason: 'the code itself exists');

      await tester.pumpWidget(host(const ReferFriendCard(member: half)));
      await tester.pump();
      expect(find.byType(IroCard), findsNothing, reason: 'but it must not be offered yet');
      expect(find.byType(IroActionButton), findsNothing, reason: 'and neither must Share');
    });

    testWidgets('a profile with no verdict at all is treated as incomplete', (tester) async {
      await tester.pumpWidget(host(const ReferFriendCard(
        member: {'id': 'm-1', 'fullName': 'Pankaj Yadav', 'membershipNumber': 'RPD-UP-57'},
      )));
      await tester.pump();
      expect(find.byType(IroCard), findsNothing);
    });

    testWidgets('tapping the code copies it', (tester) async {
      final copied = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') copied.add(call.arguments['text'] as String);
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));

      await tester.pumpWidget(host(const ReferFriendCard(member: member)));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.copy_rounded));
      await tester.pump();
      expect(copied, [inviteCodeOf(member)], reason: 'the plain code, not the spaced-out one');
    });

    testWidgets('stays compact — it is a prompt, not a section', (tester) async {
      await tester.pumpWidget(host(const ReferFriendCard(member: member)));
      await tester.pump();
      final height = tester.getSize(find.byType(ReferFriendCard)).height;
      // It began as a banner-plus-body block over 200pt tall, which pushed the
      // whole feed down the page. One row, margin included.
      expect(height, lessThan(66), reason: 'the card has grown back into a section (\${height}pt)');
    });

    testWidgets('does not overflow a narrow phone', (tester) async {
      await tester.pumpWidget(host(const ReferFriendCard(member: member), width: 300));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('speaks Hindi and Bhojpuri too', (tester) async {
      for (final locale in [const Locale('hi', 'IN'), const Locale('bho', 'IN')]) {
        await tester.pumpWidget(host(const ReferFriendCard(member: member), locale: locale));
        await tester.pump();
        expect(find.text('Refer a friend'), findsNothing, reason: '$locale still renders English');
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('the profile row', () {
    // The profile screen prints the membership number and the code side by
    // side: both are the member's own identifiers, one to quote and one to hand
    // out, and people read across them against a card they are holding.

    testWidgets('prints the number and the code on one line', (tester) async {
      await tester.pumpWidget(host(const ReferralRow(member: member)));
      await tester.pump();

      expect(find.text('Member ID'), findsOneWidget);
      expect(find.text('Referral code'), findsOneWidget);
      expect(find.text('RPD-UP-57'), findsOneWidget);
      expect(find.text(inviteCodeOf(member)), findsOneWidget);

      final id = tester.getRect(find.text('RPD-UP-57'));
      final code = tester.getRect(find.text(inviteCodeOf(member)));
      expect(code.left, greaterThan(id.right), reason: 'the code must sit beside the number, not under it');
      expect(id.center.dy, closeTo(code.center.dy, 1), reason: 'and on the same line');
    });

    testWidgets('leaves each value room to print in full', (tester) async {
      await tester.pumpWidget(host(const ReferralRow(member: member)));
      await tester.pump();

      // With the Share pill inside the row, both columns came out at about
      // 71pt — too narrow for a nine-character membership number — so it was
      // moved up beside the section heading.
      for (final text in ['RPD-UP-57', inviteCodeOf(member)]) {
        final width = tester.renderObject<RenderParagraph>(find.text(text)).size.width;
        expect(width, greaterThan(100), reason: '$text is being squeezed (\${width}pt)');
      }
    });

    testWidgets('tapping the code copies it', (tester) async {
      final copied = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') copied.add(call.arguments['text'] as String);
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));

      await tester.pumpWidget(host(const ReferralRow(member: member)));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.copy_rounded));
      await tester.pump();
      expect(copied, [inviteCodeOf(member)]);
    });

    testWidgets('does not overflow a narrow phone', (tester) async {
      for (final width in [320.0, 300.0]) {
        await tester.pumpWidget(host(const ReferralRow(member: member), width: width));
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'overflowed at ${width}pt');
      }
    });

    testWidgets('Share sits outside the row, in the section heading', (tester) async {
      await tester.pumpWidget(host(const ReferralRow(member: member)));
      await tester.pump();
      expect(find.byType(IroActionButton), findsNothing);

      await tester.pumpWidget(host(const ReferralShareButton(member: member)));
      await tester.pump();
      expect(find.text('Share'), findsOneWidget);
    });
  });

  group('whether the section shows at all', () {
    test('needs a finished profile and a code', () {
      expect(referralVisible(member), isTrue);
      expect(referralVisible({...member, 'profileComplete': false}), isFalse);
      expect(referralVisible(const {'profileComplete': true}), isFalse, reason: 'nothing to derive a code from');
      expect(referralVisible(const {'membershipNumber': 'RPD-UP-57'}), isFalse, reason: 'no verdict is not a yes');
    });
  });
}
