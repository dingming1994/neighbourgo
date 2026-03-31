import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/constants/category_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../profile/data/models/profile_model.dart';

class ReviewCard extends StatelessWidget {
  final ReviewModel review;
  const ReviewCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.bgCard,
      borderRadius: AppRadius.card,
      border: Border.all(color: AppColors.divider),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.bgMint,
              backgroundImage: review.reviewerAvatarUrl != null
                  ? CachedNetworkImageProvider(review.reviewerAvatarUrl!) : null,
              child: review.reviewerAvatarUrl == null
                  ? Text(review.reviewerName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(review.reviewerName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Row(children: [
                  RatingBarIndicator(
                    rating: review.rating,
                    itemSize: 13,
                    itemBuilder: (_, __) => const Icon(Icons.star, color: AppColors.accent),
                  ),
                  const SizedBox(width: 6),
                  Text(timeago.format(review.createdAt),
                      style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                ]),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.bgMint,
                borderRadius: AppRadius.chip,
              ),
              child: Text(
                AppCategories.getById(review.taskCategory)?.label ?? review.taskCategory,
                style: const TextStyle(fontSize: 11, color: AppColors.primary),
              ),
            ),
          ],
        ),
        if (review.comment != null && review.comment!.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(review.comment!, style: const TextStyle(fontSize: 14, height: 1.5)),
        ],
        if (review.skillEndorsements.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6, runSpacing: 4,
            children: review.skillEndorsements.map(
              (e) => Chip(
                label: Text('👍 $e', style: const TextStyle(fontSize: 11)),
                backgroundColor: AppColors.bgMint,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ).toList(),
          ),
        ],
        if (review.providerReply != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.bgMint, borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('↩️  ', style: TextStyle(fontSize: 13)),
              Expanded(child: Text(review.providerReply!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
            ]),
          ),
        ],
      ],
    ),
  );
}
