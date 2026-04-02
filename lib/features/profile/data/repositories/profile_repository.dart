import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/image_validator.dart';
import '../../../auth/data/models/user_model.dart';
import '../models/profile_model.dart';

class ProfileRepository {
  final FirebaseFirestore _db;
  final FirebaseStorage   _storage;
  final _uuid = const Uuid();

  ProfileRepository({FirebaseFirestore? db, FirebaseStorage? storage})
      : _db      = db      ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  // ── Read ──────────────────────────────────────────────────────────────────
  Stream<UserModel?> watchProfile(String uid) =>
      _db.collection(AppConstants.usersCol).doc(uid).snapshots().map(
        (s) => s.exists ? UserModelExt.fromFirestore(s) : null,
      );

  Future<UserModel?> fetchProfile(String uid) async {
    final snap = await _db.collection(AppConstants.usersCol).doc(uid).get();
    return snap.exists ? UserModelExt.fromFirestore(snap) : null;
  }

  // ── Update profile ────────────────────────────────────────────────────────
  Future<void> updateProfile(UserModel user) async {
    final data = user.toJson()
      ..remove('uid')
      ..['updatedAt'] = Timestamp.now()
      ..['completenessScore'] = user.completeness;

    // Ensure nested Freezed objects are serialized to Maps
    if (data['stats'] != null && data['stats'] is! Map) {
      data['stats'] = (data['stats'] as dynamic).toJson();
    }
    // Remove null values that Firestore may reject
    data.removeWhere((k, v) => v == null);

    await _db.collection(AppConstants.usersCol).doc(user.uid).update(data);
  }

