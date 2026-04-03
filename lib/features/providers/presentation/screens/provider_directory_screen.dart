import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../auth/data/models/user_model.dart';
import '../../../favorites/domain/providers/favorites_provider.dart';
import '../../domain/providers/provider_list_provider.dart';
import '../widgets/provider_filter_sheet.dart';
import '../../../discover/presentation/screens/discover_screen.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/category_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/error_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
class ProviderDirectoryScreen extends ConsumerStatefulWidget {
  final bool embedded;

  const ProviderDirectoryScreen({super.key, this.embedded = false});

  @override
  ConsumerState<ProviderDirectoryScreen> createState() =>
      _ProviderDirectoryScreenState();
}

class _ProviderDirectoryScreenState
    extends ConsumerState<ProviderDirectoryScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      ref.read(providerListNotifierProvider.notifier).loadMore();
    }
  }

  List<UserModel> _applyFiltersAndSort(
      List<UserModel> providers, ProviderFilterState filter) {
    var result = providers.toList();

    // Min rating filter
    if (filter.minRating != null) {
      result = result
          .where((p) => (p.stats?.avgRating ?? 0) >= filter.minRating!)
          .toList();
    }

    // Neighbourhood filter
    if (filter.neighbourhood != null) {
      final n = filter.neighbourhood!.toLowerCase();
      result = result
          .where((p) =>
              (p.neighbourhood ?? '').toLowerCase().contains(n))
          .toList();
    }

    // Sort
    switch (filter.sort) {
      case ProviderSortOption.highestRated:
        result.sort((a, b) =>
            (b.stats?.avgRating ?? 0).compareTo(a.stats?.avgRating ?? 0));
      case ProviderSortOption.mostReviews:
        result.sort((a, b) =>
            (b.stats?.totalReviews ?? 0).compareTo(a.stats?.totalReviews ?? 0));
      case ProviderSortOption.newest:
        result.sort((a, b) =>
            (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(providerListNotifierProvider);
    final selectedCategory = ref.watch(providerDirectoryCategoryProvider);
    final filter = ref.watch(providerFilterProvider);
    final searchQuery =
        widget.embedded ? ref.watch(discoverSearchQueryProvider) : '';

    // Apply client-side search filter
    var filteredProviders = state.providers;
    if (searchQuery.isNotEmpty) {
      filteredProviders = filteredProviders.where((p) {
        final name = (p.displayName ?? '').toLowerCase();
        final headline = (p.headline ?? '').toLowerCase();
        final categories = p.serviceCategories
            .map((c) => c.toLowerCase())
            .join(' ');
        return name.contains(searchQuery) ||
            headline.contains(searchQuery) ||
            categories.contains(searchQuery);
      }).toList();
    }

    // Apply advanced filters & sort
    filteredProviders = _applyFiltersAndSort(filteredProviders, filter);

    final filteredState = state.copyWith(providers: filteredProviders);

    final body = Column(
      children: [
        _CategoryFilterBar(
          selected: selectedCategory,
          onSelect: (id) {
            ref.read(providerDirectoryCategoryProvider.notifier).state = id;
            ref.read(providerListNotifierProvider.notifier).selectCategory(id);
          },
          filterCount: filter.activeCount,
          onFilterTap: () => showProviderFilterSheet(context, ref),
        ),
        Expanded(child: _buildBody(filteredState)),
      ],
    );

    if (widget.embedded) {
      return ColoredBox(
        color: AppColors.bgLight,
        child: body,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(title: const Text('Browse Providers')),
      body: body,
    );
  }

  Widget _buildBody(ProviderListState state) {
    if (state.isLoading) return const _LoadingList();

    if (state.error != null) {
      return ErrorState(
        message: state.error!,
        onRetry: () =>
            ref.read(providerListNotifierProvider.notifier).refresh(),
      );
    }

    if (state.providers.isEmpty) return const _EmptyView();

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () =>
          ref.read(providerListNotifierProvider.notifier).refresh(),
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.xxl,
        ),
        itemCount: state.providers.length + (state.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index >= state.providers.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            );
          }
          final provider = state.providers[index];
          return _ProviderCard(
            provider: provider,
            onTap: () => context.push(
              AppRoutes.publicProfile
                  .replaceFirst(':userId', provider.uid),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category Filter Bar (reuses same pattern as TaskListScreen)
// ─────────────────────────────────────────────────────────────────────────────
class _CategoryFilterBar extends StatelessWidget {
  final String? selected;
  final void Function(String?) onSelect;
  final int filterCount;
  final VoidCallback? onFilterTap;

  const _CategoryFilterBar({
    required this.selected,
    required this.onSelect,
    this.filterCount = 0,
    this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgCard,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        emoji: '✨',
                        selected: selected == null,
                        onTap: () => onSelect(null),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      ...AppCategories.all.map(
                        (cat) => Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: _FilterChip(
                            label: cat.label,
                            emoji: cat.emoji,
                            selected: selected == cat.id,
                            color: cat.color,
                            onTap: () =>
                                onSelect(selected == cat.id ? null : cat.id),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (onFilterTap != null)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: _FilterIconButton(
                    count: filterCount,
                    onTap: onFilterTap!,
                  ),
                ),
            ],
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String emoji;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color:
              selected ? chipColor.withValues(alpha: 0.12) : AppColors.bgMint,
          borderRadius: AppRadius.chip,
          border: Border.all(
            color: selected ? chipColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? chipColor : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterIconButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _FilterIconButton({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: count > 0
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : AppColors.bgMint,
              borderRadius: AppRadius.chip,
              border: Border.all(
                color: count > 0 ? AppColors.primary : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.tune_rounded,
              size: 18,
              color: count > 0 ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
          if (count > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider Card
// ─────────────────────────────────────────────────────────────────────────────
class _ProviderCard extends ConsumerWidget {
  final UserModel provider;
  final VoidCallback onTap;

  const _ProviderCard({required this.provider, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(favoriteIdsProvider).contains(provider.uid);
    final stats = provider.stats;
    final avgRating = stats?.avgRating ?? 0.0;
    final totalReviews = stats?.totalReviews ?? 0;

    // Top 2 service categories
    final topCategories = provider.serviceCategories.take(2).toList();

    // Starting rate: find the lowest hourly rate across categories
    String? startingRate;
    if (provider.serviceRates.isNotEmpty) {
      double? lowest;
      for (final entry in provider.serviceRates.entries) {
        final rateData = entry.value;
        if (rateData is Map && rateData['hourlyRate'] != null) {
          final rate = (rateData['hourlyRate'] as num).toDouble();
          if (lowest == null || rate < lowest) lowest = rate;
        }
      }
      if (lowest != null) {
        startingRate = 'From S\$${lowest.toStringAsFixed(0)}/hr';
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: AppRadius.card,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.bgMint,
                  backgroundImage: provider.avatarUrl != null
                      ? CachedNetworkImageProvider(provider.avatarUrl!)
                      : null,
                  child: provider.avatarUrl == null
                      ? const Icon(Icons.person, color: AppColors.primary)
                      : null,
                ),
                if (provider.isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.bgCard, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: AppSpacing.md),

            // Center info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + favorite
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          provider.displayName ?? 'Provider',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => toggleFavorite(ref,
                            itemId: provider.uid, type: 'provider'),
                        child: Icon(
                          isFavorite
                              ? Icons.favorite
                              : Icons.favorite_outline,
                          size: 20,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),

                  // Headline
                  if (provider.headline != null &&
                      provider.headline!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      provider.headline!,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 6),

                  // Rating stars + review count
                  Row(
                    children: [
                      ...List.generate(5, (i) {
                        if (i < avgRating.floor()) {
                          return const Icon(Icons.star_rounded,
                              size: 14, color: AppColors.accent);
                        } else if (i < avgRating.ceil() &&
                            avgRating % 1 >= 0.5) {
                          return const Icon(Icons.star_half_rounded,
                              size: 14, color: AppColors.accent);
                        }
                        return Icon(Icons.star_outline_rounded,
                            size: 14,
                            color: AppColors.textHint.withValues(alpha: 0.5));
                      }),
                      if (avgRating > 0) ...[
                        const SizedBox(width: 4),
                        Text(
                          avgRating.toStringAsFixed(1),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                      if (totalReviews > 0) ...[
                        const SizedBox(width: 4),
                        Text(
                          '($totalReviews)',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textHint),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Neighbourhood + starting rate
                  Row(
                    children: [
                      if (provider.neighbourhood != null) ...[
                        const Icon(Icons.location_on_outlined,
                            size: 14, color: AppColors.textHint),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            provider.neighbourhood!,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      if (startingRate != null) ...[
                        if (provider.neighbourhood != null)
                          const SizedBox(width: AppSpacing.sm),
                        Text(
                          startingRate,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Category chips + Hire button
                  Row(
                    children: [
                      ...topCategories.map((catId) {
                        final cat = AppCategories.getById(catId);
                        if (cat == null) return const SizedBox.shrink();
                        final catColor = AppColors.categoryColors[catId] ??
                            AppColors.primary;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.12),
                              borderRadius: AppRadius.chip,
                            ),
                            child: Text(
                              '${cat.emoji} ${cat.label}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: catColor,
                              ),
                            ),
                          ),
                        );
                      }),
                      const Spacer(),
                      SizedBox(
                        height: 30,
                        child: ElevatedButton(
                          onPressed: () => context.push(
                            AppRoutes.postTask,
                            extra: {
                              'directHireProviderId': provider.uid,
                              'directHireProviderName':
                                  provider.displayName ?? 'Provider',
                              'preSelectedCategory':
                                  provider.serviceCategories.isNotEmpty
                                      ? provider.serviceCategories.first
                                      : null,
                            },
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.button,
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Hire',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading / Empty / Error states
// ─────────────────────────────────────────────────────────────────────────────
class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, __) => const _SkeletonProviderCard(),
    );
  }
}

class _SkeletonProviderCard extends StatelessWidget {
  const _SkeletonProviderCard();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.divider,
      highlightColor: Colors.white,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: AppRadius.card,
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔍', style: TextStyle(fontSize: 52)),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No providers found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No providers found in this category',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

