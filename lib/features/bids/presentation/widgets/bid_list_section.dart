import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../data/repositories/bid_repository.dart';
import '../../domain/models/bid_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────
final bidsStreamProvider =
    StreamProvider.family<List<BidModel>, String>(
  (ref, taskId) => ref.watch(bidRepositoryProvider).getBidsStream(taskId),
);

// ─────────────────────────────────────────────────────────────────────────────
// BidListSection  (Poster view)
// ─────────────────────────────────────────────────────────────────────────────
class BidListSection extends ConsumerWidget {
  final String taskId;
  const BidListSection({super.key, required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bidsAsync = ref.watch(bidsStreamProvider(taskId));

    return bidsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Center(child: Text('加载失败: $e')),
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
                  Text('暂无报价',
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
                '收到报价 (${bids.length})',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ...bids.map((bid) => _BidCard(taskId: taskId, bid: bid)),
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
  final BidModel bid;
  const _BidCard({required this.taskId, required this.bid});

  @override
  ConsumerState<_BidCard> createState() => _BidCardState();
}

class _BidCardState extends ConsumerState<_BidCard> {
  bool _isAccepting = false;
  bool _isRejecting = false;

  Future<void> _accept() async {
    setState(() => _isAccepting = true);
    try {
      await ref.read(bidRepositoryProvider).acceptBid(
            widget.taskId,
            widget.bid.bidId,
            widget.bid.providerId,
            widget.bid.providerName,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作失败: $e'),
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
            content: Text('操作失败: $e'),
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
              // Avatar
              CircleAvatar(
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
              const SizedBox(width: 12),

              // Name + time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bid.providerName,
                        style: Theme.of(context).textTheme.titleMedium),
                    if (bid.createdAt != null)
                      Text(
                        timeago.format(bid.createdAt!),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                  ],
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
                Expanded(
                  child: AppButton(
                    label:     '接受',
                    isLoading: _isAccepting,
                    onPressed: _isRejecting ? null : _accept,
                    height:    40,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton(
                    label:      '拒绝',
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
                    '已接受',
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
        label = '待定';
      case BidStatus.accepted:
        color = AppColors.success;
        label = '已接受';
      case BidStatus.rejected:
        color = AppColors.textHint;
        label = '已拒绝';
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
