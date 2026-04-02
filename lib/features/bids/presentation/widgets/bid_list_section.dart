import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../chat/data/repositories/chat_repository.dart';
import '../../../profile/data/repositories/profile_repository.dart';
import '../../data/repositories/bid_repository.dart';
import '../../domain/models/bid_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────
final bidsStreamProvider =
    StreamProvider.family<List<BidModel>, String>(
  (ref, taskId) => ref.watch(bidRepositoryProvider).getBidsStream(taskId),
);

/// Fetches provider's average rating from their profile stats.
final providerRatingProvider =
    FutureProvider.family<double, String>((ref, providerId) async {
  final profile =
      await ref.watch(profileRepositoryProvider).fetchProfile(providerId);
  return profile?.stats?.avgRating ?? 0.0;
});

// ─────────────────────────────────────────────────────────────────────────────
// BidListSection  (Poster view)
// ─────────────────────────────────────────────────────────────────────────────
class BidListSection extends ConsumerWidget {
  final String taskId;
  final String posterId;
  const BidListSection({super.key, required this.taskId, required this.posterId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bidsAsync = ref.watch(bidsStreamProvider(taskId));

    return bidsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Center(child: Text('Failed to load bids: $e')),
      data: (bids) {
        if (bids.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined,
                      size: 48, color: AppColors.textHint),
                  SizedBox(height: 12),
                  Text('No bids yet',
                      style: TextStyle(color: AppColors.textHint)),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Bids received (${bids.length})',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ...bids.map((bid) => _BidCard(taskId: taskId, posterId: posterId, bid: bid)),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BidCard
// ─────────────────────────────────────────────────────────────────────────────
class _BidCard extends ConsumerStatefulWidget {
  final String   taskId;
  final String   posterId;
  final BidModel bid;
  const _BidCard({required this.taskId, required this.posterId, required this.bid});

  @override
  ConsumerState<_BidCard> createState() => _BidCardState();
}

class _BidCardState extends ConsumerState<_BidCard> {
  bool _isAccepting  = false;
  bool _isRejecting  = false;
  bool _isMessaging  = false;

  void _viewProfile() {
    context.push(
      AppRoutes.publicProfile.replaceFirst(':userId', widget.bid.providerId),
    );
  }

  Future<void> _messageBidder() async {
    setState(() => _isMessaging = true);
    try {
      final chatId = await ref
          .read(chatRepositoryProvider)
          .createOrGetChat(
              widget.taskId, widget.posterId, widget.bid.providerId);
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
      if (mounted) setState(() => _isMessaging = false);
    }
  }

  Future<void> _accept() async {
    setState(() => _isAccepting = true);
    try {
      await ref.read(bidRepositoryProvider).acceptBid(
            widget.taskId,
            widget.bid.bidId,
            widget.bid.providerId,
            widget.bid.providerName,
          );

      // Auto-create chat with initial message
      String? chatId;
      try {
        chatId = await ref.read(chatRepositoryProvider).createChatWithMessage(
              taskId: widget.taskId,
              posterId: widget.posterId,
              providerId: widget.bid.providerId,
              senderId: widget.posterId,
              messageText:
                  'Hi! I accepted your bid for this task. Let\'s discuss the details.',
            );
      } catch (_) {
        // Chat creation is best-effort — don't block checkout
      }

      if (mounted) {
        // Show SnackBar with action to message provider
        if (chatId != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bid accepted! Chat created with ${widget.bid.providerName}'),
              action: SnackBarAction(
                label: 'Message Provider',
                onPressed: () {
                  context.push(
                    AppRoutes.chatThread.replaceFirst(':chatId', chatId!),
                  );
                },
              ),
            ),
          );
        }

        // Navigate to checkout
        context.push(
          AppRoutes.checkout.replaceFirst(':taskId', widget.taskId),
          extra: {
            'taskId':       widget.taskId,
            'bidId':        widget.bid.bidId,
            'providerName': widget.bid.providerName,
            'bidAmount':    widget.bid.amount,
          },
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
      if (mounted) setState(() => _isAccepting = false);
    }
  }

  Future<void> _reject() async {
    setState(() => _isRejecting = true);
    try {
      await ref
          .read(bidRepositoryProvider)
          .rejectBid(widget.taskId, widget.bid.bidId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject bid: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRejecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bid        = widget.bid;
    final isAccepted = bid.status == BidStatus.accepted;
    final isPending  = bid.status == BidStatus.pending;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAccepted ? AppColors.bgMint : AppColors.bgCard,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: isAccepted ? AppColors.primary : AppColors.divider,
          width: isAccepted ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: avatar + name/time + amount/status
          Row(
            children: [
              // Avatar (tappable)
              GestureDetector(
                onTap: _viewProfile,
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.bgMint,
                  backgroundImage: bid.providerAvatar != null
                      ? CachedNetworkImageProvider(bid.providerAvatar!)
                      : null,
                  child: bid.providerAvatar == null
                      ? Text(
                          bid.providerName.isNotEmpty
                              ? bid.providerName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color:      AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),

              // Name + rating + time (tappable)
              Expanded(
                child: GestureDetector(
                  onTap: _viewProfile,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bid.providerName,
                          style: Theme.of(context).textTheme.titleMedium),
                      // Provider average rating
                      Consumer(builder: (context, ref, _) {
                        final ratingAsync =
                            ref.watch(providerRatingProvider(bid.providerId));
                        return ratingAsync.when(
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                          data: (rating) {
                            if (rating <= 0) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Row(
                                children: [
                                  const Icon(Icons.star_rounded,
                                      size: 14, color: AppColors.warning),
                                  const SizedBox(width: 2),
                                  Text(
                                    rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      }),
                      if (bid.createdAt != null)
                        Text(
                          timeago.format(bid.createdAt!),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                    ],
                  ),
                ),
              ),

              // Amount + status badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'S\$${bid.amount.toStringAsFixed(2)}',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: 4),
                  _StatusBadge(status: bid.status),
                ],
              ),
            ],
          ),

          // Message
          if (bid.message != null && bid.message!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(bid.message!,
                style: Theme.of(context).textTheme.bodyMedium),
          ],

          // Action buttons (only for pending bids)
          if (isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                // Message bidder button
                IconButton(
                  onPressed: _isMessaging ? null : _messageBidder,
                  icon: _isMessaging
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chat_bubble_outline),
                  tooltip: 'Message',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.bgMint,
                    foregroundColor: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    label:     'Accept',
                    isLoading: _isAccepting,
                    onPressed: _isRejecting ? null : _accept,
                    height:    40,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton(
                    label:      'Reject',
                    isLoading:  _isRejecting,
                    isOutlined: true,
                    onPressed:  _isAccepting ? null : _reject,
                    height:     40,
                  ),
                ),
              ],
            ),
          ],

          // Accepted confirmation row
          if (isAccepted)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  Icon(Icons.check_circle,
                      size: 16, color: AppColors.success),
                  SizedBox(width: 4),
                  Text(
                    'Accepted',
                    style: TextStyle(
                      color:      AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
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