  // ── Avatar upload ─────────────────────────────────────────────────────────
  Future<String> uploadAvatar(String uid, File file) async {
    final validationError = ImageValidator.validate(file);
    if (validationError != null) throw Exception(validationError);

    final ext = file.path.split('.').last;
    final ref = _storage.ref('${AppConstants.profilePhotosPath}/$uid/avatar.$ext');
    final task = await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/${ext == 'jpg' ? 'jpeg' : ext}'),
    );
    return task.ref.getDownloadURL();
  }

  // ── Profile photo gallery ─────────────────────────────────────────────────
  /// Upload a single photo to the gallery, returns updated photo with URL
  Future<ProfilePhoto> uploadGalleryPhoto({
    required String uid,
    required File   file,
    String? caption,
    String? categoryId,
    bool    isCover = false,
  }) async {
    final validationError = ImageValidator.validate(file);
    if (validationError != null) throw Exception(validationError);

    final photoId = _uuid.v4();
    final ext     = file.path.split('.').last;
    final ref     = _storage.ref(
      '${AppConstants.profilePhotosPath}/$uid/gallery/$photoId.$ext',
    );
    final task = await ref.putFile(file,
      SettableMetadata(contentType: 'image/${ext == 'jpg' ? 'jpeg' : ext}'),
    );
    final url = await task.ref.getDownloadURL();

    return ProfilePhoto(
      id:         photoId,
      url:        url,
      caption:    caption,
      categoryId: categoryId,
      isCover:    isCover,
      uploadedAt: DateTime.now(),
    );
  }

  /// Add a photo to the user's gallery in Firestore
  Future<void> addGalleryPhoto(String uid, ProfilePhoto photo) async {
    await _db.collection(AppConstants.usersCol).doc(uid).update({
      'photos': FieldValue.arrayUnion([photo.toJson()]),
    });
  }

  /// Remove a photo from gallery
  Future<void> removeGalleryPhoto(String uid, ProfilePhoto photo) async {
    // Delete from storage
    try {
      final ref = _storage.refFromURL(photo.url);
      await ref.delete();
    } catch (_) {}

    await _db.collection(AppConstants.usersCol).doc(uid).update({
      'photos': FieldValue.arrayRemove([photo.toJson()]),
    });
  }

  /// Reorder / update photos array (used for drag-and-drop reorder)
  Future<void> updatePhotosArray(String uid, List<ProfilePhoto> photos) async {
    await _db.collection(AppConstants.usersCol).doc(uid).update({
      'photos': photos.map((p) => p.toJson()).toList(),
    });
  }

  /// Update a category showcase block
  Future<void> updateShowcase(String uid, CategoryShowcase showcase) async {
    final userDoc = await _db.collection(AppConstants.usersCol).doc(uid).get();
    final user    = UserModelExt.fromFirestore(userDoc);
    final updated = [
      ...user.categoryShowcases.where((s) => s.categoryId != showcase.categoryId),
      showcase,
    ];
    await _db.collection(AppConstants.usersCol).doc(uid).update({
      'categoryShowcases': updated.map((s) => s.toJson()).toList(),
    });
  }

  // ── Skill tags ────────────────────────────────────────────────────────────
  Future<void> addSkillTag(String uid, String tag) async {
    await _db.collection(AppConstants.usersCol).doc(uid).update({
      'skillTags': FieldValue.arrayUnion([tag]),
    });
  }

  Future<void> removeSkillTag(String uid, String tag) async {
    await _db.collection(AppConstants.usersCol).doc(uid).update({
      'skillTags': FieldValue.arrayRemove([tag]),
    });
  }

  // ── Reviews ───────────────────────────────────────────────────────────────
  Stream<List<ReviewModel>> watchReviews(String uid, {int limit = 20}) =>
      _db.collection(AppConstants.usersCol)
          .doc(uid)
          .collection(AppConstants.reviewsCol)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((snap) => snap.docs.map((d) => ReviewModelExt.fromFirestore(d)).toList());

  /// Check if a review from [reviewerId] already exists for [taskId] on user [reviewedUserId].
  Future<bool> hasExistingReview({
    required String reviewedUserId,
    required String taskId,
    required String reviewerId,
  }) async {
    final snap = await _db
        .collection(AppConstants.usersCol)
        .doc(reviewedUserId)
        .collection(AppConstants.reviewsCol)
        .where('taskId', isEqualTo: taskId)
        .where('reviewerId', isEqualTo: reviewerId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  /// Fetch an existing review from [reviewerId] for [taskId] on user [reviewedUserId].
  Future<ReviewModel?> fetchExistingReview({
    required String reviewedUserId,
    required String taskId,
    required String reviewerId,
  }) async {
    final snap = await _db
        .collection(AppConstants.usersCol)
        .doc(reviewedUserId)
        .collection(AppConstants.reviewsCol)
        .where('taskId', isEqualTo: taskId)
        .where('reviewerId', isEqualTo: reviewerId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return ReviewModelExt.fromFirestore(snap.docs.first);
  }

  /// Submit a review, throwing if a duplicate already exists.
  Future<void> submitReview({
    required String reviewedUserId,
    required String reviewerId,
    required String reviewerName,
    String? reviewerAvatarUrl,
    required String taskId,
    required String taskCategory,
    required double rating,
    String? comment,
    required List<String> skillEndorsements,
  }) async {
    final exists = await hasExistingReview(
      reviewedUserId: reviewedUserId,
      taskId: taskId,
      reviewerId: reviewerId,
    );
    if (exists) {
      throw Exception('You have already reviewed this task');
    }

    await _db
        .collection(AppConstants.usersCol)
        .doc(reviewedUserId)
        .collection(AppConstants.reviewsCol)
        .add({
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'reviewerAvatarUrl': reviewerAvatarUrl,
      'reviewedUserId': reviewedUserId,
      'taskId': taskId,
      'taskCategory': taskCategory,
      'rating': rating,
      'comment': comment,
      'skillEndorsements': skillEndorsements,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addProviderReply(String uid, String reviewId, String reply) async {
    await _db.collection(AppConstants.usersCol)
        .doc(uid)
        .collection(AppConstants.reviewsCol)
        .doc(reviewId)
        .update({'providerReply': reply});
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────
final profileRepositoryProvider = Provider<ProfileRepository>(
  (_) => ProfileRepository(),
);

