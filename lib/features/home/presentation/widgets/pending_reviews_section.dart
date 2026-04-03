import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/category_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../../tasks/data/models/task_model.dart';
import '../../../tasks/data/repositories/task_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data class for a pending review
// ─────────────────────────────────────────────────────────────────────────────
class PendingReview {
  final TaskModel task;
  final String reviewedUserId;
  final String reviewedUserName;
  PendingReview({
    required this.task,
    required this.reviewedUserId,
    required this.reviewedUserName,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider: poster's pending reviews (completed tasks where poster hasn't reviewed provider)
// ─────────────────────────────────────────────────────────────────────────────
final posterPendingReviewsProvider =
    StreamProvider.autoDispose<List<PendingReview>>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return Stream.value([]);

  final db = FirebaseFirestore.instance;

  return ref
      .watch(taskRepositoryProvider)
      .watchMyCompletedPostTasks(user.uid)
      .asyncMap((tasks) async {
    final pending = <PendingReview>[];
    for (final task in tasks) {
      if (task.assignedProviderId == null) continue;
      final snap = await db
          .collection(AppConstants.usersCol)
          .doc(task.assignedProviderId)
          .collection(AppConstants.reviewsCol)
          .where('taskId', isEqualTo: task.id)
          .where('reviewerId', isEqualTo: user.uid)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) {
        pending.add(PendingReview(
          task: task,
          reviewedUserId: task.assignedProviderId!,
          reviewedUserName: task.assignedProviderName ?? 'Provider',
        ));
      }
    }
    return pending;
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Provider: provider's pending reviews (completed tasks where provider hasn't reviewed poster)
// ─────────────────────────────────────────────────────────────────────────────
final providerPendingReviewsProvider =
    StreamProvider.autoDispose<List<PendingReview>>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return Stream.value([]);

  final db = FirebaseFirestore.instance;

  return ref
      .watch(taskRepositoryProvider)
      .watchMyCompletedProviderTasks(user.uid)
      .asyncMap((tasks) async {
    final pending = <PendingReview>[];
    for (final task in tasks) {
      final snap = await db
          .collection(AppConstants.usersCol)
          .doc(task.posterId)
          .collection(AppConstants.reviewsCol)
          .where('taskId', isEqualTo: task.id)
          .where('reviewerId', isEqualTo: user.uid)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) {
        pending.add(PendingReview(
          task: task,
          reviewedUserId: task.posterId,
          reviewedUserName: task.posterName ?? 'Client',
        ));
      }
    }
    return pending;
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Widget: Pending Reviews Section (renders as Sliver)
// ─────────────────────────────────────────────────────────────────────────────
class PendingReviewsSection extends ConsumerWidget {
  final AutoDisposeStreamProvider<List<PendingReview>> provider;
  const PendingReviewsSection({super.key, required this.provider});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(provider);

    return reviewsAsync.when(skipLoadingOnReload: true,
      loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
      error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
      data: (reviews) {
        if (reviews.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }
        return SliverMainAxisGroup(
          slivers: [
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Pending Reviews',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _PendingReviewCard(review: reviews[i]),
                childCount: reviews.length,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pending review card
// ─────────────────────────────────────────────────────────────────────────────
class _PendingReviewCard extends StatelessWidget {
  final PendingReview review;
  const _PendingReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final category = AppCategories.getById(review.task.categoryId);
    final emoji = category?.emoji ?? '📌';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.warning.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          review.task.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Rate ${review.reviewedUserName}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => context.push(
                AppRoutes.submitReview,
                extra: {
                  'taskId': review.task.id,
                  'reviewedUserId': review.reviewedUserId,
                  'reviewedUserName': review.reviewedUserName,
                  'taskCategory': review.task.categoryId,
                },
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.star_outline, size: 16),
              label: const Text(
                'Leave Review',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
