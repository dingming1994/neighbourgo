import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/category_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../../notifications/presentation/widgets/notification_bell.dart';
import '../widgets/provider_summary_card.dart';
import '../../../services/data/models/service_listing_model.dart';
import '../../../services/data/repositories/service_listing_repository.dart';
import '../../../services/presentation/widgets/service_card.dart';
import '../../../tasks/data/models/task_model.dart';
import '../../../tasks/data/repositories/task_repository.dart';
import '../widgets/job_offers_section.dart';
import '../widgets/pending_reviews_section.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Provider: my service listings
// ─────────────────────────────────────────────────────────────────────────────
final _myServiceListingsProvider =
    StreamProvider.autoDispose<List<ServiceListingModel>>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref.watch(serviceListingRepositoryProvider).watchMyListings(user.uid);
});

// ─────────────────────────────────────────────────────────────────────────────
// Provider: selected category filter
// ─────────────────────────────────────────────────────────────────────────────
final _selectedCategoryProvider =
    StateProvider.autoDispose<String?>((ref) => null);

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
// Provider: recommended tasks (matching provider's categories + neighbourhood)
// ─────────────────────────────────────────────────────────────────────────────
class RecommendedTask {
  final TaskModel task;
  final String matchReason;
  RecommendedTask({required this.task, required this.matchReason});
}

