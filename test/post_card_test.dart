import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rpd_app/core/theme/app_colors.dart';
import 'package:rpd_app/core/translations/app_translations.dart';
import 'package:rpd_app/core/widgets/iro_ui.dart';
import 'package:rpd_app/features/post/post_views.dart';

/// The Posts list shows the same post two ways. On another member's post the
/// like and dislike are buttons; on the member's own they are figures, because
/// voting on yourself is not a thing.

Map<String, dynamic> samplePost({String status = 'OPEN'}) => {
      'clientUuid': 'abc',
      'serverId': 'srv',
      'issueName': 'Drinking water',
      'subIssueName': 'Handpump not working',
      'description': 'The handpump near the school gate has been dry for three weeks.',
      'regionLabel': 'Ward 4, Kattakkada',
      'createdAt': '2026-09-21T09:00:00Z',
      'likes': 12,
      'dislikes': 1,
      'views': 40,
      'myVote': 'LIKE',
      'status': status,
      'authorName': 'Sreekala R',
      'assigneeName': 'Manoj K',
      'assigneePostLabel': 'Booth Adhyaksh',
    };

Widget host(Widget child) {
  Get.locale = const Locale('en', 'US');
  return GetMaterialApp(
    translations: AppTranslations(),
    locale: const Locale('en', 'US'),
    fallbackLocale: const Locale('en', 'US'),
    home: Scaffold(
      backgroundColor: Iro.mint,
      body: SingleChildScrollView(child: child),
    ),
  );
}

List<IroVoteButton> votesIn(WidgetTester tester) =>
    tester.widgetList<IroVoteButton>(find.byType(IroVoteButton)).toList();

void main() {
  testWidgets("another member's post offers the vote as a button", (tester) async {
    await tester.pumpWidget(host(RegionPostCard(post: samplePost(), canVote: true)));
    await tester.pump();

    final votes = votesIn(tester);
    expect(votes.length, 2);
    expect(votes.every((v) => v.onTap != null), isTrue, reason: 'both sides should be tappable');
    // The counts still read, and the side this member took is marked.
    expect(find.text('12'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(votes.first.on, isTrue, reason: 'myVote is LIKE');
  });

  testWidgets('the member\'s own post shows the figures without the buttons', (tester) async {
    await tester.pumpWidget(host(RegionPostCard(post: samplePost(), canVote: false)));
    await tester.pump();

    final votes = votesIn(tester);
    expect(votes.length, 2);
    expect(votes.every((v) => v.onTap == null), isTrue, reason: 'nothing to press on your own post');
    // The numbers are still there — they were only ever the point.
    expect(find.text('12'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('a read-only vote draws no pressable surface', (tester) async {
    await tester.pumpWidget(host(RegionPostCard(post: samplePost(), canVote: false)));
    await tester.pump();
    // The card itself is tappable, so the check is that the votes are not.
    for (final vote in votesIn(tester)) {
      expect(
        find.descendant(of: find.byWidget(vote), matching: find.byType(InkWell)),
        findsNothing,
        reason: 'a read-only count must not look pressable',
      );
    }
  });

  testWidgets('the card carries the view count', (tester) async {
    await tester.pumpWidget(host(RegionPostCard(post: samplePost(), canVote: true)));
    await tester.pump();
    expect(find.byType(IroViewCount), findsOneWidget);
    expect(find.text('40'), findsOneWidget);
  });

  testWidgets('a post nobody has opened says nothing rather than zero', (tester) async {
    final quiet = samplePost()..['views'] = 0;
    await tester.pumpWidget(host(RegionPostCard(post: quiet, canVote: true)));
    await tester.pump();
    expect(find.text('0'), findsNothing);
  });

  testWidgets('a resolved post is marked, an open one is not', (tester) async {
    await tester.pumpWidget(host(RegionPostCard(post: samplePost(status: 'RESOLVED'), canVote: true)));
    await tester.pump();
    expect(find.text('Resolved'), findsOneWidget);

    await tester.pumpWidget(host(RegionPostCard(post: samplePost(), canVote: true)));
    await tester.pump();
    expect(find.text('Resolved'), findsNothing);
  });

  testWidgets('it says who filed it and who is on it', (tester) async {
    await tester.pumpWidget(host(RegionPostCard(post: samplePost(), canVote: true)));
    await tester.pump();
    expect(find.textContaining('Sreekala R'), findsOneWidget);
    expect(find.textContaining('Manoj K'), findsOneWidget);
    expect(find.textContaining('Booth Adhyaksh'), findsOneWidget);
  });

  testWidgets('the title and the description both show', (tester) async {
    await tester.pumpWidget(host(RegionPostCard(post: samplePost(), canVote: true)));
    await tester.pump();
    expect(find.text('Handpump not working'), findsOneWidget);
    expect(find.textContaining('dry for three weeks'), findsOneWidget);
  });
}
