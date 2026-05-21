import 'package:flutter/material.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('GymSync app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const GymSyncApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
