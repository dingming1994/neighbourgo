/// Integration test: Flow 1 — Task-Based Bidding End-to-End
///
/// Complete marketplace Flow 1:
///   1. Alice registers, posts a Cleaning task (S$60, Ang Mo Kio)
///   2. Ben registers as provider, discovers task, submits bid (S$55)
///   3. Alice views task detail, sees bid, messages Ben via bid card
///   4. Alice accepts Ben's bid → task status = assigned
///   5. Ben opens task detail, taps 'Start Work' → status = inProgress
///   6. Alice marks task as complete → status = completed
///   7. Alice leaves review for Ben (4 stars)
///   8. Ben leaves review for Alice (5 stars)
///   9. Verify reviews exist in Firestore
///
/// Run:
///   flutter test integration_test/flow1_task_bidding_test.dart -d <simulator_id>
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

  late String aliceId;
  late String benId;
  final firestore = FirebaseFirestore.instance;

  setUpAll(() async {
    await initializeTestApp();

    // Create Alice (poster)
    final alice = await signInTestUser(
      email: 'alice-flow1@test.com',
      password: 'test1234',
    );
    aliceId = alice.uid;
    await seedUser(aliceId, testPosterUser(uid: aliceId));

    await signOutTestUser();

    // Create Ben (provider)
    final ben = await signInTestUser(
      email: 'ben-flow1@test.com',
      password: 'test1234',
    );
    benId = ben.uid;
    await seedUser(benId, testProviderUser(uid: benId));

    await signOutTestUser();
  });

  tearDownAll(() async {
    await signOutTestUser();
    await cleanupEmulatorData();
  });

  // ── Helpers ──────────────────────────────────────────────────────────────

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

  group('Flow 1: Task-Based Bidding End-to-End', () {
    testWidgets(
        'Alice posts → Ben bids → Alice messages → Alice accepts → Ben starts work → Alice completes → Both review',
        (tester) async {
      // ════════════════════════════════════════════════════════════════════
      // STEP 1: Alice posts a Cleaning task (S$60, Ang Mo Kio)
      // ════════════════════════════════════════════════════════════════════

      await signInTestUser(
        email: 'alice-flow1@test.com',
        password: 'test1234',
      );

      await launchAndLogin(
        tester,
        displayName: 'Alice Tan',
        headline: 'Busy mum',
        neighbourhood: 'Ang Mo Kio',
        roleLabel: 'I need help',
      );

      expect(find.text('Home'), findsOneWidget,
          reason: 'Alice should be on HomeScreen');

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
      await tester.enterText(titleField, 'Clean my 3-room HDB');
      await tester.pump();

      final descField = find.widgetWithText(TextFormField,
          'Describe the task in detail \u2014 size of flat, special requirements, pets, etc.');
      await tester.enterText(descField,
          'Need thorough cleaning including kitchen and bathrooms. Please bring your own supplies.');
      await tester.pump();

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Step 3: Location
      expect(find.text('Where is the task?'), findsOneWidget);
      final locationField = find.widgetWithText(
          TextFormField, 'Blk 123 Ang Mo Kio Ave 6 #05-45');
      await tester.enterText(locationField, 'Blk 456 Ang Mo Kio Ave 3');
      await tester.pump();

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ang Mo Kio').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Step 4: Budget — S$60
      expect(find.text("What's your budget?"), findsOneWidget);
      final minBudgetField =
          find.widgetWithText(TextFormField, 'S\$ ').first;
      await tester.enterText(minBudgetField, '60');
      await tester.pump();

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Step 5: Review & Post
      expect(find.text('Review & Post'), findsOneWidget);
      expect(find.text('Clean my 3-room HDB'), findsOneWidget);
      expect(find.textContaining('S\$60'), findsOneWidget);

      await tester.tap(find.text('Post Task'));
      await settle(tester);

      // Verify task in Firestore
      final tasksSnap = await firestore
          .collection('tasks')
          .where('posterId', isEqualTo: aliceId)
          .where('title', isEqualTo: 'Clean my 3-room HDB')
          .get();

      expect(tasksSnap.docs.length, 1,
          reason: 'Task should exist in Firestore');

      final taskId = tasksSnap.docs.first.id;
      final taskData = tasksSnap.docs.first.data();
      expect(taskData['status'], 'open');
      expect(taskData['categoryId'], 'cleaning');
      expect(taskData['budgetMin'], 60.0);
      expect(taskData['neighbourhood'], 'Ang Mo Kio');

      // ════════════════════════════════════════════════════════════════════
      // STEP 2: Ben discovers task and submits bid (S$55)
      // ════════════════════════════════════════════════════════════════════

      await signOutTestUser();
      await signInTestUser(
        email: 'ben-flow1@test.com',
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
          reason: 'Ben should be on HomeScreen');

      // Navigate to Discover tab
      await tester.tap(find.text('Discover'));
      await settle(tester);

      // Find the posted task
      if (find.text('Clean my 3-room HDB').evaluate().isEmpty) {
        await tester.drag(
          find.byType(ListView),
          const Offset(0, -400),
        );
        await tester.pumpAndSettle();
      }

      expect(find.text('Clean my 3-room HDB'), findsOneWidget,
          reason: 'Task should appear in Discover');

      await tester.tap(find.text('Clean my 3-room HDB'));
      await settle(tester);

      // Submit bid
      expect(find.text('Submit Bid'), findsOneWidget);
      await tester.tap(find.text('Submit Bid'));
      await settle(tester);

      // Fill bid — S$55
      final amountField = find.widgetWithText(TextFormField, '0.00');
      await tester.enterText(amountField, '55');
      await tester.pump();

      final proposalField = find.widgetWithText(
        TextFormField,
        'Introduce yourself and explain why you\'re a great fit\u2026',
      );
      await tester.enterText(
        proposalField,
        'I have 5 years of professional cleaning experience in HDB flats.',
      );
      await tester.pump();

      // Submit
      final submitButtons = find.text('Submit Bid');
      await tester.tap(submitButtons.last);
      await settle(tester, seconds: 2);

      // Verify bid in Firestore
      final bidsSnap = await firestore
          .collection('tasks')
          .doc(taskId)
          .collection('bids')
          .where('providerId', isEqualTo: benId)
          .get();

      expect(bidsSnap.docs.length, 1,
          reason: 'Bid should exist in Firestore');

      final bidData = bidsSnap.docs.first.data();
      expect(bidData['amount'], 55.0);
      expect(bidData['status'], 'pending');

      // ════════════════════════════════════════════════════════════════════
      // STEP 3: Alice views bid, messages Ben via bid card
      // ════════════════════════════════════════════════════════════════════

      await signOutTestUser();
      await signInTestUser(
        email: 'alice-flow1@test.com',
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

      if (find.text('Clean my 3-room HDB').evaluate().isEmpty) {
        await tester.drag(
          find.byType(ListView),
          const Offset(0, -400),
        );
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('Clean my 3-room HDB'));
      await settle(tester);

      // Scroll to bid section
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -400),
      );
      await settle(tester);

      // Verify bid is visible
      expect(find.text('Bids received (1)'), findsOneWidget,
          reason: 'Should show 1 bid');
      expect(find.textContaining('S\$55'), findsOneWidget,
          reason: 'Bid amount should show S\$55');

      // Tap Message icon on bid card to chat with Ben
      await tester.tap(find.byIcon(Icons.chat_bubble_outline));
      await settle(tester, seconds: 2);

      // Send a message in the chat thread
      final messageInput = find.byType(TextField);
      await tester.enterText(messageInput, 'Hi Ben, when can you come?');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.send_rounded));
      await settle(tester, seconds: 2);

      // Verify message appears
      expect(find.text('Hi Ben, when can you come?'), findsOneWidget,
          reason: 'Sent message should appear in chat');

      // Verify chat in Firestore
      final sortedUids = [aliceId, benId]..sort();
      final chatId = '${taskId}_${sortedUids.join('_')}';

      final chatMessagesSnap = await firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();

      expect(chatMessagesSnap.docs.length, greaterThanOrEqualTo(1),
          reason: 'At least one message should exist in chat');

      // Navigate back from chat
      await tester.tap(find.byType(BackButton));
      await settle(tester);

      // ════════════════════════════════════════════════════════════════════
      // STEP 4: Alice accepts Ben's bid → status = assigned
      // ════════════════════════════════════════════════════════════════════

      // Navigate to Discover to find the task again
      await tester.tap(find.text('Discover'));
      await settle(tester);

      if (find.text('Clean my 3-room HDB').evaluate().isEmpty) {
        await tester.drag(
          find.byType(ListView),
          const Offset(0, -400),
        );
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('Clean my 3-room HDB'));
      await settle(tester);

      // Scroll to bid section
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -400),
      );
      await settle(tester);

      // Accept the bid
      await tester.tap(find.text('Accept'));
      await settle(tester, seconds: 2);

      // Verify Firestore: task assigned
      final assignedTask =
          await firestore.collection('tasks').doc(taskId).get();
      expect(assignedTask.data()!['status'], 'assigned',
          reason: 'Task status should be assigned');
      expect(assignedTask.data()!['assignedProviderId'], benId,
          reason: 'assignedProviderId should match Ben');

      // Verify bid accepted
      final acceptedBids = await firestore
          .collection('tasks')
          .doc(taskId)
          .collection('bids')
          .where('status', isEqualTo: 'accepted')
          .get();
      expect(acceptedBids.docs.length, 1,
          reason: 'One bid should be accepted');

      // ════════════════════════════════════════════════════════════════════
      // STEP 5: Ben opens task, taps 'Start Work' → status = inProgress
      // ════════════════════════════════════════════════════════════════════

      await signOutTestUser();
      await signInTestUser(
        email: 'ben-flow1@test.com',
        password: 'test1234',
      );

      await launchAndLogin(
        tester,
        displayName: 'Ben Lim',
        headline: 'Experienced cleaner',
        neighbourhood: 'Bedok',
        roleLabel: 'I can help',
      );

      expect(find.text('Home'), findsOneWidget);

      // Navigate to Discover to find the task
      await tester.tap(find.text('Discover'));
      await settle(tester);

      if (find.text('Clean my 3-room HDB').evaluate().isEmpty) {
        await tester.drag(
          find.byType(ListView),
          const Offset(0, -400),
        );
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('Clean my 3-room HDB'));
      await settle(tester);

      // Scroll to see Start Work button
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -300),
      );
      await settle(tester);

      // Tap Start Work
      expect(find.text('Start Work'), findsOneWidget,
          reason: 'Ben should see Start Work button');
      await tester.tap(find.text('Start Work'));
      await tester.pumpAndSettle();

      // Confirm in dialog
      expect(find.text('Start Work?'), findsOneWidget,
          reason: 'Confirmation dialog should appear');
      await tester.tap(find.text('Confirm'));
      await settle(tester, seconds: 2);

      // Verify success snackbar
      expect(find.text('Work started! Good luck!'), findsOneWidget,
          reason: 'Success snackbar should appear');

      // Verify Firestore: status = inProgress
      final inProgressTask =
          await firestore.collection('tasks').doc(taskId).get();
      expect(inProgressTask.data()!['status'], 'inProgress',
          reason: 'Task status should be inProgress');

      // ════════════════════════════════════════════════════════════════════
      // STEP 6: Alice marks task as complete → status = completed
      // ════════════════════════════════════════════════════════════════════

      await signOutTestUser();
      await signInTestUser(
        email: 'alice-flow1@test.com',
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

      if (find.text('Clean my 3-room HDB').evaluate().isEmpty) {
        await tester.drag(
          find.byType(ListView),
          const Offset(0, -400),
        );
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('Clean my 3-room HDB'));
      await settle(tester);

      // Scroll to find Mark as Complete button
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -300),
      );
      await settle(tester);

      // Tap Mark as Complete
      expect(find.text('Mark as Complete'), findsOneWidget,
          reason: 'Alice should see Mark as Complete');
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

      // ════════════════════════════════════════════════════════════════════
      // STEP 7: Alice leaves review for Ben (4 stars)
      // ════════════════════════════════════════════════════════════════════

      // Task detail should now show Leave a Review card (page refreshed after complete)
      // Navigate back to task detail to see the review card
      await tester.tap(find.text('Discover'));
      await settle(tester);

      if (find.text('Clean my 3-room HDB').evaluate().isEmpty) {
        await tester.drag(
          find.byType(ListView),
          const Offset(0, -400),
        );
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('Clean my 3-room HDB'));
      await settle(tester);

      // Scroll to find Leave a Review card
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -300),
      );
      await settle(tester);

      expect(find.text('Leave a Review'), findsOneWidget,
          reason: 'Alice should see Leave a Review card');

      // Tap Review button
      await tester.tap(find.text('Review'));
      await settle(tester);

      // On SubmitReviewScreen — tap 4th star for 4-star rating
      expect(find.text('Leave a Review'), findsOneWidget,
          reason: 'Should be on SubmitReviewScreen');

      // Tap the 4th star (index 3)
      final stars = find.byIcon(Icons.star_rounded);
      await tester.tap(stars.at(3));
      await tester.pumpAndSettle();

      expect(find.text('Very Good'), findsOneWidget,
          reason: '4 stars should show Very Good label');

      // Add a comment
      final commentField = find.widgetWithText(TextField, 'Share your experience...');
      await tester.enterText(commentField, 'Ben did a great job cleaning. Very thorough!');
      await tester.pump();

      // Submit review
      await tester.tap(find.text('Submit Review'));
      await settle(tester, seconds: 2);

      // Verify success snackbar
      expect(find.text('Review submitted!'), findsOneWidget,
          reason: 'Review submitted snackbar should appear');

      // Verify review in Firestore (stored under Ben's reviews subcollection)
      final benReviews = await firestore
          .collection('users')
          .doc(benId)
          .collection('reviews')
          .where('reviewerId', isEqualTo: aliceId)
          .where('taskId', isEqualTo: taskId)
          .get();

      expect(benReviews.docs.length, 1,
          reason: 'Alice\'s review for Ben should exist');
      expect(benReviews.docs.first.data()['rating'], 4.0,
          reason: 'Review rating should be 4 stars');

      // ════════════════════════════════════════════════════════════════════
      // STEP 8: Ben leaves review for Alice (5 stars)
      // ════════════════════════════════════════════════════════════════════

      await signOutTestUser();
      await signInTestUser(
        email: 'ben-flow1@test.com',
        password: 'test1234',
      );

      await launchAndLogin(
        tester,
        displayName: 'Ben Lim',
        headline: 'Experienced cleaner',
        neighbourhood: 'Bedok',
        roleLabel: 'I can help',
      );

      expect(find.text('Home'), findsOneWidget);

      // Navigate to Discover to find the task
      await tester.tap(find.text('Discover'));
      await settle(tester);

      if (find.text('Clean my 3-room HDB').evaluate().isEmpty) {
        await tester.drag(
          find.byType(ListView),
          const Offset(0, -400),
        );
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('Clean my 3-room HDB'));
      await settle(tester);

      // Scroll to find Leave a Review card
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -300),
      );
      await settle(tester);

      expect(find.text('Leave a Review'), findsOneWidget,
          reason: 'Ben should see Leave a Review card');

      // Tap Review button
      await tester.tap(find.text('Review'));
      await settle(tester);

      // On SubmitReviewScreen — tap 5th star for 5-star rating
      expect(find.text('Leave a Review'), findsOneWidget,
          reason: 'Should be on SubmitReviewScreen');

      final benStars = find.byIcon(Icons.star_rounded);
      await tester.tap(benStars.at(4));
      await tester.pumpAndSettle();

      expect(find.text('Excellent'), findsOneWidget,
          reason: '5 stars should show Excellent label');

      // Add a comment
      final benCommentField =
          find.widgetWithText(TextField, 'Share your experience...');
      await tester.enterText(
          benCommentField, 'Alice was very friendly and gave clear instructions.');
      await tester.pump();

      // Submit review
      await tester.tap(find.text('Submit Review'));
      await settle(tester, seconds: 2);

      // Verify success snackbar
      expect(find.text('Review submitted!'), findsOneWidget,
          reason: 'Review submitted snackbar should appear');

      // ════════════════════════════════════════════════════════════════════
      // STEP 9: Verify both reviews exist in Firestore
      // ════════════════════════════════════════════════════════════════════

      // Alice's review for Ben (already verified in step 7, re-verify)
      final benReviewsFinal = await firestore
          .collection('users')
          .doc(benId)
          .collection('reviews')
          .where('taskId', isEqualTo: taskId)
          .get();

      expect(benReviewsFinal.docs.length, 1,
          reason: 'Ben should have 1 review for this task');
      final benReviewData = benReviewsFinal.docs.first.data();
      expect(benReviewData['rating'], 4.0);
      expect(benReviewData['reviewerId'], aliceId);
      expect(benReviewData['taskCategory'], 'cleaning');

      // Ben's review for Alice
      final aliceReviews = await firestore
          .collection('users')
          .doc(aliceId)
          .collection('reviews')
          .where('reviewerId', isEqualTo: benId)
          .where('taskId', isEqualTo: taskId)
          .get();

      expect(aliceReviews.docs.length, 1,
          reason: 'Ben\'s review for Alice should exist');
      final aliceReviewData = aliceReviews.docs.first.data();
      expect(aliceReviewData['rating'], 5.0,
          reason: 'Ben\'s review for Alice should be 5 stars');

      // Final task state verification
      final finalTask =
          await firestore.collection('tasks').doc(taskId).get();
      final ft = finalTask.data()!;
      expect(ft['status'], 'completed');
      expect(ft['posterId'], aliceId);
      expect(ft['assignedProviderId'], benId);
      expect(ft['completedAt'], isNotNull);

      // Chat verification
      final finalChat =
          await firestore.collection('chats').doc(chatId).get();
      expect(finalChat.exists, isTrue,
          reason: 'Chat should exist between Alice and Ben');
    });
  });
}
