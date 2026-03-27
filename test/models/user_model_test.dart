import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:neighbourgo/features/auth/data/models/user_model.dart';

void main() {
  group('UserRole', () {
    test('has exactly 3 values', () {
      expect(UserRole.values.length, 3);
    });

    test('contains poster, provider, both', () {
      expect(UserRole.values, contains(UserRole.poster));
      expect(UserRole.values, contains(UserRole.provider));
      expect(UserRole.values, contains(UserRole.both));
    });
  });

  group('VerificationBadge', () {
    test('has exactly 8 values', () {
      expect(VerificationBadge.values.length, 8);
    });

    test('label returns correct strings', () {
      expect(VerificationBadge.phoneVerified.label, 'Phone Verified');
      expect(VerificationBadge.singpassVerified.label, 'SingPass Verified');
      expect(VerificationBadge.idVerified.label, 'ID Verified');
      expect(VerificationBadge.policeCleared.label, 'Police Clearance');
      expect(VerificationBadge.firstAidCertified.label, 'First Aid Certified');
      expect(VerificationBadge.petSocietyMember.label, 'Pet Society Member');
      expect(VerificationBadge.proProvider.label, 'Pro Provider');
      expect(VerificationBadge.repeatHireStar.label, 'Repeat Hire Star');
    });

    test('emoji returns non-empty strings', () {
      for (final badge in VerificationBadge.values) {
        expect(badge.emoji, isNotEmpty);
      }
    });

    test('emoji returns correct values', () {
      expect(VerificationBadge.phoneVerified.emoji, '📱');
      expect(VerificationBadge.singpassVerified.emoji, '🇸🇬');
      expect(VerificationBadge.proProvider.emoji, '⭐');
    });
  });

  group('ProfilePhoto', () {
    test('fromJson/toJson roundtrip', () {
      final now = DateTime(2026, 3, 28);
      final photo = ProfilePhoto(
        id: 'p1',
        url: 'https://example.com/photo.jpg',
        caption: 'My photo',
        categoryId: 'cleaning',
        isCover: true,
        uploadedAt: now,
      );
      final json = photo.toJson();
      final restored = ProfilePhoto.fromJson(json);
      expect(restored, photo);
    });

    test('isCover defaults to false', () {
      final photo = ProfilePhoto(
        id: 'p1',
        url: 'https://example.com/photo.jpg',
        uploadedAt: DateTime(2026, 1, 1),
      );
      expect(photo.isCover, false);
    });
  });

  group('CategoryShowcase', () {
    test('fromJson/toJson roundtrip', () {
      const showcase = CategoryShowcase(
        categoryId: 'cleaning',
        description: 'I love cleaning',
        photoIds: ['p1', 'p2'],
      );
      final json = showcase.toJson();
      final restored = CategoryShowcase.fromJson(json);
      expect(restored, showcase);
    });

    test('photoIds defaults to empty list', () {
      const showcase = CategoryShowcase(categoryId: 'cleaning');
      expect(showcase.photoIds, isEmpty);
    });
  });

  group('ProviderStats', () {
    test('fromJson/toJson roundtrip', () {
      const stats = ProviderStats(
        completedTasks: 10,
        avgRating: 4.5,
        totalReviews: 8,
        repeatHires: 3,
        avgResponseTime: '< 1 hour',
        earningsTotal: 1500.50,
      );
      final json = stats.toJson();
      final restored = ProviderStats.fromJson(json);
      expect(restored, stats);
    });

    test('defaults are correct', () {
      const stats = ProviderStats();
      expect(stats.completedTasks, 0);
      expect(stats.avgRating, 0.0);
      expect(stats.totalReviews, 0);
      expect(stats.repeatHires, 0);
      expect(stats.avgResponseTime, isNull);
      expect(stats.earningsTotal, 0.0);
    });
  });

  group('UserModel', () {
    final fullJson = {
      'uid': 'user123',
      'phone': '+6591234567',
      'displayName': 'Alice',
      'email': 'alice@example.com',
      'avatarUrl': 'https://example.com/avatar.jpg',
      'headline': 'Top cleaner in AMK',
      'bio': 'Experienced cleaner',
      'neighbourhood': 'Ang Mo Kio',
      'role': 'provider',
      'serviceCategories': ['cleaning', 'errands'],
      'skillTags': ['#DeepClean'],
      'categoryShowcases': [
        {
          'categoryId': 'cleaning',
          'description': 'Expert',
          'photoIds': ['p1'],
        }
      ],
      'photos': [
        {
          'id': 'p1',
          'url': 'https://example.com/p1.jpg',
          'isCover': true,
          'uploadedAt': '2026-01-01T00:00:00.000',
        }
      ],
      'introVideoUrl': 'https://example.com/intro.mp4',
      'badges': ['phoneVerified', 'singpassVerified'],
      'stats': {
        'completedTasks': 5,
        'avgRating': 4.8,
        'totalReviews': 3,
        'repeatHires': 1,
        'earningsTotal': 500.0,
      },
      'completenessScore': 80,
      'createdAt': '2026-01-01T00:00:00.000',
      'lastActiveAt': '2026-03-28T00:00:00.000',
      'isOnline': true,
      'isProfileComplete': true,
      'isDeactivated': false,
    };

    test('fromJson/toJson roundtrip with all fields populated', () {
      final user = UserModel.fromJson(fullJson);
      final json = jsonDecode(jsonEncode(user.toJson())) as Map<String, dynamic>;
      final restored = UserModel.fromJson(json);
      expect(restored, user);
    });

    test('fromJson with minimal fields (only uid, phone)', () {
      final user = UserModel.fromJson({
        'uid': 'u1',
        'phone': '+6590000000',
      });
      expect(user.uid, 'u1');
      expect(user.phone, '+6590000000');
      expect(user.displayName, isNull);
      expect(user.role, UserRole.poster);
      expect(user.serviceCategories, isEmpty);
      expect(user.photos, isEmpty);
      expect(user.badges, isEmpty);
      expect(user.stats, isNull);
      expect(user.completenessScore, 0);
      expect(user.isOnline, false);
      expect(user.isProfileComplete, false);
      expect(user.isDeactivated, false);
    });

    test('role defaults to poster', () {
      final user = UserModel.fromJson({'uid': 'u1', 'phone': '+65'});
      expect(user.role, UserRole.poster);
    });
  });

  group('UserModelExt', () {
    test('isProvider returns true for provider role', () {
      const user = UserModel(uid: 'u1', phone: '+65', role: UserRole.provider);
      expect(user.isProvider, true);
      expect(user.isPoster, false);
    });

    test('isProvider returns true for both role', () {
      const user = UserModel(uid: 'u1', phone: '+65', role: UserRole.both);
      expect(user.isProvider, true);
      expect(user.isPoster, true);
    });

    test('isPoster returns true for poster role', () {
      const user = UserModel(uid: 'u1', phone: '+65', role: UserRole.poster);
      expect(user.isPoster, true);
      expect(user.isProvider, false);
    });

    test('isSingPassVerified returns true when badge present', () {
      const user = UserModel(
        uid: 'u1',
        phone: '+65',
        badges: [VerificationBadge.singpassVerified],
      );
      expect(user.isSingPassVerified, true);
    });

    test('isSingPassVerified returns false when badge absent', () {
      const user = UserModel(uid: 'u1', phone: '+65');
      expect(user.isSingPassVerified, false);
    });

    test('coverPhoto returns photo with isCover=true', () {
      final photos = [
        ProfilePhoto(
          id: 'p1',
          url: 'url1',
          uploadedAt: DateTime(2026, 1, 1),
        ),
        ProfilePhoto(
          id: 'p2',
          url: 'url2',
          isCover: true,
          uploadedAt: DateTime(2026, 1, 2),
        ),
      ];
      final user = UserModel(uid: 'u1', phone: '+65', photos: photos);
      expect(user.coverPhoto?.id, 'p2');
    });

    test('coverPhoto returns first photo when none marked as cover', () {
      final photos = [
        ProfilePhoto(
          id: 'p1',
          url: 'url1',
          uploadedAt: DateTime(2026, 1, 1),
        ),
      ];
      final user = UserModel(uid: 'u1', phone: '+65', photos: photos);
      expect(user.coverPhoto?.id, 'p1');
    });

    test('coverPhoto returns null when no photos', () {
      const user = UserModel(uid: 'u1', phone: '+65');
      expect(user.coverPhoto, isNull);
    });

    test('completeness calculates score correctly', () {
      const emptyUser = UserModel(uid: 'u1', phone: '+65');
      expect(emptyUser.completeness, 0);

      final fullUser = UserModel(
        uid: 'u1',
        phone: '+65',
        displayName: 'Alice',
        avatarUrl: 'url',
        headline: 'Hi',
        bio: 'About me',
        neighbourhood: 'AMK',
        photos: [
          ProfilePhoto(
            id: 'p1',
            url: 'url',
            uploadedAt: DateTime(2026, 1, 1),
          ),
        ],
        serviceCategories: ['cleaning'],
        skillTags: ['#clean'],
        categoryShowcases: [
          const CategoryShowcase(categoryId: 'cleaning'),
        ],
        badges: [VerificationBadge.idVerified],
      );
      // 15 + 15 + 10 + 10 + 5 + 15 + 10 + 5 + 10 + 5 = 100
      expect(fullUser.completeness, 100);
    });

    test('completeness clamps to 100', () {
      final user = UserModel(
        uid: 'u1',
        phone: '+65',
        displayName: 'Alice',
        avatarUrl: 'url',
        headline: 'Hi',
        bio: 'About me',
        neighbourhood: 'AMK',
        photos: [
          ProfilePhoto(
            id: 'p1',
            url: 'url',
            uploadedAt: DateTime(2026, 1, 1),
          ),
        ],
        serviceCategories: ['cleaning'],
        skillTags: ['#clean'],
        categoryShowcases: [
          const CategoryShowcase(categoryId: 'cleaning'),
        ],
        badges: [VerificationBadge.idVerified],
      );
      expect(user.completeness, lessThanOrEqualTo(100));
    });
  });
}
