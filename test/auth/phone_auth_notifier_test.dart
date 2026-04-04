import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neighbourgo/features/auth/data/models/user_model.dart';
import 'package:neighbourgo/features/auth/data/repositories/auth_repository.dart';
import 'package:neighbourgo/features/auth/domain/providers/auth_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Minimal fakes to satisfy AuthRepository constructor
// ─────────────────────────────────────────────────────────────────────────────

class _NoOpAuth extends Fake implements FirebaseAuth {}

class _NoOpFirestore extends Fake implements FirebaseFirestore {}

class FakeUser extends Fake implements User {
  @override
  final String uid;
  @override
  final String? phoneNumber;

  FakeUser({this.uid = 'test-uid', this.phoneNumber = '+6591234567'});
}

class FakeUserCredential extends Fake implements UserCredential {
  @override
  final User? user;

  FakeUserCredential({User? user}) : user = user ?? FakeUser();
}

// ─────────────────────────────────────────────────────────────────────────────
// FakeAuthRepository — overrides all methods used by PhoneAuthNotifier
// ─────────────────────────────────────────────────────────────────────────────

class FakeAuthRepository extends AuthRepository {
  String sendOtpReturnValue = 'fake-verification-id';
  bool sendOtpShouldThrow = false;

  FakeUserCredential verifyOtpReturnValue = FakeUserCredential();
  bool verifyOtpShouldThrow = false;

  UserModel? fetchCurrentUserReturnValue;
  bool createOrUpdateUserCalled = false;

  FakeAuthRepository() : super(auth: _NoOpAuth(), db: _NoOpFirestore());

  @override
  Future<String> sendOtp(String phoneNumber) async {
    if (sendOtpShouldThrow) throw Exception('OTP send failed');
    return sendOtpReturnValue;
  }

  @override
  Future<UserCredential> verifyOtp(
      String verificationId, String smsCode) async {
    if (verifyOtpShouldThrow) throw Exception('Invalid OTP');
    return verifyOtpReturnValue;
  }

  @override
  Future<UserModel?> fetchCurrentUser() async {
    return fetchCurrentUserReturnValue;
  }

  @override
  Future<void> createOrUpdateUser(UserModel user) async {
    createOrUpdateUserCalled = true;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('PhoneAuthState', () {
    test('has correct default values', () {
      const state = PhoneAuthState();
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.verificationId, isNull);
      expect(state.otpSent, isFalse);
    });

    test('copyWith updates specified fields', () {
      const state = PhoneAuthState();
      final updated =
          state.copyWith(isLoading: true, verificationId: 'vid-123');

      expect(updated.isLoading, isTrue);
      expect(updated.verificationId, 'vid-123');
      expect(updated.otpSent, isFalse); // unchanged
      expect(updated.error, isNull); // null clears error
    });

    test('copyWith clears error when null is passed', () {
      final state = const PhoneAuthState().copyWith(error: 'some error');
      expect(state.error, 'some error');

      final cleared = state.copyWith();
      expect(cleared.error, isNull);
    });
  });

