// Smoke test updated for the deepThink app.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deep_think/main.dart';

void main() {
  testWidgets('DeepThinkApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const DeepThinkApp());
    // Loading spinner should be visible before hardware detection resolves.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
