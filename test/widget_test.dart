import 'dart:io';

import 'package:elio/screens/onboarding/welcome_screen.dart';
import 'package:elio/theme/elio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('welcome screen presents the Elio first-run message', (
    tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: ElioTheme.light(),
        darkTheme: ElioTheme.dark(),
        themeMode: ThemeMode.dark,
        home: WelcomeScreen(onNext: () => tapped = true),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Clarity in 2 minutes a day'), findsOneWidget);
    expect(
      find.text("Connect how you feel to where you're going"),
      findsOneWidget,
    );

    await tester.tap(find.text('Get Started'));
    expect(tapped, isTrue);
  });

  test('confirmation streak animation can be rebound after save', () {
    final source = File(
      'lib/screens/confirmation_screen.dart',
    ).readAsStringSync();

    expect(source, contains('late Animation<int> _streakCount;'));
    expect(source, isNot(contains('late final Animation<int> _streakCount;')));
    expect(
      source,
      contains('_streakCount = IntTween(begin: 0, end: actualStreak).animate('),
    );
  });
}
