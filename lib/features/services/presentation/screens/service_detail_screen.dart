import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/category_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../data/models/service_listing_model.dart';
import '../../data/repositories/service_listing_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────
final serviceDetailProvider =
    StreamProvider.family<ServiceListingModel?, String>(
  (ref, id) => ref.watch(serviceListingRepositoryProvider).watchListing(id),
);

class ServiceDetailScreen extends ConsumerWidget {
  final String listingId;

  const ServiceDetailScreen({super.key, required this.listingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingAsync = ref.watch(serviceDetailProvider(listingId));

    return listingAsync.when(
      skipLoadingOnReload: true,
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: ErrorState(
          onRetry: () => ref.invalidate(serviceDetailProvider(listingId)),
        ),
      ),
      data: (listing) {
        if (listing == null) {
          return Scaffold(
            appBar: AppBar(),
            body: EmptyState(
              emoji: '🛠️',
              title: 'Service listing no longer available',
              subtitle:
                  'This listing may have been removed or the link is outdated.',
              action: ElevatedButton.icon(
                onPressed: () => context.go(AppRoutes.home),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.button,
                  ),
                ),
                icon: const Icon(Icons.home_outlined, size: 18),
                label: const Text('Go Home'),
              ),
            ),
          );
        }

        return _DetailContent(listing: listing);
      },
    );
  }
}

Future<void> _confirmDelete(
    BuildContext context, WidgetRef ref, String listingId) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete listing?'),
      content: const Text('This will permanently delete your service listing.'),
      actions: [
        TextButton(
          onPressed: () => ctx.pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => ctx.pop(true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  if (confirmed == true && context.mounted) {
    try {
      await ref.read(serviceListingRepositoryProvider).deleteListing(listingId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service listing deleted')),
        );
        context.pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }
}

class _DetailContent extends ConsumerWidget {
  final ServiceListingModel listing;

  const _DetailContent({required this.listing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = AppCategories.getById(listing.categoryId);
    final catColor =
        AppColors.categoryColors[listing.categoryId] ?? AppColors.primary;
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final isOwnListing = currentUser?.uid == listing.providerId;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: CustomScrollView(
        slivers: [
          // Photo app bar
          SliverAppBar(
            expandedHeight: listing.photoUrls.isNotEmpty ? 250 : 120,
            pinned: true,
            actions: isOwnListing
                ? [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit listing',
                      onPressed: () => context.push(
                        AppRoutes.editService
                            .replaceFirst(':listingId', listing.id),
                        extra: listing,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Delete listing',
                      onPressed: () => _confirmDelete(context, ref, listing.id),
                    ),
                  ]
                : null,
            flexibleSpace: FlexibleSpaceBar(
              background: listing.photoUrls.isNotEmpty
                  ? PageView(
                      children: listing.photoUrls
                          .map((url) => CachedNetworkImage(
                                imageUrl: url,
                                fit: BoxFit.cover,
                                placeholder: (_, __) =>
                                    Container(color: AppColors.bgMint),
                                errorWidget: (_, __, ___) =>
                                    Container(color: AppColors.bgMint),
                              ))
                          .toList(),
                    )
                  : Container(
                      color: catColor.withValues(alpha: 0.1),
                      child: Center(
                        child: Text(
                          category?.emoji ?? '📌',
                          style: const TextStyle(fontSize: 48),
                        ),
                      ),
                    ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category chip
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.12),
                      borderRadius: AppRadius.chip,
                    ),
                    child: Text(
                      '${category?.emoji ?? ""} ${category?.label ?? listing.categoryId}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: catColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Title
                  Text(
                    listing.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Provider name
                  GestureDetector(
                    onTap: () => context.push(
                      AppRoutes.publicProfile
                          .replaceFirst(':userId', listing.providerId),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          listing.providerName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Rate
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.bgMint,
                      borderRadius: AppRadius.card,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.payments_outlined,
                            color: AppColors.primary),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            listing.rateDisplay,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Description
                  const Text(
                    'About this service',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    listing.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),

                  // Availability
                  if (listing.availability != null &&
                      listing.availability!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'Availability',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        const Icon(Icons.schedule,
                            size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            listing.availability!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Neighbourhood
                  if (listing.neighbourhood != null &&
                      listing.neighbourhood!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          listing.neighbourhood!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // Hire button (only show to non-owners)
      bottomNavigationBar: isOwnListing
          ? null
          : Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.push(AppRoutes.postTask, extra: {
                        'directHireProviderId': listing.providerId,
                        'directHireProviderName': listing.providerName,
                        'preSelectedCategory': listing.categoryId,
                      });
                    },
                    icon: const Icon(Icons.handshake_outlined),
                    label: Text('Hire ${listing.providerName}'),
                  ),
                ),
              ),
            ),
    );
  }
}
