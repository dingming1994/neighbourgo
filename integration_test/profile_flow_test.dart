/// Integration test: Profile View & Edit Flow
///
/// Verifies users can view and edit their profile, change role, and see
/// updates reflected in the UI and Firestore.
///
/// Run:
///   flutter test integration_test/profile_flow_test.dart -d <simulator_id>
///
/// Prerequisites:
///   1. Firebase emulators running: firebase emulators:start
///   2. iOS Simulator booted
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:neighbourgo/main.dart';

import 'test_helpers.dart';
import 'test_data.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late String userId;

  setUpAll(() async {
    await initializeTestApp();

    // Create and sign in a 'both' user with known profile data
    final user = await signInTestUser(
      email: 'profile-test@test.com',
      password: 'test1234',
    );
    userId = user.uid;
    await seedUser(userId, {
      ...testBothUser(uid: userId),
      'displayName': 'Test User',
      'headline': 'Tester',
      'bio': '',
      'neighbourhood': 'Ang Mo Kio',
    });
  });

  tearDownAll(() async {
    await signOutTestUser();
    await cleanupEmulatorData();
  });

  group('Profile View & Edit Flow', () {
    testWidgets('View profile, edit it, change role, verify updates',
        (tester) async {
      // ════════════════════════════════════════════════════════════════════
      // PART 1: Navigate to Profile tab and verify display
      // ════════════════════════════════════════════════════════════════════

      await tester.pumpWidget(const ProviderScope(child: NeighbourGoApp()));
      await tester.pump();

      // Wait for splash screen (2s delay + navigation)
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 200),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 15),
      );

      // Handle login/onboarding if needed
      if (find.text('Dev Login (Simulator)').evaluate().isNotEmpty) {
        await tester.tap(find.text('Dev Login (Simulator)'));
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle(
          const Duration(milliseconds: 200),
          EnginePhase.sendSemanticsUpdate,
          const Duration(seconds: 15),
        );

        // Role selection
        if (find.text('How will you use NeighbourGo?').evaluate().isNotEmpty) {
          await tester.tap(find.text('I do both'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Continue'));
          await tester.pump(const Duration(seconds: 1));
          await tester.pumpAndSettle(
            const Duration(milliseconds: 200),
            EnginePhase.sendSemanticsUpdate,
            const Duration(seconds: 15),
          );
        }

        // Profile setup
        if (find.text('Set Up Profile').evaluate().isNotEmpty) {
          final nameField =
              find.widgetWithText(TextFormField, 'e.g. Wei Ming');
          await tester.enterText(nameField, 'Test User');
          await tester.pump();

          final headlineField = find.widgetWithText(
              TextFormField, 'A brief intro about yourself');
          await tester.enterText(headlineField, 'Tester');
          await tester.pump();

          await tester.drag(
            find.byType(SingleChildScrollView),
            const Offset(0, -300),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.byType(DropdownButtonFormField<String>));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Ang Mo Kio').last);
          await tester.pumpAndSettle();

          await tester.drag(
            find.byType(SingleChildScrollView),
            const Offset(0, -200),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.text('Complete Setup'));
          await tester.pump(const Duration(seconds: 1));
          await tester.pumpAndSettle(
            const Duration(milliseconds: 200),
            EnginePhase.sendSemanticsUpdate,
            const Duration(seconds: 15),
          );
        }
      }

      // Verify we're on Home screen
      expect(find.text('Home'), findsOneWidget,
          reason: 'Should be on HomeScreen with bottom nav');

      // ── Navigate to Profile tab ────────────────────────────────────
      await tester.tap(find.text('Profile'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 200),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 15),
      );

      // Verify ProfileScreen shows 'Test User' as display name
      expect(find.text('Test User'), findsOneWidget,
          reason: 'ProfileScreen should show display name');

      // Verify current role shows 'Both'
      expect(find.text('Both'), findsOneWidget,
          reason: 'Role should show Both');

      // ════════════════════════════════════════════════════════════════════
      // PART 2: Edit Profile
      // ════════════════════════════════════════════════════════════════════

      // Tap 'Edit Profile' menu item
      await tester.tap(find.text('Edit Profile'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 200),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 15),
      );

      // Verify EditProfileScreen loads with pre-filled Display Name
      expect(find.text('Edit Profile'), findsOneWidget,
          reason: 'Should be on EditProfileScreen');

      // The Display Name field should be pre-filled with 'Test User'
      final nameField = find.widgetWithText(TextFormField, 'Your name');
      expect(nameField, findsOneWidget,
          reason: 'Display Name field should exist');

      // Clear headline and enter new value
      final headlineField = find.widgetWithText(
          TextFormField, 'e.g. Trusted cleaner in Ang Mo Kio');
      expect(headlineField, findsOneWidget,
          reason: 'Headline field should exist');
      await tester.enterText(headlineField, 'Senior Tester');
      await tester.pump();

      // Scroll down to find the About Me field
      await tester.drag(
        find.byType(ListView),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      // Enter bio in About Me field
      final bioField = find.widgetWithText(
          TextFormField, 'Tell clients about yourself\u2026');
      expect(bioField, findsOneWidget,
          reason: 'About Me field should exist');
      await tester.enterText(
          bioField, 'I am an experienced integration tester');
      await tester.pump();

      // Tap Save button
      await tester.tap(find.text('Save'));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 200),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 15),
      );

      // Verify success feedback (snackbar with 'Profile saved!')
      expect(find.text('Profile saved!'), findsOneWidget,
          reason: 'Should show success snackbar');

      // Verify navigation back to ProfileScreen
      // Wait for snackbar to dismiss and screen to settle
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 200),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 15),
      );

      // Verify Firestore user doc updated
      final firestore = FirebaseFirestore.instance;
      final userDoc =
          await firestore.collection('users').doc(userId).get();
      final userData = userDoc.data()!;
      expect(userData['headline'], 'Senior Tester',
          reason: 'Headline should be updated in Firestore');
      expect(userData['bio'], 'I am an experienced integration tester',
          reason: 'Bio should be updated in Firestore');

      // ════════════════════════════════════════════════════════════════════
      // PART 3: Change Role to Provider
      // ════════════════════════════════════════════════════════════════════

      // We should be back on ProfileScreen — verify
      expect(find.text('My Role'), findsOneWidget,
          reason: 'Should be on ProfileScreen showing My Role section');

      // Tap 'Change Role' button
      await tester.tap(find.text('Change Role'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 200),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 15),
      );

      // Verify role picker bottom sheet opens with 3 role options
      expect(find.text('Task Poster'), findsOneWidget,
          reason: 'Role picker should show Task Poster option');
      expect(find.text('Service Provider'), findsOneWidget,
          reason: 'Role picker should show Service Provider option');
      expect(find.text('Both \u2014 post & earn'), findsOneWidget,
          reason: 'Role picker should show Both option');

      // Tap 'Service Provider' role
      await tester.tap(find.text('Service Provider'));
      await tester.pumpAndSettle();

      // Tap Save
      await tester.tap(find.text('Save'));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 200),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 15),
      );

      // Verify 'Role updated!' snackbar
      expect(find.text('Role updated!'), findsOneWidget,
          reason: 'Should show role updated snackbar');

      // Verify role updates in Firestore user doc to 'provider'
      final updatedDoc =
          await firestore.collection('users').doc(userId).get();
      expect(updatedDoc.data()!['role'], 'provider',
          reason: 'Role should be provider in Firestore');

      // ════════════════════════════════════════════════════════════════════
      // PART 4: Verify Home tab shows ProviderHomeScreen
      // ════════════════════════════════════════════════════════════════════

      // Navigate to Home tab
      await tester.tap(find.text('Home'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 200),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 15),
      );

      // ProviderHomeScreen shows 'Find Work' header text (not as a tab)
      // When role=both, 'Find Help' and 'Find Work' are tabs.
      // When role=provider, only ProviderHomeScreen shows with 'Find Work' text.
      // The 'Find Help' tab should NOT be visible (no TabBar)
      expect(find.text('Find Work'), findsOneWidget,
          reason: 'ProviderHomeScreen should show Find Work');
      expect(find.text('Find Help'), findsNothing,
          reason:
              'Find Help tab should not be visible when role is provider');
    });
  });
}
