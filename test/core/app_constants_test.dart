import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neighbourgo/core/constants/app_constants.dart';
import 'package:neighbourgo/core/constants/category_constants.dart';

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // AppConstants
  // ─────────────────────────────────────────────────────────────────────────
  group('AppConstants', () {
    test('appName is NeighbourGo', () {
      expect(AppConstants.appName, 'NeighbourGo');
    });

    test('platformFeePercent is 13.0', () {
      expect(AppConstants.platformFeePercent, 13.0);
    });

    test('currency is SGD', () {
      expect(AppConstants.currency, 'SGD');
    });

    test('pageSize is 20', () {
      expect(AppConstants.pageSize, 20);
    });

    test('media limits: maxProfilePhotos=12, maxTaskPhotos=6', () {
      expect(AppConstants.maxProfilePhotos, 12);
      expect(AppConstants.maxTaskPhotos, 6);
    });

    test('Firestore collection names are correct strings', () {
      expect(AppConstants.usersCol, 'users');
      expect(AppConstants.tasksCol, 'tasks');
      expect(AppConstants.bidsCol, 'bids');
      expect(AppConstants.chatsCol, 'chats');
      expect(AppConstants.messagesCol, 'messages');
      expect(AppConstants.reviewsCol, 'reviews');
      expect(AppConstants.paymentsCol, 'payments');
      expect(AppConstants.notificationsCol, 'notifications');
    });

    test('storage paths are correct strings', () {
      expect(AppConstants.profilePhotosPath, 'profile_photos');
      expect(AppConstants.taskPhotosPath, 'task_photos');
      expect(AppConstants.chatMediaPath, 'chat_media');
      expect(AppConstants.verificationDocsPath, 'verification_docs');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // AppRoutes
  // ─────────────────────────────────────────────────────────────────────────
  group('AppRoutes', () {
    test('all route strings are valid paths starting with /', () {
      final routes = [
        AppRoutes.splash,
        AppRoutes.welcome,
        AppRoutes.phoneAuth,
        AppRoutes.otpVerify,
        AppRoutes.roleSelect,
        AppRoutes.profileSetup,
        AppRoutes.home,
        AppRoutes.taskList,
        AppRoutes.taskDetail,
        AppRoutes.postTask,
        AppRoutes.myTasks,
        AppRoutes.bidsReceived,
        AppRoutes.myProfile,
        AppRoutes.publicProfile,
        AppRoutes.editProfile,
        AppRoutes.photoGallery,
        AppRoutes.verificationCentre,
        AppRoutes.chatList,
        AppRoutes.chatThread,
        AppRoutes.wallet,
        AppRoutes.checkout,
        AppRoutes.submitReview,
        AppRoutes.notificationList,
        AppRoutes.settings,
        AppRoutes.notifications,
        AppRoutes.helpSupport,
      ];
      for (final route in routes) {
        expect(route, startsWith('/'), reason: 'Route "$route" must start with /');
      }
    });

    test('taskDetail contains :taskId parameter', () {
      expect(AppRoutes.taskDetail, contains(':taskId'));
    });

    test('chatThread contains :chatId parameter', () {
      expect(AppRoutes.chatThread, contains(':chatId'));
    });

    test('publicProfile contains :userId parameter', () {
      expect(AppRoutes.publicProfile, contains(':userId'));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // AppCategories
  // ─────────────────────────────────────────────────────────────────────────
  group('AppCategories', () {
    test('all has exactly 10 categories', () {
      expect(AppCategories.all.length, 10);
    });

    test('each category has non-empty id, label, emoji, and a color', () {
      for (final cat in AppCategories.all) {
        expect(cat.id, isNotEmpty, reason: '${cat.label} id must not be empty');
        expect(cat.label, isNotEmpty, reason: '${cat.id} label must not be empty');
        expect(cat.emoji, isNotEmpty, reason: '${cat.id} emoji must not be empty');
        expect(cat.color, isA<Color>(), reason: '${cat.id} must have a Color');
      }
    });

    test('category IDs are unique (no duplicates)', () {
      final ids = AppCategories.all.map((c) => c.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('getById returns correct category for valid ID', () {
      for (final cat in AppCategories.all) {
        final found = AppCategories.getById(cat.id);
        expect(found, isNotNull);
        expect(found!.id, cat.id);
        expect(found.label, cat.label);
      }
    });

    test('getById returns null for invalid ID', () {
      expect(AppCategories.getById('nonexistent'), isNull);
      expect(AppCategories.getById(''), isNull);
    });

    test('all 10 categories are present with correct IDs', () {
      final expectedIds = [
        'cleaning',
        'tutoring',
        'pet_care',
        'errands',
        'queuing',
        'handyman',
        'moving',
        'personal_care',
        'admin',
        'events',
      ];
      final actualIds = AppCategories.all.map((c) => c.id).toList();
      expect(actualIds, expectedIds);
    });

    test('cleaning category has correct properties', () {
      final cat = AppCategories.cleaning;
      expect(cat.id, 'cleaning');
      expect(cat.label, 'Home Cleaning');
      expect(cat.emoji, '🧹');
    });

    test('tutoring category has correct properties', () {
      final cat = AppCategories.tutoring;
      expect(cat.id, 'tutoring');
      expect(cat.label, 'Tutoring');
      expect(cat.emoji, '📚');
    });

    test('petCare category has correct properties', () {
      final cat = AppCategories.petCare;
      expect(cat.id, 'pet_care');
      expect(cat.label, 'Pet Care');
      expect(cat.emoji, '🐾');
    });

    test('errands category has correct properties', () {
      final cat = AppCategories.errands;
      expect(cat.id, 'errands');
      expect(cat.label, 'Errands');
      expect(cat.emoji, '🛍️');
    });

    test('queuing category has correct properties', () {
      final cat = AppCategories.queuing;
      expect(cat.id, 'queuing');
      expect(cat.label, 'Queue Standing');
      expect(cat.emoji, '🧍');
    });

    test('handyman category has correct properties', () {
      final cat = AppCategories.handyman;
      expect(cat.id, 'handyman');
      expect(cat.label, 'Handyman');
      expect(cat.emoji, '🔧');
    });

    test('moving category has correct properties', () {
      final cat = AppCategories.moving;
      expect(cat.id, 'moving');
      expect(cat.label, 'Moving');
      expect(cat.emoji, '📦');
    });

    test('personalCare category has correct properties', () {
      final cat = AppCategories.personalCare;
      expect(cat.id, 'personal_care');
      expect(cat.label, 'Personal Care');
      expect(cat.emoji, '🤝');
    });

    test('admin category has correct properties', () {
      final cat = AppCategories.admin;
      expect(cat.id, 'admin');
      expect(cat.label, 'Admin & Digital');
      expect(cat.emoji, '💻');
    });

    test('events category has correct properties', () {
      final cat = AppCategories.events;
      expect(cat.id, 'events');
      expect(cat.label, 'Event Help');
      expect(cat.emoji, '🎉');
    });
  });
}
