import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neighbourgo/features/auth/data/models/user_model.dart';
import 'package:neighbourgo/features/auth/data/repositories/auth_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Firebase Auth fakes
// ─────────────────────────────────────────────────────────────────────────────

class FakeUser extends Fake implements User {
  @override
  final String uid;
  @override
  final String? phoneNumber;
  @override
  final String? displayName;

  FakeUser({
    this.uid = 'test-uid',
    this.phoneNumber = '+6591234567',
    this.displayName = 'Test User',
  });

  @override
  Future<void> delete() async {}
}

class FakeUserCredential extends Fake implements UserCredential {
  @override
  final User? user;

  FakeUserCredential({User? user}) : user = user ?? FakeUser();
}

class FakeFirebaseAuth extends Fake implements FirebaseAuth {
  User? _currentUser;
  bool signOutCalled = false;
  String? lastVerifyPhoneNumber;
  AuthCredential? lastSignInCredential;
  final FakeUserCredential _signInResult;

  String codeSentVid = 'test-verification-id';

  FakeFirebaseAuth({User? currentUser, FakeUserCredential? signInResult})
      : _currentUser = currentUser,
        _signInResult = signInResult ?? FakeUserCredential();

  @override
  User? get currentUser => _currentUser;

  @override
  Stream<User?> authStateChanges() => Stream.value(_currentUser);

  @override
  Future<void> signOut() async {
    signOutCalled = true;
    _currentUser = null;
  }

  @override
  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    lastSignInCredential = credential;
    return _signInResult;
  }

  @override
  Future<void> verifyPhoneNumber({
    String? phoneNumber,
    PhoneMultiFactorInfo? multiFactorInfo,
    required PhoneVerificationCompleted verificationCompleted,
    required PhoneVerificationFailed verificationFailed,
    required PhoneCodeSent codeSent,
    required PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout,
    String? autoRetrievedSmsCodeForTesting,
    Duration timeout = const Duration(seconds: 30),
    int? forceResendingToken,
    MultiFactorSession? multiFactorSession,
  }) async {
    lastVerifyPhoneNumber = phoneNumber;
    codeSent(codeSentVid, null);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Firestore fakes
// ─────────────────────────────────────────────────────────────────────────────

class FakeDocumentSnapshot extends Fake
    implements DocumentSnapshot<Map<String, dynamic>> {
  @override
  final String id;
  final bool _exists;
  final Map<String, dynamic>? _data;

  FakeDocumentSnapshot({
    required this.id,
    bool exists = false,
    Map<String, dynamic>? data,
  })  : _exists = exists,
        _data = data;

  @override
  bool get exists => _exists;

  @override
  Map<String, dynamic>? data() => _data;
}

class FakeDocumentReference extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  @override
  final String id;
  Map<String, dynamic>? _storedData;
  bool _exists;

  Map<String, dynamic>? lastSetData;
  Map<Object, Object?>? lastUpdateData;

  FakeDocumentReference({
    required this.id,
    Map<String, dynamic>? data,
    bool exists = false,
  })  : _storedData = data,
        _exists = exists;

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get(
      [GetOptions? options]) async {
    return FakeDocumentSnapshot(id: id, exists: _exists, data: _storedData);
  }

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    lastSetData = data;
    _storedData = data;
    _exists = true;
  }

  @override
  Future<void> update(Map<Object, Object?> data) async {
    lastUpdateData = data;
  }

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) {
    return Stream.value(
      FakeDocumentSnapshot(id: id, exists: _exists, data: _storedData),
    );
  }
}

class FakeCollectionReference extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  final Map<String, FakeDocumentReference> docs = {};

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    return docs.putIfAbsent(path!, () => FakeDocumentReference(id: path));
  }

  void addDoc(String id,
      {Map<String, dynamic>? data, bool exists = false}) {
    docs[id] = FakeDocumentReference(id: id, data: data, exists: exists);
  }
}

