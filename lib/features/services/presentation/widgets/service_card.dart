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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover photo
            AspectRatio(
              aspectRatio: 16 / 10,
              child: listing.photoUrls.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: listing.photoUrls.first,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: AppColors.bgMint),
                      errorWidget: (_, __, ___) =>
                          Container(color: AppColors.bgMint),
                    )
                  : Container(
                      color: catColor.withValues(alpha: 0.1),
                      child: Center(
                        child:
                            Text(emoji, style: const TextStyle(fontSize: 32)),
                      ),
                    ),
            ),

            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    listing.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),

                  // Provider name
                  Text(
                    listing.providerName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Rating row
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 14, color: Colors.amber),
                      const SizedBox(width: 2),
                      const Text(
                        'New',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      if (listing.neighbourhood != null &&
                          listing.neighbourhood!.isNotEmpty) ...[
                        const Icon(Icons.location_on_outlined,
                            size: 12, color: AppColors.textHint),
                        const SizedBox(width: 1),
                        Flexible(
                          child: Text(
                            listing.neighbourhood!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textHint,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Price
                  Text(
                    listing.rateDisplay,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Hire button
                  SizedBox(
                    width: double.infinity,
                    height: 30,
                    child: ElevatedButton(
                      onPressed: () {
                        context.push(AppRoutes.postTask, extra: {
                          'directHireProviderId': listing.providerId,
                          'directHireProviderName': listing.providerName,
                          'preSelectedCategory': listing.categoryId,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Hire'),
                    ),
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
