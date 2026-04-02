import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable error state widget with icon, message, and retry button.
/// Use this in AsyncValue.when() error branches and custom error states.
class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorState({
    super.key,
    this.message = 'Something went wrong. Please try again.',
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 52,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 160,
            child: OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Try Again'),
            ),
          ),
        ],
      ),
    ),
  );
}
