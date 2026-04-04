import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/domain/providers/auth_provider.dart';

class VerificationCentreScreen extends ConsumerWidget {
  const VerificationCentreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.bgCard,
        elevation: 0,
        title: const Text('Verification Centre'),
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
            return const Center(child: Text('Profile unavailable'));
          }
          final userBadges = user.badges;
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Build trust with your neighbours by verifying your identity.',
                  style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4),
                ),
              ),
              const SizedBox(height: 16),
              ...VerificationBadge.values.map(
                (badge) => _BadgeRow(
                  badge: badge,
                  isVerified: userBadges.contains(badge),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BadgeRow extends StatelessWidget {
  final VerificationBadge badge;
  final bool isVerified;

  const _BadgeRow({required this.badge, required this.isVerified});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgCard,
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text(badge.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  badge.label,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isVerified)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.bgMint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Verified',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary),
              ),
            )
          else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.bgLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Not Verified',
                style: TextStyle(fontSize: 12, color: AppColors.textHint),
              ),
            ),
            const SizedBox(width: 8),
            _VerifyButton(badge: badge),
          ],
        ],
      ),
    );
  }
}

class _VerifyButton extends StatelessWidget {
  final VerificationBadge badge;
  const _VerifyButton({required this.badge});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Verification coming soon — we will notify you when available'),
            ),
          );
        },
        child: const Text(
          'Verify',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary),
        ),
      ),
    );
  }
}