final _recommendedTasksProvider =
    StreamProvider.autoDispose<List<RecommendedTask>>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null || user.serviceCategories.isEmpty) return Stream.value([]);

  // Watch all open tasks (unfiltered) and score them client-side
  return ref
      .watch(taskRepositoryProvider)
      .watchOpenTasks(limit: 50)
      .map((tasks) {
    final recommended = <RecommendedTask>[];

    for (final task in tasks) {
      final matchesCategory = user.serviceCategories.contains(task.categoryId);
      final matchesNeighbourhood = user.neighbourhood != null &&
          user.neighbourhood!.isNotEmpty &&
          task.neighbourhood == user.neighbourhood;

      if (matchesCategory && matchesNeighbourhood) {
        recommended.add(
            RecommendedTask(task: task, matchReason: 'In your neighbourhood'));
      } else if (matchesCategory) {
        recommended.add(
            RecommendedTask(task: task, matchReason: 'Matches your skills'));
      } else if (matchesNeighbourhood) {
        recommended.add(RecommendedTask(task: task, matchReason: 'Near you'));
      }
    }

    // Sort: neighbourhood+category first, then category, then neighbourhood
    recommended.sort((a, b) {
      int score(RecommendedTask r) => r.matchReason == 'In your neighbourhood'
          ? 0
          : r.matchReason == 'Matches your skills'
              ? 1
              : 2;
      return score(a).compareTo(score(b));
    });

    return recommended.take(5).toList();
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
class ProviderHomeScreen extends ConsumerWidget {
  const ProviderHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final tasksAsync = ref.watch(_openTasksProvider);
    final user = userAsync.valueOrNull;
    final firstName = user?.displayName?.split(' ').first ?? 'Neighbour';

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
                  style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.normal),
                ),
                Row(children: [
                  Text(
                    'Hi, $firstName! 👋',
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  if (user?.stats != null && user!.stats!.avgRating > 0) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.star, size: 15, color: Colors.amber),
                    const SizedBox(width: 2),
                    Text(
                      user.stats!.avgRating.toStringAsFixed(1),
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary),
                    ),
                  ],
                ]),
              ],
            ),
            actions: const [
              NotificationBell(),
            ],
          ),

          // ── Provider summary card ────────────────────────────────────────
          const SliverToBoxAdapter(
            child: ProviderSummaryCard(),
          ),

          // ── Profile completion checklist ───────────────────────────────
          if (user != null && user.completeness < 70)
            SliverToBoxAdapter(
              child: _ProfileCompletionCard(user: user),
            ),

          // ── Job Offers (Direct Hire) ────────────────────────────────────
          const JobOffersSection(),

          // ── Pending Reviews ────────────────────────────────────────────
          PendingReviewsSection(provider: providerPendingReviewsProvider),

          // ── My Services ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('My Services',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  TextButton.icon(
                    onPressed: () => context.push(AppRoutes.createService),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                  ),
                ],
              ),
            ),
          ),
          _MyServicesSection(),

          // ── Recommended for You ─────────────────────────────────────────────
          if (user != null && user.serviceCategories.isEmpty)
            const SliverToBoxAdapter(
              child: _NoServiceCategoriesPrompt(),
            )
          else if (user != null && user.serviceCategories.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('Recommended for You',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ),
            ),
            _RecommendedSection(),
          ],

          // ── Category filter chips ──────────────────────────────────────────
          if (user != null && user.serviceCategories.isNotEmpty)
            SliverToBoxAdapter(
              child:
                  _CategoryFilterRow(serviceCategories: user.serviceCategories),
            ),

          // ── Section header ─────────────────────────────────────────────────
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('All Open Tasks',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
          ),

          // ── Task list ──────────────────────────────────────────────────────
          tasksAsync.when(
            skipLoadingOnReload: true,
            loading: () => const SliverToBoxAdapter(
              child: Center(
                  child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(),
              )),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: ErrorState(
                message: 'Could not load open tasks right now.',
                onRetry: () => ref.invalidate(_openTasksProvider),
              ),
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
// Profile completion card
// ─────────────────────────────────────────────────────────────────────────────

class _ChecklistItem {
  final IconData icon;
  final String label;
  final bool complete;
  const _ChecklistItem(
      {required this.icon, required this.label, required this.complete});
}

class _ProfileCompletionCard extends StatelessWidget {
  final UserModel user;
  const _ProfileCompletionCard({required this.user});

  List<_ChecklistItem> _buildChecklist() {
    return [
      _ChecklistItem(
        icon: Icons.photo_camera_outlined,
        label: 'Add a profile photo',
        complete: user.avatarUrl != null,
      ),
      _ChecklistItem(
        icon: Icons.person_outlined,
        label: 'Set your display name',
        complete: user.displayName != null && user.displayName!.isNotEmpty,
      ),
      _ChecklistItem(
        icon: Icons.short_text,
        label: 'Write a headline',
        complete: user.headline != null && user.headline!.isNotEmpty,
      ),
      _ChecklistItem(
        icon: Icons.description_outlined,
        label: 'Add a bio',
        complete: user.bio != null && user.bio!.isNotEmpty,
      ),
      _ChecklistItem(
        icon: Icons.category_outlined,
        label: 'Select service categories',
        complete: user.serviceCategories.isNotEmpty,
      ),
      _ChecklistItem(
        icon: Icons.collections_outlined,
        label: 'Upload portfolio photos',
        complete: user.photos.isNotEmpty,
      ),
      _ChecklistItem(
        icon: Icons.schedule_outlined,
        label: 'Set your availability',
        complete: user.availableDays.isNotEmpty,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final items = _buildChecklist();
    final completed = items.where((i) => i.complete).length;
    final progress = completed / items.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.rocket_launch_outlined,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Complete Your Profile',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  '$completed/${items.length}',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'A complete profile helps you get more jobs.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: 12),
            // Checklist
            ...items.where((i) => !i.complete).map((item) => GestureDetector(
                  onTap: () => context.push(AppRoutes.editProfile),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.radio_button_unchecked,
                          size: 18,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(width: 10),
                        Icon(item.icon,
                            size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.label,
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textPrimary),
                          ),
                        ),
                        const Icon(Icons.chevron_right,
                            size: 16, color: AppColors.textHint),
                      ],
                    ),
                  ),
                )),
            ...items.where((i) => i.complete).map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Icon(item.icon, size: 16, color: AppColors.textHint),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.label,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textHint,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 12),
            // CTA
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.push(AppRoutes.editProfile),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Complete Your Profile',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// My Services section
// ─────────────────────────────────────────────────────────────────────────────
class _MyServicesSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(_myServiceListingsProvider);

    return listingsAsync.when(
      skipLoadingOnReload: true,
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: _SectionErrorCard(
          message: 'Could not load your service listings.',
          onRetry: () => ref.invalidate(_myServiceListingsProvider),
        ),
      ),
      data: (listings) {
        if (listings.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: GestureDetector(
                onTap: () => context.push(AppRoutes.createService),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.bgMint,
                    borderRadius: AppRadius.card,
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.storefront_outlined, color: AppColors.primary),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Create your first service listing',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14)),
                            SizedBox(height: 4),
                            Text(
                              'Let clients find and hire you directly.',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios,
                          size: 14, color: AppColors.textHint),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (ctx, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ServiceCard(listing: listings[i]),
            ),
            childCount: listings.length > 3 ? 3 : listings.length,
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recommended section
// ─────────────────────────────────────────────────────────────────────────────
class _RecommendedSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recAsync = ref.watch(_recommendedTasksProvider);

    return recAsync.when(
      skipLoadingOnReload: true,
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: _SectionErrorCard(
          message: 'Could not load recommended tasks right now.',
          onRetry: () => ref.invalidate(_recommendedTasksProvider),
        ),
      ),
      data: (recommended) {
        if (recommended.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'No recommended tasks right now. Try browsing all open tasks below.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
          );
        }
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) => _RecommendedTaskCard(
              task: recommended[i].task,
              matchReason: recommended[i].matchReason,
            ),
            childCount: recommended.length,
          ),
        );
      },
    );
  }
}

