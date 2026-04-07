import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide PhoneAuthProvider;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neighbourgo/core/constants/category_constants.dart';
import 'package:neighbourgo/features/auth/data/models/user_model.dart';
import 'package:neighbourgo/features/auth/domain/providers/auth_provider.dart';
import 'package:neighbourgo/features/bids/data/repositories/bid_repository.dart';
import 'package:neighbourgo/features/bids/domain/models/bid_model.dart';
import 'package:neighbourgo/features/bids/presentation/widgets/bid_list_section.dart';
import 'package:neighbourgo/features/chat/data/repositories/chat_repository.dart';
import 'package:neighbourgo/features/tasks/data/models/task_model.dart';
import 'package:neighbourgo/features/tasks/data/repositories/task_repository.dart';
import 'package:neighbourgo/features/tasks/presentation/screens/post_task_screen.dart';
import 'package:neighbourgo/features/tasks/presentation/screens/task_detail_screen.dart';
import 'package:neighbourgo/features/tasks/presentation/screens/task_list_screen.dart';

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

class FakeTaskRepository extends TaskRepository {
  List<TaskModel> tasksToReturn;
  final StreamController<List<TaskModel>> _controller =
      StreamController<List<TaskModel>>.broadcast();

  FakeTaskRepository({this.tasksToReturn = const []})
      : super(db: FakeFirebaseFirestore(), storage: FakeFirebaseStorage());

  @override
  Stream<List<TaskModel>> watchOpenTasks(
      {String? categoryId, int limit = 20, DocumentSnapshot? startAfter}) {
    // Emit initial data then keep stream open
    Future.microtask(() => _controller.add(tasksToReturn));
    return _controller.stream;
  }

  @override
  Stream<TaskModel?> watchTask(String id) {
    final match = tasksToReturn.where((t) => t.id == id).firstOrNull;
    return Stream.value(match);
  }

  @override
  Future<String> createTask(TaskModel task,
      {List<dynamic> photos = const []}) async {
    return 'fake-task-id';
  }

  @override
  Future<void> completeTask(String taskId) async {}

  void emit(List<TaskModel> tasks) => _controller.add(tasks);

  void dispose() => _controller.close();
}

/// A TaskRepository that never emits from watchOpenTasks — keeps loading state.
class _NeverEmitTaskRepository extends TaskRepository {
  _NeverEmitTaskRepository()
      : super(db: FakeFirebaseFirestore(), storage: FakeFirebaseStorage());

  @override
  Stream<List<TaskModel>> watchOpenTasks(
      {String? categoryId, int limit = 20, DocumentSnapshot? startAfter}) {
    // Return a stream that never completes — keeps isLoading true
    return StreamController<List<TaskModel>>().stream;
  }
}

class FakeBidRepository extends BidRepository {
  List<BidModel> bidsToReturn;
  bool shouldThrowOnGetBids;

  FakeBidRepository({
    this.bidsToReturn = const [],
    this.shouldThrowOnGetBids = false,
  })
      : super(db: FakeFirebaseFirestore());

  @override
  Stream<List<BidModel>> getBidsStream(String taskId) {
    if (shouldThrowOnGetBids) {
      return Stream.error(Exception('boom'));
    }
    return Stream.value(bidsToReturn);
  }
}

class FakeChatRepository extends ChatRepository {
  bool shouldThrowOnCreateOrGetChat;

  FakeChatRepository()
      : shouldThrowOnCreateOrGetChat = false,
        super(db: FakeFirebaseFirestore(), storage: FakeFirebaseStorage());

  @override
  Future<String> createOrGetChat(
      String taskId, String posterId, String providerId) async {
    if (shouldThrowOnCreateOrGetChat) {
      throw Exception('chat create failed');
    }
    return 'fake-chat-id';
  }
}

// =============================================================================
// Test data
// =============================================================================

UserModel _testUser({
  String uid = 'user-1',
  String displayName = 'Test User',
  UserRole role = UserRole.poster,
}) =>
    UserModel(
      uid: uid,
      phone: '+6591234567',
      displayName: displayName,
      role: role,
    );

