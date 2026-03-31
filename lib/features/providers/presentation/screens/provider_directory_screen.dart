import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../auth/data/models/user_model.dart';
import '../../domain/providers/provider_list_provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/category_constants.dart';
import '../../../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
class ProviderDirectoryScreen extends ConsumerStatefulWidget {
  const ProviderDirectoryScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(providerListNotifierProvider);
    final selectedCategory = ref.watch(providerDirectoryCategoryProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(title: const Text('Browse Providers')),
      body: Column(
        children: [
          _CategoryFilterBar(
            selected: selectedCategory,
            onSelect: (id) {
              ref.read(providerDirectoryCategoryProvider.notifier).state = id;
              ref.read(providerListNotifierProvider.notifier).selectCategory(id);
            },
          ),
          Expanded(child: _buildBody(state)),
        ],
      ),
    );
  }

  Widget _buildBody(ProviderListState state) {
    if (state.isLoading) return const _LoadingList();

    if (state.error != null) {
      return _ErrorView(
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

  const _CategoryFilterBar({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgCard,
      child: Column(
        children: [
          SingleChildScrollView(
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

// ─────────────────────────────────────────────────────────────────────────────
// Provider Card
// ─────────────────────────────────────────────────────────────────────────────
class _ProviderCard extends StatelessWidget {
  final UserModel provider;
  final VoidCallback onTap;

  const _ProviderCard({required this.provider, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final stats = provider.stats;
    final avgRating = stats?.avgRating ?? 0.0;
    final completedTasks = stats?.completedTasks ?? 0;

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
          border: Border.all(color: AppColors.divider),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
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
            const SizedBox(width: AppSpacing.md),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name row
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
                      if (provider.isOnline)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 6),
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
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

                  const SizedBox(height: AppSpacing.sm),

                  // Neighbourhood + Rating + Tasks
                  Row(
                    children: [
                      if (provider.neighbourhood != null) ...[
                        const Icon(Icons.location_on_outlined,
                            size: 14, color: AppColors.textHint),
                        const SizedBox(width: 2),
                        Text(
                          provider.neighbourhood!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      if (avgRating > 0) ...[
                        const Icon(Icons.star_rounded,
                            size: 14, color: AppColors.accent),
                        const SizedBox(width: 2),
                        Text(
                          avgRating.toStringAsFixed(1),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      if (completedTasks > 0) ...[
                        const Icon(Icons.check_circle_outline_rounded,
                            size: 14, color: AppColors.textHint),
                        const SizedBox(width: 2),
                        Text(
                          '$completedTasks done',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Category chips + starting rate
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
                      if (startingRate != null)
                        Text(
                          startingRate,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
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

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 52, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: 160,
              child: OutlinedButton(
                onPressed: onRetry,
                child: const Text('Try Again'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
