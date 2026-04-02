/// Integration test: Job Seeker (Provider) Full Journey
///
/// Complete provider lifecycle from registration to task completion:
///   1. App Launch — splash → welcome
///   2. Register with email
///   3. Select provider role
///   4. Setup profile
///   5. Browse tasks (seeded)
///   6. Verify provider task detail view
///   7. Submit bid
///   8. Verify bid in Firestore
///   9. Verify own bid view
///  10. Seed acceptance
///  11. Verify accepted state
///  12. Chat with poster
///  13. Seed completion
///  14. Verify completed state
///  15. Final state verification
///
/// Run:
///   flutter test integration_test/provider_journey_test.dart -d <simulator_id>
///
/// Prerequisites:
///   1. Firebase emulators running: firebase emulators:start
///   2. iOS Simulator booted
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:neighbourgo/main.dart';

import 'test_helpers.dart';
import 'test_data.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late String posterUserId;
  late String seededTaskId;
  late final FirebaseFirestore firestore;

  setUpAll(() async {
    await initializeTestApp();
    firestore = FirebaseFirestore.instance;

    // Pre-seed a poster user (Alice Tan) and an open task
    final posterUser = await signInTestUser(
      email: 'poster-seed@neighbourgo.com',
      password: 'test123456',
    );
    posterUserId = posterUser.uid;
    await seedUser(posterUserId, testPosterUser(uid: posterUserId));

    // Seed an open cleaning task from Alice
    seededTaskId = 'seeded-task-provider-journey';
    await seedTask(
      seededTaskId,
      testCleaningTask(
        taskId: seededTaskId,
        posterId: posterUserId,
        posterName: 'Alice Tan',
      ),
    );

    // Sign out so the test starts fresh (provider registers from scratch)
    await signOutTestUser();
  });

  tearDownAll(() async {
    try { await cleanupEmulatorData(); } catch (_) {}
    await signOutTestUser();
  });

  /// Standard pump-and-settle with generous timeout.
  Future<void> settle(WidgetTester tester, {int seconds = 1}) async {
    await tester.pump(Duration(seconds: seconds));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 200),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 15),
    );
  }

  group('Provider Full Journey', () {
    testWidgets(
        'Register → Browse → Bid → Accepted → Chat → Completed',
        (tester) async {
      // ════════════════════════════════════════════════════════════════════════
      // STEP 1 — App Launch
      // ════════════════════════════════════════════════════════════════════════

      await tester.pumpWidget(const ProviderScope(child: NeighbourGoApp()));
      await tester.pump();

      // Splash screen shows 'NeighbourGo'
      expect(find.text('NeighbourGo'), findsOneWidget,
          reason: 'Splash screen should show NeighbourGo');

      // Wait through splash delay (2s) + navigation
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 200),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 15),
      );

      // Verify welcome screen with 'Continue with Email' button
      expect(find.text('Continue with Email'), findsOneWidget,
          reason: 'Welcome screen should show Continue with Email button');

      // ════════════════════════════════════════════════════════════════════════
      // STEP 2 — Register with email
      // ════════════════════════════════════════════════════════════════════════

      await tester.tap(find.text('Continue with Email'));
      await settle(tester);

      // Email auth screen
      expect(find.text('Email Login'), findsOneWidget,
          reason: 'Should navigate to Email Login screen');

      final emailField =
          find.widgetWithText(TextFormField, 'you@example.com');
      await tester.enterText(emailField, 'provider-test@neighbourgo.com');
      await tester.pump();

      final passwordField =
          find.widgetWithText(TextFormField, 'Password');
      await tester.enterText(passwordField, 'test123456');
      await tester.pump();

      await tester.tap(find.text('Continue'));
      await settle(tester, seconds: 2);

      // ════════════════════════════════════════════════════════════════════════
      // STEP 3 — Select Role: provider ("I want to earn")
      // ════════════════════════════════════════════════════════════════════════

      expect(find.text('How will you use NeighbourGo?'), findsOneWidget,
          reason: 'Should navigate to role selection');

      await tester.tap(find.text('I want to earn'));
      await tester.pumpAndSettle();

      // Verify selection is shown
      expect(find.byIcon(Icons.check_circle), findsOneWidget,
          reason: 'Selected role should show check icon');

      await tester.tap(find.text('Continue'));
      await settle(tester);

      // ════════════════════════════════════════════════════════════════════════
      // STEP 4 — Profile Setup
      // ════════════════════════════════════════════════════════════════════════

      expect(find.text('Set Up Profile'), findsOneWidget,
          reason: 'Should navigate to profile setup');

      final nameField =
          find.widgetWithText(TextFormField, 'e.g. Wei Ming');
      await tester.enterText(nameField, 'Ben Lim');
      await tester.pump();

      final headlineField = find.widgetWithText(
          TextFormField, 'A brief intro about yourself');
      await tester.enterText(headlineField, 'Experienced cleaner & handyman');
      await tester.pump();

      // Scroll down to reveal neighbourhood dropdown
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();

      // Select neighbourhood
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bedok').last);
      await tester.pumpAndSettle();

      // Scroll down to Complete Setup button
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Complete Setup'));
      await settle(tester, seconds: 2);

      // Verify provider home screen
      expect(find.textContaining('Hi, Ben!'), findsOneWidget,
          reason: 'Provider home screen should greet Ben');
      expect(find.text('All Open Tasks'), findsOneWidget,
          reason: 'Provider home should show All Open Tasks section');

      // ════════════════════════════════════════════════════════════════════════
      // STEP 5 — Browse tasks: find seeded task
      // ════════════════════════════════════════════════════════════════════════

      // The seeded task should be visible in Open Tasks on provider home
      // or navigate to Discover tab
      if (find.text('Deep clean 3-room HDB').evaluate().isEmpty) {
        // Try Discover tab
        await tester.tap(find.text('Discover'));
        await settle(tester);
      }

      expect(find.text('Deep clean 3-room HDB'), findsOneWidget,
          reason: 'Seeded task should be visible');

      await tester.tap(find.text('Deep clean 3-room HDB'));
      await settle(tester);

      // ════════════════════════════════════════════════════════════════════════
      // STEP 6 — Verify provider task detail
      // ════════════════════════════════════════════════════════════════════════

      // Submit Bid button visible (task is open)
      expect(find.text('Submit Bid'), findsOneWidget,
          reason: 'Provider should see Submit Bid button on open task');

      // Should NOT see 'Mark as Complete' (that's poster-only)
      expect(find.text('Mark as Complete'), findsNothing,
          reason: 'Provider should not see Mark as Complete');

      // Scroll to see poster info
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -200),
      );
      await settle(tester);

      // Poster info shows Alice Tan
      expect(find.text('Alice Tan'), findsOneWidget,
          reason: 'Poster info should show Alice Tan');

      // ════════════════════════════════════════════════════════════════════════
      // STEP 7 — Submit bid
      // ════════════════════════════════════════════════════════════════════════

      // Scroll back up to find Submit Bid button
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, 200),
      );
      await settle(tester);

      await tester.tap(find.text('Submit Bid'));
      await settle(tester);

      // Bottom sheet should show Submit Bid form
      expect(find.text('Bid Amount (SGD)'), findsOneWidget,
          reason: 'Bid sheet should show amount field');

      // Enter bid amount
      final amountField = find.widgetWithText(TextFormField, '0.00');
      await tester.enterText(amountField, '65');
      await tester.pump();

      // Select 2 hours duration
      await tester.tap(find.text('2 hours'));
      await tester.pump();

      // Enter proposal (min 20 chars)
      final proposalField = find.widgetWithText(
          TextFormField,
          'Introduce yourself and explain why you\'re a great fit…');
      await tester.enterText(proposalField,
          'I have 5 years of professional cleaning experience in HDB flats.');
      await tester.pump();

      // Tap submit button in the sheet
      // There are two 'Submit Bid' texts: the sheet title and the button
      await tester.tap(find.text('Submit Bid').last);
      await settle(tester, seconds: 2);

      // Verify snackbar success (may auto-dismiss during pumpAndSettle)
      // Check for snackbar or verify via Firestore in next step
      final hasSnackbar = find.text('Bid submitted!').evaluate().isNotEmpty;
      if (!hasSnackbar) {
        // Snackbar may have auto-dismissed — verify bid exists in Firestore instead
        await settle(tester, seconds: 2);
      }

      // ════════════════════════════════════════════════════════════════════════
      // STEP 8 — Verify bid in Firestore
      // ════════════════════════════════════════════════════════════════════════

      final bidsSnap = await firestore
          .collection('tasks')
          .doc(seededTaskId)
          .collection('bids')
          .get();

      expect(bidsSnap.docs.length, greaterThanOrEqualTo(1),
          reason: 'At least one bid should exist in Firestore');

      final myBid = bidsSnap.docs.firstWhere(
          (doc) => doc.data()['amount'] == 65.0);
      final bidData = myBid.data();
      expect(bidData['amount'], 65.0);
      expect(bidData['status'], 'pending');

      // Capture provider UID
      final providerUserId = bidData['providerId'] as String;

      // ════════════════════════════════════════════════════════════════════════
      // STEP 9 — Verify own bid view: 'Your Bid' section
      // ════════════════════════════════════════════════════════════════════════

      // We should now be on the task detail screen (sheet dismissed)
      // Wait for sheet to fully dismiss, then scroll down to see bid section
      await settle(tester, seconds: 2);
      if (find.byType(SingleChildScrollView).evaluate().isNotEmpty) {
        await tester.drag(
          find.byType(SingleChildScrollView).first,
          const Offset(0, -300),
          warnIfMissed: false,
        );
        await settle(tester);
      }

      expect(find.text('Your Bid'), findsOneWidget,
          reason: 'Should show Your Bid section');
      expect(find.textContaining('S\$65'), findsOneWidget,
          reason: 'Should show bid amount S\$65');
      expect(find.text('Pending'), findsOneWidget,
          reason: 'Should show Pending badge');

      // ════════════════════════════════════════════════════════════════════════
      // STEP 10 — Seed acceptance
      // Provider can update their own bid (security rules allow it).
      // Task update requires REST API (poster-only operation).
      // ════════════════════════════════════════════════════════════════════════

      // Provider updates their own bid status (allowed by security rules)
      await firestore
          .collection('tasks')
          .doc(seededTaskId)
          .collection('bids')
          .doc(myBid.id)
          .update({'status': 'accepted'});

      // Task assignment is a poster operation — use REST API to bypass rules
      await seedDocViaRest(
        path: 'tasks/$seededTaskId',
        data: {
          'status': 'assigned',
          'assignedProviderId': providerUserId,
        },
      );

      // ════════════════════════════════════════════════════════════════════════
      // STEP 11 — Verify accepted state
      // ════════════════════════════════════════════════════════════════════════

      // Navigate away and back to refresh the task detail with seeded acceptance
      final ctx11 = tester.element(find.byType(Scaffold).first);
      GoRouter.of(ctx11).go('/home');
      await settle(tester, seconds: 2);
      GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/tasks/$seededTaskId');
      await settle(tester, seconds: 2);

      // Scroll down to see bid section
      if (find.byType(SingleChildScrollView).evaluate().isNotEmpty) {
        await tester.drag(
          find.byType(SingleChildScrollView).first,
          const Offset(0, -300),
        );
        await settle(tester);
      }

      // Verify Accepted badge
      expect(find.text('Accepted'), findsOneWidget,
          reason: 'Should show Accepted badge');

      // Verify Message Poster button (provider is assigned)
      expect(find.text('Message Poster'), findsOneWidget,
          reason: 'Message Poster button should be visible for assigned provider');

      // ════════════════════════════════════════════════════════════════════════
      // STEP 12 — Chat: tap 'Message Poster', send message
      // ════════════════════════════════════════════════════════════════════════

      await tester.tap(find.text('Message Poster'));
      await settle(tester);

      // Verify ChatThreadScreen
      expect(find.text('Deep clean 3-room HDB'), findsOneWidget,
          reason: 'Chat AppBar should show task title');

      // Send a message — wait for chat screen to fully load
      await settle(tester, seconds: 2);
      final messageInput = find.byType(TextField);
      expect(messageInput, findsOneWidget,
          reason: 'Chat message input should be visible');
      await tester.enterText(
          messageInput, 'Hi Alice, I can come tomorrow at 10am.');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.send_rounded));
      await settle(tester, seconds: 2);

      // Verify message appears in chat
      expect(find.text('Hi Alice, I can come tomorrow at 10am.'), findsOneWidget,
          reason: 'Sent message should appear in chat');

      // Verify message in Firestore
      final sortedUids = [posterUserId, providerUserId]..sort();
      final chatId = '${seededTaskId}_${sortedUids.join('_')}';

      final messagesSnap = await firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();

      expect(messagesSnap.docs.length, greaterThanOrEqualTo(1),
          reason: 'At least one message should exist in Firestore');

      // ════════════════════════════════════════════════════════════════════════
      // STEP 13 — Seed completion
      // ════════════════════════════════════════════════════════════════════════

      // Seed completion via REST (cross-user operation — poster marks complete)
      await seedDocViaRest(
        path: 'tasks/$seededTaskId',
        data: {
          'status': 'completed',
          'completedAt': DateTime.now().toIso8601String(),
        },
      );

      // ════════════════════════════════════════════════════════════════════════
      // STEP 14 — Verify completed state
      // ════════════════════════════════════════════════════════════════════════

      // Navigate back from chat
      await tester.tap(find.byType(BackButton));
      await settle(tester);

      // Verify completed state in Firestore directly
      // (completed task may be filtered out of UI listings)
      final completedTaskDoc =
          await firestore.collection('tasks').doc(seededTaskId).get();
      final completedData = completedTaskDoc.data()!;
      expect(completedData['status'], 'completed',
          reason: 'Task status should be completed in Firestore');
      expect(completedData['completedAt'], isNotNull,
          reason: 'completedAt should be set');

      // ════════════════════════════════════════════════════════════════════════
      // STEP 15 — Final state verification
      // ════════════════════════════════════════════════════════════════════════

      // Navigate to Home via GoRouter (may be on task detail outside shell)
      final ctx15 = tester.element(find.byType(Scaffold).first);
      GoRouter.of(ctx15).go('/home');
      await settle(tester, seconds: 2);

      // Navigate to Profile
      await tester.tap(find.text('Profile'));
      await settle(tester);

      // Profile should show 'Ben Lim'
      expect(find.text('Ben Lim'), findsOneWidget,
          reason: 'Profile should show Ben Lim');

      // Final Firestore consistency checks
      final finalTask =
          await firestore.collection('tasks').doc(seededTaskId).get();
      final ft = finalTask.data()!;
      expect(ft['status'], 'completed');
      expect(ft['posterId'], posterUserId);
      expect(ft['assignedProviderId'], providerUserId);
      expect(ft['completedAt'], isNotNull);

      final finalBids = await firestore
          .collection('tasks')
          .doc(seededTaskId)
          .collection('bids')
          .get();
      expect(finalBids.docs.length, greaterThanOrEqualTo(1));

      final acceptedBid = finalBids.docs
          .where((d) => d.data()['providerId'] == providerUserId)
          .first;
      expect(acceptedBid.data()['status'], 'accepted');

      final finalChat =
          await firestore.collection('chats').doc(chatId).get();
      expect(finalChat.exists, isTrue,
          reason: 'Chat document should still exist');
    });
  });
}
