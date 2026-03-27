/// Integration test: Post Task End-to-End (5-step flow)
///
/// Verifies the complete task posting flow: category selection -> description ->
/// location -> budget -> review & post, then confirms the task is saved to
/// Firestore and appears on the poster's home screen.
///
/// Run:
///   flutter test integration_test/post_task_test.dart -d <simulator_id>
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

  late String testUserId;

  setUpAll(() async {
    await initializeTestApp();

    // Sign in a test user and seed their Firestore user doc with role=poster
    final user = await signInTestUser(
      email: 'poster-task@test.com',
      password: 'test1234',
    );
    testUserId = user.uid;

    await seedUser(testUserId, testPosterUser(uid: testUserId));
  });

  tearDownAll(() async {
    await signOutTestUser();
    await cleanupEmulatorData();
  });

  group('Post Task Flow', () {
    testWidgets('Complete 5-step task posting and verify Firestore',
        (tester) async {
      // ── Launch app ──────────────────────────────────────────────────────
      await tester.pumpWidget(const ProviderScope(child: NeighbourGoApp()));
      await tester.pump();

      // Wait for splash screen (2s delay + navigation)
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 200),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 15),
      );

      // ── We should be on Home Screen (user is already logged in) ───────
      // If we land on Welcome, tap Dev Login to get to Home
      if (find.text('Dev Login (Simulator)').evaluate().isNotEmpty) {
        await tester.tap(find.text('Dev Login (Simulator)'));
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle(
          const Duration(milliseconds: 200),
          EnginePhase.sendSemanticsUpdate,
          const Duration(seconds: 15),
        );

        // If we hit role selection, tap through it
        if (find.text('How will you use NeighbourGo?').evaluate().isNotEmpty) {
          await tester.tap(find.text('I need help'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Continue'));
          await tester.pump(const Duration(seconds: 1));
          await tester.pumpAndSettle(
            const Duration(milliseconds: 200),
            EnginePhase.sendSemanticsUpdate,
            const Duration(seconds: 15),
          );
        }

        // If we hit profile setup, fill it out
        if (find.text('Set Up Profile').evaluate().isNotEmpty) {
          final nameField =
              find.widgetWithText(TextFormField, 'e.g. Wei Ming');
          await tester.enterText(nameField, 'Alice Tan');
          await tester.pump();

          final headlineField = find.widgetWithText(
              TextFormField, 'A brief intro about yourself');
          await tester.enterText(
              headlineField, 'Busy mum looking for help');
          await tester.pump();

          await tester.drag(
            find.byType(SingleChildScrollView),
            const Offset(0, -300),
          );
          await tester.pumpAndSettle();

          await tester
              .tap(find.byType(DropdownButtonFormField<String>));
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

      // ── Tap Post Task FAB in bottom nav ─────────────────────────────────
      // The Post button is the center icon (Icons.add) in the bottom nav
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 200),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 15),
      );

      // ── Step 1: Category Selection ──────────────────────────────────────
      expect(find.text('What do you need help with?'), findsOneWidget,
          reason: 'Should be on Step 1 - Category');
      expect(find.textContaining('1/5'), findsOneWidget,
          reason: 'Should show step 1/5 in app bar');

      // Verify 10 category cards are visible
      expect(find.text('Home Cleaning'), findsOneWidget);
      expect(find.text('Tutoring'), findsOneWidget);
      expect(find.text('Pet Care'), findsOneWidget);
      expect(find.text('Errands'), findsOneWidget);
      expect(find.text('Queue Standing'), findsOneWidget);
      expect(find.text('Handyman'), findsOneWidget);
      expect(find.text('Moving'), findsOneWidget);
      expect(find.text('Personal Care'), findsOneWidget);
      expect(find.text('Admin & Digital'), findsOneWidget);
      expect(find.text('Event Help'), findsOneWidget);

      // Tap 'Home Cleaning' category
      await tester.tap(find.text('Home Cleaning'));
      await tester.pumpAndSettle();

      // Tap Next
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // ── Step 2: Description ─────────────────────────────────────────────
      expect(find.text('Describe your task'), findsOneWidget,
          reason: 'Should be on Step 2 - Description');
      expect(find.textContaining('2/5'), findsOneWidget);

      // Enter title
      final titleField = find.widgetWithText(
          TextFormField, 'e.g. Clean my 3-room HDB flat');
      await tester.enterText(titleField, 'Deep clean 3-room HDB');
      await tester.pump();

      // Enter description (min 20 chars)
      final descField = find.widgetWithText(TextFormField,
          'Describe the task in detail \u2014 size of flat, special requirements, pets, etc.');
      await tester.enterText(descField,
          'Need thorough cleaning for my 3-room HDB flat including kitchen and bathrooms');
      await tester.pump();

      // Tap Next (skip photos - optional)
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // ── Step 3: Location ────────────────────────────────────────────────
      expect(find.text('Where is the task?'), findsOneWidget,
          reason: 'Should be on Step 3 - Location');
      expect(find.textContaining('3/5'), findsOneWidget);

      // Enter address
      final locationField = find.widgetWithText(
          TextFormField, 'Blk 123 Ang Mo Kio Ave 6 #05-45');
      await tester.enterText(locationField, 'Ang Mo Kio Ave 3');
      await tester.pump();

      // Select neighbourhood from dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ang Mo Kio').last);
      await tester.pumpAndSettle();

      // Tap Next
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // ── Step 4: Budget ──────────────────────────────────────────────────
      expect(find.text("What's your budget?"), findsOneWidget,
          reason: 'Should be on Step 4 - Budget');
      expect(find.textContaining('4/5'), findsOneWidget);

      // Clear default value and enter '50' in min budget field
      final minBudgetField =
          find.widgetWithText(TextFormField, 'S\$ ').first;
      await tester.enterText(minBudgetField, '50');
      await tester.pump();

      // Tap Next
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // ── Step 5: Review & Post ───────────────────────────────────────────
      expect(find.text('Review & Post'), findsOneWidget,
          reason: 'Should be on Step 5 - Review');
      expect(find.textContaining('5/5'), findsOneWidget);

      // Verify all entered data is displayed
      expect(find.textContaining('Home Cleaning'), findsOneWidget,
          reason: 'Review should show selected category');
      expect(find.text('Deep clean 3-room HDB'), findsOneWidget,
          reason: 'Review should show task title');
      expect(find.text('Ang Mo Kio Ave 3'), findsOneWidget,
          reason: 'Review should show location');
      expect(find.textContaining('S\$50'), findsOneWidget,
          reason: 'Review should show budget');

      // Verify urgency defaults to Flexible
      expect(find.textContaining('Flexible'), findsOneWidget,
          reason: 'Urgency should default to Flexible');

      // Tap 'Post Task' button
      await tester.tap(find.text('Post Task'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 200),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 15),
      );

      // ── Verify success feedback ─────────────────────────────────────────
      // The app shows a snackbar and navigates to TaskDetailScreen
      // The snackbar may have disappeared by now, but we should be on task detail
      // Verify we're on TaskDetailScreen by checking the task title in AppBar
      expect(find.text('Deep clean 3-room HDB'), findsWidgets,
          reason: 'Should navigate to TaskDetailScreen showing the task title');

      // ── Verify task in Firestore ────────────────────────────────────────
      final firestore = FirebaseFirestore.instance;
      final tasksSnap = await firestore
          .collection('tasks')
          .where('posterId', isEqualTo: testUserId)
          .where('title', isEqualTo: 'Deep clean 3-room HDB')
          .get();

      expect(tasksSnap.docs.length, 1,
          reason: 'Task document should exist in Firestore');

      final taskDoc = tasksSnap.docs.first.data();
      expect(taskDoc['categoryId'], 'cleaning');
      expect(taskDoc['budgetMin'], 50.0);
      expect(taskDoc['status'], 'open');
      expect(taskDoc['posterId'], testUserId);
      expect(taskDoc['locationLabel'], 'Ang Mo Kio Ave 3');
      expect(taskDoc['neighbourhood'], 'Ang Mo Kio');
      expect(taskDoc['urgency'], 'flexible');

      // ── Navigate back to Home and verify task in Active Tasks ──────────
      // Tap Home in bottom nav — use the navigator since we're on TaskDetailScreen
      // which was pushed via context.go('/tasks/$id'), so the shell is still there
      final backButton = find.byIcon(Icons.arrow_back);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle(
          const Duration(milliseconds: 200),
          EnginePhase.sendSemanticsUpdate,
          const Duration(seconds: 15),
        );
      }

      // Tap Home tab
      await tester.tap(find.text('Home'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 200),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 15),
      );

      // Verify active tasks section shows the new task
      expect(find.text('Active Tasks'), findsOneWidget,
          reason: 'PosterHomeScreen should show Active Tasks section');
      expect(find.text('Deep clean 3-room HDB'), findsOneWidget,
          reason: 'New task should appear in Active Tasks list');
    });
  });
}
