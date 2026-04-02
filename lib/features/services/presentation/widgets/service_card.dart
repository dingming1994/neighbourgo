import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/category_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/service_listing_model.dart';

class ServiceCard extends StatelessWidget {
  final ServiceListingModel listing;
  final VoidCallback? onTap;

  const ServiceCard({super.key, required this.listing, this.onTap});

  @override
  Widget build(BuildContext context) {
    final category = AppCategories.getById(listing.categoryId);
    final emoji = category?.emoji ?? '📌';
    final catColor =
        AppColors.categoryColors[listing.categoryId] ?? AppColors.primary;

    return GestureDetector(
      onTap: onTap ??
          () => context.push(
                AppRoutes.serviceDetail
                    .replaceFirst(':listingId', listing.id),
              ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.divider),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo banner
            if (listing.photoUrls.isNotEmpty)
              SizedBox(
                height: 140,
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: listing.photoUrls.first,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: AppColors.bgMint),
                  errorWidget: (_, __, ___) =>
                      Container(color: AppColors.bgMint),
                ),
              )
            else
              Container(
                height: 80,
                width: double.infinity,
                color: catColor.withValues(alpha: 0.1),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 36)),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category chip
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.12),
                      borderRadius: AppRadius.chip,
                    ),
                    child: Text(
                      '${category?.emoji ?? ""} ${category?.label ?? listing.categoryId}',
                      style: TextStyle(
                        fontSize: 11,
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
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Description
                  Text(
                    listing.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Rate + neighbourhood
                  Row(
                    children: [
                      Text(
                        listing.rateDisplay,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const Spacer(),
                      if (listing.neighbourhood != null &&
                          listing.neighbourhood!.isNotEmpty) ...[
                        const Icon(Icons.location_on_outlined,
                            size: 14, color: AppColors.textHint),
                        const SizedBox(width: 2),
                        Text(
                          listing.neighbourhood!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Provider name
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      const Icon(Icons.person_outline,
                          size: 14, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          listing.providerName,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
