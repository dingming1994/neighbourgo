import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../../tasks/data/models/task_model.dart';
import '../../../tasks/data/repositories/task_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Provider: all tasks for summary counts
// ─────────────────────────────────────────────────────────────────────────────
final _posterAllTasksProvider =
    StreamProvider.autoDispose<List<TaskModel>>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref.watch(taskRepositoryProvider).watchMyPostedTasks(user.uid);
});

// ─────────────────────────────────────────────────────────────────────────────
// Widget
// ─────────────────────────────────────────────────────────────────────────────
class PosterSummaryCard extends ConsumerWidget {
  const PosterSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(_posterAllTasksProvider);
    final tasks = tasksAsync.valueOrNull ?? [];

    final open = tasks.where((t) => t.status == TaskStatus.open).length;
    final inProgress = tasks
        .where((t) =>
            t.status == TaskStatus.assigned ||
            t.status == TaskStatus.inProgress)
        .length;
    final completed =
        tasks.where((t) => t.status == TaskStatus.completed).length;
    final needsAction =
        tasks.where((t) => t.status == TaskStatus.open && t.bidCount > 0).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Number cards row ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  _StatTile(
                    count: open,
                    label: 'Open',
                    color: AppColors.accent,
                    icon: Icons.access_time_rounded,
                  ),
                  const SizedBox(width: 12),
                  _StatTile(
                    count: inProgress,
                    label: 'In Progress',
                    color: AppColors.info,
                    icon: Icons.engineering_rounded,
                  ),
                  const SizedBox(width: 12),
                  _StatTile(
                    count: completed,
                    label: 'Completed',
                    color: AppColors.success,
                    icon: Icons.check_circle_outline,
                  ),
                ],
              ),
            ),

            // ── Action alerts ───────────────────────────────────────
            if (needsAction > 0 || inProgress > 0) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  children: [
                    if (needsAction > 0)
                      _AlertRow(
                        icon: Icons.bolt,
                        color: AppColors.accent,
                        text:
                            '$needsAction task${needsAction > 1 ? 's' : ''} need${needsAction > 1 ? '' : 's'} your action',
                      ),
                    if (inProgress > 0)
                      _AlertRow(
                        icon: Icons.sync,
                        color: AppColors.info,
                        text:
                            '$inProgress task${inProgress > 1 ? 's' : ''} in progress',
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────
class _StatTile extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  final IconData icon;

  const _StatTile({
    required this.count,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _AlertRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
