/// Integration test: Bidding Flow — Provider Submits, Poster Accepts
///
/// Verifies a provider can submit a bid on a task, the bid is saved to
/// Firestore, and the poster can accept the bid — updating both the bid
/// and task status.
///
/// Run:
///   flutter test integration_test/bidding_flow_test.dart -d <simulator_id>
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
  const taskId = 'bid-test-task-1';

  setUpAll(() async {
    await initializeTestApp();

    // Create poster user
    final posterUser = await signInTestUser(
      email: 'poster-bid@test.com',
      password: 'test1234',
    );
    posterUserId = posterUser.uid;
    await seedUser(posterUserId, testPosterUser(uid: posterUserId));

    // Sign out poster so we can create the provider user
    await signOutTestUser();

    // Create provider user
    final providerUser = await signInTestUser(
      email: 'provider-bid@test.com',
      password: 'test1234',
    );
    providerUserId = providerUser.uid;
    await seedUser(providerUserId, testProviderUser(uid: providerUserId));

    // Seed a task posted by posterUser
    await seedTask(taskId, testCleaningTask(
      taskId: taskId,
      posterId: posterUserId,
      posterName: 'Alice Tan',
    ));

    // Stay signed in as provider for the first part of the test
  });

  tearDownAll(() async {
    await signOutTestUser();
    await cleanupEmulatorData();
  });

  group('Bidding Flow', () {
    testWidgets('Provider submits bid, poster accepts it', (tester) async {
      // ════════════════════════════════════════════════════════════════════
      // PART 1: Provider submits a bid
      // ════════════════════════════════════════════════════════════════════

      // ── Launch app as provider ──────────────────────────────────────────
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
          await tester.tap(find.text('I can help'));
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
          await tester.enterText(nameField, 'Ben Lim');
          await tester.pump();

          final headlineField = find.widgetWithText(
              TextFormField, 'A brief intro about yourself');
          await tester.enterText(headlineField, 'Experienced cleaner');
          await tester.pump();

          await tester.drag(
            find.byType(SingleChildScrollView),
            const Offset(0, -300),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.byType(DropdownButtonFormField<String>));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Bedok').last);
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

      // ── Navigate to Discover tab ──────────────────────────────────────
      await tester.tap(find.text('Discover'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 200),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 15),
      );

      expect(find.text('Discover Tasks'), findsOneWidget,
          reason: 'Should be on Discover Tasks screen');

      // ── Find and tap the seeded task ──────────────────────────────────
      // Scroll to find the task if needed
      if (find.text('Deep clean 3-room HDB').evaluate().isEmpty) {
        await tester.drag(
          find.byType(ListView),
          const Offset(0, -400),
        );
        await tester.pumpAndSettle();
      }

      expect(find.text('Deep clean 3-room HDB'), findsOneWidget,
          reason: 'Seeded task should be visible in Discover list');

      await tester.tap(find.text('Deep clean 3-room HDB'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 200),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 15),
      );

      // ── Verify TaskDetailScreen and Submit Bid button ─────────────────
      expect(find.text('Deep clean 3-room HDB'), findsWidgets,
          reason: 'TaskDetailScreen should show the task title');

      // Provider should see Submit Bid button (task is open, user is not poster)
      expect(find.text('Submit Bid'), findsOneWidget,
          reason: 'Provider should see Submit Bid button on open task');

      // ── Tap Submit Bid to open the sheet ──────────────────────────────
      await tester.tap(find.text('Submit Bid'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 200),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 15),
      );

      // Verify SubmitBidSheet is open
      expect(find.text('Bid Amount (SGD)'), findsOneWidget,
          reason: 'SubmitBidSheet should show bid amount label');
      expect(find.text('Your Proposal'), findsOneWidget,
          reason: 'SubmitBidSheet should show proposal label');

      // ── Fill in bid amount ────────────────────────────────────────────
      final amountField = find.widgetWithText(TextFormField, '0.00');
      await tester.enterText(amountField, '65');
      await tester.pump();

      // ── Fill in proposal message ──────────────────────────────────────
      final proposalField = find.widgetWithText(
        TextFormField,
        'Introduce yourself and explain why you\'re a great fit\u2026',
      );
      await tester.enterText(
        proposalField,
        'I have 5 years experience in cleaning HDB flats.',
      );
      await tester.pump();

      // ── Tap submit button ─────────────────────────────────────────────
      // The submit button inside the sheet is also labelled "Submit Bid"
      // Find the one inside the sheet (last one if there are multiple)
      final submitButtons = find.text('Submit Bid');
      await tester.tap(submitButtons.last);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 200),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 15),
      );

      // ── Verify success feedback ───────────────────────────────────────
      // Sheet should close, snackbar "Bid submitted!" may appear briefly

      // ── Verify bid in Firestore ───────────────────────────────────────
      final firestore = FirebaseFirestore.instance;
      final bidsSnap = await firestore
          .collection('tasks')
          .doc(taskId)
          .collection('bids')
          .where('providerId', isEqualTo: providerUserId)
          .get();

      expect(bidsSnap.docs.length, 1,
          reason: 'Bid document should exist in Firestore');

      final bidDoc = bidsSnap.docs.first.data();
      final bidId = bidsSnap.docs.first.id;
      expect(bidDoc['amount'], 65.0);
      expect(bidDoc['status'], 'pending');
      expect(bidDoc['providerId'], providerUserId);
      expect(bidDoc['message'],
          'I have 5 years experience in cleaning HDB flats.');

      // ── Verify task bidCount incremented ──────────────────────────────
      final taskDoc = await firestore.collection('tasks').doc(taskId).get();
      expect(taskDoc.data()!['bidCount'], 1,
          reason: 'Task bidCount should be incremented to 1');

      // ════════════════════════════════════════════════════════════════════
      // PART 2: Poster accepts the bid
      // ════════════════════════════════════════════════════════════════════

      // ── Sign out provider, sign in as poster ──────────────────────────
      await signOutTestUser();
      await signInTestUser(
        email: 'poster-bid@test.com',
        password: 'test1234',
      );

      // ── Restart app as poster ─────────────────────────────────────────
      await tester.pumpWidget(const ProviderScope(child: NeighbourGoApp()));
      await tester.pump();

      // Wait for splash screen
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

        if (find.text('Set Up Profile').evaluate().isNotEmpty) {
          final nameField =
              find.widgetWithText(TextFormField, 'e.g. Wei Ming');
          await tester.enterText(nameField, 'Alice Tan');
          await tester.pump();

          final headlineField = find.widgetWithText(
              TextFormField, 'A brief intro about yourself');
          await tester.enterText(headlineField, 'Busy mum');
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
          reason: 'Poster should be on HomeScreen');

      // ── Navigate to Discover to find the task ─────────────────────────
      await tester.tap(find.text('Discover'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 200),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 15),
      );

      // Find and tap the task
      if (find.text('Deep clean 3-room HDB').evaluate().isEmpty) {
        await tester.drag(
          find.byType(ListView),
          const Offset(0, -400),
        );
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('Deep clean 3-room HDB'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 200),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 15),
      );

      // ── Verify poster sees the bid ────────────────────────────────────
      // Scroll down to see the BidListSection
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -400),
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 200),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 15),
      );

      // BidListSection shows "Bids received (1)"
      expect(find.text('Bids received (1)'), findsOneWidget,
          reason: 'Poster should see 1 bid received');

      // Verify bid card shows provider name and amount
      expect(find.text('Ben Lim'), findsOneWidget,
          reason: 'Bid card should show provider name');
      expect(find.textContaining('S\$65'), findsOneWidget,
          reason: 'Bid card should show bid amount S\$65');

      // Verify Accept and Reject buttons are visible
      expect(find.text('Accept'), findsOneWidget,
          reason: 'Accept button should be visible for pending bid');
      expect(find.text('Reject'), findsOneWidget,
          reason: 'Reject button should be visible for pending bid');

      // ── Tap Accept on the bid ─────────────────────────────────────────
      await tester.tap(find.text('Accept'));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 200),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 15),
      );

      // ── Verify Firestore updates ──────────────────────────────────────
      // Check bid status changed to accepted
      final updatedBidSnap = await firestore
          .collection('tasks')
          .doc(taskId)
          .collection('bids')
          .doc(bidId)
          .get();

      expect(updatedBidSnap.data()!['status'], 'accepted',
          reason: 'Bid status should be accepted in Firestore');

      // Check task status changed to assigned with provider info
      final updatedTaskDoc =
          await firestore.collection('tasks').doc(taskId).get();
      final updatedTask = updatedTaskDoc.data()!;

      expect(updatedTask['status'], 'assigned',
          reason: 'Task status should be assigned in Firestore');
      expect(updatedTask['assignedProviderId'], providerUserId,
          reason:
              'Task assignedProviderId should match provider user ID');
      expect(updatedTask['assignedProviderName'], 'Ben Lim',
          reason: 'Task assignedProviderName should be Ben Lim');
    });
  });
}
