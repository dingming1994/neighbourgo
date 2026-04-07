import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neighbourgo/features/auth/data/models/user_model.dart';
import 'package:neighbourgo/features/auth/domain/providers/auth_provider.dart';
import 'package:neighbourgo/features/profile/data/models/profile_model.dart';
import 'package:neighbourgo/features/profile/data/repositories/profile_repository.dart';
import 'package:neighbourgo/features/profile/presentation/screens/photo_gallery_screen.dart';
import 'package:neighbourgo/features/reviews/presentation/screens/submit_review_screen.dart';

class FakeFirebaseFirestore extends Fake implements FirebaseFirestore {}

class FakeFirebaseStorage extends Fake implements FirebaseStorage {}

class FakeProfileRepository extends ProfileRepository {
  FakeProfileRepository()
      : super(
          db: FakeFirebaseFirestore(),
          storage: FakeFirebaseStorage(),
        );

  bool shouldThrowOnSubmitReview = false;
  bool shouldThrowOnUpdatePhotos = false;

  @override
  Future<ReviewModel?> fetchExistingReview({
    required String reviewedUserId,
    required String taskId,
    required String reviewerId,
  }) async {
    return null;
  }

  @override
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
    if (shouldThrowOnSubmitReview) {
      throw Exception('permission-denied');
    }
  }

  @override
  Future<void> updatePhotosArray(String uid, List<ProfilePhoto> photos) async {
    if (shouldThrowOnUpdatePhotos) {
      throw Exception('permission-denied');
    }
  }
}

UserModel _testUser({
  String uid = 'test-uid',
  String displayName = 'Test User',
  UserRole role = UserRole.provider,
  List<ProfilePhoto> photos = const [],
}) =>
    UserModel(
      uid: uid,
      phone: '+6591234567',
      displayName: displayName,
      role: role,
      photos: photos,
    );

Widget buildTestWidget(
  Widget child, {
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(home: child),
  );
}

void testScreen(
  String description,
  Future<void> Function(WidgetTester tester) callback,
) {
  testWidgets(description, (tester) async {
    await tester.binding.setSurfaceSize(const Size(480, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

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

void main() {
  group('SubmitReviewScreen', () {
    testScreen('shows friendly error when review submission fails', (tester) async {
      final fakeProfileRepo = FakeProfileRepository()
        ..shouldThrowOnSubmitReview = true;
      final user = _testUser(role: UserRole.poster);

      await tester.pumpWidget(buildTestWidget(
        const SubmitReviewScreen(
          taskId: 'task-1',
          reviewedUserId: 'provider-1',
          reviewedUserName: 'Ben Cleaner',
          taskCategory: 'cleaning',
        ),
        overrides: [
          currentUserProvider.overrideWith((_) => Stream.value(user)),
          profileRepositoryProvider.overrideWithValue(fakeProfileRepo),
        ],
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.star_rounded).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit Review'));
      await tester.pump();

      expect(find.text('Could not submit your review right now.'), findsOneWidget);
    });
  });

  group('PhotoGalleryScreen', () {
    testScreen('shows friendly error when updating cover photo fails',
        (tester) async {
      final fakeProfileRepo = FakeProfileRepository()
        ..shouldThrowOnUpdatePhotos = true;
      final user = _testUser(
        photos: [
          ProfilePhoto(
            id: 'photo-1',
            url: 'https://example.com/photo.jpg',
            categoryId: 'cleaning',
            uploadedAt: DateTime(2026, 4, 1),
          ),
        ],
      );

      await tester.pumpWidget(buildTestWidget(
        const PhotoGalleryScreen(),
        overrides: [
          currentUserProvider.overrideWith((_) => Stream.value(user)),
          profileRepositoryProvider.overrideWithValue(fakeProfileRepo),
        ],
      ));
      await tester.pumpAndSettle();

      final photoCard = find.byWidgetPredicate(
        (widget) => widget is GestureDetector && widget.onLongPress != null,
      );
      await tester.longPress(photoCard.first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Set as Cover Photo'));
      await tester.pump();

      expect(find.text('Could not update your cover photo right now.'),
          findsOneWidget);
    });
  });
}
