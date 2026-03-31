/// Integration test: Flow 2 — Direct Hire End-to-End
///
/// Complete marketplace Flow 2:
///   1. Ben registers as provider, sets up profile with serviceCategories, rates, availability
///   2. Alice registers as poster, goes to Discover → toggle to Providers
///   3. Alice sees Ben in provider directory, taps to view profile
///   4. Alice taps 'Hire' on Ben's profile, posts a direct hire task (Cleaning, S$50, Ang Mo Kio)
///   5. Verify task in Firestore: isDirectHire=true, status=assigned, assignedProviderId=Ben
///   6. Ben sees 'Job Offers' section on ProviderHome with the task
///   7. Ben opens task detail, taps 'Accept Job' → status=inProgress
///   8. Alice and Ben exchange chat messages
///   9. Alice marks task complete → status=completed
///  10. Both leave reviews, verify in Firestore
///
/// Run:
///   flutter test integration_test/flow2_direct_hire_test.dart -d <simulator_id>
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

    // Create Ben (provider) with serviceCategories, rates, availability
    final ben = await signInTestUser(
      email: 'ben-flow2@test.com',
      password: 'test1234',
    );
    benId = ben.uid;
    await seedUser(benId, {
      ...testProviderUser(uid: benId),
      'serviceRates': {
        'cleaning': {'hourlyRate': 25.0},
      },
      'availableDays': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
      'availableHours': '9am - 6pm',
    });

    await signOutTestUser();

    // Create Alice (poster)
    final alice = await signInTestUser(
      email: 'alice-flow2@test.com',
      password: 'test1234',
    );
    aliceId = alice.uid;
    await seedUser(aliceId, testPosterUser(uid: aliceId));

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

  group('Flow 2: Direct Hire End-to-End', () {
    testWidgets(
        'Ben sets up profile → Alice browses directory → Alice hires Ben → Ben accepts → Task completes → Both review',
        (tester) async {
      // ════════════════════════════════════════════════════════════════════
      // STEP 1: Ben registers as provider with profile data
      // (Already seeded in setUpAll with serviceCategories, rates, availability)
      // Verify Ben's profile in Firestore
      // ════════════════════════════════════════════════════════════════════

      final benDoc = await firestore.collection('users').doc(benId).get();
      final benData = benDoc.data()!;
      expect(benData['role'], 'provider');
      expect(benData['serviceCategories'], contains('cleaning'));
      expect(benData['serviceRates'], isNotNull,
          reason: 'Ben should have serviceRates');
      expect(benData['availableDays'], isNotEmpty,
          reason: 'Ben should have availableDays');

      // ════════════════════════════════════════════════════════════════════
      // STEP 2: Alice signs in, goes to Discover → toggle to Providers
      // ════════════════════════════════════════════════════════════════════

      await signInTestUser(
        email: 'alice-flow2@test.com',
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

      // Navigate to Discover tab
      await tester.tap(find.text('Discover'));
      await settle(tester);

      // Toggle to Providers segment
      await tester.tap(find.text('Providers'));
      await settle(tester, seconds: 2);

      // ════════════════════════════════════════════════════════════════════
      // STEP 3: Alice sees Ben in provider directory, taps to view profile
      // ════════════════════════════════════════════════════════════════════

      // Look for Ben in the provider list
      if (find.text('Ben Lim').evaluate().isEmpty) {
        // Try scrolling to find Ben
        await tester.drag(
          find.byType(ListView),
          const Offset(0, -400),
        );
        await tester.pumpAndSettle();
      }

      expect(find.text('Ben Lim'), findsOneWidget,
          reason: 'Ben should appear in provider directory');

      // Tap Ben's card to view profile
      await tester.tap(find.text('Ben Lim'));
      await settle(tester);

      // Verify we're on Ben's profile
      expect(find.text('Ben Lim'), findsOneWidget,
          reason: 'Should be on Ben\'s profile');
      expect(find.textContaining('Experienced cleaner'), findsOneWidget,
          reason: 'Ben\'s headline should be visible');

      // ════════════════════════════════════════════════════════════════════
      // STEP 4: Alice taps 'Hire' on Ben's profile, posts a direct hire task
      // ════════════════════════════════════════════════════════════════════

      // Scroll down to find the Hire button
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -300),
      );
      await settle(tester);

      // Tap the Hire button (text is "Hire Ben")
      expect(find.text('Hire Ben'), findsOneWidget,
          reason: 'Hire button should show "Hire Ben"');
      await tester.tap(find.text('Hire Ben'));
      await settle(tester);

      // Should be on PostTaskScreen in direct hire mode
      expect(find.textContaining('Hiring: Ben Lim'), findsOneWidget,
          reason: 'Direct hire banner should show');

      // Step 1: Category — should be pre-selected to cleaning
      // The category may already be pre-selected; just tap Next
      expect(find.text('What do you need help with?'), findsOneWidget);

      // Verify cleaning is pre-selected (the chip should be selected)
      // Just proceed with Next
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Step 2: Description
      expect(find.text('Describe your task'), findsOneWidget);
      final titleField = find.widgetWithText(
          TextFormField, 'e.g. Clean my 3-room HDB flat');
      await tester.enterText(titleField, 'Weekly home cleaning');
      await tester.pump();

      final descField = find.widgetWithText(TextFormField,
          'Describe the task in detail \u2014 size of flat, special requirements, pets, etc.');
      await tester.enterText(descField,
          'Need weekly cleaning for my 4-room flat. Kitchen, bathrooms, and living room.');
      await tester.pump();

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Step 3: Location
      expect(find.text('Where is the task?'), findsOneWidget);
      final locationField = find.widgetWithText(
          TextFormField, 'Blk 123 Ang Mo Kio Ave 6 #05-45');
      await tester.enterText(locationField, 'Blk 789 Ang Mo Kio Ave 5');
      await tester.pump();

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ang Mo Kio').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Step 4: Budget — S$50
      expect(find.text("What's your budget?"), findsOneWidget);
      final minBudgetField =
          find.widgetWithText(TextFormField, 'S\$ ').first;
      await tester.enterText(minBudgetField, '50');
      await tester.pump();

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Step 5: Review & Post
      expect(find.text('Review & Post'), findsOneWidget);
      expect(find.text('Weekly home cleaning'), findsOneWidget);
      expect(find.textContaining('S\$50'), findsOneWidget);

      // Submit — button says "Send Hire Request" in direct hire mode
      await tester.tap(find.text('Send Hire Request'));
      await settle(tester, seconds: 2);

      // ════════════════════════════════════════════════════════════════════
      // STEP 5: Verify task in Firestore: isDirectHire=true, status=assigned
      // ════════════════════════════════════════════════════════════════════

      final tasksSnap = await firestore
          .collection('tasks')
          .where('posterId', isEqualTo: aliceId)
          .where('title', isEqualTo: 'Weekly home cleaning')
          .get();

      expect(tasksSnap.docs.length, 1,
          reason: 'Direct hire task should exist in Firestore');

      final taskId = tasksSnap.docs.first.id;
      final taskData = tasksSnap.docs.first.data();
      expect(taskData['isDirectHire'], true,
          reason: 'Task should be marked as direct hire');
      expect(taskData['status'], 'assigned',
          reason: 'Task status should be assigned');
      expect(taskData['assignedProviderId'], benId,
          reason: 'assignedProviderId should be Ben');
      expect(taskData['categoryId'], 'cleaning');
      expect(taskData['budgetMin'], 50.0);
      expect(taskData['neighbourhood'], 'Ang Mo Kio');

      // ════════════════════════════════════════════════════════════════════
      // STEP 6: Ben sees 'Job Offers' section on ProviderHome
      // ════════════════════════════════════════════════════════════════════

      await signOutTestUser();
      await signInTestUser(
        email: 'ben-flow2@test.com',
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

      // Verify Job Offers section shows on home
      expect(find.text('Job Offers'), findsOneWidget,
          reason: 'Job Offers section should be visible');
      expect(find.text('Weekly home cleaning'), findsOneWidget,
          reason: 'Direct hire task should appear in Job Offers');
      expect(find.text('Direct Hire'), findsOneWidget,
          reason: 'Direct Hire badge should be visible');

      // ════════════════════════════════════════════════════════════════════
      // STEP 7: Ben opens task, taps 'Accept Job' → status=inProgress
      // ════════════════════════════════════════════════════════════════════

      // Tap on the task in Job Offers to navigate to task detail
      await tester.tap(find.text('Weekly home cleaning'));
      await settle(tester);

      // Scroll to see Accept Job button
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -300),
      );
      await settle(tester);

      // Verify direct hire banner
      expect(find.text('You have been hired directly for this task'),
          findsOneWidget,
          reason: 'Direct hire banner should be visible');

      // Tap Accept Job
      expect(find.text('Accept Job'), findsOneWidget,
          reason: 'Accept Job button should be visible');
      await tester.tap(find.text('Accept Job'));
      await tester.pumpAndSettle();

      // Confirm in dialog
      expect(find.text('Accept Job?'), findsOneWidget,
          reason: 'Confirmation dialog should appear');
      await tester.tap(find.text('Accept'));
      await settle(tester, seconds: 2);

      // Verify success snackbar
      expect(find.text('Job accepted! Work started.'), findsOneWidget,
          reason: 'Success snackbar should appear');

      // Verify Firestore: status = inProgress
      final inProgressTask =
          await firestore.collection('tasks').doc(taskId).get();
      expect(inProgressTask.data()!['status'], 'inProgress',
          reason: 'Task status should be inProgress after accepting');

      // ════════════════════════════════════════════════════════════════════
      // STEP 8: Alice and Ben exchange chat messages
      // ════════════════════════════════════════════════════════════════════

      // Ben sends a message first — navigate to Messages tab
      await tester.tap(find.text('Messages'));
      await settle(tester);

      // Look for the chat related to this task
      if (find.text('Weekly home cleaning').evaluate().isNotEmpty) {
        await tester.tap(find.text('Weekly home cleaning'));
        await settle(tester);
      } else {
        // Create a chat via task detail
        await tester.tap(find.text('Home'));
        await settle(tester);

        // Navigate to Discover to find the task
        await tester.tap(find.text('Discover'));
        await settle(tester);

        if (find.text('Weekly home cleaning').evaluate().isEmpty) {
          await tester.drag(
            find.byType(ListView),
            const Offset(0, -400),
          );
          await tester.pumpAndSettle();
        }

        await tester.tap(find.text('Weekly home cleaning'));
        await settle(tester);

        // Find and tap the chat/message button on task detail
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -300),
        );
        await settle(tester);

        // Look for message button
        if (find.byIcon(Icons.chat_bubble_outline).evaluate().isNotEmpty) {
          await tester.tap(find.byIcon(Icons.chat_bubble_outline));
          await settle(tester);
        } else if (find.text('Message').evaluate().isNotEmpty) {
          await tester.tap(find.text('Message'));
          await settle(tester);
        }
      }

      // Send message from Ben
      final benMessageInput = find.byType(TextField);
      if (benMessageInput.evaluate().isNotEmpty) {
        await tester.enterText(
            benMessageInput, 'Hi Alice, I accepted the job. When should I come?');
        await tester.pump();

        await tester.tap(find.byIcon(Icons.send_rounded));
        await settle(tester, seconds: 2);

        expect(
            find.text('Hi Alice, I accepted the job. When should I come?'),
            findsOneWidget,
            reason: 'Ben\'s message should appear in chat');
      }

      // Switch to Alice to send a reply
      await signOutTestUser();
      await signInTestUser(
        email: 'alice-flow2@test.com',
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

      // Navigate to Messages
      await tester.tap(find.text('Messages'));
      await settle(tester);

      // Open the chat
      if (find.text('Weekly home cleaning').evaluate().isNotEmpty) {
        await tester.tap(find.text('Weekly home cleaning'));
        await settle(tester);
      }

      // Send message from Alice
      final aliceMessageInput = find.byType(TextField);
      if (aliceMessageInput.evaluate().isNotEmpty) {
        await tester.enterText(
            aliceMessageInput, 'Tomorrow morning at 10am please!');
        await tester.pump();

        await tester.tap(find.byIcon(Icons.send_rounded));
        await settle(tester, seconds: 2);

        expect(find.text('Tomorrow morning at 10am please!'), findsOneWidget,
            reason: 'Alice\'s message should appear in chat');
      }

      // Verify chat in Firestore
      final sortedUids = [aliceId, benId]..sort();
      final chatId = '${taskId}_${sortedUids.join('_')}';

      final chatMessagesSnap = await firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();

      expect(chatMessagesSnap.docs.length, greaterThanOrEqualTo(2),
          reason: 'At least 2 messages should exist in chat');

      // Navigate back from chat
      await tester.tap(find.byType(BackButton));
      await settle(tester);

      // ════════════════════════════════════════════════════════════════════
      // STEP 9: Alice marks task complete → status=completed
      // ════════════════════════════════════════════════════════════════════

      // Navigate to Discover to find the task
      await tester.tap(find.text('Discover'));
      await settle(tester);

      if (find.text('Weekly home cleaning').evaluate().isEmpty) {
        await tester.drag(
          find.byType(ListView),
          const Offset(0, -400),
        );
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('Weekly home cleaning'));
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

      // Verify Firestore: task completed
      final completedTask =
          await firestore.collection('tasks').doc(taskId).get();
      final completedData = completedTask.data()!;
      expect(completedData['status'], 'completed',
          reason: 'Task status should be completed');
      expect(completedData['completedAt'], isNotNull,
          reason: 'completedAt timestamp should be set');

      // ════════════════════════════════════════════════════════════════════
      // STEP 10A: Alice leaves review for Ben (4 stars)
      // ════════════════════════════════════════════════════════════════════

      // Navigate to Discover to find the completed task
      await tester.tap(find.text('Discover'));
      await settle(tester);

      if (find.text('Weekly home cleaning').evaluate().isEmpty) {
        await tester.drag(
          find.byType(ListView),
          const Offset(0, -400),
        );
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('Weekly home cleaning'));
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

      final stars = find.byIcon(Icons.star_rounded);
      await tester.tap(stars.at(3));
      await tester.pumpAndSettle();

      expect(find.text('Very Good'), findsOneWidget,
          reason: '4 stars should show Very Good label');

      // Add a comment
      final commentField =
          find.widgetWithText(TextField, 'Share your experience...');
      await tester.enterText(
          commentField, 'Ben was punctual and did excellent work!');
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
      // STEP 10B: Ben leaves review for Alice (5 stars)
      // ════════════════════════════════════════════════════════════════════

      await signOutTestUser();
      await signInTestUser(
        email: 'ben-flow2@test.com',
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

      if (find.text('Weekly home cleaning').evaluate().isEmpty) {
        await tester.drag(
          find.byType(ListView),
          const Offset(0, -400),
        );
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('Weekly home cleaning'));
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
          benCommentField, 'Alice was very friendly and the flat was tidy.');
      await tester.pump();

      // Submit review
      await tester.tap(find.text('Submit Review'));
      await settle(tester, seconds: 2);

      // Verify success snackbar
      expect(find.text('Review submitted!'), findsOneWidget,
          reason: 'Review submitted snackbar should appear');

      // ════════════════════════════════════════════════════════════════════
      // FINAL: Verify both reviews exist in Firestore
      // ════════════════════════════════════════════════════════════════════

      // Alice's review for Ben
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
      expect(ft['isDirectHire'], true);
      expect(ft['completedAt'], isNotNull);

      // Chat verification
      final finalChat =
          await firestore.collection('chats').doc(chatId).get();
      expect(finalChat.exists, isTrue,
          reason: 'Chat should exist between Alice and Ben');
    });
  });
}
