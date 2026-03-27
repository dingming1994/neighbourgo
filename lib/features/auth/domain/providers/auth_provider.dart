import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

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
      state = state.copyWith(isLoading: false, verificationId: vid, otpSent: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
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
      state = state.copyWith(isLoading: false, error: 'Invalid OTP. Please try again.');
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
