import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/models/user_model.dart';

/// Compact stats card shown on the ProviderHomeScreen.
/// Displays completedTasks, avgRating, totalReviews, and a hidden earnings figure.
class ProviderStatsWidget extends StatefulWidget {
  final ProviderStats? stats;

  const ProviderStatsWidget({super.key, required this.stats});

  @override
  State<ProviderStatsWidget> createState() => _ProviderStatsWidgetState();
}

class _ProviderStatsWidgetState extends State<ProviderStatsWidget> {
  bool _earningsVisible = false;

  @override
  Widget build(BuildContext context) {
    final stats = widget.stats;

    final completedTasks = stats?.completedTasks ?? 0;
    final avgRating      = stats?.avgRating      ?? 0.0;
    final totalReviews   = stats?.totalReviews   ?? 0;
    final earnings       = stats?.earningsTotal  ?? 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Completed tasks
          _StatCell(
            label: 'Completed',
            value: stats == null ? '--' : '$completedTasks',
            icon: Icons.check_circle_outline,
            iconColor: AppColors.primary,
          ),
          _Divider(),
          // Avg rating
          _StatCell(
            label: 'Rating',
            value: stats == null ? '--' : avgRating.toStringAsFixed(1),
            icon: Icons.star_outline,
            iconColor: AppColors.accent,
            suffix: stats != null && totalReviews > 0
                ? ' ($totalReviews)'
                : null,
          ),
          _Divider(),
          // Earnings (togglable)
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _earningsVisible = !_earningsVisible),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StatCell(
                    label: 'Earnings',
                    value: stats == null
                        ? '--'
                        : _earningsVisible
                            ? 'S\$${earnings.toStringAsFixed(2)}'
                            : '••••••',
                    icon: _earningsVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    iconColor: AppColors.textSecondary,
                    compact: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal helpers
// ─────────────────────────────────────────────────────────────────────────────

class _StatCell extends StatelessWidget {
  final String   label;
  final String   value;
  final IconData icon;
  final Color    iconColor;
  final String?  suffix;
  final bool     compact;

  const _StatCell({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.suffix,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              children: [
                TextSpan(text: value),
                if (suffix != null)
                  TextSpan(
                    text: suffix,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 40,
    color: AppColors.divider,
    margin: const EdgeInsets.symmetric(horizontal: 4),
  );
}
