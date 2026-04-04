import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neighbourgo/features/tasks/data/models/task_model.dart';
import 'package:neighbourgo/features/tasks/data/repositories/task_repository.dart';
import 'package:neighbourgo/features/tasks/domain/providers/task_list_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Fake TaskRepository for notifier tests
// ─────────────────────────────────────────────────────────────────────────────

class FakeTaskRepository extends TaskRepository {
  final StreamController<List<TaskModel>> _controller =
      StreamController<List<TaskModel>>.broadcast();
  String? lastCategoryId;
  int? lastLimit;
  int watchOpenTasksCallCount = 0;

  FakeTaskRepository()
      : super(db: _NoOpFirestore(), storage: _NoOpStorage());

  @override
  Stream<List<TaskModel>> watchOpenTasks({
    String? categoryId,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) {
    lastCategoryId = categoryId;
    lastLimit = limit;
    watchOpenTasksCallCount++;
    return _controller.stream;
  }

  void emitTasks(List<TaskModel> tasks) => _controller.add(tasks);
  void emitError(Object error) => _controller.addError(error);

  void dispose() => _controller.close();
}

// Minimal no-op implementations to satisfy super constructor
class _NoOpFirestore extends Fake implements FirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _NoOpCollectionReference();
}

class _NoOpCollectionReference extends Fake
    implements CollectionReference<Map<String, dynamic>> {}

class _NoOpStorage extends Fake implements FirebaseStorage {}

// ─────────────────────────────────────────────────────────────────────────────
// Helper to create a minimal TaskModel for tests
// ─────────────────────────────────────────────────────────────────────────────

