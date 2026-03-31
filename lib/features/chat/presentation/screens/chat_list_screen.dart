import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Please sign in'));
          }
          return _ChatList(userId: user.uid);
        },
      ),
    );
  }
}

class _ChatList extends ConsumerWidget {
  final String userId;
  const _ChatList({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(chatsStreamProvider(userId));

    return chatsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Failed to load chats: $e',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary)),
        ),
      ),
      data: (chats) {
        if (chats.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline,
                    size: 64, color: AppColors.textHint.withOpacity(0.4)),
                const SizedBox(height: 16),
                const Text('No messages yet',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                const Text('Start a conversation by bidding on a task',
                    style: TextStyle(color: AppColors.textHint)),
              ],
            ),
          );
        }

        return ListView.separated(
          itemCount: chats.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, indent: 72),
          itemBuilder: (context, i) => _ChatTile(
            chat: chats[i],
            currentUserId: userId,
          ),
        );
      },
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
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: isDirectChat
            ? AppColors.accent.withOpacity(0.12)
            : AppColors.primary.withOpacity(0.12),
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
                fontWeight:
                    hasUnread ? FontWeight.w700 : FontWeight.w600,
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
                color: hasUnread
                    ? AppColors.primary
                    : AppColors.textHint,
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
                color: hasUnread
                    ? AppColors.textPrimary
                    : AppColors.textHint,
                fontWeight:
                    hasUnread ? FontWeight.w500 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (hasUnread)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
