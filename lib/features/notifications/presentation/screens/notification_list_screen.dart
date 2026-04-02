import 'package:cloud_firestore/cloud_firestore.dart';
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

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.bgCard,
        elevation: 0,
        title: const Text('Notifications',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
      ),
      body: notifAsync.when(
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

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(notificationsProvider);
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) => _NotificationTile(
                notification: notifications[i],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final AppNotification notification;
  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      tileColor: notification.isRead ? null : AppColors.bgMint.withValues(alpha: 0.3),
      leading: CircleAvatar(
        backgroundColor: _iconColor(notification.type).withValues(alpha: 0.12),
        child: Icon(_icon(notification.type), color: _iconColor(notification.type), size: 20),
      ),
      title: Text(
        notification.title,
        style: TextStyle(
          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(notification.body, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 2),
          Text(timeago.format(notification.createdAt),
              style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
        ],
      ),
      trailing: notification.isRead
          ? null
          : Container(
              width: 8, height: 8,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
      onTap: () => _onTap(context, ref),
    );
  }

  void _onTap(BuildContext context, WidgetRef ref) {
    // Mark as read
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user != null && !notification.isRead) {
      FirebaseFirestore.instance
          .collection(AppConstants.notificationsCol)
          .doc(user.uid)
          .collection('items')
          .doc(notification.id)
          .update({'isRead': true});
    }

    // Navigate based on type
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
