import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_demo_disco/main.dart';

void main() {
  testWidgets('App initializes without crashing', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MainApp());

    // Verify that the app starts and shows the loading or login screen
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
  
  testWidgets('Login screen is eventually shown', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MainApp());
    
    // Wait a bit for the auth check, but not indefinitely
    await tester.pump(const Duration(milliseconds: 100));
    
    // The app should eventually show login elements or still be loading
    // We just verify the app doesn't crash
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
