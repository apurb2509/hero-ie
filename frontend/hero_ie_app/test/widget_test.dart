import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_ie_app/main.dart';

void main() {
  testWidgets('App starts smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const HeroIEApp());

    // Verify that HERO-IE text is present
    expect(find.text('HERO-IE'), findsOneWidget);
  });
}
