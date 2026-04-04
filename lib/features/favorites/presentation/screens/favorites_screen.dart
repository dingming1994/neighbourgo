import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/constants/category_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../tasks/data/models/task_model.dart';
import '../../../tasks/data/repositories/task_repository.dart';
import '../../../profile/data/repositories/profile_repository.dart';
import '../../domain/providers/favorites_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.bgLight,
        appBar: AppBar(
          backgroundColor: AppColors.bgCard,
          elevation: 0,
          title: const Text(
            'Favorites',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textHint,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Saved Tasks'),
              Tab(text: 'Saved Providers'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _SavedTasksTab(),
            _SavedProvidersTab(),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Saved Tasks tab
// ─────────────────────────────────────────────────────────────────────────────
class _SavedTasksTab extends ConsumerWidget {
  const _SavedTasksTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favAsync = ref.watch(favoritesProvider);

    return favAsync.when(skipLoadingOnReload: true,
      loading: () => const _ShimmerList(),
      error: (e, _) => ErrorState(
        message: 'Could not load your saved tasks right now.',
        onRetry: () => ref.invalidate(favoritesProvider),
      ),
      data: (items) {
        final taskItems =
            items.where((f) => f.type == 'task').toList();
        if (taskItems.isEmpty) {
          return const _EmptyState(
            emoji: '\u2764\uFE0F',
            title: 'No saved tasks yet',
            subtitle: 'Tap the heart on any task to save it here',
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(favoritesProvider),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: taskItems.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSpacing.sm),
            itemBuilder: (_, i) =>
                _FavoriteTaskCard(taskId: taskItems[i].itemId),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Saved Providers tab
// ─────────────────────────────────────────────────────────────────────────────
class _SavedProvidersTab extends ConsumerWidget {
  const _SavedProvidersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favAsync = ref.watch(favoritesProvider);

    return favAsync.when(skipLoadingOnReload: true,
      loading: () => const _ShimmerList(),
      error: (e, _) => ErrorState(
        message: 'Could not load your saved providers right now.',
        onRetry: () => ref.invalidate(favoritesProvider),
      ),
      data: (items) {
        final providerItems =
            items.where((f) => f.type == 'provider').toList();
        if (providerItems.isEmpty) {
          return const _EmptyState(
            emoji: '\u2764\uFE0F',
            title: 'No saved providers yet',
            subtitle: 'Tap the heart on any provider to save them here',
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(favoritesProvider),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: providerItems.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSpacing.sm),
            itemBuilder: (_, i) => _FavoriteProviderCard(
                providerId: providerItems[i].itemId),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual favorite task card (loads task by ID)
// ─────────────────────────────────────────────────────────────────────────────
final _taskByIdProvider = StreamProvider.family<TaskModel?, String>(
  (ref, id) => ref.watch(taskRepositoryProvider).watchTask(id),
);

class _FavoriteTaskCard extends ConsumerWidget {
  final String taskId;
  const _FavoriteTaskCard({required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskAsync = ref.watch(_taskByIdProvider(taskId));
    final favIds = ref.watch(favoriteIdsProvider);

    return taskAsync.when(skipLoadingOnReload: true,
      loading: () => const _ShimmerCard(),
      error: (_, __) => _UnavailableFavoriteCard(
        icon: Icons.error_outline,
        title: 'Could not load this saved task',
        subtitle: 'It may be temporarily unavailable. You can retry or remove it.',
        primaryLabel: 'Retry',
        onPrimary: () => ref.invalidate(_taskByIdProvider(taskId)),
        secondaryLabel: 'Remove',
        onSecondary: () => toggleFavorite(ref, itemId: taskId, type: 'task'),
      ),
      data: (task) {
        if (task == null) {
          return _UnavailableFavoriteCard(
            icon: Icons.inventory_2_outlined,
            title: 'Saved task unavailable',
            subtitle: 'This task may have been removed or is no longer available.',
            primaryLabel: 'Remove',
            onPrimary: () => toggleFavorite(ref, itemId: taskId, type: 'task'),
          );
        }
        final category = AppCategories.getById(task.categoryId);
        final categoryColor =
            AppColors.categoryColors[task.categoryId] ?? AppColors.primary;

        return GestureDetector(
          onTap: () => context.push('/tasks/${task.id}'),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: AppRadius.card,
              border: Border.all(color: AppColors.divider),
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category badge + favorite
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha: 0.12),
                        borderRadius: AppRadius.chip,
                      ),
                      child: Text(
                        '${category?.emoji ?? '\u{1F4CB}'} ${category?.label ?? task.categoryId}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: categoryColor,
                        ),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () =>
                          toggleFavorite(ref, itemId: taskId, type: 'task'),
                      child: Icon(
                        favIds.contains(taskId)
                            ? Icons.favorite
                            : Icons.favorite_outline,
                        size: 20,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  task.title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: AppColors.textHint),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        task.neighbourhood ?? task.locationLabel,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      task.budgetDisplay,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual favorite provider card (loads user by ID)
// ─────────────────────────────────────────────────────────────────────────────
final _providerByIdProvider = StreamProvider.family<UserModel?, String>(
  (ref, uid) => ref.watch(profileRepositoryProvider).watchProfile(uid),
);

class _FavoriteProviderCard extends ConsumerWidget {
  final String providerId;
  const _FavoriteProviderCard({required this.providerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provAsync = ref.watch(_providerByIdProvider(providerId));
    final favIds = ref.watch(favoriteIdsProvider);

    return provAsync.when(skipLoadingOnReload: true,
      loading: () => const _ShimmerCard(),
      error: (_, __) => _UnavailableFavoriteCard(
        icon: Icons.error_outline,
        title: 'Could not load this saved provider',
        subtitle: 'It may be temporarily unavailable. You can retry or remove it.',
        primaryLabel: 'Retry',
        onPrimary: () => ref.invalidate(_providerByIdProvider(providerId)),
        secondaryLabel: 'Remove',
        onSecondary: () =>
            toggleFavorite(ref, itemId: providerId, type: 'provider'),
      ),
      data: (provider) {
        if (provider == null) {
          return _UnavailableFavoriteCard(
            icon: Icons.person_off_outlined,
            title: 'Saved provider unavailable',
            subtitle:
                'This provider profile may have been removed or is no longer public.',
            primaryLabel: 'Remove',
            onPrimary: () =>
                toggleFavorite(ref, itemId: providerId, type: 'provider'),
          );
        }
        final stats = provider.stats;
        final avgRating = stats?.avgRating ?? 0.0;

        return GestureDetector(
          onTap: () => context.push('/profile/${provider.uid}'),
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
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.bgMint,
                  backgroundImage: provider.avatarUrl != null
                      ? CachedNetworkImageProvider(provider.avatarUrl!)
                      : null,
                  child: provider.avatarUrl == null
                      ? const Icon(Icons.person,
                          color: AppColors.primary, size: 24)
                      : null,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.displayName ?? 'Provider',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          if (provider.neighbourhood != null) ...[
                            const Icon(Icons.location_on_outlined,
                                size: 14, color: AppColors.textHint),
                            const SizedBox(width: 2),
                            Text(provider.neighbourhood!,
                                style:
                                    Theme.of(context).textTheme.bodySmall),
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
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => toggleFavorite(ref,
                      itemId: providerId, type: 'provider'),
                  child: Icon(
                    favIds.contains(providerId)
                        ? Icons.favorite
                        : Icons.favorite_outline,
                    size: 20,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared widgets
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  const _EmptyState({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 56)),
              const SizedBox(height: AppSpacing.md),
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.sm),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
}

class _UnavailableFavoriteCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  const _UnavailableFavoriteCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.divider),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      OutlinedButton(
                        onPressed: onPrimary,
                        child: Text(primaryLabel),
                      ),
                      if (secondaryLabel != null && onSecondary != null)
                        TextButton(
                          onPressed: onSecondary,
                          child: Text(secondaryLabel!),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _ShimmerList extends StatelessWidget {
  const _ShimmerList();

  @override
  Widget build(BuildContext context) => ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, __) => const _ShimmerCard(),
      );
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
        baseColor: AppColors.divider,
        highlightColor: AppColors.bgLight,
        child: Container(
          height: 88,
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: AppRadius.card,
          ),
        ),
      );
}
