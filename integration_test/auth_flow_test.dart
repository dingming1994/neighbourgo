/// Integration test: Dev Login & Onboarding Flow
///
/// Verifies the complete flow: splash -> welcome -> dev login -> role selection
/// -> profile setup -> home screen.
///
/// Run:
///   flutter test integration_test/auth_flow_test.dart -d <simulator_id>
///
/// Prerequisites:
///   1. Firebase emulators running: firebase emulators:start
///   2. iOS Simulator booted
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:neighbourgo/main.dart';

import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeTestApp();
  });

  tearDownAll(() async {
    await signOutTestUser();
    await cleanupEmulatorData();
  });

  group('Auth & Onboarding Flow', () {
    testWidgets('Dev login through full onboarding to home screen',
        (tester) async {
      // ── Launch app ──────────────────────────────────────────────────────
      await tester.pumpWidget(const ProviderScope(child: NeighbourGoApp()));
      await tester.pump();

      // ── Splash Screen ──────────────────────────────────────────────────
      // Verify splash content
      expect(find.text('NeighbourGo'), findsOneWidget);
      expect(find.text('Your neighbourhood, connected'), findsOneWidget);

      // Wait for splash 2-second delay + navigation
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // ── Welcome Screen ─────────────────────────────────────────────────
      expect(find.text('Get Started with Phone'), findsOneWidget);
      expect(find.text('Dev Login (Simulator)'), findsOneWidget);

      // Tap Dev Login
      await tester.tap(find.text('Dev Login (Simulator)'));

      // Wait for anonymous auth + Firestore write + navigation
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 200),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 15),
      );

      // ── Role Selection Screen ──────────────────────────────────────────
      expect(
        find.text('How will you use NeighbourGo?'),
        findsOneWidget,
        reason: 'Should navigate to RoleSelectionScreen after dev login',
      );

      // Verify 3 role cards visible
      expect(find.text('I need help'), findsOneWidget);
      expect(find.text('I want to earn'), findsOneWidget);
      expect(find.text('Both — post & earn'), findsOneWidget);

      // Tap 'Both' role card
      await tester.tap(find.text('Both — post & earn'));
      await tester.pumpAndSettle();

      // Verify selection indicator (check_circle icon)
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      // Tap 'Continue'
      await tester.tap(find.text('Continue'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 200),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 15),
      );

      // ── Profile Setup Screen ───────────────────────────────────────────
      expect(
        find.text('Set Up Profile'),
        findsOneWidget,
        reason: 'Should navigate to ProfileSetupScreen after role selection',
      );

      // Verify Display Name field exists
      expect(find.text('Display Name'), findsOneWidget);

      // Enter Display Name (first TextFormField)
      final nameField = find.widgetWithText(TextFormField, 'e.g. Wei Ming');
      await tester.enterText(nameField, 'Test User');
      await tester.pump();

      // Enter Headline (second TextFormField)
      final headlineField =
          find.widgetWithText(TextFormField, 'A brief intro about yourself');
      await tester.enterText(headlineField, 'Integration tester');
      await tester.pump();

      // Scroll down to reveal neighbourhood dropdown and submit button
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();

      // Select neighbourhood from dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // Tap 'Ang Mo Kio' from the dropdown overlay
      // Use .last because the text appears both in the dropdown trigger and overlay
      await tester.tap(find.text('Ang Mo Kio').last);
      await tester.pumpAndSettle();

      // Scroll down to reveal Complete Setup button
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      // Tap 'Complete Setup'
      await tester.tap(find.text('Complete Setup'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 200),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 15),
      );

      // ── Home Screen ────────────────────────────────────────────────────
      // Verify bottom navigation bar with 5 items
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Discover'), findsOneWidget);
      expect(find.text('Messages'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget); // Post FAB

      // For 'both' role, verify TabBar with Find Help / Find Work
      expect(find.text('Find Help'), findsOneWidget);
      expect(find.text('Find Work'), findsOneWidget);

      // Verify greeting shows the user's first name ('Test' from 'Test User')
      expect(find.textContaining('Test'), findsWidgets);
    });
  });
}
