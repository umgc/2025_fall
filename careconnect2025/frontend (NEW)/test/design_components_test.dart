import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:care_connect_app/widgets/careconnect_button.dart';
import 'package:care_connect_app/widgets/careconnect_card.dart';
import 'package:care_connect_app/widgets/careconnect_input.dart';
import 'package:care_connect_app/widgets/careconnect_logo.dart';
import 'package:care_connect_app/config/theme/careconnect_theme.dart';

void main() {
  group('Design Components Tests', () {
    testWidgets('CareConnectButton renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: CareConnectTheme.lightTheme,
          home: Scaffold(
            body: CareConnectButton(
              text: 'Test Button',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Test Button'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('CareConnectCard renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: CareConnectTheme.lightTheme,
          home: Scaffold(
            body: CareConnectCard(
              child: Text('Test Card Content'),
            ),
          ),
        ),
      );

      expect(find.text('Test Card Content'), findsOneWidget);
      expect(find.byType(Container), findsOneWidget);
    });

    testWidgets('CareConnectInput renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: CareConnectTheme.lightTheme,
          home: Scaffold(
            body: CareConnectInput(
              label: 'Test Input',
              hint: 'Enter text',
            ),
          ),
        ),
      );

      expect(find.text('Test Input'), findsOneWidget);
      expect(find.text('Enter text'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('CareConnectLogo renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: CareConnectTheme.lightTheme,
          home: Scaffold(
            body: CareConnectLogo(
              width: 100,
              height: 50,
            ),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('Theme switching works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: CareConnectTheme.lightTheme,
          darkTheme: CareConnectTheme.darkTheme,
          themeMode: ThemeMode.light,
          home: Scaffold(
            body: CareConnectButton(
              text: 'Theme Test',
              onPressed: () {},
            ),
          ),
        ),
      );

      // Test light theme
      expect(find.text('Theme Test'), findsOneWidget);
      
      // Switch to dark theme
      await tester.pumpWidget(
        MaterialApp(
          theme: CareConnectTheme.lightTheme,
          darkTheme: CareConnectTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: Scaffold(
            body: CareConnectButton(
              text: 'Theme Test',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Theme Test'), findsOneWidget);
    });
  });
}