TaskModel _testTask({
  String id = 'task-1',
  String posterId = 'user-1',
  String title = 'Clean my 3-room HDB',
  String description =
      'Need deep cleaning for the whole flat including bathrooms and kitchen.',
  String categoryId = 'cleaning',
  TaskStatus status = TaskStatus.open,
  String? assignedProviderId,
  String? assignedProviderName,
  List<String> photoUrls = const [],
}) =>
    TaskModel(
      id: id,
      posterId: posterId,
      posterName: 'Poster Name',
      title: title,
      description: description,
      categoryId: categoryId,
      locationLabel: 'Blk 123 Ang Mo Kio',
      neighbourhood: 'Ang Mo Kio',
      budgetMin: 50,
      budgetMax: 100,
      urgency: TaskUrgency.flexible,
      status: status,
      assignedProviderId: assignedProviderId,
      assignedProviderName: assignedProviderName,
      photoUrls: photoUrls,
    );

// =============================================================================
// Helpers
// =============================================================================

Widget buildTestWidget(
  Widget child, {
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(home: child),
  );
}

/// testWidgets with a large surface and overflow error suppression.
void testTask(
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

// =============================================================================
// Tests
// =============================================================================

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // TaskListScreen
  // ─────────────────────────────────────────────────────────────────────────
  group('TaskListScreen', () {
    late FakeTaskRepository fakeTaskRepo;

    setUp(() {
      fakeTaskRepo = FakeTaskRepository();
    });

    List<Override> overrides() => [
          taskRepositoryProvider.overrideWithValue(fakeTaskRepo),
        ];

    testTask('renders Discover Tasks title in AppBar', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const TaskListScreen(),
        overrides: overrides(),
      ));
      await tester.pump();
      expect(find.text('Discover Tasks'), findsOneWidget);
    });

    testTask('renders category filter chips including All chip',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const TaskListScreen(),
        overrides: overrides(),
      ));
      await tester.pump();
      // 'All' chip
      expect(find.text('All'), findsOneWidget);
      // At least the first category label
      expect(find.text(AppCategories.all.first.label), findsWidgets);
    });

    testTask('shows empty state widget when no tasks', (tester) async {
      fakeTaskRepo.tasksToReturn = [];
      await tester.pumpWidget(buildTestWidget(
        const TaskListScreen(),
        overrides: overrides(),
      ));
      // Let microtask stream emit empty list then rebuild
      await tester.pumpAndSettle();
      expect(find.text('No tasks found'), findsOneWidget);
      expect(find.text('Try a different category or check back later'),
          findsOneWidget);
    });

    testTask('shows loading state initially', (tester) async {
      // Use a repo that never emits so loading persists
      final neverEmitRepo = _NeverEmitTaskRepository();
      await tester.pumpWidget(buildTestWidget(
        const TaskListScreen(),
        overrides: [taskRepositoryProvider.overrideWithValue(neverEmitRepo)],
      ));
      await tester.pump();
      // Should not show empty state or task data — it's still loading
      expect(find.text('No tasks found'), findsNothing);
      expect(find.text('Discover Tasks'), findsOneWidget);
    });

    testTask('shows friendly error when tasks fail to load', (tester) async {
      final errorRepo = _ErrorTaskRepository();
      await tester.pumpWidget(buildTestWidget(
        const TaskListScreen(),
        overrides: [taskRepositoryProvider.overrideWithValue(errorRepo)],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Could not load available tasks right now.'),
          findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // PostTaskScreen
  // ─────────────────────────────────────────────────────────────────────────
  group('PostTaskScreen', () {
    final user = _testUser();

    List<Override> overrides() => [
          currentUserProvider.overrideWith((_) => Stream.value(user)),
          taskRepositoryProvider.overrideWithValue(
            FakeTaskRepository(),
          ),
        ];

    testTask('renders step 1 with category grid (10 categories)',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const PostTaskScreen(),
        overrides: overrides(),
      ));
      await tester.pump();

      // Check all 10 categories are present by emoji
      for (final cat in AppCategories.all) {
        expect(find.text(cat.emoji), findsOneWidget);
      }
    });

    testTask('category cards show emoji and label', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const PostTaskScreen(),
        overrides: overrides(),
      ));
      await tester.pump();

      // Check first category has both emoji and label
      final firstCat = AppCategories.all.first;
      expect(find.text(firstCat.emoji), findsOneWidget);
      expect(find.text(firstCat.label), findsOneWidget);
    });

    testTask('Next button exists at bottom', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const PostTaskScreen(),
        overrides: overrides(),
      ));
      await tester.pump();

      expect(find.text('Next'), findsOneWidget);
    });

    testTask('renders step 1 heading', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const PostTaskScreen(),
        overrides: overrides(),
      ));
      await tester.pump();

      expect(find.text('What do you need help with?'), findsOneWidget);
    });

    testTask('shows Post a Task title with step progress', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const PostTaskScreen(),
        overrides: overrides(),
      ));
      await tester.pump();

      expect(find.text('Post a Task  (1/5)'), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // TaskDetailScreen
  // ─────────────────────────────────────────────────────────────────────────
  group('TaskDetailScreen', () {
    late FakeTaskRepository fakeTaskRepo;
    late FakeBidRepository fakeBidRepo;
    late FakeChatRepository fakeChatRepo;

    setUp(() {
      fakeBidRepo = FakeBidRepository();
      fakeChatRepo = FakeChatRepository();
    });

    List<Override> baseOverrides({
      required UserModel user,
      required FakeTaskRepository taskRepo,
    }) =>
        [
          taskRepositoryProvider.overrideWithValue(taskRepo),
          bidRepositoryProvider.overrideWithValue(fakeBidRepo),
          chatRepositoryProvider.overrideWithValue(fakeChatRepo),
          currentUserProvider.overrideWith((_) => Stream.value(user)),
        ];

    testTask('renders task title, description, budget', (tester) async {
      final task = _testTask();
      fakeTaskRepo = FakeTaskRepository(tasksToReturn: [task]);

      await tester.pumpWidget(buildTestWidget(
        TaskDetailScreen(taskId: task.id),
        overrides: baseOverrides(
          user: _testUser(uid: 'other-user', role: UserRole.provider),
          taskRepo: fakeTaskRepo,
        ),
      ));
      await tester.pump();

      // Title appears in AppBar and body
      expect(find.text(task.title), findsWidgets);
      // Description
      expect(find.text(task.description), findsOneWidget);
      // Budget display (S$50 – S$100)
      expect(find.text(task.budgetDisplay), findsOneWidget);
    });

    testTask('shows recovery state when task is missing', (tester) async {
      fakeTaskRepo = FakeTaskRepository(tasksToReturn: const []);

      await tester.pumpWidget(buildTestWidget(
        const TaskDetailScreen(taskId: 'missing-task'),
        overrides: baseOverrides(
          user: _testUser(uid: 'provider-1', role: UserRole.provider),
          taskRepo: fakeTaskRepo,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Task no longer available'), findsOneWidget);
      expect(find.text('Browse Tasks'), findsOneWidget);
    });

    testTask('shows Submit Bid button for provider role user when task is open',
        (tester) async {
      final task = _testTask(status: TaskStatus.open);
      fakeTaskRepo = FakeTaskRepository(tasksToReturn: [task]);

      await tester.pumpWidget(buildTestWidget(
        TaskDetailScreen(taskId: task.id),
        overrides: baseOverrides(
          user: _testUser(uid: 'provider-1', role: UserRole.provider),
          taskRepo: fakeTaskRepo,
        ),
      ));
      await tester.pump();

      expect(find.text('Submit Bid'), findsOneWidget);
    });

    testTask('shows Mark as Complete button for poster when task is assigned',
        (tester) async {
      final task = _testTask(
        status: TaskStatus.assigned,
        assignedProviderId: 'provider-1',
        assignedProviderName: 'Provider',
      );
      fakeTaskRepo = FakeTaskRepository(tasksToReturn: [task]);

      await tester.pumpWidget(buildTestWidget(
        TaskDetailScreen(taskId: task.id),
        overrides: baseOverrides(
          user: _testUser(uid: 'user-1', role: UserRole.poster),
          taskRepo: fakeTaskRepo,
        ),
      ));
      await tester.pump();

      expect(find.text('Mark as Complete'), findsOneWidget);
    });

    testTask('shows Mark as Complete button for poster when task is inProgress',
        (tester) async {
      final task = _testTask(
        status: TaskStatus.inProgress,
        assignedProviderId: 'provider-1',
        assignedProviderName: 'Provider',
      );
      fakeTaskRepo = FakeTaskRepository(tasksToReturn: [task]);

      await tester.pumpWidget(buildTestWidget(
        TaskDetailScreen(taskId: task.id),
        overrides: baseOverrides(
          user: _testUser(uid: 'user-1', role: UserRole.poster),
          taskRepo: fakeTaskRepo,
        ),
      ));
      await tester.pump();

      expect(find.text('Mark as Complete'), findsOneWidget);
    });

    testTask('shows BidListSection for poster role user', (tester) async {
      final task = _testTask();
      fakeTaskRepo = FakeTaskRepository(tasksToReturn: [task]);

      await tester.pumpWidget(buildTestWidget(
        TaskDetailScreen(taskId: task.id),
        overrides: baseOverrides(
          user: _testUser(uid: 'user-1', role: UserRole.poster),
          taskRepo: fakeTaskRepo,
        ),
      ));
      await tester.pump();

      // BidListSection is rendered for poster
      expect(find.byType(BidListSection), findsOneWidget);
    });

    testTask('does not show Submit Bid for poster', (tester) async {
      final task = _testTask();
      fakeTaskRepo = FakeTaskRepository(tasksToReturn: [task]);

      await tester.pumpWidget(buildTestWidget(
        TaskDetailScreen(taskId: task.id),
        overrides: baseOverrides(
          user: _testUser(uid: 'user-1', role: UserRole.poster),
          taskRepo: fakeTaskRepo,
        ),
      ));
      await tester.pump();

      expect(find.text('Submit Bid'), findsNothing);
    });

    testTask('shows friendly error when opening chat fails', (tester) async {
      final task = _testTask(
        status: TaskStatus.assigned,
        assignedProviderId: 'provider-1',
        assignedProviderName: 'Provider',
      );
      fakeTaskRepo = FakeTaskRepository(tasksToReturn: [task]);
      fakeChatRepo.shouldThrowOnCreateOrGetChat = true;

      await tester.pumpWidget(buildTestWidget(
        TaskDetailScreen(taskId: task.id),
        overrides: baseOverrides(
          user: _testUser(uid: 'user-1', role: UserRole.poster),
          taskRepo: fakeTaskRepo,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Message Provider'));
      await tester.pumpAndSettle();

      expect(
        find.text('Could not open chat right now. Please try again.'),
        findsOneWidget,
      );
    });
  });

  group('BidListSection', () {
    testTask('shows friendly error when bids fail to load', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const Scaffold(
          body: BidListSection(
            taskId: 'task-1',
            posterId: 'user-1',
          ),
        ),
        overrides: [
          bidRepositoryProvider.overrideWithValue(
            FakeBidRepository(shouldThrowOnGetBids: true),
          ),
          chatRepositoryProvider.overrideWithValue(FakeChatRepository()),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Could not load bids for this task right now.'),
          findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testTask('shows friendly error when bidder chat fails to open',
        (tester) async {
      final chatRepo = FakeChatRepository()
        ..shouldThrowOnCreateOrGetChat = true;
      await tester.pumpWidget(buildTestWidget(
        const Scaffold(
          body: BidListSection(
            taskId: 'task-1',
            posterId: 'user-1',
          ),
        ),
        overrides: [
          bidRepositoryProvider.overrideWithValue(
            FakeBidRepository(
              bidsToReturn: [
                const BidModel(
                  bidId: 'bid-1',
                  taskId: 'task-1',
                  providerId: 'provider-1',
                  providerName: 'Provider',
                  amount: 60,
                  status: BidStatus.pending,
                ),
              ],
            ),
          ),
          chatRepositoryProvider.overrideWithValue(chatRepo),
        ],
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Message'));
      await tester.pumpAndSettle();

      expect(
        find.text('Could not open chat right now. Please try again.'),
        findsOneWidget,
      );
    });
  });
}

class _ErrorTaskRepository extends TaskRepository {
  _ErrorTaskRepository()
      : super(db: FakeFirebaseFirestore(), storage: FakeFirebaseStorage());

  @override
  Stream<List<TaskModel>> watchOpenTasks({
    String? categoryId,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) {
    return Stream.error(Exception('boom'));
  }
}
