import 'package:flutter_test/flutter_test.dart';
import 'package:neighbourgo/features/profile/data/models/profile_model.dart';

void main() {
  group('ReviewModel', () {
    final fullJson = {
      'id': 'rev1',
      'reviewerId': 'userA',
      'reviewerName': 'Alice',
      'reviewerAvatarUrl': 'https://example.com/alice.jpg',
      'reviewedUserId': 'userB',
      'taskId': 'task1',
      'taskCategory': 'cleaning',
      'rating': 4.5,
      'comment': 'Great work!',
      'skillEndorsements': ['punctual', 'thorough'],
      'providerReply': 'Thank you!',
      'createdAt': '2026-03-28T12:00:00.000',
    };

    test('fromJson/toJson roundtrip', () {
      final review = ReviewModel.fromJson(fullJson);
      final json = review.toJson();
      final restored = ReviewModel.fromJson(json);
      expect(restored, review);
    });

    test('skillEndorsements defaults to empty list', () {
      final review = ReviewModel.fromJson({
        'id': 'r1',
        'reviewerId': 'u1',
        'reviewerName': 'Alice',
        'reviewedUserId': 'u2',
        'taskId': 't1',
        'taskCategory': 'cleaning',
        'rating': 5.0,
        'createdAt': '2026-03-28T00:00:00.000',
      });
      expect(review.skillEndorsements, isEmpty);
    });

    test('optional fields default to null', () {
      final review = ReviewModel(
        id: 'r1',
        reviewerId: 'u1',
        reviewerName: 'Alice',
        reviewedUserId: 'u2',
        taskId: 't1',
        taskCategory: 'cleaning',
        rating: 4.0,
        createdAt: DateTime(2026, 3, 28),
      );
      expect(review.reviewerAvatarUrl, isNull);
      expect(review.comment, isNull);
      expect(review.providerReply, isNull);
    });

    test('all fields populated correctly', () {
      final review = ReviewModel.fromJson(fullJson);
      expect(review.id, 'rev1');
      expect(review.reviewerId, 'userA');
      expect(review.reviewerName, 'Alice');
      expect(review.reviewerAvatarUrl, 'https://example.com/alice.jpg');
      expect(review.reviewedUserId, 'userB');
      expect(review.taskId, 'task1');
      expect(review.taskCategory, 'cleaning');
      expect(review.rating, 4.5);
      expect(review.comment, 'Great work!');
      expect(review.skillEndorsements, ['punctual', 'thorough']);
      expect(review.providerReply, 'Thank you!');
    });
  });
}
