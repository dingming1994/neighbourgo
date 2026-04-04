import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/category_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../../tasks/data/models/task_model.dart';
import '../../../tasks/data/repositories/task_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Provider: direct hire offers for the current provider
// ─────────────────────────────────────────────────────────────────────────────
final directHireOffersProvider =
    StreamProvider.autoDispose<List<TaskModel>>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref.watch(taskRepositoryProvider).watchDirectHireOffers(user.uid);
});

// ─────────────────────────────────────────────────────────────────────────────
// Widget: Job Offers Section (renders as Sliver)
// ─────────────────────────────────────────────────────────────────────────────
class JobOffersSection extends ConsumerWidget {
  const JobOffersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offersAsync = ref.watch(directHireOffersProvider);

    return offersAsync.when(skipLoadingOnReload: true,
      loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
      error: (_, __) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: ErrorState(
            message: 'Could not load job offers right now.',
            onRetry: () => ref.invalidate(directHireOffersProvider),
          ),
        ),
      ),
      data: (offers) {
        if (offers.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }
        return SliverMainAxisGroup(
          slivers: [
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Icon(Icons.work_outline, size: 20, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'Job Offers',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _JobOfferCard(task: offers[i]),
                childCount: offers.length,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Job offer card
// ─────────────────────────────────────────────────────────────────────────────
class _JobOfferCard extends StatelessWidget {
  final TaskModel task;
  const _JobOfferCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final category = AppCategories.getById(task.categoryId);
    final emoji = category?.emoji ?? '📌';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: GestureDetector(
        onTap: () => context.push('/tasks/${task.id}'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: AppRadius.card,
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Direct hire badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Direct Hire',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              // Title + emoji
              Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      task.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Budget + poster
              Row(
                children: [
                  _Chip(
                    label: task.budgetDisplay,
                    color: AppColors.primary.withValues(alpha: 0.1),
                  ),
                  const SizedBox(width: 8),
                  if (task.posterName != null)
                    Expanded(
                      child: Text(
                        'by ${task.posterName}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
              if (task.neighbourhood != null &&
                  task.neighbourhood!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      task.neighbourhood!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
              ],
              const SizedBox(height: 12),
              // CTA
              const Row(
                children: [
                  Icon(Icons.touch_app_outlined,
                      size: 14, color: AppColors.primary),
                  SizedBox(width: 4),
                  Text(
                    'Tap to view & respond',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration:
            BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
        child: Text(label,
            style:
                const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      );
}