TaskModel _makeTask(String id, {TaskStatus status = TaskStatus.open}) =>
    TaskModel(
      id: id,
      posterId: 'poster-1',
      title: 'Task $id',
      description: 'Description',
      categoryId: 'cleaning',
      locationLabel: 'Blk 1',
      budgetMin: 30.0,
      urgency: TaskUrgency.flexible,
      status: status,
    );

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('TaskListState', () {
    test('default state has empty tasks, isLoading=true, hasMore=true', () {
      const state = TaskListState();

      expect(state.tasks, isEmpty);
      expect(state.isLoading, isTrue);
      expect(state.isLoadingMore, isFalse);
      expect(state.hasMore, isTrue);
      expect(state.error, isNull);
    });

    test('copyWith updates individual fields', () {
      const state = TaskListState();
      final tasks = [_makeTask('t1'), _makeTask('t2')];

      final updated = state.copyWith(
        tasks: tasks,
        isLoading: false,
        hasMore: false,
      );

      expect(updated.tasks.length, 2);
      expect(updated.isLoading, isFalse);
      expect(updated.hasMore, isFalse);
      expect(updated.isLoadingMore, isFalse); // unchanged default
      expect(updated.error, isNull); // unchanged default
    });

    test('copyWith preserves unchanged fields', () {
      final state = TaskListState(
        tasks: [_makeTask('t1')],
        isLoading: false,
        hasMore: true,
        error: 'some error',
      );

      final updated = state.copyWith(isLoadingMore: true);

      expect(updated.tasks.length, 1);
      expect(updated.isLoading, isFalse);
      expect(updated.hasMore, isTrue);
      expect(updated.isLoadingMore, isTrue);
      expect(updated.error, 'some error');
    });

    test('copyWith clearError removes error', () {
      const state = TaskListState(error: 'oops');

      final updated = state.copyWith(clearError: true);

      expect(updated.error, isNull);
    });

    test('copyWith error overrides existing error', () {
      const state = TaskListState(error: 'old');

      final updated = state.copyWith(error: 'new');

      expect(updated.error, 'new');
    });
  });

  group('TaskListNotifier', () {
    late FakeTaskRepository fakeRepo;

    setUp(() {
      fakeRepo = FakeTaskRepository();
    });

    tearDown(() {
      fakeRepo.dispose();
    });

    test('initial state: empty tasks, isLoading=true, hasMore=true', () {
      final notifier = TaskListNotifier(fakeRepo);
      addTearDown(notifier.dispose);

      expect(notifier.state.tasks, isEmpty);
      expect(notifier.state.isLoading, isTrue);
      expect(notifier.state.hasMore, isTrue);
    });

    test('subscribes to watchOpenTasks on creation', () {
      final notifier = TaskListNotifier(fakeRepo);
      addTearDown(notifier.dispose);

      expect(fakeRepo.watchOpenTasksCallCount, 1);
    });

    test('updates state when tasks are emitted', () async {
      final notifier = TaskListNotifier(fakeRepo);
      addTearDown(notifier.dispose);

      final tasks = [_makeTask('t1'), _makeTask('t2')];
      fakeRepo.emitTasks(tasks);

      // Allow stream to propagate
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.tasks.length, 2);
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.isLoadingMore, isFalse);
    });

    test('hasMore is true when tasks.length >= limit', () async {
      final notifier = TaskListNotifier(fakeRepo);
      addTearDown(notifier.dispose);

      // Emit exactly pageSize (20) tasks — hasMore should be true
      final tasks = List.generate(20, (i) => _makeTask('t$i'));
      fakeRepo.emitTasks(tasks);
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.hasMore, isTrue);
    });

    test('hasMore is false when tasks.length < limit', () async {
      final notifier = TaskListNotifier(fakeRepo);
      addTearDown(notifier.dispose);

      // Emit fewer than pageSize tasks
      final tasks = [_makeTask('t1')];
      fakeRepo.emitTasks(tasks);
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.hasMore, isFalse);
    });

    test('sets error on stream error', () async {
      final notifier = TaskListNotifier(fakeRepo);
      addTearDown(notifier.dispose);

      fakeRepo.emitError(Exception('Network failure'));
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.error, isNotNull);
      expect(
        notifier.state.error,
        'Could not load available tasks right now.',
      );
      expect(notifier.state.isLoading, isFalse);
    });

    group('selectCategory', () {
      test('updates categoryId and re-subscribes', () async {
        final notifier = TaskListNotifier(fakeRepo);
        addTearDown(notifier.dispose);

        final initialCallCount = fakeRepo.watchOpenTasksCallCount;
        notifier.selectCategory('cleaning');

        expect(fakeRepo.lastCategoryId, 'cleaning');
        expect(fakeRepo.watchOpenTasksCallCount, initialCallCount + 1);
        expect(notifier.state.isLoading, isTrue);
      });

      test('does not re-subscribe for same category', () {
        final notifier = TaskListNotifier(fakeRepo);
        addTearDown(notifier.dispose);

        notifier.selectCategory('cleaning');
        final callCount = fakeRepo.watchOpenTasksCallCount;
        notifier.selectCategory('cleaning'); // same

        expect(fakeRepo.watchOpenTasksCallCount, callCount);
      });

      test('resets limit when category changes', () {
        final notifier = TaskListNotifier(fakeRepo);
        addTearDown(notifier.dispose);

        notifier.selectCategory('tutoring');

        expect(fakeRepo.lastLimit, 20); // AppConstants.pageSize
      });
    });

    group('refresh', () {
      test('resets state and reloads', () async {
        final notifier = TaskListNotifier(fakeRepo);
        addTearDown(notifier.dispose);

        // First get some data
        fakeRepo.emitTasks([_makeTask('t1')]);
        await Future<void>.delayed(Duration.zero);
        expect(notifier.state.isLoading, isFalse);

        final callCount = fakeRepo.watchOpenTasksCallCount;
        await notifier.refresh();

        expect(notifier.state.isLoading, isTrue);
        expect(fakeRepo.watchOpenTasksCallCount, callCount + 1);
        expect(fakeRepo.lastLimit, 20); // reset to pageSize
      });
    });

    group('loadMore', () {
      test('increases limit and re-subscribes', () async {
        final notifier = TaskListNotifier(fakeRepo);
        addTearDown(notifier.dispose);

        // Emit enough tasks to indicate hasMore
        final tasks = List.generate(20, (i) => _makeTask('t$i'));
        fakeRepo.emitTasks(tasks);
        await Future<void>.delayed(Duration.zero);

        final callCount = fakeRepo.watchOpenTasksCallCount;
        notifier.loadMore();

        expect(fakeRepo.lastLimit, 40); // 20 + 20
        expect(fakeRepo.watchOpenTasksCallCount, callCount + 1);
      });

      test('does not load if hasMore is false', () async {
        final notifier = TaskListNotifier(fakeRepo);
        addTearDown(notifier.dispose);

        // Emit fewer than pageSize => hasMore=false
        fakeRepo.emitTasks([_makeTask('t1')]);
        await Future<void>.delayed(Duration.zero);

        final callCount = fakeRepo.watchOpenTasksCallCount;
        notifier.loadMore();

        expect(fakeRepo.watchOpenTasksCallCount, callCount); // no change
      });

      test('does not load if already loading', () {
        final notifier = TaskListNotifier(fakeRepo);
        addTearDown(notifier.dispose);

        // State is already isLoading=true (initial state)
        final callCount = fakeRepo.watchOpenTasksCallCount;
        notifier.loadMore();

        expect(fakeRepo.watchOpenTasksCallCount, callCount); // no change
      });
    });
  });
}
