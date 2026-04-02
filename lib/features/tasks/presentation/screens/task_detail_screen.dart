import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/models/task_model.dart';
import '../../../../core/constants/category_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../../bids/presentation/widgets/bid_list_section.dart';
import '../../../bids/presentation/widgets/submit_bid_sheet.dart';
import '../../../bids/domain/models/bid_model.dart';
import '../../../chat/data/repositories/chat_repository.dart';

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

        final cat        = AppCategories.getById(task.categoryId);
        final isPoster   = currentUser?.uid == task.posterId;
        final isProvider = !isPoster && currentUser != null;
        final isOpen     = task.status == TaskStatus.open;
        final isInProgress = task.status == TaskStatus.inProgress ||
            task.status == TaskStatus.assigned;

        return Scaffold(
          appBar: AppBar(
            title: Text(task.title),
            leading: Navigator.canPop(context)
                ? null  // default back button
                : IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.go(AppRoutes.home),
                  ),
          ),
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

                // ── Timeline ─────────────────────────────────────────────
                _TaskTimeline(task: task),
                const SizedBox(height: 20),

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
                  _InfoRow(Icons.near_me_outlined, task.neighbourhood!),
                if (task.estimatedDurationMins != null)
                  _InfoRow(
                    Icons.schedule_outlined,
                    'Est. ${task.estimatedDurationMins} mins',
                  ),

                // ── Poster info ───────────────────────────────────────────
                if (task.posterName != null) ...[
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  _PosterInfo(
                    posterName:      task.posterName!,
                    posterAvatarUrl: task.posterAvatarUrl,
                  ),
                ],

                const SizedBox(height: 28),

                // ── Leave a Review prompt (completed tasks) ─────────────
                if (task.status == TaskStatus.completed && currentUser != null) ...[
                  if (isPoster && task.assignedProviderId != null) ...[
                    _LeaveReviewCard(
                      taskId:           taskId,
                      reviewedUserId:   task.assignedProviderId!,
                      reviewedUserName: task.assignedProviderName ?? 'Provider',
                      taskCategory:     task.categoryId,
                    ),
                    const SizedBox(height: 16),
                  ] else if (isProvider) ...[
                    _LeaveReviewCard(
                      taskId:           taskId,
                      reviewedUserId:   task.posterId,
                      reviewedUserName: task.posterName ?? 'Poster',
                      taskCategory:     task.categoryId,
                    ),
                    const SizedBox(height: 16),
                  ],
                ],

                // ── Work in Progress banner ───────────────────────────────
                if (task.status == TaskStatus.inProgress) ...[
                  _WorkInProgressBanner(),
                  const SizedBox(height: 16),
                ],

                // ── Role-based section ────────────────────────────────────
                if (isPoster) ...[
                  // Mark Complete button (when inProgress/assigned)
                  if (isInProgress) ...[
                    _MarkCompleteButton(
                      taskId: taskId,
                      task:   task,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Message provider button (when assigned)
                  if ((isInProgress || task.status == TaskStatus.completed) &&
                      task.assignedProviderId != null) ...[
                    _MessageButton(
                      taskId:      taskId,
                      posterId:    task.posterId,
                      providerId:  task.assignedProviderId!,
                      label:       'Message Provider',
                    ),
                    const SizedBox(height: 16),
                  ],

                  const Divider(),
                  const SizedBox(height: 16),
                  BidListSection(taskId: taskId, posterId: task.posterId),
                ] else if (isProvider) ...[
                  // Provider view — Direct Hire Accept/Decline
                  if (task.isDirectHire &&
                      task.assignedProviderId == currentUser.uid &&
                      task.status == TaskStatus.assigned) ...[
                    _DirectHireResponseButtons(taskId: taskId),
                    const SizedBox(height: 12),
                  ] else ...[
                    // Normal bid-based flow
                    // Check if provider already has a bid on this task
                    Builder(builder: (context) {
                      final bidsAsync = ref.watch(bidsStreamProvider(taskId));
                      final hasBid = bidsAsync.whenOrNull(
                        data: (bids) => bids.any((b) => b.providerId == currentUser.uid),
                      ) ?? false;

                      if (isOpen && !hasBid) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AppButton(
                            label: 'Submit Bid',
                            onPressed: () => showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20)),
                              ),
                              builder: (_) =>
                                  SubmitBidSheet(taskId: taskId, taskBudget: task.budgetMin),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),

                    // Show provider's own bid if any
                    _ProviderBidView(
                      taskId:     taskId,
                      providerId: currentUser.uid,
                      posterId:   task.posterId,
                      taskStatus: task.status,
                    ),

                    // Start Work button (when assigned to this provider, status == assigned)
                    if (task.assignedProviderId == currentUser.uid &&
                        task.status == TaskStatus.assigned) ...[
                      const SizedBox(height: 12),
                      _StartWorkButton(taskId: taskId),
                    ],
                  ],

                  // Message poster button (when assigned to this provider)
                  if (task.assignedProviderId == currentUser.uid) ...[
                    const SizedBox(height: 12),
                    _MessageButton(
                      taskId:     taskId,
                      posterId:   task.posterId,
                      providerId: currentUser.uid,
                      label:      'Message Poster',
                    ),
                  ],

                  if (!isOpen &&
                      task.assignedProviderId != currentUser.uid) ...[
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
                        Expanded(
                          child: Text(
                            'This task is ${_statusLabel(task.status)} and no longer accepting bids',
                            style: const TextStyle(
                                color: AppColors.primary),
                          ),
                        ),
                      ]),
                    ),
                  ],
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
      case TaskStatus.open:       return 'Open';
      case TaskStatus.assigned:   return 'Assigned';
      case TaskStatus.inProgress: return 'In Progress';
      case TaskStatus.completed:  return 'Completed';
      case TaskStatus.cancelled:  return 'Cancelled';
      case TaskStatus.disputed:   return 'Disputed';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PosterInfo
