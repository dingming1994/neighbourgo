import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_model.dart';
import '../../../../core/constants/app_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Repository
// ─────────────────────────────────────────────────────────────────────────────
class AuthRepository {
  final FirebaseAuth      _auth;
  final FirebaseFirestore _db;

  AuthRepository({FirebaseAuth? auth, FirebaseFirestore? db})
      : _auth = auth ?? FirebaseAuth.instance,
        _db   = db   ?? FirebaseFirestore.instance;

  // ── Observe auth state ────────────────────────────────────────────────────
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // ── Phone OTP ─────────────────────────────────────────────────────────────
  /// Step 1: Send OTP to phone number (e.g. "+6591234567")
  Future<String> sendOtp(String phoneNumber) async {
    final completer = Completer<String>();

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 120),
      verificationCompleted: (PhoneAuthCredential cred) async {
        // Auto-retrieval on Android / instant verify on iOS test numbers.
        // Sign in and signal with a special marker so the notifier skips OTP.
        try {
          await _auth.signInWithCredential(cred);
          if (!completer.isCompleted) completer.complete('__auto_verified__');
        } catch (_) {
          // ignore — codeSent will follow on failure
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        if (!completer.isCompleted) {
          completer.completeError(Exception('OTP send failed: ${e.message}'));
        }
      },
      codeSent: (String vid, int? resendToken) {
        if (!completer.isCompleted) {
          completer.complete(vid);
        }
      },
      codeAutoRetrievalTimeout: (String vid) {
        // Timeout — if we still don't have a result, complete with the vid
        if (!completer.isCompleted) {
          if (vid.isNotEmpty) {
            completer.complete(vid);
          } else {
            completer.completeError(Exception('Verification timed out'));
          }
        }
      },
    );

    return completer.future;
  }

  /// Step 2: Verify OTP code
  Future<UserCredential> verifyOtp(String verificationId, String smsCode) async {
    final cred = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return _auth.signInWithCredential(cred);
  }

  // ── User document ─────────────────────────────────────────────────────────
  /// Create or update user document in Firestore
  Future<void> createOrUpdateUser(UserModel user) async {
    final ref = _db.collection(AppConstants.usersCol).doc(user.uid);
    final snap = await ref.get();
    final now = DateTime.now();

    if (!snap.exists) {
      // New user — serialize nested Freezed objects properly
      final data = user.toJson();
      if (data['stats'] is ProviderStats) {
        data['stats'] = (data['stats'] as ProviderStats).toJson();
      }
      // Remove null nested objects that Firestore can't handle
      data.removeWhere((k, v) => v == null);
      await ref.set({
        ...data,
        'createdAt':    Timestamp.fromDate(now),
        'lastActiveAt': Timestamp.fromDate(now),
      });
    } else {
      // Update last active
      await ref.update({'lastActiveAt': Timestamp.fromDate(now)});
    }
  }

  /// Update the role field on an existing user document.
  Future<void> updateUserRole(String uid, String role) async {
    await _db.collection(AppConstants.usersCol).doc(uid).update({
      'role': role,
      'lastActiveAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Fetch current user document
  Future<UserModel?> fetchCurrentUser() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final snap = await _db.collection(AppConstants.usersCol).doc(uid).get();
    if (!snap.exists) return null;
    return UserModelExt.fromFirestore(snap);
  }

  /// Stream current user document (real-time)
  Stream<UserModel?> watchCurrentUser() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(null);
    return _db.collection(AppConstants.usersCol).doc(uid).snapshots().map(
      (snap) => snap.exists ? UserModelExt.fromFirestore(snap) : null,
    );
  }

  // ── Dev bypass login (simulator/testing only) ─────────────────────────────
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return await _auth.createUserWithEmailAndPassword(email: email, password: password);
      }
      rethrow;
    }
  }

  // ── Sign out ──────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ── Delete account ────────────────────────────────────────────────────────
  Future<void> deleteAccount() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _db.collection(AppConstants.usersCol).doc(uid).update({
        'isDeactivated': true,
        'deactivatedAt': Timestamp.now(),
      });
    }
    await _auth.currentUser?.delete();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Riverpod Providers
// ─────────────────────────────────────────────────────────────────────────────
final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());
