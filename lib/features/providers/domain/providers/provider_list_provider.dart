import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/data/models/user_model.dart';
import '../../data/repositories/provider_repository.dart';
import '../../../../core/constants/app_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────
class ProviderListState {
  final List<UserModel> providers;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;

  const ProviderListState({
    this.providers = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  ProviderListState copyWith({
    List<UserModel>? providers,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    bool clearError = false,
  }) =>
      ProviderListState(
        providers: providers ?? this.providers,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasMore: hasMore ?? this.hasMore,
        error: clearError ? null : (error ?? this.error),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────
class ProviderListNotifier extends StateNotifier<ProviderListState> {
  final ProviderRepository _repo;
  StreamSubscription<List<UserModel>>? _sub;
  String? _categoryId;
  int _currentLimit = AppConstants.pageSize;

  ProviderListNotifier(this._repo) : super(const ProviderListState()) {
    _subscribe();
  }

  void _subscribe() {
    _sub?.cancel();
    _sub = _repo
        .watchProviders(
          categoryId: _categoryId,
          limit: _currentLimit,
        )
        .listen(
          (providers) {
            if (!mounted) return;
            state = state.copyWith(
              providers: providers,
              isLoading: false,
              isLoadingMore: false,
              hasMore: providers.length >= _currentLimit,
              clearError: true,
            );
          },
          onError: (e) {
            if (!mounted) return;
            state = state.copyWith(
              isLoading: false,
              isLoadingMore: false,
              error: e.toString(),
            );
          },
        );
  }

  void selectCategory(String? categoryId) {
    if (_categoryId == categoryId) return;
    _categoryId = categoryId;
    _currentLimit = AppConstants.pageSize;
    state = const ProviderListState(isLoading: true);
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
    state = const ProviderListState(isLoading: true);
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
enum ProviderSortOption { highestRated, mostReviews, newest }

class ProviderFilterState {
  final double? minRating;
  final String? neighbourhood;
  final ProviderSortOption sort;

  const ProviderFilterState({
    this.minRating,
    this.neighbourhood,
    this.sort = ProviderSortOption.highestRated,
  });

  ProviderFilterState copyWith({
    double? minRating,
    String? neighbourhood,
    ProviderSortOption? sort,
    bool clearMinRating = false,
    bool clearNeighbourhood = false,
  }) =>
      ProviderFilterState(
        minRating: clearMinRating ? null : (minRating ?? this.minRating),
        neighbourhood:
            clearNeighbourhood ? null : (neighbourhood ?? this.neighbourhood),
        sort: sort ?? this.sort,
      );

  int get activeCount {
    int count = 0;
    if (minRating != null) count++;
    if (neighbourhood != null) count++;
    if (sort != ProviderSortOption.highestRated) count++;
    return count;
  }

  static const empty = ProviderFilterState();
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────
final providerDirectoryCategoryProvider = StateProvider<String?>((ref) => null);
final providerFilterProvider = StateProvider<ProviderFilterState>(
    (ref) => const ProviderFilterState());

final providerListNotifierProvider =
    StateNotifierProvider.autoDispose<ProviderListNotifier, ProviderListState>(
        (ref) {
  return ProviderListNotifier(ref.watch(providerRepositoryProvider));
});