class _SectionErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _SectionErrorCard({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoServiceCategoriesPrompt extends StatelessWidget {
  const _NoServiceCategoriesPrompt();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgMint,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.tips_and_updates_outlined,
                color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Get personalized recommendations',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Add your service categories in profile to get task recommendations.',
                    style:
                        TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => context.push(AppRoutes.editProfile),
                    child: const Text(
                      'Edit Profile',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
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

class _RecommendedTaskCard extends StatelessWidget {
  final TaskModel task;
  final String matchReason;
  const _RecommendedTaskCard({required this.task, required this.matchReason});

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
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Match reason badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  matchReason,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary),
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
                          fontSize: 15, fontWeight: FontWeight.w700),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Category + budget
              Row(
                children: [
                  _Chip(
                      label: category?.label ?? task.categoryId,
                      color: AppColors.primaryLight.withValues(alpha: 0.15)),
                  const SizedBox(width: 8),
                  _Chip(
                      label: task.budgetDisplay,
                      color: AppColors.primary.withValues(alpha: 0.1)),
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
                          fontSize: 13, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
              ],
            ],
          ),
        ),
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
              onSelected: (_) =>
                  ref.read(_selectedCategoryProvider.notifier).state = null,
              selectedColor: AppColors.primary.withValues(alpha: 0.15),
              checkmarkColor: AppColors.primary,
            ),
          ),
          ...categories.map((cat) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text('${cat.emoji} ${cat.label}'),
                  selected: selected == cat.id,
                  onSelected: (_) => ref
                      .read(_selectedCategoryProvider.notifier)
                      .state = selected == cat.id ? null : cat.id,
                  selectedColor: AppColors.primary.withValues(alpha: 0.15),
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
              // Title + emoji
              Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      task.title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
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
                  _Chip(
                      label: category?.label ?? task.categoryId,
                      color: AppColors.primaryLight.withValues(alpha: 0.15)),
                  const SizedBox(width: 8),
                  _Chip(
                      label: task.budgetDisplay,
                      color: AppColors.primary.withValues(alpha: 0.1)),
                ],
              ),
              const SizedBox(height: 10),
              // Neighbourhood + timeago
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (task.neighbourhood != null &&
                      task.neighbourhood!.isNotEmpty)
                    Expanded(
                      child: Row(children: [
                        const Icon(Icons.location_on_outlined,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            task.neighbourhood!,
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                    )
                  else
                    const SizedBox.shrink(),
                  Text(
                    task.createdAt != null
                        ? timeago.format(task.createdAt!)
                        : '',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textHint),
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
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      );
}
