import 'package:cloud_firestore/cloud_firestore.dart';

/// Factory methods for creating realistic test data in the Firebase emulators.
///
/// All data uses Singapore-specific values to match the production app.

// ─────────────────────────────────────────────────────────────────────────────
// Test Users
// ─────────────────────────────────────────────────────────────────────────────

/// A poster user who requests tasks.
Map<String, dynamic> testPosterUser({required String uid}) => {
      'uid': uid,
      'phone': '+6591234567',
      'displayName': 'Alice Tan',
      'email': 'alice@test.com',
      'headline': 'Busy mum looking for help',
      'bio': 'Working professional and mother of two in Ang Mo Kio.',
      'neighbourhood': 'Ang Mo Kio',
      'role': 'poster',
      'serviceCategories': <String>[],
      'skillTags': <String>[],
      'photos': <Map<String, dynamic>>[],
      'badges': <String>[],
      'completenessScore': 55,
      'isOnline': true,
      'isProfileComplete': true,
      'isDeactivated': false,
      'createdAt': FieldValue.serverTimestamp(),
      'lastActiveAt': FieldValue.serverTimestamp(),
    };

/// A provider user who fulfils tasks.
Map<String, dynamic> testProviderUser({required String uid}) => {
      'uid': uid,
      'phone': '+6598765432',
      'displayName': 'Ben Lim',
      'email': 'ben@test.com',
      'headline': 'Experienced cleaner & handyman',
      'bio': 'Five years of professional cleaning experience in Singapore.',
      'neighbourhood': 'Bedok',
      'role': 'provider',
      'serviceCategories': ['cleaning', 'handyman'],
      'skillTags': ['#DeepClean', '#Plumbing'],
      'photos': <Map<String, dynamic>>[],
      'badges': ['phoneVerified'],
      'stats': {
        'completedTasks': 42,
        'avgRating': 4.8,
        'totalReviews': 38,
        'repeatHires': 5,
        'avgResponseTime': '< 1 hour',
        'earningsTotal': 6200.0,
      },
      'completenessScore': 75,
      'isOnline': true,
      'isProfileComplete': true,
      'isDeactivated': false,
      'createdAt': FieldValue.serverTimestamp(),
      'lastActiveAt': FieldValue.serverTimestamp(),
    };

/// A user who both posts and provides tasks.
Map<String, dynamic> testBothUser({required String uid}) => {
      'uid': uid,
      'phone': '+6590001111',
      'displayName': 'Charlie Wong',
      'email': 'charlie@test.com',
      'headline': 'Community helper',
      'bio': 'I love helping my neighbours and sometimes need help too!',
      'neighbourhood': 'Tampines',
      'role': 'both',
      'serviceCategories': ['tutoring', 'errands'],
      'skillTags': ['#MathTutor', '#Errands'],
      'photos': <Map<String, dynamic>>[],
      'badges': ['phoneVerified'],
      'completenessScore': 60,
      'isOnline': true,
      'isProfileComplete': true,
      'isDeactivated': false,
      'createdAt': FieldValue.serverTimestamp(),
      'lastActiveAt': FieldValue.serverTimestamp(),
    };

// ─────────────────────────────────────────────────────────────────────────────
// Test Tasks
// ─────────────────────────────────────────────────────────────────────────────

/// A cleaning task posted in Ang Mo Kio.
Map<String, dynamic> testCleaningTask({
  required String taskId,
  required String posterId,
  String posterName = 'Alice Tan',
}) =>
    {
      'id': taskId,
      'posterId': posterId,
      'posterName': posterName,
      'title': 'Deep clean 3-room HDB',
      'description':
          'Need thorough cleaning for my 3-room HDB flat including kitchen and bathrooms. '
              'Please bring your own supplies.',
      'categoryId': 'cleaning',
      'photoUrls': <String>[],
      'tags': ['#HDB', '#DeepClean'],
      'locationLabel': 'Blk 456 Ang Mo Kio Ave 3',
      'neighbourhood': 'Ang Mo Kio',
      'budgetMin': 50.0,
      'budgetMax': 80.0,
      'currency': 'SGD',
      'urgency': 'flexible',
      'status': 'open',
      'bidCount': 0,
      'viewCount': 0,
      'isPaid': false,
      'isEscrowReleased': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

/// A tutoring task posted in Tampines.
Map<String, dynamic> testTutoringTask({
  required String taskId,
  required String posterId,
  String posterName = 'Alice Tan',
}) =>
    {
      'id': taskId,
      'posterId': posterId,
      'posterName': posterName,
      'title': 'Primary 5 Maths tutor needed',
      'description':
          'Looking for a patient tutor to help my child with PSLE maths preparation. '
              '2 sessions per week, 1.5 hours each.',
      'categoryId': 'tutoring',
      'photoUrls': <String>[],
      'tags': ['#PSLE', '#Maths'],
      'locationLabel': 'Blk 201 Tampines St 21',
      'neighbourhood': 'Tampines',
      'budgetMin': 35.0,
      'budgetMax': 50.0,
      'currency': 'SGD',
      'urgency': 'flexible',
      'status': 'open',
      'bidCount': 0,
      'viewCount': 0,
      'isPaid': false,
      'isEscrowReleased': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

// ─────────────────────────────────────────────────────────────────────────────
// Firestore seeding helpers
// ─────────────────────────────────────────────────────────────────────────────

FirebaseFirestore get _firestore => FirebaseFirestore.instance;

/// Write a user document to the `users` collection.
Future<void> seedUser(String uid, Map<String, dynamic> data) =>
    _firestore.collection('users').doc(uid).set(data);

/// Write a task document to the `tasks` collection.
Future<void> seedTask(String taskId, Map<String, dynamic> data) =>
    _firestore.collection('tasks').doc(taskId).set(data);

/// Write a bid document to the `bids` collection.
Future<void> seedBid(String bidId, Map<String, dynamic> data) =>
    _firestore.collection('bids').doc(bidId).set(data);

/// Write a chat document to the `chats` collection.
Future<void> seedChat(String chatId, Map<String, dynamic> data) =>
    _firestore.collection('chats').doc(chatId).set(data);

/// Write a message document under `chats/{chatId}/messages`.
Future<void> seedMessage(
        String chatId, String messageId, Map<String, dynamic> data) =>
    _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .set(data);