class FakeFirebaseFirestore extends Fake implements FirebaseFirestore {
  final Map<String, FakeCollectionReference> _collections = {};

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return _collections.putIfAbsent(
        collectionPath, () => FakeCollectionReference());
  }

  FakeCollectionReference getCollection(String path) {
    return _collections.putIfAbsent(path, () => FakeCollectionReference());
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('AuthRepository', () {
    group('signOut', () {
      test('calls FirebaseAuth.signOut', () async {
        final auth = FakeFirebaseAuth();
        final repo = AuthRepository(auth: auth, db: FakeFirebaseFirestore());

        await repo.signOut();

        expect(auth.signOutCalled, isTrue);
      });
    });

    group('sendOtp', () {
      test('calls verifyPhoneNumber and returns verificationId', () async {
        final auth = FakeFirebaseAuth();
        auth.codeSentVid = 'my-verification-id';
        final repo = AuthRepository(auth: auth, db: FakeFirebaseFirestore());

        final vid = await repo.sendOtp('+6591234567');

        expect(auth.lastVerifyPhoneNumber, '+6591234567');
        expect(vid, 'my-verification-id');
      });
    });

    group('verifyOtp', () {
      test('calls signInWithCredential and returns UserCredential', () async {
        final auth = FakeFirebaseAuth();
        final repo = AuthRepository(auth: auth, db: FakeFirebaseFirestore());

        final result = await repo.verifyOtp('test-vid', '123456');

        expect(auth.lastSignInCredential, isNotNull);
        expect(result, isA<UserCredential>());
        expect(result.user, isNotNull);
      });
    });

    group('createOrUpdateUser', () {
      test('writes new user doc to Firestore users collection', () async {
        final db = FakeFirebaseFirestore();
        final repo = AuthRepository(auth: FakeFirebaseAuth(), db: db);

        final user = UserModel(uid: 'user-123', phone: '+6591234567');
        await repo.createOrUpdateUser(user);

        final docRef = db.getCollection('users').docs['user-123']!;
        expect(docRef.lastSetData, isNotNull);
        expect(docRef.lastSetData!['uid'], 'user-123');
        expect(docRef.lastSetData!['phone'], '+6591234567');
        expect(docRef.lastSetData!['createdAt'], isA<Timestamp>());
        expect(docRef.lastSetData!['lastActiveAt'], isA<Timestamp>());
      });

      test('updates lastActiveAt for existing user', () async {
        final db = FakeFirebaseFirestore();
        db.getCollection('users').addDoc(
          'user-123',
          data: {'uid': 'user-123', 'phone': '+65000'},
          exists: true,
        );
        final repo = AuthRepository(auth: FakeFirebaseAuth(), db: db);

        final user = UserModel(uid: 'user-123', phone: '+6591234567');
        await repo.createOrUpdateUser(user);

        final docRef = db.getCollection('users').docs['user-123']!;
        expect(docRef.lastUpdateData, isNotNull);
        expect(docRef.lastUpdateData!['lastActiveAt'], isA<Timestamp>());
      });
    });

    group('fetchCurrentUser', () {
      test('returns null when no authenticated user', () async {
        final auth = FakeFirebaseAuth(currentUser: null);
        final repo = AuthRepository(auth: auth, db: FakeFirebaseFirestore());

        final result = await repo.fetchCurrentUser();

        expect(result, isNull);
      });

      test('reads from Firestore and returns UserModel', () async {
        final auth =
            FakeFirebaseAuth(currentUser: FakeUser(uid: 'user-123'));
        final db = FakeFirebaseFirestore();
        db.getCollection('users').addDoc(
          'user-123',
          data: {'phone': '+6591234567', 'role': 'poster'},
          exists: true,
        );
        final repo = AuthRepository(auth: auth, db: db);

        final result = await repo.fetchCurrentUser();

        expect(result, isNotNull);
        expect(result!.uid, 'user-123');
        expect(result.phone, '+6591234567');
      });

      test('returns null when user doc does not exist', () async {
        final auth =
            FakeFirebaseAuth(currentUser: FakeUser(uid: 'missing-uid'));
        final db = FakeFirebaseFirestore();
        final repo = AuthRepository(auth: auth, db: db);

        final result = await repo.fetchCurrentUser();

        expect(result, isNull);
      });
    });

    group('watchCurrentUser', () {
      test('returns Stream with null when no user', () {
        final auth = FakeFirebaseAuth(currentUser: null);
        final repo = AuthRepository(auth: auth, db: FakeFirebaseFirestore());

        expect(repo.watchCurrentUser(), emits(null));
      });

      test('returns a Stream<UserModel?> for authenticated user', () {
        final auth =
            FakeFirebaseAuth(currentUser: FakeUser(uid: 'user-123'));
        final db = FakeFirebaseFirestore();
        db.getCollection('users').addDoc(
          'user-123',
          data: {'phone': '+6591234567', 'role': 'poster'},
          exists: true,
        );
        final repo = AuthRepository(auth: auth, db: db);

        expect(
          repo.watchCurrentUser(),
          emits(isA<UserModel>()
              .having((u) => u.uid, 'uid', 'user-123')
              .having((u) => u.phone, 'phone', '+6591234567')),
        );
      });

      test('emits null when user doc does not exist', () {
        final auth =
            FakeFirebaseAuth(currentUser: FakeUser(uid: 'no-doc'));
        final db = FakeFirebaseFirestore();
        final repo = AuthRepository(auth: auth, db: db);

        expect(repo.watchCurrentUser(), emits(null));
      });
    });

    group('authStateChanges', () {
      test('returns stream from FirebaseAuth', () {
        final auth =
            FakeFirebaseAuth(currentUser: FakeUser(uid: 'user-1'));
        final repo = AuthRepository(auth: auth, db: FakeFirebaseFirestore());

        expect(
          repo.authStateChanges,
          emits(isA<User>().having((u) => u.uid, 'uid', 'user-1')),
        );
      });
    });

    group('currentUser', () {
      test('returns null when not authenticated', () {
        final auth = FakeFirebaseAuth(currentUser: null);
        final repo = AuthRepository(auth: auth, db: FakeFirebaseFirestore());

        expect(repo.currentUser, isNull);
      });

      test('returns User when authenticated', () {
        final auth =
            FakeFirebaseAuth(currentUser: FakeUser(uid: 'u1'));
        final repo = AuthRepository(auth: auth, db: FakeFirebaseFirestore());

        expect(repo.currentUser, isNotNull);
        expect(repo.currentUser!.uid, 'u1');
      });
    });
  });
}
