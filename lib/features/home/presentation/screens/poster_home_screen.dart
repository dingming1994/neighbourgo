import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/category_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../../notifications/presentation/widgets/notification_bell.dart';
import '../../../tasks/data/models/task_model.dart';
import '../../../tasks/data/repositories/task_repository.dart';
import '../widgets/pending_reviews_section.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Provider: poster's active tasks (excludes completed/cancelled)
// ─────────────────────────────────────────────────────────────────────────────
final _posterActiveTasksProvider = StreamProvider.autoDispose<List<TaskModel>>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref.watch(taskRepositoryProvider).watchMyPostedTasks(user.uid).map(
    (tasks) => tasks.where((t) =>
      t.status != TaskStatus.completed && t.status != TaskStatus.cancelled,
    ).toList(),
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
class PosterHomeScreen extends ConsumerWidget {
  const PosterHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync  = ref.watch(currentUserProvider);
    final tasksAsync = ref.watch(_posterActiveTasksProvider);
    final firstName  = userAsync.valueOrNull?.displayName?.split(' ').first ?? 'Neighbour';

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────────
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: AppColors.bgCard,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Tasks',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.normal),
                ),
                Text(
                  'Hi, $firstName! 👋',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            actions: const [
              NotificationBell(),
            ],
          ),

          // ── Post a Task CTA ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: ElevatedButton.icon(
                onPressed: () => context.push(AppRoutes.postTask),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 52),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
                ),
                icon: const Icon(Icons.add_circle_outline, size: 22),
                label: const Text('Post a Task', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ),

          // ── Pending Reviews ────────────────────────────────────────────
          PendingReviewsSection(provider: posterPendingReviewsProvider),

          // ── Section header ───────────────────────────────────────────────
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Active Tasks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
          ),

          // ── Task list ────────────────────────────────────────────────────
          tasksAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Center(child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(),
              )),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Center(child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Error loading tasks: $e', style: const TextStyle(color: AppColors.error)),
              )),
            ),
            data: (tasks) {
              if (tasks.isEmpty) {
                return const SliverToBoxAdapter(child: _EmptyTasksState());
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _PosterTaskCard(task: tasks[i]),
                  childCount: tasks.length,
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyTasksState extends StatelessWidget {
  const _EmptyTasksState();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 60, horizontal: 32),
    child: Column(
      children: [
        Text('📋', style: TextStyle(fontSize: 48)),
        SizedBox(height: 16),
        Text(
          'No active tasks. Post your first task!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Task card
// ─────────────────────────────────────────────────────────────────────────────
class _PosterTaskCard extends StatelessWidget {
  final TaskModel task;
  const _PosterTaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final category = AppCategories.all.where((c) => c.id == task.categoryId).firstOrNull;
    final emoji    = category?.emoji ?? '📌';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: GestureDetector(
        onTap: () => context.push('/tasks/${task.id}'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: AppRadius.card,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + emoji
              Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      task.title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Category + budget
              Row(
                children: [
                  _Chip(label: category?.label ?? task.categoryId, color: AppColors.primaryLight.withOpacity(0.15)),
                  const SizedBox(width: 8),
                  _Chip(label: task.budgetDisplay, color: AppColors.primary.withOpacity(0.1)),
                ],
              ),
              const SizedBox(height: 10),
              // Bid count + time
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    const Icon(Icons.gavel, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${task.bidCount} bid${task.bidCount == 1 ? '' : 's'}',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ]),
                  Text(
                    task.createdAt != null ? timeago.format(task.createdAt!) : '',
                    style: const TextStyle(fontSize: 12, color: AppColors.textHint),
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
  final Color  color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
    child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
  );
}
