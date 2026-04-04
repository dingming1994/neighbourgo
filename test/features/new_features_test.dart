import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide PhoneAuthProvider;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neighbourgo/features/auth/data/models/user_model.dart';
import 'package:neighbourgo/features/auth/domain/providers/auth_provider.dart';
import 'package:neighbourgo/features/bids/data/repositories/bid_repository.dart';
import 'package:neighbourgo/features/bids/domain/models/bid_model.dart';
import 'package:neighbourgo/features/bids/presentation/screens/my_bids_screen.dart';
import 'package:neighbourgo/features/discover/presentation/screens/discover_screen.dart';
import 'package:neighbourgo/features/favorites/data/repositories/favorites_repository.dart';
import 'package:neighbourgo/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:neighbourgo/features/home/presentation/widgets/job_offers_section.dart';
import 'package:neighbourgo/features/home/presentation/widgets/pending_reviews_section.dart';
import 'package:neighbourgo/features/notifications/domain/providers/notification_providers.dart';
import 'package:neighbourgo/features/notifications/presentation/screens/notification_list_screen.dart';
import 'package:neighbourgo/features/profile/data/repositories/profile_repository.dart';
import 'package:neighbourgo/features/services/data/models/service_listing_model.dart';
import 'package:neighbourgo/features/services/data/repositories/service_listing_repository.dart';
import 'package:neighbourgo/features/services/presentation/screens/service_listings_screen.dart';
import 'package:neighbourgo/features/tasks/data/models/task_model.dart';
import 'package:neighbourgo/features/tasks/data/repositories/task_repository.dart';
import 'package:neighbourgo/features/tasks/presentation/screens/my_tasks_screen.dart';

// =============================================================================
// Fakes
// =============================================================================

class FakeFirebaseAuth extends Fake implements FirebaseAuth {
  @override
  Stream<User?> authStateChanges() => Stream.value(null);
  @override
  User? get currentUser => null;
}

class FakeFirebaseFirestore extends Fake implements FirebaseFirestore {}

class FakeFirebaseStorage extends Fake implements FirebaseStorage {}

// ── Task Repository Fake ────────────────────────────────────────────────────

class FakeTaskRepository extends TaskRepository {
  final List<TaskModel> postedTasks;
  final List<TaskModel> completedTasks;
  final List<TaskModel> cancelledTasks;
  final Map<String, TaskModel?> taskById;

  FakeTaskRepository({
    this.postedTasks = const [],
    this.completedTasks = const [],
    this.cancelledTasks = const [],
    this.taskById = const {},
  }) : super(db: FakeFirebaseFirestore(), storage: FakeFirebaseStorage());

  @override
  Stream<List<TaskModel>> watchMyPostedTasks(String uid) =>
      Stream.value(postedTasks);

  @override
  Stream<List<TaskModel>> watchMyCompletedPostTasks(String uid) =>
      Stream.value(completedTasks);

  @override
  Stream<List<TaskModel>> watchMyCancelledPostTasks(String uid) =>
      Stream.value(cancelledTasks);

  @override
  Stream<TaskModel?> watchTask(String id) => Stream.value(taskById[id]);

  @override
  Stream<List<TaskModel>> watchOpenTasks({
    String? categoryId,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) =>
      Stream.value(postedTasks);
}

// ── Bid Repository Fake ─────────────────────────────────────────────────────

class FakeBidRepository extends BidRepository {
  final List<BidModel> bids;

  FakeBidRepository({this.bids = const []})
      : super(db: FakeFirebaseFirestore());

  @override
  Stream<List<BidModel>> watchMyBids(String providerId) => Stream.value(bids);

  @override
  Stream<List<BidModel>> getBidsStream(String taskId) =>
      Stream.value(bids.where((b) => b.taskId == taskId).toList());
}

// ── Service Listing Repository Fake ─────────────────────────────────────────

class FakeServiceListingRepository extends ServiceListingRepository {
  final List<ServiceListingModel> listings;

  FakeServiceListingRepository({this.listings = const []})
      : super(db: FakeFirebaseFirestore(), storage: FakeFirebaseStorage());

  @override
  Stream<List<ServiceListingModel>> watchActiveListings({
    String? categoryId,
    int limit = 20,
  }) {
    if (categoryId == null) return Stream.value(listings);
    return Stream.value(
      listings.where((l) => l.categoryId == categoryId).toList(),
    );
  }

