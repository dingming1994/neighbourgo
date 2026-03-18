import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../data/repositories/bid_repository.dart';
import '../../domain/models/bid_model.dart';

class SubmitBidSheet extends ConsumerStatefulWidget {
  final String       taskId;
  final VoidCallback? onSuccess;

  const SubmitBidSheet({super.key, required this.taskId, this.onSuccess});

  @override
  ConsumerState<SubmitBidSheet> createState() => _SubmitBidSheetState();
}

class _SubmitBidSheetState extends ConsumerState<SubmitBidSheet> {
  final _formKey     = GlobalKey<FormState>();
  final _amountCtrl  = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool  _isSubmitting = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    setState(() => _isSubmitting = true);
    try {
      final amount = double.parse(_amountCtrl.text.trim());
      final bid = BidModel(
        bidId:         '',
        taskId:        widget.taskId,
        providerId:    user.uid,
        providerName:  user.displayName ?? 'Anonymous',
        providerAvatar: user.avatarUrl,
        amount:        amount,
        message:       _messageCtrl.text.trim().isEmpty
                           ? null
                           : _messageCtrl.text.trim(),
        status:        BidStatus.pending,
      );
      await ref.read(bidRepositoryProvider).submitBid(widget.taskId, bid);
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSuccess?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('报价已提交！'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('提交失败：$e'),
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

            Text('提交报价', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 20),

            // Amount
            Text('报价金额 (SGD)',
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
                if (v == null || v.isEmpty) return '请输入报价金额';
                final n = double.tryParse(v);
                if (n == null || n <= 0) return '请输入有效金额';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Message
            Text('留言（可选）',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            TextFormField(
              controller: _messageCtrl,
              maxLines:   3,
              maxLength:  200,
              decoration: const InputDecoration(
                hintText: '简单介绍一下你的服务，提高接单率…',
              ),
            ),
            const SizedBox(height: 8),

            AppButton(
              label:     '提交报价',
              isLoading: _isSubmitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
