import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/category_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../../tasks/data/models/task_model.dart';
import '../../../tasks/data/repositories/task_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Provider: selected category filter
// ─────────────────────────────────────────────────────────────────────────────
final _selectedCategoryProvider = StateProvider.autoDispose<String?>((ref) => null);

// ─────────────────────────────────────────────────────────────────────────────
// Provider: open tasks (filtered by category)
// ─────────────────────────────────────────────────────────────────────────────
final _openTasksProvider = StreamProvider.autoDispose<List<TaskModel>>((ref) {
  final categoryId = ref.watch(_selectedCategoryProvider);
  return ref.watch(taskRepositoryProvider).watchOpenTasks(
    categoryId: categoryId,
    limit: AppConstants.pageSize,
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
class ProviderHomeScreen extends ConsumerWidget {
  const ProviderHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync  = ref.watch(currentUserProvider);
    final tasksAsync = ref.watch(_openTasksProvider);
    final user       = userAsync.valueOrNull;
    final firstName  = user?.displayName?.split(' ').first ?? 'Neighbour';

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ────────────────────────────────────────────────────────
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: AppColors.bgCard,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Find Work',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.normal),
                ),
                Row(children: [
                  Text(
                    'Hi, $firstName! 👋',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  if (user?.stats != null && user!.stats!.avgRating > 0) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.star, size: 15, color: Colors.amber),
                    const SizedBox(width: 2),
                    Text(
                      user.stats!.avgRating.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                  ],
                ]),
              ],
            ),
            actions: [
              IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
            ],
          ),

          // ── Category filter chips ──────────────────────────────────────────
          if (user != null && user.serviceCategories.isNotEmpty)
            SliverToBoxAdapter(
              child: _CategoryFilterRow(serviceCategories: user.serviceCategories),
            ),

          // ── Section header ─────────────────────────────────────────────────
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Open Tasks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
          ),

          // ── Task list ──────────────────────────────────────────────────────
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
                  (ctx, i) => _ProviderTaskCard(task: tasks[i]),
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
// Category filter row
// ─────────────────────────────────────────────────────────────────────────────
class _CategoryFilterRow extends ConsumerWidget {
  final List<String> serviceCategories;
  const _CategoryFilterRow({required this.serviceCategories});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(_selectedCategoryProvider);

    final categories = serviceCategories
        .map((id) => AppCategories.getById(id))
        .whereType<ServiceCategory>()
        .toList();

    if (categories.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          // "All" chip
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('All'),
              selected: selected == null,
              onSelected: (_) => ref.read(_selectedCategoryProvider.notifier).state = null,
              selectedColor: AppColors.primary.withOpacity(0.15),
              checkmarkColor: AppColors.primary,
            ),
          ),
          ...categories.map((cat) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text('${cat.emoji} ${cat.label}'),
              selected: selected == cat.id,
              onSelected: (_) => ref.read(_selectedCategoryProvider.notifier).state =
                  selected == cat.id ? null : cat.id,
              selectedColor: AppColors.primary.withOpacity(0.15),
              checkmarkColor: AppColors.primary,
            ),
          )),
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
        Text('🔍', style: TextStyle(fontSize: 48)),
        SizedBox(height: 16),
        Text(
          'No open tasks right now. Check back soon!',
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
class _ProviderTaskCard extends StatelessWidget {
  final TaskModel task;
  const _ProviderTaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final category = AppCategories.getById(task.categoryId);
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
              // Neighbourhood + timeago
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (task.neighbourhood != null && task.neighbourhood!.isNotEmpty)
                    Row(children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        task.neighbourhood!,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ])
                  else
                    const SizedBox.shrink(),
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
