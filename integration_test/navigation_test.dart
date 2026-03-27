/// Integration test: Bottom Navigation & Screen Transitions
///
/// Verifies all 5 bottom nav tabs work correctly, navigation between screens
/// is smooth, and rapid tab switching doesn't cause issues.
///
/// Run:
///   flutter test integration_test/navigation_test.dart -d <simulator_id>
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
import 'test_data.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late String userId;

  setUpAll(() async {
    await initializeTestApp();

    // Create and sign in a 'both' user
    final user = await signInTestUser(
      email: 'nav-test@test.com',
      password: 'test1234',
    );
    userId = user.uid;
    await seedUser(userId, {
      ...testBothUser(uid: userId),
      'displayName': 'Nav Tester',
      'headline': 'Navigation tester',
      'neighbourhood': 'Ang Mo Kio',
    });

    // Seed one task so Discover has something to tap
    await seedTask('nav-task-1', testCleaningTask(
      taskId: 'nav-task-1',
      posterId: userId,
      posterName: 'Nav Tester',
    ));
  });

  tearDownAll(() async {
    await signOutTestUser();
    await cleanupEmulatorData();
  });

  group('Bottom Navigation & Screen Transitions', () {
    testWidgets('All tabs navigate correctly and transitions are smooth',
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
        if (find
            .text('How will you use NeighbourGo?')
            .evaluate()
            .isNotEmpty) {
          await tester.tap(find.text('Both — post & earn'));
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
          await tester.enterText(nameField, 'Nav Tester');
          await tester.pump();

          final headlineField = find.widgetWithText(
              TextFormField, 'A brief intro about yourself');
          await tester.enterText(headlineField, 'Navigation tester');
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

      // ════════════════════════════════════════════════════════════════════
      // PART 1: Verify bottom navigation bar has 5 items
      // ════════════════════════════════════════════════════════════════════

      expect(find.text('Home'), findsOneWidget,
          reason: 'Home tab should be visible');
      expect(find.text('Discover'), findsOneWidget,
          reason: 'Discover tab should be visible');
      expect(find.byIcon(Icons.add), findsOneWidget,
          reason: 'Post FAB button should be visible');
      expect(find.text('Messages'), findsOneWidget,
          reason: 'Messages tab should be visible');
      expect(find.text('Profile'), findsOneWidget,
          reason: 'Profile tab should be visible');

      // ════════════════════════════════════════════════════════════════════
      // PART 2: Home tab — verify TabBar for 'both' role
      // ════════════════════════════════════════════════════════════════════

      // Already on Home tab — verify TabBar with Find Help / Find Work
      expect(find.text('Find Help'), findsOneWidget,
          reason: 'Home should show Find Help tab for role=both');
      expect(find.text('Find Work'), findsOneWidget,
          reason: 'Home should show Find Work tab for role=both');

      // Tap 'Find Work' tab — verify ProviderHomeScreen content loads
      await tester.tap(find.text('Find Work'));
      await tester.pumpAndSettle();

      // ProviderHomeScreen should render (look for provider-specific content)
      expect(find.text('Find Work'), findsOneWidget,
          reason: 'Find Work tab should remain visible');

      // Tap 'Find Help' tab — verify PosterHomeScreen content loads
      await tester.tap(find.text('Find Help'));
      await tester.pumpAndSettle();

      expect(find.text('Find Help'), findsOneWidget,
          reason: 'Find Help tab should remain visible');

      // ════════════════════════════════════════════════════════════════════
      // PART 3: Discover tab
      // ════════════════════════════════════════════════════════════════════

      await tester.tap(find.text('Discover'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 200),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 15),
      );

      expect(find.text('Discover Tasks'), findsOneWidget,
          reason: 'Discover tab should show TaskListScreen with title');

      // ════════════════════════════════════════════════════════════════════
      // PART 4: Messages tab
      // ════════════════════════════════════════════════════════════════════

      await tester.tap(find.text('Messages'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 200),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 15),
      );

      expect(find.text('Messages'), findsWidgets,
          reason:
              'Messages tab should show ChatListScreen (title + tab label)');

      // ════════════════════════════════════════════════════════════════════
      // PART 5: Profile tab
      // ════════════════════════════════════════════════════════════════════

      await tester.tap(find.text('Profile'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 200),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 15),
      );

      expect(find.text('Nav Tester'), findsOneWidget,
          reason: 'Profile tab should show user display name');

      // ════════════════════════════════════════════════════════════════════
      // PART 6: Post Task FAB — opens full screen, close returns
      // ════════════════════════════════════════════════════════════════════

      // Go back to Home first to set a known state
      await tester.tap(find.text('Home'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 200),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 15),
      );

      // Tap Post Task FAB (the add icon in the center of bottom nav)
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 200),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 15),
      );

      // Verify PostTaskScreen opens (full screen, outside shell)
      expect(find.textContaining('Post a Task'), findsOneWidget,
          reason: 'PostTaskScreen should open with title');

      // Tap close button to return (on step 0 it shows X icon)
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 200),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 15),
      );

      // Verify returns to previous tab (Home)
      expect(find.text('Find Help'), findsOneWidget,
          reason: 'Should return to Home tab after closing PostTaskScreen');

      // ════════════════════════════════════════════════════════════════════
      // PART 7: Navigate to TaskDetailScreen via Discover → tap task card
      // ════════════════════════════════════════════════════════════════════

      await tester.tap(find.text('Discover'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 200),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 15),
      );

      expect(find.text('Discover Tasks'), findsOneWidget,
          reason: 'Should be on Discover tab');

      // Tap on the seeded task
      await tester.tap(find.text('Deep clean 3-room HDB'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 200),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 15),
      );

      // Verify TaskDetailScreen opens
      expect(find.textContaining('thorough cleaning'), findsOneWidget,
          reason: 'TaskDetailScreen should show task description');

      // Tap back to return to Discover
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 200),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 15),
      );

      expect(find.text('Discover Tasks'), findsOneWidget,
          reason: 'Should return to Discover list after back');

      // ════════════════════════════════════════════════════════════════════
      // PART 8: Navigate to EditProfileScreen via Profile → Edit Profile
      // ════════════════════════════════════════════════════════════════════

      await tester.tap(find.text('Profile'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 200),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 15),
      );

      expect(find.text('Nav Tester'), findsOneWidget,
          reason: 'Should be on ProfileScreen');

      await tester.tap(find.text('Edit Profile'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 200),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 15),
      );

      expect(find.text('Edit Profile'), findsOneWidget,
          reason: 'Should navigate to EditProfileScreen');

      // Tap back to return to ProfileScreen
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 200),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 15),
      );

      expect(find.text('Nav Tester'), findsOneWidget,
          reason: 'Should return to ProfileScreen after back');

      // ════════════════════════════════════════════════════════════════════
      // PART 9: Rapid tab switching — no stack overflow or duplicate routes
      // ════════════════════════════════════════════════════════════════════

      // Tap each tab 3 times quickly
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Home'));
        await tester.pump(const Duration(milliseconds: 100));

        await tester.tap(find.text('Discover'));
        await tester.pump(const Duration(milliseconds: 100));

        await tester.tap(find.text('Messages'));
        await tester.pump(const Duration(milliseconds: 100));

        await tester.tap(find.text('Profile'));
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Let everything settle — no crash should occur
      await tester.pumpAndSettle(
        const Duration(milliseconds: 200),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 15),
      );

      // Verify we're on the last tapped tab (Profile)
      expect(find.text('Nav Tester'), findsOneWidget,
          reason:
              'Should be on ProfileScreen after rapid switching without crash');

      // Navigate back to Home to confirm navigation still works
      await tester.tap(find.text('Home'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 200),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 15),
      );

      expect(find.text('Find Help'), findsOneWidget,
          reason: 'Home tab should work normally after rapid switching');
    });
  });
}
