import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../../tasks/data/repositories/task_repository.dart';
import '../../data/repositories/bid_repository.dart';
import '../../domain/models/bid_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────
final _myBidsProvider = StreamProvider.autoDispose<List<BidModel>>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref.watch(bidRepositoryProvider).watchMyBids(user.uid);
});

/// Cache task titles by taskId to avoid redundant fetches.
final _taskTitleProvider = FutureProvider.family.autoDispose<String, String>((ref, taskId) async {
  final stream = ref.watch(taskRepositoryProvider).watchTask(taskId);
  final task = await stream.first;
  return task?.title ?? 'Unknown Task';
});

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
class MyBidsScreen extends ConsumerWidget {
  const MyBidsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.bgLight,
        appBar: AppBar(
          backgroundColor: AppColors.bgCard,
          elevation: 0,
          title: const Text('My Bids'),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Accepted'),
              Tab(text: 'Rejected'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _BidTab(
              status: BidStatus.pending,
              emptyEmoji: '⏳',
              emptyTitle: 'No bids yet',
              emptySubtitle: 'Browse open tasks and place your first bid',
              emptyAction: Builder(builder: (context) => ElevatedButton.icon(
                onPressed: () => context.push(AppRoutes.taskList),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
                ),
                icon: const Icon(Icons.search, size: 18),
                label: const Text('Browse Open Tasks'),
              )),
            ),
            const _BidTab(status: BidStatus.accepted, emptyEmoji: '🎉', emptyTitle: 'No accepted bids yet'),
            const _BidTab(status: BidStatus.rejected, emptyEmoji: '📭', emptyTitle: 'No rejected bids'),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bid tab — filters all bids by status
// ─────────────────────────────────────────────────────────────────────────────
class _BidTab extends ConsumerWidget {
  final BidStatus status;
  final String emptyEmoji;
  final String emptyTitle;
  final String? emptySubtitle;
  final Widget? emptyAction;

  const _BidTab({
    required this.status,
    required this.emptyEmoji,
    required this.emptyTitle,
    this.emptySubtitle,
    this.emptyAction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bidsAsync = ref.watch(_myBidsProvider);

    return bidsAsync.when(skipLoadingOnReload: true,
      loading: () => const _BidsLoadingList(),
      error: (e, _) => ErrorState(
        message: e.toString(),
        onRetry: () => ref.invalidate(_myBidsProvider),
      ),
      data: (allBids) {
        final bids = allBids.where((b) => b.status == status).toList();
        if (bids.isEmpty) {
          return EmptyState(
            emoji: emptyEmoji,
            title: emptyTitle,
            subtitle: emptySubtitle,
            action: emptyAction,
          );
        }
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(_myBidsProvider);
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: bids.length,
            itemBuilder: (_, i) => _BidCard(bid: bids[i]),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bid card
// ─────────────────────────────────────────────────────────────────────────────
class _BidCard extends ConsumerWidget {
  final BidModel bid;
  const _BidCard({required this.bid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleAsync = ref.watch(_taskTitleProvider(bid.taskId));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: GestureDetector(
        onTap: () => context.push('/tasks/${bid.taskId}'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: AppRadius.card,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Task title + status badge
              Row(
                children: [
                  Expanded(
                    child: titleAsync.when(skipLoadingOnReload: true,
                      data: (title) => Text(
                        title,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      loading: () => const Text(
                        'Loading...',
                        style: TextStyle(fontSize: 15, color: AppColors.textHint),
                      ),
                      error: (_, __) => const Text(
                        'Unknown Task',
                        style: TextStyle(fontSize: 15, color: AppColors.textHint),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _BidStatusBadge(status: bid.status),
                ],
              ),
              const SizedBox(height: 10),
              // Bid amount
              Row(
                children: [
                  const Icon(Icons.attach_money, size: 16, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    'S\$${bid.amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              if (bid.message != null && bid.message!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  bid.message!,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              // Date
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  bid.createdAt != null ? timeago.format(bid.createdAt!) : '',
                  style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bid status badge
// ─────────────────────────────────────────────────────────────────────────────
class _BidStatusBadge extends StatelessWidget {
  final BidStatus status;
  const _BidStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      BidStatus.pending  => ('Pending', const Color(0xFFFF9800)),
      BidStatus.accepted => ('Accepted', const Color(0xFF4CAF50)),
      BidStatus.rejected => ('Rejected', const Color(0xFF9E9E9E)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _BidsLoadingList extends StatelessWidget {
  const _BidsLoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: 4,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Shimmer.fromColors(
          baseColor: AppColors.divider,
          highlightColor: Colors.white,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: AppRadius.card,
            ),
          ),
        ),
      ),
    );
  }
}
