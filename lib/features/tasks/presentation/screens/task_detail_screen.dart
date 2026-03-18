import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/models/task_model.dart';
import '../../../../core/constants/category_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../../bids/presentation/widgets/bid_list_section.dart';
import '../../../bids/presentation/widgets/submit_bid_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────
final taskDetailProvider = StreamProvider.family<TaskModel?, String>(
  (ref, id) => ref.watch(taskRepositoryProvider).watchTask(id),
);

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
class TaskDetailScreen extends ConsumerWidget {
  final String taskId;
  const TaskDetailScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskAsync   = ref.watch(taskDetailProvider(taskId));
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

    return taskAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          Scaffold(body: Center(child: Text('Error: $e'))),
      data: (task) {
        if (task == null) {
          return const Scaffold(
              body: Center(child: Text('Task not found')));
        }

        final cat      = AppCategories.getById(task.categoryId);
        final isPoster = currentUser?.uid == task.posterId;
        final isProvider =
            !isPoster && currentUser != null;
        final isOpen = task.status == TaskStatus.open;

        return Scaffold(
          appBar: AppBar(title: Text(task.title)),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Photos ────────────────────────────────────────────────
                if (task.photoUrls.isNotEmpty) ...[
                  _PhotoCarousel(photoUrls: task.photoUrls),
                  const SizedBox(height: 20),
                ],

                // ── Category & Urgency ────────────────────────────────────
                Row(children: [
                  Text(cat?.emoji ?? '📋',
                      style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 10),
                  Chip(
                    label: Text(cat?.label ?? task.categoryId),
                    backgroundColor:
                        (cat?.color ?? AppColors.primary).withValues(alpha: 0.1),
                  ),
                  const Spacer(),
                  Text(task.urgencyDisplay),
                ]),
                const SizedBox(height: 16),

                // ── Title ─────────────────────────────────────────────────
                Text(task.title,
                    style:
                        Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),

                // ── Description ───────────────────────────────────────────
                Text(task.description,
                    style: const TextStyle(height: 1.6)),
                const SizedBox(height: 20),

                // ── Info rows ─────────────────────────────────────────────
                _InfoRow(Icons.location_on_outlined, task.locationLabel),
                _InfoRow(Icons.attach_money, task.budgetDisplay),
                _InfoRow(Icons.info_outline, _statusLabel(task.status)),
                if (task.neighbourhood != null)
                  _InfoRow(
                      Icons.near_me_outlined, task.neighbourhood!),
                if (task.estimatedDurationMins != null)
                  _InfoRow(
                    Icons.schedule_outlined,
                    '预计 ${task.estimatedDurationMins} 分钟',
                  ),

                const SizedBox(height: 28),

                // ── Role-based section ────────────────────────────────────
                if (isPoster) ...[
                  const Divider(),
                  const SizedBox(height: 16),
                  BidListSection(taskId: taskId),
                ] else if (isProvider && isOpen) ...[
                  AppButton(
                    label: '提交报价',
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20)),
                      ),
                      builder: (_) =>
                          SubmitBidSheet(taskId: taskId),
                    ),
                  ),
                ] else if (isProvider && !isOpen) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.bgMint,
                      borderRadius: AppRadius.card,
                    ),
                    child: Row(children: [
                      const Icon(Icons.lock_outline,
                          color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        '该任务已${_statusLabel(task.status)}，不再接受报价',
                        style: const TextStyle(
                            color: AppColors.primary),
                      ),
                    ]),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _statusLabel(TaskStatus status) {
    switch (status) {
      case TaskStatus.open:       return '招募中';
      case TaskStatus.assigned:   return '已指派';
      case TaskStatus.inProgress: return '进行中';
      case TaskStatus.completed:  return '已完成';
      case TaskStatus.cancelled:  return '已取消';
      case TaskStatus.disputed:   return '争议中';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PhotoCarousel
// ─────────────────────────────────────────────────────────────────────────────
class _PhotoCarousel extends StatelessWidget {
  final List<String> photoUrls;
  const _PhotoCarousel({required this.photoUrls});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photoUrls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => ClipRRect(
          borderRadius: AppRadius.card,
          child: CachedNetworkImage(
            imageUrl: photoUrls[i],
            width:    280,
            height:   220,
            fit:      BoxFit.cover,
            placeholder: (_, __) => Container(
              width:  280,
              height: 220,
              color:  AppColors.bgMint,
              child:  const Center(
                  child: CircularProgressIndicator()),
            ),
            errorWidget: (_, __, ___) => Container(
              width:  280,
              height: 220,
              color:  AppColors.bgMint,
              child:  const Icon(Icons.broken_image_outlined,
                  color: AppColors.textHint),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _InfoRow
// ─────────────────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String   text;
  const _InfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Icon(icon, size: 18, color: AppColors.textHint),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ]),
      );
}
