import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/providers/auth_provider.dart';

class PhoneAuthScreen extends ConsumerStatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  ConsumerState<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends ConsumerState<PhoneAuthScreen> {
  final _phoneCtrl = TextEditingController();
  final _formKey   = GlobalKey<FormState>();
  String _countryCode = '+65';

  @override
  void dispose() { _phoneCtrl.dispose(); super.dispose(); }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    final phone = '$_countryCode${_phoneCtrl.text.trim()}';
    await ref.read(phoneAuthProvider.notifier).sendOtp(phone);

    final state = ref.read(phoneAuthProvider);
    if (state.otpSent && mounted) {
      context.push(
        '${AppRoutes.otpVerify}?vid=${state.verificationId}&phone=${Uri.encodeComponent(phone)}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(phoneAuthProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Enter Phone Number')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text('Your phone number', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'We\'ll send a 6-digit OTP to verify your number.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 32),

                // ── Phone input row ──────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Country code picker
                    GestureDetector(
                      onTap: () {
                        // TODO: show country picker sheet
                      },
                      child: Container(
                        height: 52,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppColors.bgCard,
                          borderRadius: AppRadius.button,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Text('🇸🇬', style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 6),
                            Text(_countryCode, style: const TextStyle(fontWeight: FontWeight.w600)),
                            const Icon(Icons.expand_more, size: 18, color: AppColors.textHint),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Phone number field
                    Expanded(
                      child: TextFormField(
                        controller:  _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        style:       const TextStyle(fontSize: 18, letterSpacing: 1.5),
                        decoration:  const InputDecoration(
                          hintText: '9123 4567',
                          prefixIcon: Icon(Icons.phone_outlined, color: AppColors.textHint),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Enter your phone number';
                          if (v.trim().length < 8) return 'Enter a valid SG number';
                          return null;
                        },
                        onFieldSubmitted: (_) => _sendOtp(),
                      ),
                    ),
                  ],
                ),

                // ── Error message ─────────────────────────────────────────────
                if (state.error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: AppRadius.button,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(state.error!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
                      ],
                    ),
                  ),
                ],

                const Spacer(),

                AppButton(
                  label: 'Send OTP',
                  isLoading: state.isLoading,
                  onPressed: _sendOtp,
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Standard SMS rates may apply.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textHint),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
