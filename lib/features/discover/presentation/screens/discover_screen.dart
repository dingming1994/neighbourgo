import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/data/models/user_model.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../../tasks/presentation/screens/task_list_screen.dart';
import '../../../providers/presentation/screens/provider_directory_screen.dart';
import '../../../services/presentation/screens/service_listings_screen.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Toggle state — persists during session
// ─────────────────────────────────────────────────────────────────────────────
enum DiscoverSegment { tasks, providers, services }

final discoverSegmentProvider =
    StateProvider<DiscoverSegment>((_) => DiscoverSegment.tasks);

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.valueOrNull;

    // Provider-role users only see Tasks (no toggle)
    final showToggle = user != null && user.role != UserRole.provider;

    if (!showToggle) {
      return const TaskListScreen();
    }

    final segment = ref.watch(discoverSegmentProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text('Discover'),
        actions: [
          if (segment == DiscoverSegment.tasks)
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded),
              tooltip: 'Post a Task',
              onPressed: () => context.push(AppRoutes.postTask),
            ),
        ],
      ),
      body: Column(
        children: [
          _SegmentedToggle(
            selected: segment,
            onChanged: (s) =>
                ref.read(discoverSegmentProvider.notifier).state = s,
          ),
          Expanded(
            child: switch (segment) {
              DiscoverSegment.tasks => const TaskListScreen(embedded: true),
              DiscoverSegment.providers =>
                const ProviderDirectoryScreen(embedded: true),
              DiscoverSegment.services =>
                const ServiceListingsScreen(embedded: true),
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Segmented Toggle
// ─────────────────────────────────────────────────────────────────────────────
class _SegmentedToggle extends StatelessWidget {
  final DiscoverSegment selected;
  final ValueChanged<DiscoverSegment> onChanged;

  const _SegmentedToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgCard,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgLight,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(3),
        child: Row(
          children: [
            _SegmentButton(
              label: 'Tasks',
              icon: Icons.assignment_outlined,
              isSelected: selected == DiscoverSegment.tasks,
              onTap: () => onChanged(DiscoverSegment.tasks),
            ),
            _SegmentButton(
              label: 'Providers',
              icon: Icons.people_outline_rounded,
              isSelected: selected == DiscoverSegment.providers,
              onTap: () => onChanged(DiscoverSegment.providers),
            ),
            _SegmentButton(
              label: 'Services',
              icon: Icons.storefront_outlined,
              isSelected: selected == DiscoverSegment.services,
              onTap: () => onChanged(DiscoverSegment.services),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.bgCard : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? AppColors.primary : AppColors.textHint,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color:
                      isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
