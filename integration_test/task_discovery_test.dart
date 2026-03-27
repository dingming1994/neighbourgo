/// Integration test: Task Discovery & Filtering
///
/// Verifies the Discover tab shows tasks correctly, category filtering works,
/// each task card displays the expected fields, and tapping a card opens the
/// TaskDetailScreen.
///
/// Run:
///   flutter test integration_test/task_discovery_test.dart -d <simulator_id>
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

    // Sign in a test user and seed their Firestore user doc with role=both
    final user = await signInTestUser(
      email: 'discover-test@test.com',
      password: 'test1234',
    );
    testUserId = user.uid;

    await seedUser(testUserId, testBothUser(uid: testUserId));

    // Seed 5 tasks across 3 categories: 2 cleaning, 2 tutoring, 1 pet_care
    await seedTask(
      'discover-clean-1',
      testCleaningTask(
        taskId: 'discover-clean-1',
        posterId: testUserId,
        posterName: 'Charlie Wong',
      ),
    );
    await seedTask('discover-clean-2', {
      ...testCleaningTask(
        taskId: 'discover-clean-2',
        posterId: testUserId,
        posterName: 'Charlie Wong',
      ),
      'title': 'Weekly home cleaning',
      'description':
          'Need a reliable cleaner for weekly home cleaning, 3-room HDB in Tampines.',
      'locationLabel': 'Blk 201 Tampines St 21',
      'neighbourhood': 'Tampines',
      'budgetMin': 40.0,
      'budgetMax': 60.0,
    });

    await seedTask(
      'discover-tutor-1',
      testTutoringTask(
        taskId: 'discover-tutor-1',
        posterId: testUserId,
        posterName: 'Charlie Wong',
      ),
    );
    await seedTask('discover-tutor-2', {
      ...testTutoringTask(
        taskId: 'discover-tutor-2',
        posterId: testUserId,
        posterName: 'Charlie Wong',
      ),
      'title': 'Secondary 3 Science tutor',
      'description':
          'Looking for a tutor to help my child with Physics and Chemistry for O-Levels.',
      'budgetMin': 45.0,
      'budgetMax': 70.0,
    });

    await seedTask('discover-pet-1', {
      'id': 'discover-pet-1',
      'posterId': testUserId,
      'posterName': 'Charlie Wong',
      'title': 'Dog walking in Bishan',
      'description':
          'Need someone to walk my golden retriever twice a day in Bishan Park area.',
      'categoryId': 'pet_care',
      'photoUrls': <String>[],
      'tags': ['#DogWalking', '#Bishan'],
      'locationLabel': 'Bishan Park',
      'neighbourhood': 'Bishan',
      'budgetMin': 20.0,
      'budgetMax': 30.0,
      'currency': 'SGD',
      'urgency': 'flexible',
      'status': 'open',
      'bidCount': 0,
      'viewCount': 0,
      'isPaid': false,
      'isEscrowReleased': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  });

  tearDownAll(() async {
    await signOutTestUser();
    await cleanupEmulatorData();
  });

  group('Task Discovery & Filtering', () {
    testWidgets('Discover tab shows tasks, filters work, and detail opens',
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

      // ── Handle login/onboarding if needed ──────────────────────────────
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
          await tester.tap(find.text('Both'));
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
          await tester.enterText(nameField, 'Charlie Wong');
          await tester.pump();

          final headlineField = find.widgetWithText(
              TextFormField, 'A brief intro about yourself');
          await tester.enterText(headlineField, 'Community helper');
          await tester.pump();

          await tester.drag(
            find.byType(SingleChildScrollView),
            const Offset(0, -300),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.byType(DropdownButtonFormField<String>));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Tampines').last);
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

      // ── Tap Discover tab in bottom nav ─────────────────────────────────
      await tester.tap(find.text('Discover'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 200),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 15),
      );

      // ── Verify TaskListScreen AppBar ───────────────────────────────────
      expect(find.text('Discover Tasks'), findsOneWidget,
          reason: 'AppBar should show "Discover Tasks"');

      // ── Verify all 5 tasks are visible (scroll if needed) ─────────────
      // Task titles from seeded data
      final taskTitles = [
        'Deep clean 3-room HDB',
        'Weekly home cleaning',
        'Primary 5 Maths tutor needed',
        'Secondary 3 Science tutor',
        'Dog walking in Bishan',
      ];

      // Some tasks may be off-screen; scroll to find them
      for (final title in taskTitles) {
        if (find.text(title).evaluate().isEmpty) {
          // Scroll down to find the task
          await tester.drag(
            find.byType(ListView),
            const Offset(0, -400),
          );
          await tester.pumpAndSettle();
        }
        expect(find.text(title), findsOneWidget,
            reason: 'Task "$title" should be visible in Discover list');
      }

      // ── Verify task card fields ────────────────────────────────────────
      // Each card shows: category badge, budget, time info
      // Check that category badges are present
      expect(find.textContaining('Home Cleaning'), findsWidgets,
          reason: 'Cleaning category badges should be visible');
      expect(find.textContaining('Be the first to bid'), findsWidgets,
          reason: 'Bid status should show for tasks with 0 bids');

      // ── Scroll back to top before filtering ────────────────────────────
      await tester.drag(
        find.byType(ListView),
        const Offset(0, 800),
      );
      await tester.pumpAndSettle();

      // ── Tap 'Home Cleaning' filter chip ────────────────────────────────
      // The filter chips show "emoji label" — find by label text
      final cleaningChipFinder = find.text('Home Cleaning');
      // There may be multiple (chip + category badges on cards) — tap the first (chip)
      await tester.tap(cleaningChipFinder.first);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 200),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 15),
      );

      // Verify only 2 cleaning tasks are shown
      expect(find.text('Deep clean 3-room HDB'), findsOneWidget,
          reason: 'Cleaning task 1 should be visible');
      expect(find.text('Weekly home cleaning'), findsOneWidget,
          reason: 'Cleaning task 2 should be visible');
      // Tutoring and pet care tasks should NOT be visible
      expect(find.text('Primary 5 Maths tutor needed'), findsNothing,
          reason: 'Tutoring tasks should be filtered out');
      expect(find.text('Dog walking in Bishan'), findsNothing,
          reason: 'Pet care tasks should be filtered out');

      // ── Tap 'Tutoring' filter chip ─────────────────────────────────────
      await tester.tap(find.text('Tutoring').first);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 200),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 15),
      );

      // Verify only 2 tutoring tasks are shown
      expect(find.text('Primary 5 Maths tutor needed'), findsOneWidget,
          reason: 'Tutoring task 1 should be visible');
      expect(find.text('Secondary 3 Science tutor'), findsOneWidget,
          reason: 'Tutoring task 2 should be visible');
      // Cleaning and pet care tasks should NOT be visible
      expect(find.text('Deep clean 3-room HDB'), findsNothing,
          reason: 'Cleaning tasks should be filtered out');
      expect(find.text('Dog walking in Bishan'), findsNothing,
          reason: 'Pet care tasks should be filtered out');

      // ── Tap 'All' chip to clear filter ─────────────────────────────────
      await tester.tap(find.text('All'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 200),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 15),
      );

      // Verify all 5 tasks are shown again (scroll if needed)
      for (final title in taskTitles) {
        if (find.text(title).evaluate().isEmpty) {
          await tester.drag(
            find.byType(ListView),
            const Offset(0, -400),
          );
          await tester.pumpAndSettle();
        }
        expect(find.text(title), findsOneWidget,
            reason: 'Task "$title" should be visible after clearing filter');
      }

      // ── Scroll back to top before tapping ──────────────────────────────
      await tester.drag(
        find.byType(ListView),
        const Offset(0, 800),
      );
      await tester.pumpAndSettle();

      // ── Tap on first task card ─────────────────────────────────────────
      // Find the first visible task title and tap it
      final firstTaskTitle = find.text('Deep clean 3-room HDB');
      if (firstTaskTitle.evaluate().isEmpty) {
        // If not visible, the first task in the list is whatever is on screen
        await tester.tap(find.text(taskTitles.firstWhere(
          (t) => find.text(t).evaluate().isNotEmpty,
        )));
      } else {
        await tester.tap(firstTaskTitle);
      }
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 200),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 15),
      );

      // ── Verify TaskDetailScreen opens ──────────────────────────────────
      // The task detail AppBar shows the task title
      expect(find.text('Deep clean 3-room HDB'), findsWidgets,
          reason: 'TaskDetailScreen should show the task title');
      // Verify we're on detail screen by checking for description text
      expect(
        find.textContaining('thorough cleaning'),
        findsOneWidget,
        reason: 'TaskDetailScreen should show task description',
      );

      // ── Tap back to return to Discover ─────────────────────────────────
      final backButton = find.byIcon(Icons.arrow_back);
      expect(backButton, findsOneWidget,
          reason: 'Back button should be visible on TaskDetailScreen');
      await tester.tap(backButton);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 200),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 15),
      );

      // Verify we're back on Discover
      expect(find.text('Discover Tasks'), findsOneWidget,
          reason: 'Should return to Discover Tasks screen');
    });
  });
}
