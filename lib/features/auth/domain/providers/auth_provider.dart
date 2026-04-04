import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

String _normalizePhoneAuthError(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-phone-number':
        return 'That phone number looks invalid. Please check it and try again.';
      case 'too-many-requests':
        return 'Too many attempts right now. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'Could not reach the network. Check your connection and try again.';
      case 'operation-not-allowed':
        return 'Phone sign-in is unavailable right now. Please try again later.';
    }
  }

  final message = error.toString().toLowerCase();
  if (message.contains('invalid-phone-number')) {
    return 'That phone number looks invalid. Please check it and try again.';
  }
  if (message.contains('too-many-requests')) {
    return 'Too many attempts right now. Please wait a moment and try again.';
  }
  if (message.contains('network')) {
    return 'Could not reach the network. Check your connection and try again.';
  }

  return 'Could not send the verification code right now. Please try again.';
}

String _normalizeOtpError(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-verification-code':
      case 'invalid-verification-id':
        return 'Invalid OTP. Please try again.';
      case 'session-expired':
        return 'This OTP has expired. Please request a new code.';
      case 'network-request-failed':
        return 'Could not verify the code right now. Check your connection and try again.';
    }
  }

  final message = error.toString().toLowerCase();
  if (message.contains('session-expired')) {
    return 'This OTP has expired. Please request a new code.';
  }

  return 'Invalid OTP. Please try again.';
}

// ─────────────────────────────────────────────────────────────────────────────
// Auth state stream (Firebase User or null)
// ─────────────────────────────────────────────────────────────────────────────
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

// ─────────────────────────────────────────────────────────────────────────────
// Current user document (Firestore)
// ─────────────────────────────────────────────────────────────────────────────
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final auth = ref.watch(authStateProvider).valueOrNull;
  if (auth == null) return Stream.value(null);

  // Fallback: if Firestore doc doesn't exist yet (e.g. anonymous dev login),
  // synthesise a minimal UserModel so the app doesn't spin forever.
  return ref.watch(authRepositoryProvider).watchCurrentUser().map((user) {
    if (user != null) return user;
    return UserModel(
      uid: auth.uid,
      phone: auth.phoneNumber ?? '+6500000000',
      displayName: auth.displayName ?? 'User',
      role: UserRole.both,
    );
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Phone Auth Notifier
// ─────────────────────────────────────────────────────────────────────────────
class PhoneAuthState {
  final bool     isLoading;
  final String?  error;
  final String?  verificationId;
  final bool     otpSent;

  const PhoneAuthState({
    this.isLoading     = false,
    this.error,
    this.verificationId,
    this.otpSent       = false,
  });

  PhoneAuthState copyWith({
    bool?   isLoading,
    String? error,
    String? verificationId,
    bool?   otpSent,
  }) => PhoneAuthState(
    isLoading:      isLoading      ?? this.isLoading,
    error:          error,          // null clears error
    verificationId: verificationId ?? this.verificationId,
    otpSent:        otpSent        ?? this.otpSent,
  );
}

class PhoneAuthNotifier extends StateNotifier<PhoneAuthState> {
  final AuthRepository _repo;

  PhoneAuthNotifier(this._repo) : super(const PhoneAuthState());

  Future<void> sendOtp(String phoneNumber) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final vid = await _repo.sendOtp(phoneNumber);
      if (vid == '__auto_verified__') {
        // iOS test number or Android instant-verify — user is already signed in.
        // Signal auto-verified so the UI can skip OTP screen.
        state = state.copyWith(isLoading: false, otpSent: false, verificationId: vid);
      } else {
        state = state.copyWith(isLoading: false, verificationId: vid, otpSent: true);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _normalizePhoneAuthError(e),
      );
    }
  }

  Future<bool> verifyOtp(String smsCode) async {
    if (state.verificationId == null) return false;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final cred = await _repo.verifyOtp(state.verificationId!, smsCode);
      // Create user doc if first sign-in
      if (cred.user != null) {
        final existing = await _repo.fetchCurrentUser();
        if (existing == null) {
          await _repo.createOrUpdateUser(UserModel(
            uid:   cred.user!.uid,
            phone: cred.user!.phoneNumber ?? '',
          ));
        }
      }
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _normalizeOtpError(e),
      );
      return false;
    }
  }

  void reset() => state = const PhoneAuthState();
}

final phoneAuthProvider = StateNotifierProvider<PhoneAuthNotifier, PhoneAuthState>(
  (ref) => PhoneAuthNotifier(ref.watch(authRepositoryProvider)),
);

// ─────────────────────────────────────────────────────────────────────────────
// Sign out action
// ─────────────────────────────────────────────────────────────────────────────
final signOutProvider = Provider((ref) => () async {
  await ref.read(authRepositoryProvider).signOut();
});
