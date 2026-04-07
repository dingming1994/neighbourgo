import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../tasks/data/repositories/task_repository.dart';
import '../tasks/data/models/task_model.dart';
import 'payment_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CheckoutScreen
// ─────────────────────────────────────────────────────────────────────────────
class CheckoutScreen extends ConsumerStatefulWidget {
  final String taskId;
  final String bidId;
  final String providerName;
  final double bidAmount;

  const CheckoutScreen({
    super.key,
    required this.taskId,
    required this.bidId,
    required this.providerName,
    required this.bidAmount,
  });

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _isLoading = false;

  double get _platformFee =>
      double.parse((widget.bidAmount * AppConstants.platformFeePercent / 100)
          .toStringAsFixed(2));

  double get _total => double.parse(
      (widget.bidAmount + _platformFee).toStringAsFixed(2));

  Future<void> _pay() async {
    setState(() => _isLoading = true);
    try {
      final paymentService = ref.read(paymentServiceProvider);

      // 1. Create escrow PaymentIntent via Cloud Function
      final clientSecret = await paymentService.createEscrowPayment(
        taskId: widget.taskId,
        bidId:  widget.bidId,
        amount: _total,
      );

      // 2. Present Stripe payment sheet
      final success = await paymentService.presentPaymentSheet(
        clientSecret:        clientSecret,
        merchantDisplayName: AppConstants.appName,
      );

      if (!success) {
        // User cancelled — stay on screen
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // 3. Mark task as in_progress now that payment is authorised
      await ref
          .read(taskRepositoryProvider)
          .updateStatus(widget.taskId, TaskStatus.inProgress);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment authorised! Task is now in progress.'),
            backgroundColor: AppColors.success,
          ),
        );
        // Pop checkout screen back to task detail
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment could not be processed. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Summary card ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color:        AppColors.bgCard,
                borderRadius: AppRadius.card,
                border:       Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Summary',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 20),

                  _SummaryRow(
                    label: 'Provider',
                    value: widget.providerName,
                  ),
                  const SizedBox(height: 12),
                  _SummaryRow(
                    label: 'Bid amount',
                    value:
                        '${AppConstants.currencySymbol}${widget.bidAmount.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 12),
                  _SummaryRow(
                    label:
                        'Platform fee (${AppConstants.platformFeePercent.toStringAsFixed(0)}%)',
                    value:
                        '${AppConstants.currencySymbol}${_platformFee.toStringAsFixed(2)}',
                    labelColor: AppColors.textSecondary,
                    valueColor: AppColors.textSecondary,
                  ),
                  const Divider(height: 28),
                  _SummaryRow(
                    label: 'Total',
                    value:
                        '${AppConstants.currencySymbol}${_total.toStringAsFixed(2)}',
                    isBold: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Escrow note ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:        AppColors.bgMint,
                borderRadius: AppRadius.card,
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_outlined,
                      color: AppColors.primary, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Payment is held in escrow and only released to the provider once you mark the task as complete.',
                      style: TextStyle(
                          color: AppColors.primary, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // ── Pay button ─────────────────────────────────────────────────
            AppButton(
              label:     'Pay ${AppConstants.currencySymbol}${_total.toStringAsFixed(2)}',
              isLoading: _isLoading,
              onPressed: _pay,
            ),

            const SizedBox(height: 8),
            Center(
              child: Text(
                'Secured by Stripe',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textHint,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SummaryRow
// ─────────────────────────────────────────────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  final String  label;
  final String  value;
  final bool    isBold;
  final Color?  labelColor;
  final Color?  valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold    = false,
    this.labelColor,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final style = isBold
        ? Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w700)
        : Theme.of(context).textTheme.bodyMedium;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                style?.copyWith(color: labelColor)),
        Text(value,
            style: style?.copyWith(
                color: valueColor ?? AppColors.textPrimary)),
      ],
    );
  }
}
