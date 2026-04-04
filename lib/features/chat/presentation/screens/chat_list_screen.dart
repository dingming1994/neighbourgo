import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../data/repositories/chat_repository.dart';
import '../../domain/models/chat_model.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.bgCard,
        elevation: 0,
        title: const Text('Messages',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
      ),
      body: userAsync.when(
        skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(currentUserProvider),
        ),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Please sign in'));
          }
          return _ChatList(user: user);
        },
      ),
    );
  }
}

class _ChatList extends ConsumerWidget {
  final UserModel user;
  const _ChatList({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(chatsStreamProvider(user.uid));
    final isProviderOnly = user.role == UserRole.provider;

    return chatsAsync.when(
      skipLoadingOnReload: true,
      loading: () => const _ChatLoadingList(),
      error: (e, _) => ErrorState(
        message: e.toString(),
        onRetry: () => ref.invalidate(chatsStreamProvider(user.uid)),
      ),
      data: (chats) {
        if (chats.isEmpty) {
          return EmptyState(
            emoji: '💬',
            title: 'No conversations yet',
            subtitle: isProviderOnly
                ? 'Bid on an open task to start chatting with posters'
                : 'Accept a bid or open one of your tasks to message a provider',
            action: ElevatedButton.icon(
              onPressed: () => context.push(
                isProviderOnly ? AppRoutes.taskList : AppRoutes.myTasks,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
              ),
              icon: Icon(
                  isProviderOnly ? Icons.search : Icons.assignment_outlined,
                  size: 18),
              label: Text(isProviderOnly ? 'Browse Tasks' : 'View My Tasks'),
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(chatsStreamProvider(user.uid));
          },
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: chats.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
            itemBuilder: (context, i) => _ChatTile(
              chat: chats[i],
              currentUserId: user.uid,
            ),
          ),
        );
      },
    );
  }
}

class _ChatLoadingList extends StatelessWidget {
  const _ChatLoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 6,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: AppColors.divider,
        highlightColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
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
                      width: 160,
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: 220,
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

class _ChatTile extends StatelessWidget {
  final ChatModel chat;
  final String currentUserId;

  const _ChatTile({required this.chat, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final hasUnread = chat.unreadCount > 0;
    final isDirectChat = chat.taskId == null;
    final displayTitle = isDirectChat
        ? (chat.otherUserName ?? 'Direct Message')
        : (chat.taskTitle ?? 'Task');

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: isDirectChat
            ? AppColors.accent.withValues(alpha: 0.12)
            : AppColors.primary.withValues(alpha: 0.12),
        child: Icon(
          isDirectChat ? Icons.person : Icons.task_alt,
          color: isDirectChat ? AppColors.accent : AppColors.primary,
          size: 22,
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              displayTitle,
              style: TextStyle(
                fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                fontSize: 15,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (chat.lastMessageTime != null) ...[
            const SizedBox(width: 8),
            Text(
              timeago.format(chat.lastMessageTime!, locale: 'en_short'),
              style: TextStyle(
                fontSize: 12,
                color: hasUnread ? AppColors.primary : AppColors.textHint,
              ),
            ),
          ],
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              chat.lastMessage ?? 'Start the conversation…',
              style: TextStyle(
                fontSize: 13,
                color: hasUnread ? AppColors.textPrimary : AppColors.textHint,
                fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (hasUnread)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${chat.unreadCount}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      onTap: () => context.push(
        AppRoutes.chatThread.replaceFirst(':chatId', chat.chatId),
      ),
    );
  }
}
