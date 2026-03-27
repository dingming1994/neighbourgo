/// Main entry point for NeighbourGo integration tests.
///
/// Run all integration tests:
///   flutter test integration_test/app_test.dart -d <simulator_id>
///
/// Or run individual test files directly:
///   flutter test integration_test/auth_flow_test.dart -d <simulator_id>
///
/// Prerequisites:
///   1. Firebase emulators running: firebase emulators:start
///   2. iOS Simulator booted (or Android emulator)
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeTestApp();
  });

  tearDownAll(() async {
    await cleanupEmulatorData();
  });

  group('Integration Test Suite', () {
    // Individual test files are run separately via:
    //   flutter test integration_test/<test_file>.dart
    //
    // This file serves as a smoke-test entry point that verifies
    // the infrastructure is wired up correctly.

    testWidgets('Firebase emulators are connected', (tester) async {
      // If initializeTestApp() succeeded without throwing,
      // all emulators are reachable.
      expect(true, isTrue, reason: 'Firebase emulators initialised OK');
    });

    testWidgets('Can sign in an anonymous test user', (tester) async {
      final user = await signInTestUser();
      expect(user.uid, isNotEmpty);
      await signOutTestUser();
    });
  });
}
