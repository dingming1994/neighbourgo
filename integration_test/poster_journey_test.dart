/// Integration test: Job Poster Full Journey
///
/// Complete poster lifecycle from registration to task completion:
///   1. App Launch — splash → welcome
///   2. Register with email
///   3. Select poster role
///   4. Setup profile
///   5. Post a task (5-step flow)
///   6. Verify task in Firestore
///   7. Seed bid from pre-seeded provider
///   8. View bids on task detail
///   9. Accept bid
///  10. Chat with provider
///  11. Mark task as complete
///  12. Final state verification
///
/// Run:
///   flutter test integration_test/poster_journey_test.dart -d <simulator_id>
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

  late String providerUserId;
  late final FirebaseFirestore firestore;

  setUpAll(() async {
    await initializeTestApp();
    firestore = FirebaseFirestore.instance;

    // Pre-seed a provider user (Ben Lim) for cross-user interactions
    final providerUser = await signInTestUser(
      email: 'provider-seed@neighbourgo.com',
      password: 'test123456',
    );
    providerUserId = providerUser.uid;
    await seedUser(providerUserId, testProviderUser(uid: providerUserId));

    // Sign out so the test starts fresh (poster registers from scratch)
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

  group('Poster Full Journey', () {
    testWidgets(
        'Register → Post Task → View Bids → Accept → Chat → Complete',
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
      await tester.enterText(emailField, 'poster-test@neighbourgo.com');
      await tester.pump();

      final passwordField =
          find.widgetWithText(TextFormField, 'Password');
      await tester.enterText(passwordField, 'test123456');
      await tester.pump();

      await tester.tap(find.text('Continue'));

      // Wait longer for auth + navigation — the router needs time to process
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await settle(tester, seconds: 5);

      // Debug: print what's on screen
      debugPrint('=== WIDGETS AFTER EMAIL REGISTER ===');
      debugPrint('Role select? ${find.text("How will you use NeighbourGo?").evaluate().length}');
      debugPrint('Welcome? ${find.text("Continue with Email").evaluate().length}');
      debugPrint('Home? ${find.text("Home").evaluate().length}');
      debugPrint('Splash? ${find.text("NeighbourGo").evaluate().length}');
      debugPrint('Profile setup? ${find.text("Set Up Profile").evaluate().length}');
      debugPrint('Email login? ${find.text("Email Login").evaluate().length}');

      // ════════════════════════════════════════════════════════════════════════
      // STEP 3 — Select Role: poster ("I need help")
      // ════════════════════════════════════════════════════════════════════════

      expect(find.text('How will you use NeighbourGo?'), findsOneWidget,
          reason: 'Should navigate to role selection');

      await tester.tap(find.text('I need help'));
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
      await tester.enterText(nameField, 'Alice Tan');
      await tester.pump();

      final headlineField = find.widgetWithText(
          TextFormField, 'A brief intro about yourself');
      await tester.enterText(headlineField, 'Busy mum looking for help');
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
      await tester.tap(find.text('Ang Mo Kio').last);
      await tester.pumpAndSettle();

      // Scroll down to Complete Setup button
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Complete Setup'));
      await settle(tester, seconds: 3);

      // Give extra time for profile save + navigation
      if (find.textContaining('Hi, Alice!').evaluate().isEmpty) {
        await settle(tester, seconds: 3);
      }
      expect(find.textContaining('Hi, Alice!'), findsOneWidget,
          reason: 'Home screen should greet Alice');
      expect(find.text('Post a Task'), findsOneWidget,
          reason: 'Home screen should show Post a Task button');

      // ════════════════════════════════════════════════════════════════════════
      // STEP 5 — Post Task (5-step flow)
      // ════════════════════════════════════════════════════════════════════════

      // Tap Post via "Post a Task" button or bottom nav FAB
      if (find.text('Post a Task').evaluate().isNotEmpty) {
        await tester.tap(find.text('Post a Task'));
      } else {
        await tester.tap(find.byIcon(Icons.add));
      }
      await settle(tester, seconds: 2);

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
      await tester.enterText(titleField, 'Deep clean 3-room HDB');
      await tester.pump();

      final descField = find.widgetWithText(TextFormField,
          'Describe the task in detail \u2014 size of flat, special requirements, pets, etc.');
      await tester.enterText(descField,
          'Need thorough cleaning for my 3-room HDB flat including kitchen, bathrooms, and all bedrooms.');
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

      // Step 4: Budget
      expect(find.text("What's your budget?"), findsOneWidget);
      final minBudgetField =
          find.widgetWithText(TextFormField, 'S\$ ').first;
      await tester.enterText(minBudgetField, '50');
      await tester.pump();

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Step 5: Review & Post
      expect(find.text('Review & Post'), findsOneWidget);
      expect(find.text('Deep clean 3-room HDB'), findsOneWidget);
      expect(find.textContaining('S\$50'), findsOneWidget);

      await tester.tap(find.text('Post Task'));
      await settle(tester, seconds: 2);

      // ════════════════════════════════════════════════════════════════════════
      // STEP 6 — Verify task in Firestore
      // ════════════════════════════════════════════════════════════════════════

      final tasksSnap = await firestore
          .collection('tasks')
          .where('title', isEqualTo: 'Deep clean 3-room HDB')
          .get();

      expect(tasksSnap.docs.length, 1,
          reason: 'Task should exist in Firestore');

      final taskId = tasksSnap.docs.first.id;
      final taskData = tasksSnap.docs.first.data();
      expect(taskData['status'], 'open');
      expect(taskData['categoryId'], 'cleaning');
      expect(taskData['budgetMin'], 50.0);
      expect(taskData['neighbourhood'], 'Ang Mo Kio');

      // Capture poster UID for later verification
      final posterUserId = taskData['posterId'] as String;

      // ════════════════════════════════════════════════════════════════════════
      // STEP 7 — Seed bid from pre-seeded provider (Ben Lim)
      // Use emulator REST API to bypass security rules (admin write)
      // ════════════════════════════════════════════════════════════════════════

      await seedBidViaRest(
        taskId: taskId,
        bidId: 'seeded-bid-1',
        data: {
          'bidId': 'seeded-bid-1',
          'taskId': taskId,
          'providerId': providerUserId,
          'providerName': 'Ben Lim',
          'amount': 65.0,
          'message': 'I have 5 years experience in cleaning HDB flats.',
          'status': 'pending',
          'createdAt': DateTime.now().toIso8601String(),
        },
      );

      // Update bidCount on the task (poster can update their own task)
      await firestore.collection('tasks').doc(taskId).update({
        'bidCount': 1,
      });

      // ════════════════════════════════════════════════════════════════════════
      // STEP 8 — View bids: navigate to task detail
      // After posting, the app navigated to task detail via context.go().
      // We seeded the bid via REST. Navigate away and back to refresh.
      // ════════════════════════════════════════════════════════════════════════

      // Navigate to home first (resets to shell route)
      final element = tester.element(find.byType(Scaffold).first);
      GoRouter.of(element).go('/home');
      await settle(tester, seconds: 2);

      // Navigate to Discover tab
      await tester.tap(find.text('Discover'));
      await settle(tester);

      // Find and tap the posted task
      if (find.text('Deep clean 3-room HDB').evaluate().isEmpty) {
        final listView = find.byType(ListView);
        if (listView.evaluate().isNotEmpty) {
          await tester.drag(listView, const Offset(0, -400));
          await tester.pumpAndSettle();
        }
      }

      expect(find.text('Deep clean 3-room HDB'), findsOneWidget,
          reason: 'Posted task should appear in Discover');

      await tester.tap(find.text('Deep clean 3-room HDB'));
      await settle(tester);

      // Scroll down to bid section
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -400),
      );
      await settle(tester);

      // Verify bid is visible with amount and provider info
      expect(find.text('Bids received (1)'), findsOneWidget,
          reason: 'Should show 1 bid');
      expect(find.textContaining('S\$65'), findsOneWidget,
          reason: 'Bid amount should show S\$65');
      expect(find.text('Accept'), findsOneWidget,
          reason: 'Accept button should be visible');
      expect(find.text('Reject'), findsOneWidget,
          reason: 'Reject button should be visible');

      // ════════════════════════════════════════════════════════════════════════
      // STEP 9 — Accept bid
      // ════════════════════════════════════════════════════════════════════════

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

      // ════════════════════════════════════════════════════════════════════════
      // STEP 10 — Chat: tap 'Message Provider', send message
      // ════════════════════════════════════════════════════════════════════════

      // Navigate away and back to refresh the task detail with updated status
      final ctx10 = tester.element(find.byType(Scaffold).first);
      GoRouter.of(ctx10).go('/home');
      await settle(tester, seconds: 2);
      GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/tasks/$taskId');
      await settle(tester, seconds: 2);

      // Scroll to find Message Provider button
      if (find.text('Message Provider').evaluate().isEmpty &&
          find.byType(SingleChildScrollView).evaluate().isNotEmpty) {
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -300),
        );
        await settle(tester);
      }

      expect(find.text('Message Provider'), findsOneWidget,
          reason: 'Message Provider button should be visible');

      await tester.tap(find.text('Message Provider'));
      await settle(tester, seconds: 5);

      // Verify ChatThreadScreen — check for chat-specific elements
      // If chat failed to open, check for error snackbar
      if (find.byType(TextField).evaluate().isEmpty) {
        // Not on chat screen yet — try again
        await settle(tester, seconds: 5);
      }

      final messageInput = find.byType(TextField);
      expect(messageInput, findsOneWidget,
          reason: 'Chat message input should be visible');
      await tester.enterText(
          messageInput, 'Hi Ben, when can you come?');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.send_rounded));
      await settle(tester, seconds: 2);

      // Verify message appears in chat
      expect(find.text('Hi Ben, when can you come?'), findsOneWidget,
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

      // ════════════════════════════════════════════════════════════════════════
      // STEP 11 — Complete task: navigate back, find task, mark complete
      // ════════════════════════════════════════════════════════════════════════

      // Navigate back from chat to task detail, then to home
      await tester.tap(find.byType(BackButton));
      await settle(tester);

      // Navigate directly to task detail (assigned tasks don't show in Discover)
      final ctx11 = tester.element(find.byType(Scaffold).first);
      GoRouter.of(ctx11).go('/tasks/$taskId');
      await settle(tester, seconds: 2);

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

      // Verify Firestore: task completed with timestamp
      final completedTask =
          await firestore.collection('tasks').doc(taskId).get();
      final completedData = completedTask.data()!;
      expect(completedData['status'], 'completed',
          reason: 'Task status should be completed');
      expect(completedData['completedAt'], isNotNull,
          reason: 'completedAt timestamp should be set');

      // ════════════════════════════════════════════════════════════════════════
      // STEP 12 — Final state verification
      // ════════════════════════════════════════════════════════════════════════

      // Navigate to Home via GoRouter (task detail is outside shell)
      final ctx12 = tester.element(find.byType(Scaffold).first);
      GoRouter.of(ctx12).go('/home');
      await settle(tester, seconds: 2);

      // Completed task should NOT appear in Active Tasks
      if (find.text('Active Tasks').evaluate().isNotEmpty) {
        expect(find.text('Deep clean 3-room HDB'), findsNothing,
            reason:
                'Completed task should not appear in Active Tasks');
      }

      // Verify profile shows 'Alice Tan'
      await tester.tap(find.text('Profile'));
      await settle(tester);

      expect(find.text('Alice Tan'), findsOneWidget,
          reason: 'Profile should show Alice Tan');

      // Final Firestore consistency checks
      final finalTask =
          await firestore.collection('tasks').doc(taskId).get();
      final ft = finalTask.data()!;
      expect(ft['status'], 'completed');
      expect(ft['posterId'], posterUserId);
      expect(ft['assignedProviderId'], providerUserId);
      expect(ft['completedAt'], isNotNull);

      final finalBids = await firestore
          .collection('tasks')
          .doc(taskId)
          .collection('bids')
          .get();
      expect(finalBids.docs.length, 1);
      expect(finalBids.docs.first.data()['status'], 'accepted');

      final finalChat =
          await firestore.collection('chats').doc(chatId).get();
      expect(finalChat.exists, isTrue,
          reason: 'Chat document should still exist');
    });
  });
}