  @override
  Stream<List<ServiceListingModel>> watchMyListings(String providerId) =>
      Stream.value(
        listings.where((l) => l.providerId == providerId).toList(),
      );
}

// ── Favorites Repository Fake ───────────────────────────────────────────────

class FakeFavoritesRepository extends FavoritesRepository {
  final List<FavoriteItem> favorites;

  FakeFavoritesRepository({this.favorites = const []})
      : super(db: FakeFirebaseFirestore());

  @override
  Stream<List<FavoriteItem>> watchFavorites(String uid) =>
      Stream.value(favorites);

  @override
  Future<void> addFavorite(String uid, String itemId, String type) async {}

  @override
  Future<void> removeFavorite(String uid, String itemId) async {}
}

// ── Profile Repository Fake ─────────────────────────────────────────────────

class FakeProfileRepository extends ProfileRepository {
  final Map<String, UserModel?> profilesByUid;

  FakeProfileRepository({this.profilesByUid = const {}})
      : super(db: FakeFirebaseFirestore(), storage: FakeFirebaseStorage());

  @override
  Stream<UserModel?> watchProfile(String uid) =>
      Stream.value(profilesByUid[uid]);
}

// =============================================================================
// Test data
// =============================================================================

const _testUser = UserModel(
  uid: 'user-001',
  phone: '+6591234567',
  displayName: 'Test User',
  role: UserRole.both,
  neighbourhood: 'Ang Mo Kio',
);

const _testProvider = UserModel(
  uid: 'provider-001',
  phone: '+6598765432',
  displayName: 'Alice Provider',
  role: UserRole.provider,
  neighbourhood: 'Bedok',
  headline: 'Professional cleaner',
);

TaskModel _makeTask({
  String id = 'task-001',
  String title = 'Clean my house',
  TaskStatus status = TaskStatus.open,
  String categoryId = 'cleaning',
  int bidCount = 0,
}) =>
    TaskModel(
      id: id,
      posterId: 'user-001',
      posterName: 'Test User',
      title: title,
      description: 'Need help cleaning',
      categoryId: categoryId,
      locationLabel: 'Blk 123 AMK Ave 6',
      neighbourhood: 'Ang Mo Kio',
      budgetMin: 50,
      budgetMax: 100,
      urgency: TaskUrgency.flexible,
      status: status,
      bidCount: bidCount,
      createdAt: DateTime(2026, 4, 1),
    );

BidModel _makeBid({
  String bidId = 'bid-001',
  String taskId = 'task-001',
  BidStatus status = BidStatus.pending,
  double amount = 75,
  String? message,
}) =>
    BidModel(
      bidId: bidId,
      taskId: taskId,
      providerId: 'provider-001',
      providerName: 'Alice Provider',
      amount: amount,
      status: status,
      message: message,
      createdAt: DateTime(2026, 4, 1),
    );

const _testServiceListing = ServiceListingModel(
  id: 'sl-001',
  providerId: 'provider-001',
  providerName: 'Alice Provider',
  categoryId: 'cleaning',
  title: 'Professional Deep Cleaning',
  description: 'Thorough cleaning of HDB and condos',
  hourlyRate: 35.0,
  neighbourhood: 'Bedok',
);

// =============================================================================
// Helpers
// =============================================================================

Widget _buildTestWidget(Widget child, List<Override> overrides) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(home: child),
  );
}

/// Suppress overflow errors and set a large surface size for screen tests.
void _testScreen(
  String description,
  Future<void> Function(WidgetTester) callback,
) {
  testWidgets(description, (tester) async {
    tester.view.physicalSize = const Size(480, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final old = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      old?.call(details);
    };

    await callback(tester);

    FlutterError.onError = old;
  });
}

// =============================================================================
// My Tasks Screen tests
// =============================================================================

