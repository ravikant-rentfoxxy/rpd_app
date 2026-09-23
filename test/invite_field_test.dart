import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rpd_app/core/translations/app_translations.dart';
import 'package:rpd_app/features/join/invite_field.dart';

/// The invite result card is what a member reads before they commit to a code,
/// so what it says in each state is worth pinning down.

Widget _host(Widget child, {Locale locale = const Locale('en', 'US')}) {
  Get.locale = locale;
  return GetMaterialApp(
    translations: AppTranslations(),
    locale: locale,
    fallbackLocale: const Locale('en', 'US'),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

/// The card is private, so it is reached the way the field builds it.
Widget _card(InviteLookup? lookup) => Builder(
      builder: (context) => Column(children: [InviteResultForTest(result: lookup)]),
    );

void main() {
  test('a code with no post attached is not treated as an error', () {
    const lookup = InviteLookup(code: 'ABCDEFGHJK', state: 'NONE');
    expect(lookup.noPost, isTrue);
    expect(lookup.spent, isFalse);
  });

  test('a used code is spent, not merely invalid', () {
    const lookup = InviteLookup(code: 'ABCDEFGHJK', state: 'REDEEMED', reason: 'This code has already been used');
    expect(lookup.valid, isFalse);
    expect(lookup.noPost, isFalse);
    expect(lookup.spent, isTrue);
  });

  test('reads the server shape', () {
    final lookup = InviteLookup.fromJson('x', const {
      'code': 'YHJ87Z7ZJG',
      'valid': true,
      'state': 'OPEN',
      'postTitle': 'Assembly In-charge',
      'where': 'Satyavedu',
      'issuedByName': 'Ravi Kant',
    });
    expect(lookup.code, 'YHJ87Z7ZJG');
    expect(lookup.valid, isTrue);
    expect(lookup.postTitle, 'Assembly In-charge');
  });

  testWidgets('a valid invite names the post, the place and who gave it', (tester) async {
    await tester.pumpWidget(_host(_card(const InviteLookup(
      code: 'YHJ87Z7ZJG',
      valid: true,
      state: 'OPEN',
      postTitle: 'Assembly In-charge',
      where: 'Satyavedu',
      issuedByName: 'Ravi Kant',
    ))));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('This code makes you'), findsOneWidget);
    expect(find.text('Assembly In-charge'), findsOneWidget);
    expect(find.text('Satyavedu'), findsOneWidget);
    expect(find.text('Given by Ravi Kant'), findsOneWidget);
  });

  testWidgets('a spent invite shows the server reason instead', (tester) async {
    await tester.pumpWidget(_host(_card(const InviteLookup(
      code: 'YHJ87Z7ZJG',
      state: 'REDEEMED',
      reason: 'This code has already been used',
      postTitle: 'Assembly In-charge',
    ))));
    await tester.pump();
    expect(find.text('This code cannot be used'), findsOneWidget);
    expect(find.text('This code has already been used'), findsOneWidget);
    // The post it would have granted is not dangled in front of them.
    expect(find.text('Assembly In-charge'), findsNothing);
  });

  testWidgets('a code with no post attached draws nothing at all', (tester) async {
    await tester.pumpWidget(_host(_card(const InviteLookup(code: 'K7M2XQ9P', state: 'NONE'))));
    await tester.pump();
    expect(find.text('This code cannot be used'), findsNothing);
    expect(find.text('This code makes you'), findsNothing);
  });

  testWidgets('the Hindi copy is there too', (tester) async {
    await tester.pumpWidget(_host(
      _card(const InviteLookup(code: 'YHJ87Z7ZJG', valid: true, state: 'OPEN', postTitle: 'Assembly In-charge')),
      locale: const Locale('hi', 'IN'),
    ));
    await tester.pump();
    expect(find.text('इस कोड से आप बनेंगे'), findsOneWidget);
  });

  test('typing is upper-cased as it goes in', () {
    final formatter = UpperCaseTextFormatter();
    final out = formatter.formatEditUpdate(
      const TextEditingValue(text: ''),
      const TextEditingValue(text: 'yhj87z7zjg'),
    );
    expect(out.text, 'YHJ87Z7ZJG');
  });
}