// ─────────────────────────────────────────────────────────────────────────────
class _PosterInfo extends StatelessWidget {
  final String  posterName;
  final String? posterAvatarUrl;
  const _PosterInfo({required this.posterName, this.posterAvatarUrl});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.bgMint,
          backgroundImage: posterAvatarUrl != null
              ? CachedNetworkImageProvider(posterAvatarUrl!)
              : null,
          child: posterAvatarUrl == null
              ? Text(
                  posterName.isNotEmpty
                      ? posterName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color:      AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Posted by',
              style: TextStyle(
                  fontSize: 12, color: AppColors.textHint),
            ),
            Text(
              posterName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _MarkCompleteButton
// ─────────────────────────────────────────────────────────────────────────────
class _MarkCompleteButton extends ConsumerStatefulWidget {
  final String    taskId;
  final TaskModel task;
  const _MarkCompleteButton({required this.taskId, required this.task});

  @override
  ConsumerState<_MarkCompleteButton> createState() =>
      _MarkCompleteButtonState();
}

class _MarkCompleteButtonState extends ConsumerState<_MarkCompleteButton> {
  bool _isLoading = false;

  Future<void> _markComplete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mark as Complete?'),
        content: const Text(
            'Confirm the task has been completed. This will release the escrow payment to the provider.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await ref
          .read(taskRepositoryProvider)
          .completeTask(widget.taskId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task marked as complete!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label:     'Mark as Complete',
      isLoading: _isLoading,
      onPressed: _markComplete,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _StartWorkButton
// ─────────────────────────────────────────────────────────────────────────────
class _StartWorkButton extends ConsumerStatefulWidget {
  final String taskId;
  const _StartWorkButton({required this.taskId});

  @override
  ConsumerState<_StartWorkButton> createState() => _StartWorkButtonState();
}

class _StartWorkButtonState extends ConsumerState<_StartWorkButton> {
  bool _isLoading = false;

  Future<void> _startWork() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Start Work?'),
        content: const Text(
            'Confirm that you are starting work on this task. The poster will be notified.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await ref
          .read(taskRepositoryProvider)
          .updateStatus(widget.taskId, TaskStatus.inProgress);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Work started! Good luck!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label:     'Start Work',
      isLoading: _isLoading,
      onPressed: _startWork,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _DirectHireResponseButtons — Accept / Decline for direct hire offers
// ─────────────────────────────────────────────────────────────────────────────
class _DirectHireResponseButtons extends ConsumerStatefulWidget {
  final String taskId;
  const _DirectHireResponseButtons({required this.taskId});

  @override
  ConsumerState<_DirectHireResponseButtons> createState() =>
      _DirectHireResponseButtonsState();
}

class _DirectHireResponseButtonsState
    extends ConsumerState<_DirectHireResponseButtons> {
  bool _isLoading = false;

  Future<void> _acceptJob() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Accept Job?'),
        content: const Text(
            'You will start working on this task immediately.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Accept'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await ref
          .read(taskRepositoryProvider)
          .updateStatus(widget.taskId, TaskStatus.inProgress);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job accepted! Work started.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _declineJob() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Decline Job?'),
        content: const Text(
            'This will cancel the task and notify the client.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Decline'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await ref
          .read(taskRepositoryProvider)
          .declineDirectHire(widget.taskId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job declined.'),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: AppRadius.card,
            border:
                Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.work_outline, color: AppColors.primary, size: 22),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'You have been hired directly for this task',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppButton(
          label: 'Accept Job',
          isLoading: _isLoading,
          onPressed: _acceptJob,
        ),
        const SizedBox(height: 8),
        AppButton(
          label: 'Decline',
          isOutlined: true,
          isLoading: _isLoading,
          onPressed: _declineJob,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _WorkInProgressBanner
// ─────────────────────────────────────────────────────────────────────────────
class _WorkInProgressBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.construction_rounded,
              color: AppColors.primary, size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Work in Progress',
              style: TextStyle(
                color:      AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize:   15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _MessageButton  — creates/gets chat then navigates
// ─────────────────────────────────────────────────────────────────────────────
class _MessageButton extends ConsumerStatefulWidget {
  final String taskId;
  final String posterId;
  final String providerId;
  final String label;
  const _MessageButton({
    required this.taskId,
    required this.posterId,
    required this.providerId,
    required this.label,
  });

  @override
  ConsumerState<_MessageButton> createState() => _MessageButtonState();
}

class _MessageButtonState extends ConsumerState<_MessageButton> {
  bool _isLoading = false;

  Future<void> _openChat() async {
    setState(() => _isLoading = true);
    try {
      final chatId = await ref
          .read(chatRepositoryProvider)
          .createOrGetChat(
              widget.taskId, widget.posterId, widget.providerId);
      if (mounted) {
        context.push(
            AppRoutes.chatThread.replaceFirst(':chatId', chatId));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open chat: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label:      widget.label,
      isOutlined: true,
      isLoading:  _isLoading,
      onPressed:  _openChat,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ProviderBidView  — shows provider's own bid on this task
// ─────────────────────────────────────────────────────────────────────────────
class _ProviderBidView extends ConsumerWidget {
  final String     taskId;
  final String     providerId;
  final String     posterId;
  final TaskStatus taskStatus;
  const _ProviderBidView({
    required this.taskId,
    required this.providerId,
    required this.posterId,
    required this.taskStatus,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bidsAsync = ref.watch(bidsStreamProvider(taskId));

    return bidsAsync.when(
      loading: () => const SizedBox.shrink(),
      error:   (_, __) => const SizedBox.shrink(),
      data: (bids) {
        final myBid = bids.where((b) => b.providerId == providerId).firstOrNull;
        if (myBid == null) return const SizedBox.shrink();

        final isAccepted = myBid.status == BidStatus.accepted;
        final isRejected = myBid.status == BidStatus.rejected;

        return Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isAccepted
                ? AppColors.bgMint
                : isRejected
                    ? AppColors.bgCard
                    : AppColors.bgCard,
            borderRadius: AppRadius.card,
            border: Border.all(
              color: isAccepted
                  ? AppColors.primary
                  : isRejected
                      ? AppColors.divider
                      : AppColors.warning.withValues(alpha: 0.4),
              width: isAccepted ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Bid',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  _StatusBadge(status: myBid.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'S\$${myBid.amount.toStringAsFixed(2)}',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: AppColors.primary),
              ),
              if (myBid.message != null && myBid.message!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  myBid.message!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              if (isAccepted) ...[
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Icon(Icons.check_circle,
                        size: 16, color: AppColors.success),
                    SizedBox(width: 4),
                    Text(
                      'Bid accepted — get ready to start!',
                      style: TextStyle(
                        color:      AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _StatusBadge
// ─────────────────────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final BidStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    late final Color  color;
    late final String label;

    switch (status) {
      case BidStatus.pending:
        color = AppColors.warning;
        label = 'Pending';
      case BidStatus.accepted:
        color = AppColors.success;
        label = 'Accepted';
      case BidStatus.rejected:
        color = AppColors.textHint;
        label = 'Rejected';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color:      color,
          fontSize:   11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
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
// _LeaveReviewCard
// ─────────────────────────────────────────────────────────────────────────────
class _LeaveReviewCard extends StatelessWidget {
  final String taskId;
  final String reviewedUserId;
  final String reviewedUserName;
  final String taskCategory;
  const _LeaveReviewCard({
    required this.taskId,
    required this.reviewedUserId,
    required this.reviewedUserName,
    required this.taskCategory,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.star_rounded, color: AppColors.warning, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Leave a Review',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Rate your experience with $reviewedUserName',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.push(
              AppRoutes.submitReview,
              extra: {
                'taskId': taskId,
                'reviewedUserId': reviewedUserId,
                'reviewedUserName': reviewedUserName,
                'taskCategory': taskCategory,
              },
            ),
            child: const Text('Review'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TaskTimeline
// ─────────────────────────────────────────────────────────────────────────────
class _TaskTimeline extends StatelessWidget {
  final TaskModel task;
  const _TaskTimeline({required this.task});

  @override
  Widget build(BuildContext context) {
    final steps = _buildSteps();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          for (int i = 0; i < steps.length; i++) ...[
            Expanded(child: _StepItem(step: steps[i])),
            if (i < steps.length - 1)
              Expanded(
                flex: 0,
                child: Container(
                  width: 20,
                  height: 2,
                  color: steps[i].isCompleted
                      ? AppColors.success
                      : AppColors.divider,
                ),
              ),
          ],
        ],
      ),
    );
  }

  List<_TimelineStep> _buildSteps() {
    final isCancelled = task.status == TaskStatus.cancelled;
    final isDisputed = task.status == TaskStatus.disputed;

    if (isCancelled) {
      return [
        _TimelineStep(
          label: 'Posted',
          icon: Icons.check_circle,
          color: AppColors.success,
          isCompleted: true,
          timestamp: task.createdAt,
        ),
        _TimelineStep(
          label: 'Cancelled',
          icon: Icons.cancel,
          color: AppColors.error,
          isCompleted: true,
          timestamp: task.updatedAt,
        ),
      ];
    }

    if (isDisputed) {
      final currentIndex = _statusIndex(task.status);
      final steps = _defaultSteps();
      // Mark steps up to the disputed point, then add disputed step
      final result = <_TimelineStep>[];
      for (int i = 0; i < steps.length; i++) {
        if (i < currentIndex) {
          result.add(steps[i].copyWith(isCompleted: true));
        } else {
          break;
        }
      }
      result.add(_TimelineStep(
        label: 'Disputed',
        icon: Icons.warning_rounded,
        color: AppColors.warning,
        isCompleted: true,
        timestamp: task.updatedAt,
      ));
      return result;
    }

    final currentIndex = _statusIndex(task.status);
    return _defaultSteps().asMap().entries.map((entry) {
      final i = entry.key;
      final step = entry.value;
      if (i < currentIndex) {
        return step.copyWith(isCompleted: true);
      } else if (i == currentIndex) {
        return step.copyWith(isCurrent: true);
      }
      return step;
    }).toList();
  }

  List<_TimelineStep> _defaultSteps() {
    return [
      _TimelineStep(
        label: 'Posted',
        icon: Icons.check_circle,
        color: AppColors.success,
        timestamp: task.createdAt,
      ),
      _TimelineStep(
        label: 'Bidding',
        icon: Icons.gavel,
        color: AppColors.success,
      ),
      _TimelineStep(
        label: 'Matched',
        icon: Icons.handshake,
        color: AppColors.success,
      ),
      _TimelineStep(
        label: 'In Progress',
        icon: Icons.play_circle_filled,
        color: AppColors.success,
      ),
      _TimelineStep(
        label: 'Completed',
        icon: Icons.check_circle,
        color: AppColors.success,
        timestamp: task.completedAt,
      ),
    ];
  }

  int _statusIndex(TaskStatus status) {
    switch (status) {
      case TaskStatus.open:
        return 0;
      case TaskStatus.assigned:
        return 2;
      case TaskStatus.inProgress:
        return 3;
      case TaskStatus.completed:
        return 4;
      case TaskStatus.cancelled:
      case TaskStatus.disputed:
        return -1;
    }
  }
}

class _TimelineStep {
  final String label;
  final IconData icon;
  final Color color;
  final bool isCompleted;
  final bool isCurrent;
  final DateTime? timestamp;

  const _TimelineStep({
    required this.label,
    required this.icon,
    required this.color,
    this.isCompleted = false,
    this.isCurrent = false,
    this.timestamp,
  });

  _TimelineStep copyWith({bool? isCompleted, bool? isCurrent}) {
    return _TimelineStep(
      label: label,
      icon: icon,
      color: color,
      isCompleted: isCompleted ?? this.isCompleted,
      isCurrent: isCurrent ?? this.isCurrent,
      timestamp: timestamp,
    );
  }
}

class _StepItem extends StatelessWidget {
  final _TimelineStep step;
  const _StepItem({required this.step});

  @override
  Widget build(BuildContext context) {
    final Color iconColor;
    final IconData displayIcon;

    if (step.isCompleted) {
      iconColor = step.color;
      displayIcon = step.icon;
    } else if (step.isCurrent) {
      iconColor = AppColors.primary;
      displayIcon = step.icon;
    } else {
      iconColor = AppColors.textHint;
      displayIcon = Icons.circle_outlined;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(displayIcon, size: 22, color: iconColor),
        const SizedBox(height: 4),
        Text(
          step.label,
          style: TextStyle(
            fontSize: 10,
            fontWeight:
                step.isCurrent ? FontWeight.w700 : FontWeight.w500,
            color: step.isCompleted || step.isCurrent
                ? AppColors.textPrimary
                : AppColors.textHint,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (step.isCompleted && step.timestamp != null) ...[
          const SizedBox(height: 2),
          Text(
            _formatDate(step.timestamp!),
            style: const TextStyle(
              fontSize: 8,
              color: AppColors.textHint,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
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
