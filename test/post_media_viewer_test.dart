import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rpd_app/core/translations/app_translations.dart';
import 'package:rpd_app/features/post/post_media_viewer.dart';

/// The detail screen used to size its media to the picture, so a portrait photo
/// pushed the description and the actions off the bottom. These pin the cap and
/// the way out of it.

const screen = Size(400, 800);

final post = <String, dynamic>{'clientUuid': 'abc', 'serverId': 'srv'};

Widget host(Widget child) {
  Get.locale = const Locale('en', 'US');
  return GetMaterialApp(
    translations: AppTranslations(),
    locale: const Locale('en', 'US'),
    fallbackLocale: const Locale('en', 'US'),
    home: Scaffold(body: ListView(children: [child, const SizedBox(height: 900)])),
  );
}

void main() {
  setUp(() {
    // A fixed screen, so "30% of it" is a number the test can check.
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  test('a tag is unique per post and per kind', () {
    final other = {'clientUuid': 'xyz'};
    expect(postMediaHeroTag(post, 'image'), isNot(postMediaHeroTag(other, 'image')));
    expect(postMediaHeroTag(post, 'image'), isNot(postMediaHeroTag(post, 'video')));
    // Same post, same kind, same tag — or the flight has nothing to fly to.
    expect(postMediaHeroTag(post, 'image'), postMediaHeroTag({...post}, 'image'));
  });

  test('the thumbnail is well under half the screen, the viewer is half', () {
    expect(postMediaThumbFraction, lessThan(postMediaViewerFraction));
    expect(postMediaThumbFraction, 0.30);
    expect(postMediaViewerFraction, 0.50);
  });

  testWidgets('the thumbnail is capped at the height it is given', (tester) async {
    tester.view.physicalSize = screen;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final height = screen.height * postMediaThumbFraction;
    await tester.pumpWidget(host(PostImageThumb(post: post, raw: null, height: height)));
    await tester.pump();

    final box = tester.getSize(find.byType(PostImageThumb));
    expect(box.height, moreOrLessEquals(height, epsilon: 0.5));
    // 240 of an 800-high screen — the post below it stays on screen.
    expect(box.height, moreOrLessEquals(240, epsilon: 0.5));
  });

  testWidgets('the thumbnail carries a Hero that the viewer matches', (tester) async {
    tester.view.physicalSize = screen;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host(PostImageThumb(post: post, raw: null, height: 240)));
    await tester.pump();

    final tag = postMediaHeroTag(post, 'image');
    final thumbHero = tester.widget<Hero>(find.byType(Hero));
    expect(thumbHero.tag, tag);

    await tester.tap(find.byType(PostImageThumb));
    await tester.pumpAndSettle();

    // Both ends of the flight share the tag.
    final heroes = tester.widgetList<Hero>(find.byType(Hero)).map((h) => h.tag).toList();
    expect(heroes, contains(tag));
  });

  testWidgets('tapping opens the media over a blurred backdrop', (tester) async {
    tester.view.physicalSize = screen;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host(PostImageThumb(post: post, raw: null, height: 240)));
    await tester.pump();
    expect(find.byType(BackdropFilter), findsNothing);

    await tester.tap(find.byType(PostImageThumb));
    await tester.pumpAndSettle();

    expect(find.byType(BackdropFilter), findsOneWidget, reason: 'the page behind should be blurred');
    expect(find.byType(InteractiveViewer), findsOneWidget, reason: 'the opened photo should zoom');
    expect(find.byIcon(Icons.close_rounded), findsOneWidget, reason: 'there has to be a visible way out');
  });

  testWidgets('the opened media takes half the screen', (tester) async {
    tester.view.physicalSize = screen;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host(PostImageThumb(post: post, raw: null, height: 240)));
    await tester.pump();
    await tester.tap(find.byType(PostImageThumb));
    await tester.pumpAndSettle();

    final opened = tester.getSize(find.byType(InteractiveViewer));
    expect(opened.height, moreOrLessEquals(screen.height * postMediaViewerFraction, epsilon: 1));
  });

  testWidgets('the close button dismisses it', (tester) async {
    tester.view.physicalSize = screen;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host(PostImageThumb(post: post, raw: null, height: 240)));
    await tester.pump();
    await tester.tap(find.byType(PostImageThumb));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('tapping the backdrop dismisses it, tapping the media does not', (tester) async {
    tester.view.physicalSize = screen;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host(PostImageThumb(post: post, raw: null, height: 240)));
    await tester.pump();
    await tester.tap(find.byType(PostImageThumb));
    await tester.pumpAndSettle();

    // The media itself absorbs the tap.
    await tester.tap(find.byType(InteractiveViewer));
    await tester.pumpAndSettle();
    expect(find.byType(BackdropFilter), findsOneWidget);

    // The area above it is backdrop.
    await tester.tapAt(const Offset(200, 30));
    await tester.pumpAndSettle();
    expect(find.byType(BackdropFilter), findsNothing);
  });
}
