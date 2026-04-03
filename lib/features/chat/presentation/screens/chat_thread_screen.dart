import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/image_validator.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../data/repositories/chat_repository.dart';
import '../../domain/models/message_model.dart';

class ChatThreadScreen extends ConsumerStatefulWidget {
  final String chatId;
  const ChatThreadScreen({super.key, required this.chatId});

  @override
  ConsumerState<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends ConsumerState<ChatThreadScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;
  bool _showScrollToBottom = false;
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Mark messages as read when opening the chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider).valueOrNull;
      if (user != null) {
        ref.read(chatRepositoryProvider).markMessagesAsRead(widget.chatId, user.uid);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final isNearBottom = _scrollController.position.maxScrollExtent -
            _scrollController.offset <
        150;
    if (_showScrollToBottom == isNearBottom) {
      setState(() => _showScrollToBottom = !isNearBottom);
    }
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (animate) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController
              .jumpTo(_scrollController.position.maxScrollExtent);
        }
      }
    });
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _sendText() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    setState(() => _isSending = true);
    _textController.clear();

    try {
      final message = MessageModel(
        messageId: '',
        chatId: widget.chatId,
        senderId: user.uid,
        text: text,
        timestamp: DateTime.now(),
      );
      await ref
          .read(chatRepositoryProvider)
          .sendMessage(widget.chatId, message);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _sendImage() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;

    final file = File(picked.path);
    final validationError = ImageValidator.validate(file);
    if (validationError != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(validationError), backgroundColor: AppColors.error),
        );
      }
      return;
    }

    setState(() => _isSending = true);
    try {
      final repo = ref.read(chatRepositoryProvider);
      final url =
          await repo.uploadChatImage(widget.chatId, file);
      final message = MessageModel(
        messageId: '',
        chatId: widget.chatId,
        senderId: user.uid,
        imageUrl: url,
        timestamp: DateTime.now(),
      );
      await repo.sendMessage(widget.chatId, message);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send image: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatAsync = ref.watch(chatStreamProvider(widget.chatId));
    final messagesAsync = ref.watch(messagesStreamProvider(widget.chatId));
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

    final chat = chatAsync.valueOrNull;
    final isDirectChat = chat?.taskId == null;
    final title = isDirectChat
        ? (chat?.otherUserName ?? 'Chat')
        : (chat?.taskTitle ?? 'Chat');
    final subtitle = isDirectChat ? 'Direct message' : 'Task chat';

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.bgCard,
        elevation: 0,
        titleSpacing: 0,
        leading: const BackButton(),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 16)),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Message list ──────────────────────────────────────────────
          Expanded(
            child: messagesAsync.when(skipLoadingOnReload: true,
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorState(
                onRetry: () => ref.invalidate(messagesStreamProvider(widget.chatId)),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 48,
                            color: AppColors.textHint.withOpacity(0.4)),
                        const SizedBox(height: 12),
                        const Text('No messages yet',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 15)),
                        const SizedBox(height: 4),
                        const Text('Say hello!',
                            style: TextStyle(
                                color: AppColors.textHint, fontSize: 13)),
                      ],
                    ),
                  );
                }

                // Auto-scroll on new messages if near bottom
                if (messages.length != _lastMessageCount) {
                  _lastMessageCount = messages.length;
                  if (!_showScrollToBottom) {
                    _scrollToBottom();
                  }
                }

                return Stack(
                  children: [
                    ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 12),
                      itemCount: messages.length,
                      itemBuilder: (context, i) {
                        final msg = messages[i];
                        final isMe = msg.senderId == currentUser?.uid;

                        // Date separator: show when first message or different day
                        final showDateSeparator = i == 0 ||
                            !_isSameDay(
                                msg.timestamp, messages[i - 1].timestamp);

                        // Message grouping: same sender within 2 minutes
                        final isFirstInGroup = i == 0 ||
                            messages[i - 1].senderId != msg.senderId ||
                            msg.timestamp
                                    .difference(messages[i - 1].timestamp)
                                    .inMinutes
                                    .abs() >
                                2 ||
                            showDateSeparator;

                        final isLastInGroup = i == messages.length - 1 ||
                            messages[i + 1].senderId != msg.senderId ||
                            messages[i + 1]
                                    .timestamp
                                    .difference(msg.timestamp)
                                    .inMinutes
                                    .abs() >
                                2 ||
                            !_isSameDay(
                                msg.timestamp, messages[i + 1].timestamp);

                        return Column(
                          children: [
                            if (showDateSeparator)
                              _DateSeparator(date: msg.timestamp),
                            _MessageBubble(
                              message: msg,
                              isMe: isMe,
                              isFirstInGroup: isFirstInGroup,
                              isLastInGroup: isLastInGroup,
                            ),
                          ],
                        );
                      },
                    ),
                    // Scroll-to-bottom FAB
                    if (_showScrollToBottom)
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: FloatingActionButton.small(
                          onPressed: () => _scrollToBottom(),
                          backgroundColor: AppColors.bgCard,
                          elevation: 4,
                          child: const Icon(Icons.keyboard_arrow_down,
                              color: AppColors.textSecondary),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          // ── Input bar ─────────────────────────────────────────────────
          _InputBar(
            controller: _textController,
            isSending: _isSending,
            onSendText: _sendText,
            onPickImage: _sendImage,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Date separator
// ─────────────────────────────────────────────────────────────────────────────
class _DateSeparator extends StatelessWidget {
  final DateTime date;
  const _DateSeparator({required this.date});

  String _label() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(date.year, date.month, date.day);
    final diff = today.difference(msgDay).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat('d MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppColors.divider)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _label(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textHint,
              ),
            ),
          ),
          const Expanded(child: Divider(color: AppColors.divider)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Message bubble
// ─────────────────────────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final bool isFirstInGroup;
  final bool isLastInGroup;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    this.isFirstInGroup = true,
    this.isLastInGroup = true,
  });

  @override
  Widget build(BuildContext context) {
    // Tighter spacing for grouped messages
    final topMargin = isFirstInGroup ? 4.0 : 1.0;
    final bottomMargin = isLastInGroup ? 4.0 : 1.0;

    // Adjust bubble corners for grouping
    const big = Radius.circular(16);
    const small = Radius.circular(4);

    BorderRadius bubbleRadius;
    if (isMe) {
      bubbleRadius = BorderRadius.only(
        topLeft: big,
        topRight: isFirstInGroup ? big : small,
        bottomLeft: big,
        bottomRight: small,
      );
    } else {
      bubbleRadius = BorderRadius.only(
        topLeft: isFirstInGroup ? big : small,
        topRight: big,
        bottomLeft: small,
        bottomRight: big,
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: topMargin,
          bottom: bottomMargin,
          left: isMe ? 48 : 0,
          right: isMe ? 0 : 48,
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (message.imageUrl != null)
              GestureDetector(
                onTap: () => _openFullScreenImage(context, message.imageUrl!),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: message.imageUrl!,
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 200,
                      height: 200,
                      color: AppColors.border,
                      child: const Center(
                          child: CircularProgressIndicator()),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 200,
                      height: 200,
                      color: AppColors.border,
                      child: const Icon(Icons.broken_image),
                    ),
                  ),
                ),
              ),
            if (message.text != null && message.text!.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isMe ? AppColors.primary : AppColors.bgCard,
                  borderRadius: bubbleRadius,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  message.text!,
                  style: TextStyle(
                    color: isMe ? Colors.white : AppColors.textPrimary,
                    fontSize: 15,
                  ),
                ),
              ),
            // Only show time on last message in group
            if (isLastInGroup) ...[
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(message.timestamp),
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textHint),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      message.isRead ? Icons.done_all : Icons.done,
                      size: 12,
                      color: message.isRead
                          ? AppColors.primary
                          : AppColors.textHint,
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static void _openFullScreenImage(BuildContext context, String url) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: PhotoView(
          imageProvider: CachedNetworkImageProvider(url),
          backgroundDecoration: const BoxDecoration(color: Colors.black),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 3,
        ),
      ),
    ));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Input bar
// ─────────────────────────────────────────────────────────────────────────────
class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSendText;
  final VoidCallback onPickImage;

  const _InputBar({
    required this.controller,
    required this.isSending,
    required this.onSendText,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 12,
        right: 8,
        top: 8,
        bottom: 8 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Image picker button
          IconButton(
            onPressed: isSending ? null : onPickImage,
            icon: const Icon(Icons.image_outlined),
            color: AppColors.textSecondary,
            padding: EdgeInsets.zero,
            constraints:
                const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          const SizedBox(width: 4),
          // Text field
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 120),
              child: TextField(
                controller: controller,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Type a message…',
                  hintStyle: TextStyle(
                      color: AppColors.textHint.withOpacity(0.7),
                      fontSize: 15),
                  filled: true,
                  fillColor: AppColors.bgLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => onSendText(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send button
          AnimatedBuilder(
            animation: controller,
            builder: (_, __) {
              final hasText = controller.text.trim().isNotEmpty;
              return GestureDetector(
                onTap: (hasText && !isSending) ? onSendText : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: hasText && !isSending
                        ? AppColors.primary
                        : AppColors.border,
                    shape: BoxShape.circle,
                  ),
                  child: isSending
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
