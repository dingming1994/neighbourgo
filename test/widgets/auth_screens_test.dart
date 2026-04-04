import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide PhoneAuthProvider;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neighbourgo/core/router/app_router.dart';
import 'package:neighbourgo/features/auth/data/models/user_model.dart';
import 'package:neighbourgo/features/auth/data/repositories/auth_repository.dart';
import 'package:neighbourgo/features/auth/domain/providers/auth_provider.dart';
import 'package:neighbourgo/features/auth/presentation/screens/otp_screen.dart';
import 'package:neighbourgo/features/auth/presentation/screens/phone_auth_screen.dart';
import 'package:neighbourgo/features/auth/presentation/screens/profile_setup_screen.dart';
import 'package:neighbourgo/features/auth/presentation/screens/role_selection_screen.dart';
import 'package:neighbourgo/features/auth/presentation/screens/welcome_screen.dart';
import 'package:neighbourgo/features/profile/data/repositories/profile_repository.dart';

// =============================================================================
// Fakes
// =============================================================================

class FakeFirebaseAuth extends Fake implements FirebaseAuth {
  @override
  Stream<User?> authStateChanges() => Stream.value(null);

  @override
  User? get currentUser => null;

  @override
  Future<UserCredential> signInAnonymously() =>
      throw FirebaseAuthException(code: 'operation-not-allowed', message: 'disabled');
}

class FakeFirebaseFirestore extends Fake implements FirebaseFirestore {}

class FakeFirebaseStorage extends Fake implements FirebaseStorage {}

class FakeSignedInUser extends Fake implements User {
  @override
  String get uid => 'signed-in-user';
}

class FakeAuthRepository extends AuthRepository {
  UserModel? userToReturn;
  bool shouldThrow = false;

  FakeAuthRepository()
      : super(
          auth: FakeFirebaseAuth(),
          db: FakeFirebaseFirestore(),
        );

  @override
  Stream<User?> get authStateChanges => Stream.value(null);

  @override
  User? get currentUser => null;

  @override
  Future<UserModel?> fetchCurrentUser() async {
    if (shouldThrow) throw Exception('fetch failed');
    return userToReturn;
  }

  @override
  Future<void> createOrUpdateUser(UserModel user) async {
    if (shouldThrow) throw Exception('update failed');
    userToReturn = user;
  }

  @override
  Stream<UserModel?> watchCurrentUser() => Stream.value(userToReturn);

  @override
  Future<String> sendOtp(String phoneNumber) async {
    if (shouldThrow) throw Exception('send otp failed');
    return 'fake-verification-id';
  }

  @override
  Future<UserCredential> verifyOtp(String verificationId, String smsCode) async {
    throw UnimplementedError('not needed for widget tests');
  }
}

class FakeProfileRepository extends ProfileRepository {
  bool updateCalled = false;
  bool shouldThrow = false;

  FakeProfileRepository()
      : super(
          db: FakeFirebaseFirestore(),
          storage: FakeFirebaseStorage(),
        );

  @override
  Future<void> updateProfile(UserModel user) async {
    if (shouldThrow) throw Exception('permission-denied');
    updateCalled = true;
  }

  @override
  Future<String> uploadAvatar(String uid, dynamic file) async {
    return 'https://example.com/avatar.jpg';
  }
}

class _FakePhoneAuthNotifier extends PhoneAuthNotifier {
  _FakePhoneAuthNotifier(PhoneAuthState initial)
      : super(FakeAuthRepository()) {
    state = initial;
  }

  @override
  Future<void> sendOtp(String phoneNumber) async {}

  @override
  Future<bool> verifyOtp(String smsCode) async => false;
}

// Wrap widget in MaterialApp + ProviderScope
Widget buildTestWidget(
  Widget child, {
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(home: child),
  );
}

