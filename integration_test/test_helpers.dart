import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'firebase_emulator_config.dart';

/// Whether the test app has already been initialised in this process.
bool _initialized = false;

/// Initialise Firebase and connect every SDK to its local emulator.
///
/// Safe to call multiple times — subsequent calls are no-ops.
Future<void> initializeTestApp() async {
  if (_initialized) return;

  // Firebase.initializeApp is already called by the app's main(),
  // but integration tests start their own isolate, so we must init here.
  await Firebase.initializeApp();

  // Connect Auth emulator
  await FirebaseAuth.instance.useAuthEmulator(
    emulatorHost,
    authEmulatorPort,
  );

  // Connect Firestore emulator
  FirebaseFirestore.instance.useFirestoreEmulator(
    emulatorHost,
    firestoreEmulatorPort,
  );

  // Connect Storage emulator
  await FirebaseStorage.instance.useStorageEmulator(
    emulatorHost,
    storageEmulatorPort,
  );

  _initialized = true;
}

/// Create an anonymous user via the Auth emulator and return the [User].
///
/// If [email] and [password] are provided, creates an email/password account
/// instead (useful when you need two distinct users in the same test).
Future<User> signInTestUser({
  String? email,
  String? password,
}) async {
  final auth = FirebaseAuth.instance;

  if (email != null && password != null) {
    try {
      final cred = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return cred.user!;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        final cred = await auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        return cred.user!;
      }
      rethrow;
    }
  }

  // Default: anonymous sign-in
  final cred = await auth.signInAnonymously();
  return cred.user!;
}

/// Sign out the current user.
Future<void> signOutTestUser() async {
  await FirebaseAuth.instance.signOut();
}

/// Delete **all** documents from the given top-level Firestore collections.
///
/// Call this in `tearDown` / `tearDownAll` to keep the emulator clean between
/// test groups.
Future<void> cleanupEmulatorData({
  List<String> collections = const [
    'users',
    'tasks',
    'bids',
    'chats',
    'messages',
    'reviews',
    'payments',
    'notifications',
  ],
}) async {
  final firestore = FirebaseFirestore.instance;

  for (final name in collections) {
    final snap = await firestore.collection(name).get();
    for (final doc in snap.docs) {
      // Also delete known sub-collections (e.g. chats/{id}/messages)
      if (name == 'chats') {
        final msgSnap =
            await doc.reference.collection('messages').get();
        for (final msg in msgSnap.docs) {
          await msg.reference.delete();
        }
      }
      await doc.reference.delete();
    }
  }
}

/// Pump the widget tree and wait for animations / async frames to settle.
///
/// Useful after navigating or tapping buttons that trigger transitions.
Future<void> pumpAndSettle(
  WidgetTester tester, {
  Duration duration = const Duration(milliseconds: 100),
  Duration timeout = const Duration(seconds: 10),
}) async {
  await tester.pumpAndSettle(
    duration,
    EnginePhase.sendSemanticsUpdate,
    timeout,
  );
}
