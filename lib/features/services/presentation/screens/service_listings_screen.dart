import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/category_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../discover/presentation/screens/discover_screen.dart';
import '../../data/models/service_listing_model.dart';
import '../../data/repositories/service_listing_repository.dart';
import '../widgets/service_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// State providers
// ─────────────────────────────────────────────────────────────────────────────
final _serviceCategoryProvider =
    StateProvider.autoDispose<String?>((ref) => null);

final _serviceListingsProvider =
    StreamProvider.autoDispose<List<ServiceListingModel>>((ref) {
  final categoryId = ref.watch(_serviceCategoryProvider);
  return ref
      .watch(serviceListingRepositoryProvider)
      .watchActiveListings(categoryId: categoryId);
});

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
class ServiceListingsScreen extends ConsumerWidget {
  final bool embedded;
  const ServiceListingsScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(_serviceListingsProvider);
    final selectedCategory = ref.watch(_serviceCategoryProvider);
    final searchQuery =
        embedded ? ref.watch(discoverSearchQueryProvider) : '';

    final body = Column(
      children: [
        _CategoryFilterBar(
          selected: selectedCategory,
          onSelect: (id) =>
              ref.read(_serviceCategoryProvider.notifier).state = id,
        ),
        Expanded(
          child: listingsAsync.when(
            loading: () => const _LoadingList(),
            error: (e, _) => Center(
              child: Text('Error: $e',
                  style: const TextStyle(color: AppColors.error)),
            ),
            data: (allListings) {
              final listings = searchQuery.isEmpty
                  ? allListings
                  : allListings.where((s) {
                      return s.title.toLowerCase().contains(searchQuery) ||
                          s.description.toLowerCase().contains(searchQuery) ||
                          s.providerName.toLowerCase().contains(searchQuery);
                    }).toList();
              if (listings.isEmpty) {
                return searchQuery.isNotEmpty
                    ? _SearchEmptyView(query: searchQuery)
                    : const _EmptyView();
              }
              return Column(
                children: [
                  if (searchQuery.isNotEmpty)
                    _SearchResultCount(
                      count: listings.length,
                      label: 'service',
                    ),
                  Expanded(
                    child: RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () async {
                        ref.invalidate(_serviceListingsProvider);
                      },
                      child: GridView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: AppSpacing.sm,
                          mainAxisSpacing: AppSpacing.sm,
                          childAspectRatio: 0.58,
                        ),
                        itemCount: listings.length,
                        itemBuilder: (_, i) =>
                            ServiceCard(listing: listings[i]),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );

    if (embedded) {
      return ColoredBox(color: AppColors.bgLight, child: body);
    }

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(title: const Text('Service Listings')),
      body: body,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category filter bar
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
// Loading / Empty
// ─────────────────────────────────────────────────────────────────────────────
class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 0.58,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: AppColors.divider,
        highlightColor: Colors.white,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: AppRadius.card,
          ),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🏪', style: TextStyle(fontSize: 52)),
            SizedBox(height: AppSpacing.md),
            Text(
              'No services listed yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Service listings from providers will appear here.',
              style: TextStyle(
                  fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchEmptyView extends StatelessWidget {
  final String query;
  const _SearchEmptyView({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 64,
              color: AppColors.textHint,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No results for "$query"',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Try adjusting your search or filters',
              style: TextStyle(
                  fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResultCount extends StatelessWidget {
  final int count;
  final String label;
  const _SearchResultCount({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      color: AppColors.bgLight,
      child: Text(
        '$count ${label}${count != 1 ? 's' : ''} found',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}
