import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/task_model.dart';
import '../../data/repositories/task_repository.dart';
import '../../../../core/constants/app_constants.dart';

const _taskListLoadErrorMessage = 'Could not load available tasks right now.';

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────
class TaskListState {
  final List<TaskModel> tasks;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;

  const TaskListState({
    this.tasks = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  TaskListState copyWith({
    List<TaskModel>? tasks,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    bool clearError = false,
  }) =>
      TaskListState(
        tasks: tasks ?? this.tasks,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasMore: hasMore ?? this.hasMore,
        error: clearError ? null : (error ?? this.error),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────
class TaskListNotifier extends StateNotifier<TaskListState> {
  final TaskRepository _repo;
  StreamSubscription<List<TaskModel>>? _sub;
  String? _categoryId;
  int _currentLimit = AppConstants.pageSize;

  TaskListNotifier(this._repo) : super(const TaskListState()) {
    _subscribe();
  }

  void _subscribe() {
    _sub?.cancel();
    _sub = _repo
        .watchOpenTasks(
          categoryId: _categoryId,
          limit: _currentLimit,
        )
        .listen(
          (tasks) {
            if (!mounted) return;
            state = state.copyWith(
              tasks: tasks,
              isLoading: false,
              isLoadingMore: false,
              hasMore: tasks.length >= _currentLimit,
              clearError: true,
            );
          },
          onError: (e) {
            if (!mounted) return;
            state = state.copyWith(
              isLoading: false,
              isLoadingMore: false,
              error: _taskListLoadErrorMessage,
            );
          },
        );
  }

  void selectCategory(String? categoryId) {
    if (_categoryId == categoryId) return;
    _categoryId = categoryId;
    _currentLimit = AppConstants.pageSize;
    state = const TaskListState(isLoading: true);
    _subscribe();
  }

  void loadMore() {
    if (!state.hasMore || state.isLoadingMore || state.isLoading) return;
    _currentLimit += AppConstants.pageSize;
    state = state.copyWith(isLoadingMore: true);
    _subscribe();
  }

  Future<void> refresh() async {
    _currentLimit = AppConstants.pageSize;
    state = const TaskListState(isLoading: true);
    _subscribe();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter & Sort
// ─────────────────────────────────────────────────────────────────────────────
enum TaskSortOption { newest, priceLowHigh, priceHighLow }

class TaskFilterState {
  final double? budgetMin;
  final double? budgetMax;
  final String? neighbourhood;
  final TaskSortOption sort;

  const TaskFilterState({
    this.budgetMin,
    this.budgetMax,
    this.neighbourhood,
    this.sort = TaskSortOption.newest,
  });

  TaskFilterState copyWith({
    double? budgetMin,
    double? budgetMax,
    String? neighbourhood,
    TaskSortOption? sort,
    bool clearBudgetMin = false,
    bool clearBudgetMax = false,
    bool clearNeighbourhood = false,
  }) =>
      TaskFilterState(
        budgetMin: clearBudgetMin ? null : (budgetMin ?? this.budgetMin),
        budgetMax: clearBudgetMax ? null : (budgetMax ?? this.budgetMax),
        neighbourhood:
            clearNeighbourhood ? null : (neighbourhood ?? this.neighbourhood),
        sort: sort ?? this.sort,
      );

  int get activeCount {
    int count = 0;
    if (budgetMin != null) count++;
    if (budgetMax != null) count++;
    if (neighbourhood != null) count++;
    if (sort != TaskSortOption.newest) count++;
    return count;
  }

  static const empty = TaskFilterState();
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────
final selectedCategoryProvider = StateProvider<String?>((ref) => null);
final taskFilterProvider = StateProvider<TaskFilterState>(
    (ref) => const TaskFilterState());

final taskListNotifierProvider =
    StateNotifierProvider.autoDispose<TaskListNotifier, TaskListState>((ref) {
  return TaskListNotifier(ref.watch(taskRepositoryProvider));
});