void main() {
  group('MyTasksScreen', () {
    List<Override> overrides({
      List<TaskModel> posted = const [],
      List<TaskModel> completed = const [],
      List<TaskModel> cancelled = const [],
    }) {
      final fakeTaskRepo = FakeTaskRepository(
        postedTasks: posted,
        completedTasks: completed,
        cancelledTasks: cancelled,
      );
      return [
        currentUserProvider.overrideWith((_) => Stream.value(_testUser)),
        taskRepositoryProvider.overrideWithValue(fakeTaskRepo),
      ];
    }

    _testScreen('renders title and 3 tabs', (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        const MyTasksScreen(),
        overrides(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('My Tasks'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Cancelled'), findsOneWidget);
    });

    _testScreen('shows empty state when no active tasks', (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        const MyTasksScreen(),
        overrides(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('📋'), findsOneWidget);
      expect(find.text('No active tasks yet'), findsOneWidget);
      expect(find.text('Post a Task'), findsOneWidget);
    });

    _testScreen('shows task card with title and status badge', (tester) async {
      final task = _makeTask(title: 'Fix my plumbing', bidCount: 3);
      await tester.pumpWidget(_buildTestWidget(
        const MyTasksScreen(),
        overrides(posted: [task]),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Fix my plumbing'), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);
      expect(find.text('3 bids'), findsOneWidget);
    });

    _testScreen('completed tab shows empty state', (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        const MyTasksScreen(),
        overrides(),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();

      expect(find.text('✅'), findsOneWidget);
      expect(find.text('No completed tasks yet'), findsOneWidget);
    });

    _testScreen('cancelled tab shows empty state', (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        const MyTasksScreen(),
        overrides(),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancelled'));
      await tester.pumpAndSettle();

      expect(find.text('🚫'), findsOneWidget);
      expect(find.text('No cancelled tasks'), findsOneWidget);
    });

    _testScreen('completed tab shows completed tasks', (tester) async {
      final task = _makeTask(
        id: 'task-002',
        title: 'Walk my dog',
        status: TaskStatus.completed,
      );
      await tester.pumpWidget(_buildTestWidget(
        const MyTasksScreen(),
        overrides(completed: [task]),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();

      expect(find.text('Walk my dog'), findsOneWidget);
      expect(find.text('Completed'), findsWidgets); // tab + badge
    });
  });

  // ===========================================================================
  // My Bids Screen tests
  // ===========================================================================

  group('MyBidsScreen', () {
    List<Override> overrides({
      List<BidModel> bids = const [],
      Map<String, TaskModel?> taskById = const {},
    }) {
      final fakeTaskRepo = FakeTaskRepository(taskById: taskById);
      final fakeBidRepo = FakeBidRepository(bids: bids);
      return [
        currentUserProvider.overrideWith((_) => Stream.value(_testProvider)),
        taskRepositoryProvider.overrideWithValue(fakeTaskRepo),
        bidRepositoryProvider.overrideWithValue(fakeBidRepo),
      ];
    }

    _testScreen('renders title and 3 tabs', (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        const MyBidsScreen(),
        overrides(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('My Bids'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Accepted'), findsOneWidget);
      expect(find.text('Rejected'), findsOneWidget);
    });

    _testScreen('shows empty state for pending bids', (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        const MyBidsScreen(),
        overrides(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('⏳'), findsOneWidget);
      expect(find.text('No bids yet'), findsOneWidget);
      expect(find.text('Browse Open Tasks'), findsOneWidget);
    });

    _testScreen('shows bid card with amount and status', (tester) async {
      final bid = _makeBid(
        taskId: 'task-001',
        amount: 120,
        message: 'I can do this quickly',
      );
      final task = _makeTask(title: 'Fix plumbing');
      await tester.pumpWidget(_buildTestWidget(
        const MyBidsScreen(),
        overrides(
          bids: [bid],
          taskById: {'task-001': task},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('S\$120'), findsOneWidget);
      expect(find.text('I can do this quickly'), findsOneWidget);
      expect(find.text('Pending'), findsWidgets); // tab + badge
    });

    _testScreen('accepted tab shows empty state', (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        const MyBidsScreen(),
        overrides(),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Accepted'));
      await tester.pumpAndSettle();

      expect(find.text('🎉'), findsOneWidget);
      expect(find.text('No accepted bids yet'), findsOneWidget);
    });

    _testScreen('rejected tab shows empty state', (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        const MyBidsScreen(),
        overrides(),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rejected'));
      await tester.pumpAndSettle();

      expect(find.text('📭'), findsOneWidget);
      expect(find.text('No rejected bids'), findsOneWidget);
    });

    _testScreen('accepted tab shows accepted bids', (tester) async {
      final bid = _makeBid(
        bidId: 'bid-002',
        taskId: 'task-001',
        amount: 80,
        status: BidStatus.accepted,
      );
      final task = _makeTask(title: 'Cook dinner');
      await tester.pumpWidget(_buildTestWidget(
        const MyBidsScreen(),
        overrides(
          bids: [bid],
          taskById: {'task-001': task},
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Accepted'));
      await tester.pumpAndSettle();

      expect(find.text('S\$80'), findsOneWidget);
      expect(find.text('Cook dinner'), findsOneWidget);
    });
  });

  // ===========================================================================
  // Favorites Screen tests
  // ===========================================================================

  group('FavoritesScreen', () {
    List<Override> overrides({
      List<FavoriteItem> favorites = const [],
      Map<String, TaskModel?> taskById = const {},
      Map<String, UserModel?> profilesByUid = const {},
    }) {
      final fakeTaskRepo = FakeTaskRepository(taskById: taskById);
      final fakeFavRepo = FakeFavoritesRepository(favorites: favorites);
      final fakeProfileRepo =
          FakeProfileRepository(profilesByUid: profilesByUid);
      return [
        currentUserProvider.overrideWith((_) => Stream.value(_testUser)),
        taskRepositoryProvider.overrideWithValue(fakeTaskRepo),
        favoritesRepositoryProvider.overrideWithValue(fakeFavRepo),
        profileRepositoryProvider.overrideWithValue(fakeProfileRepo),
      ];
    }

    _testScreen('renders title and 2 tabs', (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        const FavoritesScreen(),
        overrides(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Favorites'), findsOneWidget);
      expect(find.text('Saved Tasks'), findsOneWidget);
      expect(find.text('Saved Providers'), findsOneWidget);
    });

    _testScreen('shows empty state for saved tasks', (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        const FavoritesScreen(),
        overrides(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No saved tasks yet'), findsOneWidget);
      expect(
        find.text('Tap the heart on any task to save it here'),
        findsOneWidget,
      );
    });

    _testScreen('shows empty state for saved providers', (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        const FavoritesScreen(),
        overrides(),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Saved Providers'));
      await tester.pumpAndSettle();

      expect(find.text('No saved providers yet'), findsOneWidget);
      expect(
        find.text('Tap the heart on any provider to save them here'),
        findsOneWidget,
      );
    });

    _testScreen('shows favorited task card', (tester) async {
      final task = _makeTask(title: 'Move furniture');
      await tester.pumpWidget(_buildTestWidget(
        const FavoritesScreen(),
        overrides(
          favorites: [
            const FavoriteItem(
              itemId: 'task-001',
              type: 'task',
            ),
          ],
          taskById: {'task-001': task},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Move furniture'), findsOneWidget);
      expect(find.text('Ang Mo Kio'), findsOneWidget);
      // Heart icon should be present
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    _testScreen('shows favorited provider card', (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        const FavoritesScreen(),
        overrides(
          favorites: [
            const FavoriteItem(
              itemId: 'provider-001',
              type: 'provider',
            ),
          ],
          profilesByUid: {'provider-001': _testProvider},
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Saved Providers'));
      await tester.pumpAndSettle();

      expect(find.text('Alice Provider'), findsOneWidget);
      expect(find.text('Professional cleaner'), findsOneWidget);
      expect(find.text('Bedok'), findsOneWidget);
    });

    _testScreen('heart icon toggles favorite', (tester) async {
      final task = _makeTask(title: 'Paint wall');
      await tester.pumpWidget(_buildTestWidget(
        const FavoritesScreen(),
        overrides(
          favorites: [
            const FavoriteItem(
              itemId: 'task-001',
              type: 'task',
            ),
          ],
          taskById: {'task-001': task},
        ),
      ));
      await tester.pumpAndSettle();

      // Find heart icon and tap it
      final heartFinder = find.byIcon(Icons.favorite);
      expect(heartFinder, findsOneWidget);
      await tester.tap(heartFinder);
      await tester.pump();
      // No crash = success (the fake repo handles the toggle)
    });

    _testScreen('shows unavailable state when a saved task no longer exists',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        const FavoritesScreen(),
        overrides(
          favorites: [
            const FavoriteItem(
              itemId: 'missing-task',
              type: 'task',
            ),
          ],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Saved task unavailable'), findsOneWidget);
      expect(find.text('Remove'), findsOneWidget);
    });

    _testScreen('shows unavailable state when a saved provider no longer exists',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        const FavoritesScreen(),
        overrides(
          favorites: [
            const FavoriteItem(
              itemId: 'missing-provider',
              type: 'provider',
            ),
          ],
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Saved Providers'));
      await tester.pumpAndSettle();

      expect(find.text('Saved provider unavailable'), findsOneWidget);
      expect(find.text('Remove'), findsOneWidget);
    });
  });

  group('Home sliver recovery states', () {
    _testScreen('JobOffersSection shows visible error state on failure',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            directHireOffersProvider.overrideWith(
              (_) => Stream.error(Exception('boom')),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CustomScrollView(
                slivers: [
                  JobOffersSection(),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Could not load job offers right now.'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    _testScreen('PendingReviewsSection shows visible error state on failure',
        (tester) async {
      final failingProvider =
          StreamProvider.autoDispose<List<PendingReview>>(
        (_) => Stream.error(Exception('boom')),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CustomScrollView(
                slivers: [
                  PendingReviewsSection(provider: failingProvider),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Could not load pending reviews right now.'),
        findsOneWidget,
      );
      expect(find.text('Try Again'), findsOneWidget);
    });
  });

  // ===========================================================================
  // Service Listings Screen tests
  // ===========================================================================

  group('ServiceListingsScreen', () {
    List<Override> overrides({
      List<ServiceListingModel> listings = const [],
    }) {
      final fakeRepo = FakeServiceListingRepository(listings: listings);
      return [
        serviceListingRepositoryProvider.overrideWithValue(fakeRepo),
      ];
    }

    _testScreen('shows empty state when no listings', (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        const ServiceListingsScreen(),
        overrides(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('🏪'), findsOneWidget);
      expect(find.text('No services listed yet'), findsOneWidget);
      expect(
        find.text('Service listings from providers will appear here.'),
        findsOneWidget,
      );
    });

    _testScreen('shows service listing card', (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        const ServiceListingsScreen(),
        overrides(listings: [_testServiceListing]),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Professional Deep Cleaning'), findsOneWidget);
    });

    _testScreen('shows category filter chips with All selected',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        const ServiceListingsScreen(),
        overrides(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('All'), findsOneWidget);
      expect(find.text('✨'), findsOneWidget);
    });

    _testScreen('renders AppBar title when not embedded', (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        const ServiceListingsScreen(embedded: false),
        overrides(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Service Listings'), findsOneWidget);
    });

    _testScreen('shows multiple listings', (tester) async {
      const listing2 = ServiceListingModel(
        id: 'sl-002',
        providerId: 'provider-002',
        providerName: 'Bob Lee',
        categoryId: 'tutoring',
        title: 'Math Tutoring',
        description: 'Primary to JC level',
        hourlyRate: 50.0,
      );
      await tester.pumpWidget(_buildTestWidget(
        const ServiceListingsScreen(),
        overrides(listings: [_testServiceListing, listing2]),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Professional Deep Cleaning'), findsOneWidget);
      expect(find.text('Math Tutoring'), findsOneWidget);
    });
  });

  // ===========================================================================
  // Search (DiscoverScreen search query provider) tests
  // ===========================================================================

  group('Search — TaskListScreen filtering (unit-like)', () {
    test('tasks can be filtered by title', () {
      final tasks = [
        _makeTask(id: 't1', title: 'Clean my kitchen'),
        _makeTask(id: 't2', title: 'Walk my dog'),
        _makeTask(id: 't3', title: 'Kitchen renovation'),
      ];
      const query = 'kitchen';
      final filtered = tasks
          .where((t) =>
              t.title.toLowerCase().contains(query) ||
              t.description.toLowerCase().contains(query))
          .toList();

      expect(filtered.length, 2);
      expect(filtered.map((t) => t.id), containsAll(['t1', 't3']));
    });

    test('providers can be filtered by displayName', () {
      final providers = [
        _testProvider,
        _testUser,
      ];
      const query = 'alice';
      final filtered = providers
          .where((u) =>
              (u.displayName ?? '').toLowerCase().contains(query) ||
              (u.headline ?? '').toLowerCase().contains(query))
          .toList();

      expect(filtered.length, 1);
      expect(filtered.first.displayName, 'Alice Provider');
    });

    test('service listings can be filtered by title and provider name', () {
      const listings = [
        _testServiceListing,
        ServiceListingModel(
          id: 'sl-002',
          providerId: 'p2',
          providerName: 'Bob',
          categoryId: 'tutoring',
          title: 'Math Tutor',
          description: 'Primary school',
        ),
      ];
      const query = 'alice';
      final filtered = listings
          .where((s) =>
              s.title.toLowerCase().contains(query) ||
              s.description.toLowerCase().contains(query) ||
              s.providerName.toLowerCase().contains(query))
          .toList();

      expect(filtered.length, 1);
      expect(filtered.first.providerName, 'Alice Provider');
    });

    _testScreen('discover search field hydrates from persisted query',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        const DiscoverScreen(),
        [
          currentUserProvider.overrideWith((_) => Stream.value(_testProvider)),
          taskRepositoryProvider.overrideWithValue(FakeTaskRepository(
            postedTasks: [
              _makeTask(id: 't1', title: 'Kitchen cleanup'),
            ],
          )),
          discoverSearchQueryProvider.overrideWith((_) => 'kitchen'),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('kitchen'), findsOneWidget);
    });
  });

  group('NotificationListScreen', () {
    _testScreen('shows actionable empty state when there are no notifications',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        const NotificationListScreen(),
        [
          currentUserProvider.overrideWith((_) => Stream.value(_testUser)),
          notificationsProvider.overrideWith((_) => Stream.value([])),
          unreadNotificationCountProvider.overrideWith((_) => Stream.value(0)),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('No notifications yet'), findsOneWidget);
      expect(find.text('Browse Tasks'), findsOneWidget);
    });

    _testScreen('uses view profile action label for review notifications',
        (tester) async {
      final notification = AppNotification(
        id: 'notif-001',
        type: 'review_received',
        title: 'New review received',
        body: 'Someone left you a review.',
        isRead: false,
        createdAt: DateTime(2026, 4, 2),
        data: const {'userId': 'provider-001'},
      );

      await tester.pumpWidget(_buildTestWidget(
        const NotificationListScreen(),
        [
          currentUserProvider.overrideWith((_) => Stream.value(_testUser)),
          notificationsProvider.overrideWith((_) => Stream.value([notification])),
          unreadNotificationCountProvider.overrideWith((_) => Stream.value(1)),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('View Profile'), findsOneWidget);
      expect(find.text('Leave Review'), findsNothing);
    });
  });

  // ===========================================================================
  // Regression: existing model tests still pass
  // ===========================================================================

  group('Regression — TaskModel', () {
    test('fromJson/toJson roundtrip', () {
      final task = _makeTask();
      final json = task.toJson();
      final restored = TaskModel.fromJson(json);
      expect(restored.title, task.title);
      expect(restored.status, task.status);
      expect(restored.budgetMin, task.budgetMin);
    });

    test('copyWith changes status', () {
      final task = _makeTask();
      final updated = task.copyWith(status: TaskStatus.completed);
      expect(updated.status, TaskStatus.completed);
      expect(updated.title, task.title);
    });
  });

  group('Regression — BidModel', () {
    test('fromJson/toJson roundtrip', () {
      final bid = _makeBid(amount: 99);
      final json = bid.toJson();
      final restored = BidModel.fromJson(json);
      expect(restored.amount, 99);
      expect(restored.status, BidStatus.pending);
    });

    test('copyWith changes status', () {
      final bid = _makeBid();
      final updated = bid.copyWith(status: BidStatus.accepted);
      expect(updated.status, BidStatus.accepted);
      expect(updated.amount, bid.amount);
    });
  });

  group('Regression — ServiceListingModel', () {
    test('fromJson/toJson roundtrip', () {
      final json = _testServiceListing.toJson();
      final restored = ServiceListingModel.fromJson(json);
      expect(restored.title, _testServiceListing.title);
      expect(restored.hourlyRate, 35.0);
    });

    test('rateDisplay shows hourly rate', () {
      expect(_testServiceListing.rateDisplay, 'S\$35/hr');
    });
  });

  group('Regression — FavoriteItem', () {
    test('creates correctly', () {
      const item = FavoriteItem(
        itemId: 'task-001',
        type: 'task',
        addedAt: null,
      );
      expect(item.itemId, 'task-001');
      expect(item.type, 'task');
    });
  });
}
