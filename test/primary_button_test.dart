import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpd_app/core/theme/app_colors.dart';
import 'package:rpd_app/core/widgets/ui.dart';

/// Every primary action carries the same fill as the create button in the tab
/// bar, so the one thing to press on a screen looks the same wherever a member
/// meets it — Continue, Submit application, Create task and the rest.

Gradient? fillOf(WidgetTester tester) {
  final boxes = tester.widgetList<DecoratedBox>(
    find.descendant(of: find.byType(PrimaryButton), matching: find.byType(DecoratedBox)),
  );
  for (final box in boxes) {
    final d = box.decoration;
    if (d is BoxDecoration && d.gradient != null) return d.gradient;
  }
  return null;
}

Widget host(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('a primary button is filled with the brand gradient by default', (tester) async {
    await tester.pumpWidget(host(PrimaryButton('Continue', onTap: () {})));
    await tester.pump();
    expect(fillOf(tester), Iro.headerGradient);
  });

  testWidgets('a disabled one stays flat, so it still reads as unavailable', (tester) async {
    await tester.pumpWidget(host(PrimaryButton('Continue', enabled: false, onTap: () {})));
    await tester.pump();
    expect(fillOf(tester), isNull);
  });

  testWidgets('a ghost button keeps its outline', (tester) async {
    await tester.pumpWidget(host(PrimaryButton('Sign out', ghost: true, onTap: () {})));
    await tester.pump();
    expect(fillOf(tester), isNull);
  });

  testWidgets('the flat fill is still reachable by passing null', (tester) async {
    await tester.pumpWidget(host(PrimaryButton('Continue', gradient: null, onTap: () {})));
    await tester.pump();
    expect(fillOf(tester), isNull);
  });

  testWidgets('tapping still fires', (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(PrimaryButton('Continue', onTap: () => taps++)));
    await tester.pump();
    await tester.tap(find.byType(PrimaryButton));
    await tester.pump();
    expect(taps, 1);
  });
}