  group('PhoneAuthNotifier', () {
    late FakeAuthRepository fakeRepo;
    late PhoneAuthNotifier notifier;

    setUp(() {
      fakeRepo = FakeAuthRepository();
      notifier = PhoneAuthNotifier(fakeRepo);
    });

    test(
        'initial state: isLoading=false, error=null, verificationId=null, otpSent=false',
        () {
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, isNull);
      expect(notifier.state.verificationId, isNull);
      expect(notifier.state.otpSent, isFalse);
    });

    group('sendOtp', () {
      test('sets otpSent=true and verificationId on success', () async {
        await notifier.sendOtp('+6591234567');

        expect(notifier.state.isLoading, isFalse);
        expect(notifier.state.otpSent, isTrue);
        expect(notifier.state.verificationId, 'fake-verification-id');
        expect(notifier.state.error, isNull);
      });

      test('sets error on failure', () async {
        fakeRepo.sendOtpShouldThrow = true;

        await notifier.sendOtp('+6591234567');

        expect(notifier.state.isLoading, isFalse);
        expect(notifier.state.error, isNotNull);
        expect(
          notifier.state.error,
          'Could not send the verification code right now. Please try again.',
        );
        expect(notifier.state.otpSent, isFalse);
      });

      test('maps Firebase phone auth errors to user-facing copy', () async {
        fakeRepo = FakeAuthRepository();
        notifier = PhoneAuthNotifier(fakeRepo);
        fakeRepo.sendOtpShouldThrow = false;
        fakeRepo.sendOtpReturnValue = 'fake-verification-id';

        fakeRepo.sendOtpShouldThrow = false;
        fakeRepo = FakeAuthRepositoryThatThrowsFirebase(
          exception: FirebaseAuthException(code: 'too-many-requests'),
        );
        notifier = PhoneAuthNotifier(fakeRepo);

        await notifier.sendOtp('+6591234567');

        expect(
          notifier.state.error,
          'Too many attempts right now. Please wait a moment and try again.',
        );
      });

      test('clears previous error on new attempt', () async {
        fakeRepo.sendOtpShouldThrow = true;
        await notifier.sendOtp('+6591234567');
        expect(notifier.state.error, isNotNull);

        fakeRepo.sendOtpShouldThrow = false;
        await notifier.sendOtp('+6591234567');
        expect(notifier.state.error, isNull);
        expect(notifier.state.otpSent, isTrue);
      });
    });

    group('verifyOtp', () {
      test('returns true on success', () async {
        await notifier.sendOtp('+6591234567');

        final result = await notifier.verifyOtp('123456');

        expect(result, isTrue);
        expect(notifier.state.isLoading, isFalse);
        expect(notifier.state.error, isNull);
      });

      test('returns false on failure', () async {
        await notifier.sendOtp('+6591234567');
        fakeRepo.verifyOtpShouldThrow = true;

        final result = await notifier.verifyOtp('000000');

        expect(result, isFalse);
        expect(notifier.state.isLoading, isFalse);
        expect(notifier.state.error, 'Invalid OTP. Please try again.');
      });

      test('maps expired OTP errors to user-facing copy', () async {
        fakeRepo = FakeAuthRepositoryThatThrowsFirebase(
          verifyException: FirebaseAuthException(code: 'session-expired'),
        );
        notifier = PhoneAuthNotifier(fakeRepo);

        await notifier.sendOtp('+6591234567');
        final result = await notifier.verifyOtp('000000');

        expect(result, isFalse);
        expect(
          notifier.state.error,
          'This OTP has expired. Please request a new code.',
        );
      });

      test('returns false when no verificationId', () async {
        // Don't call sendOtp — verificationId remains null
        final result = await notifier.verifyOtp('123456');

        expect(result, isFalse);
      });

      test('creates user document for new users', () async {
        fakeRepo.fetchCurrentUserReturnValue = null; // no existing user

        await notifier.sendOtp('+6591234567');
        await notifier.verifyOtp('123456');

        expect(fakeRepo.createOrUpdateUserCalled, isTrue);
      });

      test('does not create user document for existing users', () async {
        fakeRepo.fetchCurrentUserReturnValue =
            const UserModel(uid: 'existing', phone: '+65000');

        await notifier.sendOtp('+6591234567');
        await notifier.verifyOtp('123456');

        expect(fakeRepo.createOrUpdateUserCalled, isFalse);
      });
    });

    test('reset returns to initial state', () async {
      await notifier.sendOtp('+6591234567');
      expect(notifier.state.otpSent, isTrue);
      expect(notifier.state.verificationId, isNotNull);

      notifier.reset();

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, isNull);
      expect(notifier.state.verificationId, isNull);
      expect(notifier.state.otpSent, isFalse);
    });
  });
}

class FakeAuthRepositoryThatThrowsFirebase extends FakeAuthRepository {
  final FirebaseAuthException? exception;
  final FirebaseAuthException? verifyException;

  FakeAuthRepositoryThatThrowsFirebase({
    this.exception,
    this.verifyException,
  });

  @override
  Future<String> sendOtp(String phoneNumber) async {
    if (exception != null) throw exception!;
    return super.sendOtp(phoneNumber);
  }

  @override
  Future<UserCredential> verifyOtp(
    String verificationId,
    String smsCode,
  ) async {
    if (verifyException != null) throw verifyException!;
    return super.verifyOtp(verificationId, smsCode);
  }
}
