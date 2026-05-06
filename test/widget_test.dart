import 'package:elio/screens/confirmation_screen.dart';
import 'package:elio/theme/elio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('confirmation screen starts after loading streak', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ElioTheme.dark(),
        home: const ConfirmationScreen(
          moodValue: 0.5,
          moodWord: 'Okay',
          intentionText: 'Stay present',
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 2600));

    expect(tester.takeException(), isNull);
    expect(find.text('Done'), findsOneWidget);
  });
}
