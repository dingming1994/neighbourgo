import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/constants/category_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../data/models/task_model.dart';
import '../../data/repositories/task_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────
final _activeTasksProvider = StreamProvider.autoDispose<List<TaskModel>>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref.watch(taskRepositoryProvider).watchMyPostedTasks(user.uid);
});

final _completedTasksProvider = StreamProvider.autoDispose<List<TaskModel>>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref.watch(taskRepositoryProvider).watchMyCompletedPostTasks(user.uid);
});

final _cancelledTasksProvider = StreamProvider.autoDispose<List<TaskModel>>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref.watch(taskRepositoryProvider).watchMyCancelledPostTasks(user.uid);
});

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
class MyTasksScreen extends ConsumerWidget {
  const MyTasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.bgLight,
        appBar: AppBar(
          backgroundColor: AppColors.bgCard,
          elevation: 0,
          title: const Text('My Tasks'),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Active'),
              Tab(text: 'Completed'),
              Tab(text: 'Cancelled'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _TaskList(provider: _activeTasksProvider, emptyEmoji: '📋', emptyMessage: 'No active tasks yet.\nPost a task to get started!'),
            _TaskList(provider: _completedTasksProvider, emptyEmoji: '✅', emptyMessage: 'No completed tasks yet.'),
            _TaskList(provider: _cancelledTasksProvider, emptyEmoji: '🚫', emptyMessage: 'No cancelled tasks.'),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Task list per tab
// ─────────────────────────────────────────────────────────────────────────────
class _TaskList extends ConsumerWidget {
  final AutoDisposeStreamProvider<List<TaskModel>> provider;
  final String emptyEmoji;
  final String emptyMessage;

  const _TaskList({
    required this.provider,
    required this.emptyEmoji,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(provider);

    return tasksAsync.when(
      loading: () => const _MyTasksLoadingList(),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Error: $e', style: const TextStyle(color: AppColors.error)),
        ),
      ),
      data: (tasks) {
        if (tasks.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emptyEmoji, style: const TextStyle(fontSize: 56)),
                  const SizedBox(height: 16),
                  Text(
                    emptyMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          );
        }
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(provider);
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: tasks.length,
            itemBuilder: (_, i) => _MyTaskCard(task: tasks[i]),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Task card with status badge
// ─────────────────────────────────────────────────────────────────────────────
class _MyTaskCard extends StatelessWidget {
  final TaskModel task;
  const _MyTaskCard({required this.task});

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
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + emoji + status badge
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
                  const SizedBox(width: 8),
                  _StatusBadge(status: task.status),
                ],
              ),
              const SizedBox(height: 10),
              // Category + budget
              Row(
                children: [
                  _Chip(
                    label: category?.label ?? task.categoryId,
                    color: AppColors.primaryLight.withOpacity(0.15),
                  ),
                  const SizedBox(width: 8),
                  _Chip(
                    label: task.budgetDisplay,
                    color: AppColors.primary.withOpacity(0.1),
                  ),
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
                  if (task.assignedProviderName != null)
                    Row(children: [
                      const Icon(Icons.person, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        task.assignedProviderName!,
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

// ─────────────────────────────────────────────────────────────────────────────
// Status badge
// ─────────────────────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final TaskStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      TaskStatus.open       => ('Open', AppColors.primary),
      TaskStatus.assigned   => ('Assigned', const Color(0xFF2196F3)),
      TaskStatus.inProgress => ('In Progress', const Color(0xFFFF9800)),
      TaskStatus.completed  => ('Completed', const Color(0xFF4CAF50)),
      TaskStatus.cancelled  => ('Cancelled', const Color(0xFF9E9E9E)),
      TaskStatus.disputed   => ('Disputed', const Color(0xFFF44336)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chip
// ─────────────────────────────────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
    child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
  );
}

class _MyTasksLoadingList extends StatelessWidget {
  const _MyTasksLoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: 4,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Shimmer.fromColors(
          baseColor: AppColors.divider,
          highlightColor: Colors.white,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: AppRadius.card,
            ),
          ),
        ),
      ),
    );
  }
}
