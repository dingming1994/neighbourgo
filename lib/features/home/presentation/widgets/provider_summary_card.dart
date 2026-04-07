import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../../bids/data/repositories/bid_repository.dart';

class ProviderSummaryCard extends ConsumerWidget {
  const ProviderSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final stats = user?.stats;

    final completedTasks = stats?.completedTasks ?? 0;
    final avgRating = stats?.avgRating ?? 0.0;
    final totalReviews = stats?.totalReviews ?? 0;
    final earnings = stats?.earningsTotal ?? 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Stats row ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
              child: Row(
                children: [
                  _StatTile(
                    value: completedTasks.toString(),
                    label: 'Jobs Done',
                    color: AppColors.success,
                    icon: Icons.check_circle_outline,
                  ),
                  const SizedBox(width: 8),
                  _StatTile(
                    value: avgRating > 0
                        ? avgRating.toStringAsFixed(1)
                        : '—',
                    label: '$totalReviews reviews',
                    color: AppColors.accent,
                    icon: Icons.star_rounded,
                  ),
                  const SizedBox(width: 8),
                  _StatTile(
                    value: earnings > 0
                        ? 'S\$${earnings.toStringAsFixed(0)}'
                        : '—',
                    label: 'Earned',
                    color: AppColors.primary,
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                ],
              ),
            ),

            // ── Rating bar ──────────────────────────────────────────
            if (avgRating > 0) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Row(
                  children: [
                    ...List.generate(5, (i) {
                      if (i < avgRating.floor()) {
                        return const Icon(Icons.star_rounded,
                            size: 18, color: AppColors.accent);
                      } else if (i < avgRating) {
                        return const Icon(Icons.star_half_rounded,
                            size: 18, color: AppColors.accent);
                      } else {
                        return Icon(Icons.star_outline_rounded,
                            size: 18,
                            color: AppColors.accent.withOpacity(0.3));
                      }
                    }),
                    const SizedBox(width: 8),
                    Text(
                      '${avgRating.toStringAsFixed(1)} ($totalReviews)',
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],

            // ── New provider nudge ──────────────────────────────────
            if (completedTasks == 0) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Row(
                  children: [
                    Icon(Icons.rocket_launch_rounded,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Complete your first job to start building your reputation!',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;

  const _StatTile({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
