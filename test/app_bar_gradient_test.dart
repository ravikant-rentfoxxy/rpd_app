import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpd_app/core/theme/app_colors.dart';

void main() {
  testWidgets('the app bar gradient fills the bar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            flexibleSpace: appBarGradientSpace,
            title: const Text("Posts"),
          ),
          body: const SizedBox.shrink(),
        ),
      ),
    );
    // A childless DecoratedBox takes constraints.smallest inside AppBar's
    // flexibleSpace stack, which left every bar painting nothing.
    final painted = tester.getSize(find.byWidget(appBarGradientSpace));
    final bar = tester.getSize(find.byType(AppBar));
    expect(painted, bar, reason: 'the gradient must fill the bar it sits behind');
  });
}
