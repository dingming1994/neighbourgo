import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../data/repositories/bid_repository.dart';
import '../../domain/models/bid_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Duration options
// ─────────────────────────────────────────────────────────────────────────────
enum _BidDuration {
  oneHour('1 hour', 60),
  twoHours('2 hours', 120),
  halfDay('Half day', 240),
  fullDay('Full day', 480),
  custom('Custom', 0);

  const _BidDuration(this.label, this.minutes);
  final String label;
  final int    minutes;
}

class SubmitBidSheet extends ConsumerStatefulWidget {
  final String       taskId;
  final VoidCallback? onSuccess;

  const SubmitBidSheet({super.key, required this.taskId, this.onSuccess});

  @override
  ConsumerState<SubmitBidSheet> createState() => _SubmitBidSheetState();
}

class _SubmitBidSheetState extends ConsumerState<SubmitBidSheet> {
  final _formKey       = GlobalKey<FormState>();
  final _amountCtrl    = TextEditingController();
  final _messageCtrl   = TextEditingController();
  final _customMinsCtrl = TextEditingController();

  _BidDuration _selectedDuration = _BidDuration.oneHour;
  bool         _isSubmitting     = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _messageCtrl.dispose();
    _customMinsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: not logged in'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final amount = double.parse(_amountCtrl.text.trim());
      final bid = BidModel(
        bidId:          '',
        taskId:         widget.taskId,
        providerId:     user.uid,
        providerName:   user.displayName ?? 'Anonymous',
        providerAvatar: user.avatarUrl,
        amount:         amount,
        message:        _messageCtrl.text.trim(),
        status:         BidStatus.pending,
      );
      await ref.read(bidRepositoryProvider).submitBid(widget.taskId, bid);
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSuccess?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bid submitted!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submit failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left:   24,
        right:  24,
        top:    24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Text('Submit Bid',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 20),

            // ── Amount ────────────────────────────────────────────────────
            Text('Bid Amount (SGD)',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                prefixText: 'S\$ ',
                hintText:   '0.00',
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter a bid amount';
                final n = double.tryParse(v);
                if (n == null || n <= 0) return 'Enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // ── Estimated Duration ────────────────────────────────────────
            Text('Estimated Duration',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _BidDuration.values.map((d) {
                final isSelected = _selectedDuration == d;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDuration = d),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.bgCard,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.divider,
                      ),
                    ),
                    child: Text(
                      d.label,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppColors.textPrimary,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            // Custom duration input
            if (_selectedDuration == _BidDuration.custom) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _customMinsCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  hintText:   'e.g. 90',
                  suffixText: 'minutes',
                ),
                validator: (v) {
                  if (_selectedDuration != _BidDuration.custom) return null;
                  if (v == null || v.isEmpty) return 'Enter duration in minutes';
                  final n = int.tryParse(v);
                  if (n == null || n <= 0) return 'Enter a valid duration';
                  return null;
                },
              ),
            ],
            const SizedBox(height: 20),

            // ── Message / Proposal ────────────────────────────────────────
            Text('Your Proposal',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            const Text(
              'Describe your experience and approach (min. 20 characters)',
              style: TextStyle(fontSize: 12, color: AppColors.textHint),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _messageCtrl,
              maxLines:   4,
              maxLength:  200,
              decoration: const InputDecoration(
                hintText: 'Introduce yourself and explain why you\'re a great fit…',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'A proposal is required';
                }
                if (v.trim().length < 20) {
                  return 'Proposal must be at least 20 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),

            SafeArea(
              child: AppButton(
                label:     'Submit Bid',
                isLoading: _isSubmitting,
                onPressed: () {
                  debugPrint('=== SUBMIT BID TAPPED ===');
                  _submit();
                },
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
