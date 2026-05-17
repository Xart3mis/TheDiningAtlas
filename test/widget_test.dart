// Basic smoke test for The Dining Atlas app.

import 'package:flutter_test/flutter_test.dart';

import 'package:dining_atlas/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DiningAtlasApp());

    // Verify the app renders the main shell with bottom navigation.
    expect(find.text('Atlas'), findsOneWidget);
  });
}