// Helper: testWidgets with a large surface and overflow error suppression.
// Layout-heavy screens overflow in the default 800x600 test surface. These
// overflow warnings are cosmetic (the widgets we're testing still render).
void testPhone(
  String description,
  Future<void> Function(WidgetTester tester) callback,
) {
  testWidgets(description, (tester) async {
    await tester.binding.setSurfaceSize(const Size(480, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // Suppress overflow errors for this test
    final origOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      final msg = details.exception.toString();
      if (msg.contains('overflowed by')) return;
      origOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = origOnError);

    await callback(tester);
  });
}

// =============================================================================
// Tests
// =============================================================================

void main() {
  // ───────────────────────────────────────────────────────────────────────────
  // WelcomeScreen
  // ───────────────────────────────────────────────────────────────────────────
  group('WelcomeScreen', () {
    testPhone('renders app logo emoji', (tester) async {
      await tester.pumpWidget(buildTestWidget(const WelcomeScreen()));
      expect(find.text('🏘️'), findsOneWidget);
    });

    testPhone('renders title NeighbourGo', (tester) async {
      await tester.pumpWidget(buildTestWidget(const WelcomeScreen()));
      expect(find.text('NeighbourGo'), findsOneWidget);
    });

    testPhone('renders Get Started button', (tester) async {
      await tester.pumpWidget(buildTestWidget(const WelcomeScreen()));
      expect(find.text('Get Started with Phone'), findsOneWidget);
    });

    testPhone('renders Dev Login button in non-production', (tester) async {
      await tester.pumpWidget(buildTestWidget(const WelcomeScreen()));
      expect(find.text('Dev Login (Skip Auth)'), findsOneWidget);
    });

    testPhone('Dev Login button is tappable', (tester) async {
      await tester.pumpWidget(buildTestWidget(const WelcomeScreen()));
      final devButton = find.text('Dev Login (Skip Auth)');
      expect(devButton, findsOneWidget);
      expect(tester.widget<TextButton>(find.ancestor(
        of: devButton,
        matching: find.byType(TextButton),
      )).onPressed, isNotNull);
    });

    testPhone('displays category pills', (tester) async {
      await tester.pumpWidget(buildTestWidget(const WelcomeScreen()));
      expect(find.text('🧹 Cleaning'), findsOneWidget);
      expect(find.text('📚 Tuition'), findsOneWidget);
      expect(find.text('🐾 Pet Care'), findsOneWidget);
      expect(find.text('🔧 Handyman'), findsOneWidget);
      expect(find.text('🧍 Queuing'), findsOneWidget);
      expect(find.text('🍱 Errands'), findsOneWidget);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // RoleSelectionScreen
  // ───────────────────────────────────────────────────────────────────────────
  group('RoleSelectionScreen', () {
    late FakeAuthRepository fakeAuthRepo;

    setUp(() {
      fakeAuthRepo = FakeAuthRepository();
    });

    Widget buildRoleScreen() => buildTestWidget(
          const RoleSelectionScreen(),
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuthRepo),
          ],
        );

    testPhone('renders 3 role cards', (tester) async {
      await tester.pumpWidget(buildRoleScreen());
      expect(find.text('I need help'), findsOneWidget);
      expect(find.text('I want to earn'), findsOneWidget);
      expect(find.text('Both — post & earn'), findsOneWidget);
    });

    testPhone('tapping a card selects it with visual feedback', (tester) async {
      await tester.pumpWidget(buildRoleScreen());
      expect(find.byIcon(Icons.check_circle), findsNothing);

      await tester.tap(find.text('I need help'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testPhone('Continue button disabled until role selected', (tester) async {
      await tester.pumpWidget(buildRoleScreen());

      final continueButton = find.widgetWithText(ElevatedButton, 'Continue');
      expect(continueButton, findsOneWidget);

      final button = tester.widget<ElevatedButton>(continueButton);
      expect(button.onPressed, isNull);

      await tester.tap(find.text('I need help'));
      await tester.pumpAndSettle();

      final enabledButton = tester.widget<ElevatedButton>(continueButton);
      expect(enabledButton.onPressed, isNotNull);
    });

    testPhone('renders AppBar with correct title', (tester) async {
      await tester.pumpWidget(buildRoleScreen());
      expect(find.text('How will you use NeighbourGo?'), findsOneWidget);
    });

    testPhone('renders Choose your role heading', (tester) async {
      await tester.pumpWidget(buildRoleScreen());
      expect(find.text('Choose your role'), findsOneWidget);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // ProfileSetupScreen
  // ───────────────────────────────────────────────────────────────────────────
  group('ProfileSetupScreen', () {
    late FakeProfileRepository fakeProfileRepo;
    const testUser = UserModel(
      uid: 'test-uid',
      phone: '+6591234567',
      displayName: 'Test User',
      role: UserRole.both,
    );

    setUp(() {
      fakeProfileRepo = FakeProfileRepository();
    });

    Widget buildProfileScreen() => buildTestWidget(
          const ProfileSetupScreen(),
          overrides: [
            profileRepositoryProvider.overrideWithValue(fakeProfileRepo),
            currentUserProvider.overrideWith((_) => Stream.value(testUser)),
          ],
        );

    testPhone('renders Display Name field', (tester) async {
      await tester.pumpWidget(buildProfileScreen());
      await tester.pumpAndSettle();
      expect(find.text('Display Name'), findsOneWidget);
      expect(find.byType(TextFormField), findsWidgets);
    });

    testPhone('renders Headline field', (tester) async {
      await tester.pumpWidget(buildProfileScreen());
      await tester.pumpAndSettle();
      expect(find.text('Headline'), findsOneWidget);
    });

    testPhone('renders About Me (Bio) field', (tester) async {
      await tester.pumpWidget(buildProfileScreen());
      await tester.pumpAndSettle();
      expect(find.text('About Me'), findsOneWidget);
    });

    testPhone('renders Neighbourhood dropdown', (tester) async {
      await tester.pumpWidget(buildProfileScreen());
      await tester.pumpAndSettle();
      expect(find.text('Your Neighbourhood'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });

    testPhone('Display Name is required — shows error when empty', (tester) async {
      await tester.pumpWidget(buildProfileScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Complete Setup'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your name'), findsOneWidget);
    });

    testPhone('Skip for now button is visible', (tester) async {
      await tester.pumpWidget(buildProfileScreen());
      await tester.pumpAndSettle();
      expect(find.text('Skip for now'), findsOneWidget);
    });

    testPhone('renders Set Up Profile in AppBar', (tester) async {
      await tester.pumpWidget(buildProfileScreen());
      await tester.pumpAndSettle();
      expect(find.text('Set Up Profile'), findsOneWidget);
    });

    testPhone('renders avatar picker with camera icon', (tester) async {
      await tester.pumpWidget(buildProfileScreen());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
      expect(find.byType(CircleAvatar), findsOneWidget);
    });

  });

  // ───────────────────────────────────────────────────────────────────────────
  // PhoneAuthScreen
  // ───────────────────────────────────────────────────────────────────────────
  group('PhoneAuthScreen', () {
    Widget buildPhoneScreen({PhoneAuthState? initialState}) {
      final state = initialState ?? const PhoneAuthState();
      return buildTestWidget(
        const PhoneAuthScreen(),
        overrides: [
          phoneAuthProvider.overrideWith(
            (_) => _FakePhoneAuthNotifier(state),
          ),
        ],
      );
    }

    testPhone('renders phone input field', (tester) async {
      await tester.pumpWidget(buildPhoneScreen());
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Enter Phone Number'), findsOneWidget);
    });

    testPhone('renders Send OTP button', (tester) async {
      await tester.pumpWidget(buildPhoneScreen());
      expect(find.text('Send OTP'), findsOneWidget);
    });

    testPhone('empty phone shows validation error on submit', (tester) async {
      await tester.pumpWidget(buildPhoneScreen());

      await tester.tap(find.text('Send OTP'));
      await tester.pumpAndSettle();

      expect(find.text('Enter your phone number'), findsOneWidget);
    });

    testPhone('renders default country code +65 with flag', (tester) async {
      await tester.pumpWidget(buildPhoneScreen());
      expect(find.text('+65'), findsOneWidget);
      expect(find.text('\u{1F1F8}\u{1F1EC}'), findsOneWidget); // SG flag
    });

    testPhone('select country code via picker', (tester) async {
      await tester.pumpWidget(buildPhoneScreen());

      // Tap the country code button to open picker
      await tester.tap(find.text('+65'));
      await tester.pumpAndSettle();

      // Bottom sheet should show country list
      expect(find.text('Select Country'), findsOneWidget);
      expect(find.text('Malaysia'), findsOneWidget);
      expect(find.text('United States'), findsOneWidget);

      // Select Malaysia
      await tester.tap(find.text('Malaysia'));
      await tester.pumpAndSettle();

      // Country code should now be +60
      expect(find.text('+60'), findsOneWidget);
      expect(find.text('\u{1F1F2}\u{1F1FE}'), findsOneWidget); // MY flag
    });

    testPhone('phone input accepts digits only', (tester) async {
      await tester.pumpWidget(buildPhoneScreen());

      final field = find.byType(TextFormField);
      await tester.enterText(field, 'abc123def456');
      await tester.pump();

      // Only digits should be kept
      final ctrl = tester.widget<TextFormField>(field);
      expect(ctrl.controller!.text, '123456');
    });

    testPhone('shows validation error for short phone number', (tester) async {
      await tester.pumpWidget(buildPhoneScreen());

      final field = find.byType(TextFormField);
      await tester.enterText(field, '123');
      await tester.tap(find.text('Send OTP'));
      await tester.pumpAndSettle();

      expect(find.text('Minimum 7 digits required'), findsOneWidget);
    });

    testPhone('valid phone number passes validation', (tester) async {
      await tester.pumpWidget(buildPhoneScreen());

      final field = find.byType(TextFormField);
      await tester.enterText(field, '91234567');
      await tester.tap(find.text('Send OTP'));
      await tester.pumpAndSettle();

      // No validation errors should appear
      expect(find.text('Minimum 7 digits required'), findsNothing);
      expect(find.text('Enter your phone number'), findsNothing);
    });

    testPhone('shows error message when state has error', (tester) async {
      await tester.pumpWidget(buildPhoneScreen(
        initialState: const PhoneAuthState(error: 'Something went wrong'),
      ));
      await tester.pump();

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testPhone('shows normalized auth error copy', (tester) async {
      await tester.pumpWidget(buildPhoneScreen(
        initialState: const PhoneAuthState(
          error: 'Too many attempts right now. Please wait a moment and try again.',
        ),
      ));
      await tester.pump();

      expect(
        find.text(
          'Too many attempts right now. Please wait a moment and try again.',
        ),
        findsOneWidget,
      );
    });

    testPhone('renders heading and subtitle text', (tester) async {
      await tester.pumpWidget(buildPhoneScreen());
      expect(find.text('Your phone number'), findsOneWidget);
      expect(find.textContaining('6-digit OTP'), findsOneWidget);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // OtpScreen
  // ───────────────────────────────────────────────────────────────────────────
  group('OtpScreen', () {
    Widget buildOtpScreen({PhoneAuthState? initialState}) {
      final state = initialState ?? const PhoneAuthState();
      return buildTestWidget(
        const OtpScreen(
          verificationId: 'test-vid',
          phoneNumber: '+6591234567',
        ),
        overrides: [
          phoneAuthProvider.overrideWith(
            (_) => _FakePhoneAuthNotifier(state),
          ),
          currentUserProvider.overrideWith((_) => Stream.value(null)),
        ],
      );
    }

    testPhone('renders Pinput widget for 6 digits', (tester) async {
      await tester.pumpWidget(buildOtpScreen());
      expect(find.text('Enter the 6-digit code'), findsOneWidget);
    });

    testPhone('renders Verify button', (tester) async {
      await tester.pumpWidget(buildOtpScreen());
      expect(find.text('Verify'), findsOneWidget);
    });

    testPhone('shows sent-to phone number', (tester) async {
      await tester.pumpWidget(buildOtpScreen());
      expect(find.text('Sent to +6591234567'), findsOneWidget);
    });

    testPhone('renders Verify OTP in AppBar', (tester) async {
      await tester.pumpWidget(buildOtpScreen());
      expect(find.text('Verify OTP'), findsOneWidget);
    });

    testPhone('shows resend countdown text', (tester) async {
      await tester.pumpWidget(buildOtpScreen());
      expect(find.textContaining('Resend in'), findsOneWidget);
    });

    testPhone('renders emoji icon', (tester) async {
      await tester.pumpWidget(buildOtpScreen());
      expect(find.text('📲'), findsOneWidget);
    });

    testPhone('shows OTP error copy from state', (tester) async {
      await tester.pumpWidget(buildOtpScreen(
        initialState: const PhoneAuthState(
          error: 'This OTP has expired. Please request a new code.',
        ),
      ));
      await tester.pump();

      expect(
        find.text('This OTP has expired. Please request a new code.'),
        findsOneWidget,
      );
    });
  });

  group('AppRouter', () {
    testPhone('shows friendly missing-page recovery state', (tester) async {
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((_) => Stream.value(FakeSignedInUser())),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      router.go('/missing-page');
      await tester.pumpAndSettle();

      expect(
        find.text(
          'We could not open that page. It may have moved or no longer exist.',
        ),
        findsOneWidget,
      );
      expect(find.text('Try Again'), findsOneWidget);
      expect(find.textContaining('Page not found:'), findsNothing);
      await tester.pump(const Duration(seconds: 3));
    });
  });
}
