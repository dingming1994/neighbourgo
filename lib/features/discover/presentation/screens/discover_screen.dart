import 'dart:async';

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

/// Search query shared across all Discover tabs (tasks, providers, services).
final discoverSearchQueryProvider = StateProvider<String>((_) => '');

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  bool _isDebouncing = false;

  @override
  void initState() {
    super.initState();
    _searchController.text = ref.read(discoverSearchQueryProvider);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    if (value.trim().toLowerCase() != ref.read(discoverSearchQueryProvider)) {
      setState(() => _isDebouncing = true);
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(discoverSearchQueryProvider.notifier).state =
          value.trim().toLowerCase();
      if (mounted) setState(() => _isDebouncing = false);
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    ref.read(discoverSearchQueryProvider.notifier).state = '';
    setState(() => _isDebouncing = false);
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.valueOrNull;

    // Provider-role users only see Tasks, but still keep the shared search UX.
    final providerOnly = user != null && user.role == UserRole.provider;

    final segment = providerOnly
        ? DiscoverSegment.tasks
        : ref.watch(discoverSegmentProvider);
    final searchQuery = ref.watch(discoverSearchQueryProvider);

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
          // Search bar
          Container(
            color: AppColors.bgCard,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              0,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: switch (segment) {
                  DiscoverSegment.tasks => 'Search tasks...',
                  DiscoverSegment.providers => 'Search providers...',
                  DiscoverSegment.services => 'Search services...',
                },
                hintStyle: const TextStyle(
                  color: AppColors.textHint,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textHint,
                  size: 20,
                ),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        onPressed: _clearSearch,
                      )
                    : null,
                filled: true,
                fillColor: AppColors.bgLight,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (_isDebouncing)
            const LinearProgressIndicator(
              minHeight: 2,
              color: AppColors.primary,
              backgroundColor: Colors.transparent,
            ),
          if (!providerOnly)
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
