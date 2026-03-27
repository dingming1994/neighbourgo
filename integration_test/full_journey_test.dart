/// Integration test: Full User Journey (Post → Bid → Assign → Complete)
///
/// End-to-end master test that chains the entire task lifecycle:
///   1. Poster posts a Cleaning task
///   2. Provider discovers the task and submits a bid
///   3. Poster accepts the bid (task → assigned)
///   4. Poster sends a chat message
///   5. Poster marks the task as complete
///   6. Final state verification in Firestore
///
/// Run:
///   flutter test integration_test/full_journey_test.dart -d <simulator_id>
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

  late String posterUserId;
  late String providerUserId;
  final firestore = FirebaseFirestore.instance;

  setUpAll(() async {
    await initializeTestApp();

    // Create poster user
    final posterUser = await signInTestUser(
      email: 'poster-journey@test.com',
      password: 'test1234',
    );
    posterUserId = posterUser.uid;
    await seedUser(posterUserId, testPosterUser(uid: posterUserId));

    // Sign out poster so we can create the provider user
    await signOutTestUser();

    // Create provider user
    final providerUser = await signInTestUser(
      email: 'provider-journey@test.com',
      password: 'test1234',
    );
    providerUserId = providerUser.uid;
    await seedUser(providerUserId, testProviderUser(uid: providerUserId));

    // Sign out provider; test starts by signing in as poster
    await signOutTestUser();
  });

  tearDownAll(() async {
    await signOutTestUser();
    await cleanupEmulatorData();
  });

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Launch the app widget, wait through splash, handle login/onboarding.
  Future<void> launchAndLogin(
    WidgetTester tester, {
    required String displayName,
    required String headline,
    required String neighbourhood,
    required String roleLabel,
  }) async {
    await tester.pumpWidget(const ProviderScope(child: NeighbourGoApp()));
    await tester.pump();

    // Splash screen (2s delay + navigation)
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
        await tester.tap(find.text(roleLabel));
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
        await tester.enterText(nameField, displayName);
        await tester.pump();

        final headlineField = find.widgetWithText(
            TextFormField, 'A brief intro about yourself');
        await tester.enterText(headlineField, headline);
        await tester.pump();

        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -300),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(DropdownButtonFormField<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text(neighbourhood).last);
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
  }

  /// Standard pump-and-settle with generous timeout.
  Future<void> settle(WidgetTester tester, {int seconds = 1}) async {
    await tester.pump(Duration(seconds: seconds));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 200),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 15),
    );
  }

  group('Full User Journey', () {
    testWidgets('Post → Bid → Assign → Chat → Complete', (tester) async {
      // ══════════════════════════════════════════════════════════════════════
      // STEP 1: Poster posts a task
      // ══════════════════════════════════════════════════════════════════════

      await signInTestUser(
        email: 'poster-journey@test.com',
        password: 'test1234',
      );

      await launchAndLogin(
        tester,
        displayName: 'Alice Tan',
        headline: 'Busy mum',
        neighbourhood: 'Ang Mo Kio',
        roleLabel: 'I need help',
      );

      // Verify Home screen
      expect(find.text('Home'), findsOneWidget,
          reason: 'Poster should be on HomeScreen');

      // Tap Post Task FAB
      await tester.tap(find.byIcon(Icons.add));
      await settle(tester);

      // Step 1: Category
      expect(find.text('What do you need help with?'), findsOneWidget);
      await tester.tap(find.text('Home Cleaning'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Step 2: Description
      expect(find.text('Describe your task'), findsOneWidget);
      final titleField = find.widgetWithText(
          TextFormField, 'e.g. Clean my 3-room HDB flat');
      await tester.enterText(titleField, 'Clean my flat');
      await tester.pump();

      final descField = find.widgetWithText(TextFormField,
          'Describe the task in detail \u2014 size of flat, special requirements, pets, etc.');
      await tester.enterText(descField,
          'Need thorough cleaning for my 3-room flat including all rooms');
      await tester.pump();

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Step 3: Location
      expect(find.text('Where is the task?'), findsOneWidget);
      final locationField = find.widgetWithText(
          TextFormField, 'Blk 123 Ang Mo Kio Ave 6 #05-45');
      await tester.enterText(locationField, 'Bedok North Ave 1');
      await tester.pump();

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bedok').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Step 4: Budget
      expect(find.text("What's your budget?"), findsOneWidget);
      final minBudgetField =
          find.widgetWithText(TextFormField, 'S\$ ').first;
      await tester.enterText(minBudgetField, '60');
      await tester.pump();

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Step 5: Review & Post
      expect(find.text('Review & Post'), findsOneWidget);
      expect(find.text('Clean my flat'), findsOneWidget);
      expect(find.textContaining('S\$60'), findsOneWidget);

      await tester.tap(find.text('Post Task'));
      await settle(tester);

      // Verify task in Firestore
      final tasksSnap = await firestore
          .collection('tasks')
          .where('posterId', isEqualTo: posterUserId)
          .where('title', isEqualTo: 'Clean my flat')
          .get();

      expect(tasksSnap.docs.length, 1,
          reason: 'Task should exist in Firestore');

      final taskId = tasksSnap.docs.first.id;
      final taskData = tasksSnap.docs.first.data();
      expect(taskData['status'], 'open');
      expect(taskData['categoryId'], 'cleaning');
      expect(taskData['budgetMin'], 60.0);
      expect(taskData['neighbourhood'], 'Bedok');

      // ══════════════════════════════════════════════════════════════════════
      // STEP 2: Provider discovers task and submits a bid
      // ══════════════════════════════════════════════════════════════════════

      await signOutTestUser();
      await signInTestUser(
        email: 'provider-journey@test.com',
        password: 'test1234',
      );

      await launchAndLogin(
        tester,
        displayName: 'Ben Lim',
        headline: 'Experienced cleaner',
        neighbourhood: 'Bedok',
        roleLabel: 'I can help',
      );

      expect(find.text('Home'), findsOneWidget,
          reason: 'Provider should be on HomeScreen');

      // Navigate to Discover tab
      await tester.tap(find.text('Discover'));
      await settle(tester);

      expect(find.text('Discover Tasks'), findsOneWidget);

      // Find the posted task
      if (find.text('Clean my flat').evaluate().isEmpty) {
        await tester.drag(
          find.byType(ListView),
          const Offset(0, -400),
        );
        await tester.pumpAndSettle();
      }

      expect(find.text('Clean my flat'), findsOneWidget,
          reason: 'Posted task should appear in Discover');

      await tester.tap(find.text('Clean my flat'));
      await settle(tester);

      // Verify provider sees Submit Bid
      expect(find.text('Submit Bid'), findsOneWidget);

      // Open bid sheet
      await tester.tap(find.text('Submit Bid'));
      await settle(tester);

      // Fill bid
      final amountField = find.widgetWithText(TextFormField, '0.00');
      await tester.enterText(amountField, '70');
      await tester.pump();

      final proposalField = find.widgetWithText(
        TextFormField,
        'Introduce yourself and explain why you\'re a great fit\u2026',
      );
      await tester.enterText(
        proposalField,
        'I have 5 years experience in cleaning HDB flats.',
      );
      await tester.pump();

      // Submit bid
      final submitButtons = find.text('Submit Bid');
      await tester.tap(submitButtons.last);
      await settle(tester, seconds: 2);

      // Verify bid in Firestore
      final bidsSnap = await firestore
          .collection('tasks')
          .doc(taskId)
          .collection('bids')
          .where('providerId', isEqualTo: providerUserId)
          .get();

      expect(bidsSnap.docs.length, 1,
          reason: 'Bid should exist in Firestore');

      final bidData = bidsSnap.docs.first.data();
      expect(bidData['amount'], 70.0);
      expect(bidData['status'], 'pending');

      // ══════════════════════════════════════════════════════════════════════
      // STEP 3: Poster accepts the bid
      // ══════════════════════════════════════════════════════════════════════

      await signOutTestUser();
      await signInTestUser(
        email: 'poster-journey@test.com',
        password: 'test1234',
      );

      await launchAndLogin(
        tester,
        displayName: 'Alice Tan',
        headline: 'Busy mum',
        neighbourhood: 'Ang Mo Kio',
        roleLabel: 'I need help',
      );

      expect(find.text('Home'), findsOneWidget);

      // Navigate to Discover to find the task
      await tester.tap(find.text('Discover'));
      await settle(tester);

      if (find.text('Clean my flat').evaluate().isEmpty) {
        await tester.drag(
          find.byType(ListView),
          const Offset(0, -400),
        );
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('Clean my flat'));
      await settle(tester);

      // Scroll to see bid section
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -400),
      );
      await settle(tester);

      // Verify bid is visible
      expect(find.text('Bids received (1)'), findsOneWidget,
          reason: 'Should show 1 bid');
      expect(find.textContaining('S\$70'), findsOneWidget,
          reason: 'Bid amount should show S\$70');

      // Accept the bid
      await tester.tap(find.text('Accept'));
      await settle(tester, seconds: 2);

      // Verify Firestore: task assigned, bid accepted
      final assignedTask =
          await firestore.collection('tasks').doc(taskId).get();
      expect(assignedTask.data()!['status'], 'assigned',
          reason: 'Task status should be assigned');
      expect(assignedTask.data()!['assignedProviderId'], providerUserId,
          reason: 'assignedProviderId should match provider');

      final acceptedBids = await firestore
          .collection('tasks')
          .doc(taskId)
          .collection('bids')
          .where('status', isEqualTo: 'accepted')
          .get();
      expect(acceptedBids.docs.length, 1,
          reason: 'One bid should be accepted');

      // ══════════════════════════════════════════════════════════════════════
      // STEP 4: Poster sends a chat message
      // ══════════════════════════════════════════════════════════════════════

      // Navigate to Messages tab
      await tester.tap(find.text('Messages'));
      await settle(tester);

      // Find the chat for this task
      expect(find.text('Clean my flat'), findsOneWidget,
          reason: 'Chat with task title should appear in Messages');

      await tester.tap(find.text('Clean my flat'));
      await settle(tester);

      // Send a message
      final messageInput = find.byType(TextField);
      await tester.enterText(messageInput, 'When can you come?');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.send_rounded));
      await settle(tester, seconds: 2);

      // Verify message appears in chat
      expect(find.text('When can you come?'), findsOneWidget,
          reason: 'Sent message should appear in chat');

      // Verify message in Firestore
      final sortedUids = [posterUserId, providerUserId]..sort();
      final chatId = '${taskId}_${sortedUids.join('_')}';

      final messagesSnap = await firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();

      expect(messagesSnap.docs.length, greaterThanOrEqualTo(1),
          reason: 'At least one message should exist in Firestore');

      final chatDoc =
          await firestore.collection('chats').doc(chatId).get();
      expect(chatDoc.data()!['lastMessage'], 'When can you come?',
          reason: 'Chat lastMessage should be updated');

      // ══════════════════════════════════════════════════════════════════════
      // STEP 5: Poster marks task as complete
      // ══════════════════════════════════════════════════════════════════════

      // Navigate back to the task detail
      await tester.tap(find.byType(BackButton));
      await settle(tester);

      // Go to Discover to find the task
      await tester.tap(find.text('Discover'));
      await settle(tester);

      if (find.text('Clean my flat').evaluate().isEmpty) {
        await tester.drag(
          find.byType(ListView),
          const Offset(0, -400),
        );
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('Clean my flat'));
      await settle(tester);

      // Scroll to find Mark as Complete button
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -300),
      );
      await settle(tester);

      // Tap Mark as Complete
      expect(find.text('Mark as Complete'), findsOneWidget,
          reason: 'Poster should see Mark as Complete on assigned task');
      await tester.tap(find.text('Mark as Complete'));
      await tester.pumpAndSettle();

      // Confirm in dialog
      expect(find.text('Mark as Complete?'), findsOneWidget,
          reason: 'Confirmation dialog should appear');
      await tester.tap(find.text('Confirm'));
      await settle(tester, seconds: 2);

      // Verify success snackbar
      expect(find.text('Task marked as complete!'), findsOneWidget,
          reason: 'Success snackbar should appear');

      // Verify Firestore: task completed with timestamp
      final completedTask =
          await firestore.collection('tasks').doc(taskId).get();
      final completedData = completedTask.data()!;
      expect(completedData['status'], 'completed',
          reason: 'Task status should be completed');
      expect(completedData['completedAt'], isNotNull,
          reason: 'completedAt timestamp should be set');

      // ══════════════════════════════════════════════════════════════════════
      // STEP 6: Final state verification
      // ══════════════════════════════════════════════════════════════════════

      // Navigate to Home and verify the completed task is NOT in Active Tasks
      await tester.tap(find.text('Home'));
      await settle(tester);

      // The task should not appear in Active Tasks (it's completed)
      // Active Tasks only shows open/assigned/inProgress tasks
      if (find.text('Active Tasks').evaluate().isNotEmpty) {
        expect(find.text('Clean my flat'), findsNothing,
            reason:
                'Completed task should not appear in Active Tasks');
      }

      // Final Firestore consistency checks
      // Task document
      final finalTask =
          await firestore.collection('tasks').doc(taskId).get();
      final ft = finalTask.data()!;
      expect(ft['status'], 'completed');
      expect(ft['posterId'], posterUserId);
      expect(ft['assignedProviderId'], providerUserId);
      expect(ft['completedAt'], isNotNull);

      // Bid document
      final finalBids = await firestore
          .collection('tasks')
          .doc(taskId)
          .collection('bids')
          .get();
      expect(finalBids.docs.length, 1);
      expect(finalBids.docs.first.data()['status'], 'accepted');

      // Chat document
      final finalChat =
          await firestore.collection('chats').doc(chatId).get();
      expect(finalChat.exists, isTrue,
          reason: 'Chat document should still exist');
      expect(finalChat.data()!['lastMessage'], 'When can you come?');
    });
  });
}
