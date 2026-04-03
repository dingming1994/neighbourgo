import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../domain/providers/notification_providers.dart';

class NotificationListScreen extends ConsumerWidget {
  const NotificationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(notificationsProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider).valueOrNull ?? 0;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.bgCard,
        elevation: 0,
        title: const Text('Notifications',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
        actions: [
          if (unreadCount > 0)
            TextButton.icon(
              onPressed: () {
                final user = ref.read(currentUserProvider).valueOrNull;
                if (user != null) {
                  markAllNotificationsAsRead(user.uid);
                }
              },
              icon: const Icon(Icons.done_all, size: 18),
              label: const Text('Mark All Read', style: TextStyle(fontSize: 13)),
            ),
        ],
      ),
      body: notifAsync.when(skipLoadingOnReload: true,
        loading: () => const _NotificationLoadingList(),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(notificationsProvider),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🔔', style: TextStyle(fontSize: 56)),
                    SizedBox(height: 16),
                    Text('No notifications yet',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary)),
                    SizedBox(height: 8),
                    Text("You'll see updates on your tasks and bids here",
                        style: TextStyle(color: AppColors.textHint)),
                  ],
                ),
              ),
            );
          }

          // Group by date
          final groups = _groupByDate(notifications);

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(notificationsProvider);
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: groups.length,
              itemBuilder: (_, i) => _DateGroup(
                label: groups[i].label,
                notifications: groups[i].notifications,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Date grouping
// ─────────────────────────────────────────────────────────────────────────────
class _NotificationGroup {
  final String label;
  final List<AppNotification> notifications;
  _NotificationGroup({required this.label, required this.notifications});
}

List<_NotificationGroup> _groupByDate(List<AppNotification> notifications) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));

  final Map<String, List<AppNotification>> grouped = {};
  for (final n in notifications) {
    final date = DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
    String label;
    if (date == today) {
      label = 'Today';
    } else if (date == yesterday) {
      label = 'Yesterday';
    } else {
      label = 'Earlier';
    }
    (grouped[label] ??= []).add(n);
  }

  final result = <_NotificationGroup>[];
  for (final key in ['Today', 'Yesterday', 'Earlier']) {
    if (grouped.containsKey(key)) {
      result.add(_NotificationGroup(label: key, notifications: grouped[key]!));
    }
  }
  return result;
}

// ─────────────────────────────────────────────────────────────────────────────
// Date group section
// ─────────────────────────────────────────────────────────────────────────────
class _DateGroup extends StatelessWidget {
  final String label;
  final List<AppNotification> notifications;
  const _DateGroup({required this.label, required this.notifications});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textHint,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...notifications.map((n) => _NotificationTile(notification: n)),
        const Divider(height: 1),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notification tile with swipe-to-dismiss and action button
// ─────────────────────────────────────────────────────────────────────────────
class _NotificationTile extends ConsumerWidget {
  final AppNotification notification;
  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.primary.withValues(alpha: 0.12),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.done, color: AppColors.primary, size: 20),
            SizedBox(width: 4),
            Text('Read', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      onDismissed: (_) {
        final user = ref.read(currentUserProvider).valueOrNull;
        if (user != null && !notification.isRead) {
          markNotificationAsRead(user.uid, notification.id);
        }
      },
      child: InkWell(
        onTap: () => _onTap(context, ref),
        child: Container(
          color: notification.isRead ? null : AppColors.bgMint.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              CircleAvatar(
                radius: 20,
                backgroundColor: _iconColor(notification.type).withValues(alpha: 0.12),
                child: Icon(_icon(notification.type), color: _iconColor(notification.type), size: 20),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8, height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(notification.body, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(timeago.format(notification.createdAt),
                            style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                        const Spacer(),
                        _ActionButton(notification: notification),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTap(BuildContext context, WidgetRef ref) {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user != null && !notification.isRead) {
      markNotificationAsRead(user.uid, notification.id);
    }
    _navigateByType(context, notification);
  }

  IconData _icon(String type) {
    switch (type) {
      case 'bid_received':    return Icons.gavel;
      case 'bid_accepted':    return Icons.check_circle_outline;
      case 'bid_rejected':    return Icons.cancel_outlined;
      case 'task_completed':  return Icons.task_alt;
      case 'new_message':     return Icons.chat_bubble_outline;
      case 'review_received': return Icons.star_outline;
      default:                return Icons.notifications_outlined;
    }
  }

  Color _iconColor(String type) {
    switch (type) {
      case 'bid_received':    return AppColors.primary;
      case 'bid_accepted':    return AppColors.success;
      case 'bid_rejected':    return AppColors.error;
      case 'task_completed':  return AppColors.success;
      case 'new_message':     return AppColors.accent;
      case 'review_received': return AppColors.warning;
      default:                return AppColors.textSecondary;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Contextual action button per notification type
// ─────────────────────────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final AppNotification notification;
  const _ActionButton({required this.notification});

  @override
  Widget build(BuildContext context) {
    final label = _actionLabel(notification.type);
    if (label == null) return const SizedBox.shrink();

    return SizedBox(
      height: 28,
      child: TextButton(
        onPressed: () => _navigateByType(context, notification),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      ),
    );
  }

  String? _actionLabel(String type) {
    switch (type) {
      case 'bid_received':    return 'View Bids';
      case 'bid_accepted':
      case 'bid_rejected':
      case 'task_completed':  return 'View Task';
      case 'new_message':     return 'Reply';
      case 'review_received': return 'Leave Review';
      default:                return null;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared navigation
// ─────────────────────────────────────────────────────────────────────────────
void _navigateByType(BuildContext context, AppNotification notification) {
  final data = notification.data;
  switch (notification.type) {
    case 'bid_received':
    case 'bid_accepted':
    case 'bid_rejected':
    case 'task_completed':
      final taskId = data['taskId'] as String?;
      if (taskId != null) {
        context.push(AppRoutes.taskDetail.replaceFirst(':taskId', taskId));
      }
    case 'new_message':
      final chatId = data['chatId'] as String?;
      if (chatId != null) {
        context.push(AppRoutes.chatThread.replaceFirst(':chatId', chatId));
      }
    case 'review_received':
      final userId = data['userId'] as String?;
      if (userId != null) {
        context.push(AppRoutes.publicProfile.replaceFirst(':userId', userId));
      }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shimmer loading
// ─────────────────────────────────────────────────────────────────────────────
class _NotificationLoadingList extends StatelessWidget {
  const _NotificationLoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 6,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: AppColors.divider,
        highlightColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.bgCard,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      width: 180,
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: 240,
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 10,
                      width: 80,
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
