/// Integration test: Chat Messaging Flow
///
/// Verifies two users can exchange messages through the chat system after a
/// bid is accepted. Seeds a task (status=assigned), an accepted bid, both
/// users, and a chat document. Then the poster sends a message and we verify
/// it appears in the UI and Firestore.
///
/// Run:
///   flutter test integration_test/chat_flow_test.dart -d <simulator_id>
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
  const taskId = 'chat-test-task-1';
  late String chatId;

  setUpAll(() async {
    await initializeTestApp();

    // Create poster user
    final posterUser = await signInTestUser(
      email: 'poster-chat@test.com',
      password: 'test1234',
    );
    posterUserId = posterUser.uid;
    await seedUser(posterUserId, testPosterUser(uid: posterUserId));

    // Sign out poster so we can create the provider user
    await signOutTestUser();

    // Create provider user
    final providerUser = await signInTestUser(
      email: 'provider-chat@test.com',
      password: 'test1234',
    );
    providerUserId = providerUser.uid;
    await seedUser(providerUserId, testProviderUser(uid: providerUserId));

    // Build deterministic chat ID (sorts UIDs lexicographically)
    final sortedUids = [posterUserId, providerUserId]..sort();
    chatId = '${taskId}_${sortedUids.join('_')}';

    // Seed a task (status=assigned) posted by posterUser, assigned to providerUser
    await seedTask(taskId, {
      ...testCleaningTask(
        taskId: taskId,
        posterId: posterUserId,
        posterName: 'Alice Tan',
      ),
      'status': 'assigned',
      'assignedProviderId': providerUserId,
      'assignedProviderName': 'Ben Lim',
      'bidCount': 1,
    });

    // Seed an accepted bid
    final firestore = FirebaseFirestore.instance;
    await firestore
        .collection('tasks')
        .doc(taskId)
        .collection('bids')
        .doc('bid-chat-1')
        .set({
      'bidId': 'bid-chat-1',
      'taskId': taskId,
      'providerId': providerUserId,
      'providerName': 'Ben Lim',
      'amount': 65.0,
      'message': 'I have 5 years experience in cleaning HDB flats.',
      'status': 'accepted',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Seed a chat document linking posterUser and providerUser
    await seedChat(chatId, {
      'chatId': chatId,
      'taskId': taskId,
      'taskTitle': 'Deep clean 3-room HDB',
      'participants': sortedUids,
      'lastMessage': null,
      'lastMessageTime': null,
      'unreadCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Sign out provider; we'll sign in as poster for the test
    await signOutTestUser();

    // Sign in as poster
    await signInTestUser(
      email: 'poster-chat@test.com',
      password: 'test1234',
    );
  });

  tearDownAll(() async {
    await signOutTestUser();
    await cleanupEmulatorData();
  });

  group('Chat Messaging Flow', () {
    testWidgets('Poster sends a message and it appears in chat and Firestore',
        (tester) async {
      // ════════════════════════════════════════════════════════════════════
      // PART 1: Navigate to Messages tab and find the chat
      // ════════════════════════════════════════════════════════════════════

      // ── Launch app as poster ──────────────────────────────────────────
      await tester.pumpWidget(const ProviderScope(child: NeighbourGoApp()));
      await tester.pump();

      // Wait for splash screen (2s delay + navigation)
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 200),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 15),
      );

      // ── Handle login/onboarding if needed ────────────────────────────
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

        // Profile setup
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
          reason: 'Should be on HomeScreen with bottom nav');

      // ── Navigate to Messages tab ────────────────────────────────────
      await tester.tap(find.text('Messages'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 200),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 15),
      );

      // Verify ChatListScreen shows with 'Messages' title
      expect(find.text('Messages'), findsWidgets,
          reason: 'Should be on ChatListScreen with Messages title');

      // ── Verify the chat with the task title is visible ──────────────
      expect(find.text('Deep clean 3-room HDB'), findsOneWidget,
          reason: 'Chat list should show the chat with task title');

      // ════════════════════════════════════════════════════════════════════
      // PART 2: Open the chat thread
      // ════════════════════════════════════════════════════════════════════

      await tester.tap(find.text('Deep clean 3-room HDB'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 200),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 15),
      );

      // Verify ChatThreadScreen shows task title in AppBar
      expect(find.text('Deep clean 3-room HDB'), findsOneWidget,
          reason: 'ChatThreadScreen should show task title');
      expect(find.text('Task chat'), findsOneWidget,
          reason: 'ChatThreadScreen should show "Task chat" subtitle');

      // Verify empty state or message input is displayed
      // The input field with placeholder "Type a message…" should be visible
      expect(find.text('Type a message\u2026'), findsOneWidget,
          reason: 'Message input field should be visible');

      // ════════════════════════════════════════════════════════════════════
      // PART 3: Send a message
      // ════════════════════════════════════════════════════════════════════

      // Type the message
      final messageInput = find.byType(TextField);
      await tester.enterText(messageInput, 'Hello, when can you start?');
      await tester.pump();

      // Tap send button (Icons.send_rounded)
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 200),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 15),
      );

      // ── Verify message appears in the chat ──────────────────────────
      expect(find.text('Hello, when can you start?'), findsOneWidget,
          reason: 'Sent message should appear in the chat thread');

      // ════════════════════════════════════════════════════════════════════
      // PART 4: Verify Firestore state
      // ════════════════════════════════════════════════════════════════════

      final firestore = FirebaseFirestore.instance;

      // Verify message document exists in chats/{chatId}/messages/
      final messagesSnap = await firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();

      expect(messagesSnap.docs.length, 1,
          reason: 'One message should exist in Firestore');

      final messageDoc = messagesSnap.docs.first.data();
      expect(messageDoc['text'], 'Hello, when can you start?');
      expect(messageDoc['senderId'], posterUserId);

      // Verify chat document lastMessage updated
      final chatDoc =
          await firestore.collection('chats').doc(chatId).get();
      expect(chatDoc.data()!['lastMessage'], 'Hello, when can you start?',
          reason: 'Chat lastMessage should be updated');

      // ════════════════════════════════════════════════════════════════════
      // PART 5: Navigate back and verify last message preview
      // ════════════════════════════════════════════════════════════════════

      // Tap back to return to ChatListScreen
      await tester.tap(find.byType(BackButton));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 200),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 15),
      );

      // Verify last message preview shows the sent message
      expect(find.text('Hello, when can you start?'), findsOneWidget,
          reason:
              'Chat list should show last message preview');
    });
  });
}
