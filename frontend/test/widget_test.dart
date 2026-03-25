import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testapp/main.dart';

void main() {
  testWidgets('Login screen displays correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const LocalCommerceApp());

    // Verify that the login screen elements are present.
    expect(find.text('Login to your account'), findsOneWidget);
    expect(find.text('Select Role'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);

    // Verify the default login button text.
    expect(find.text('Login as Customer'), findsOneWidget);
  });
}
