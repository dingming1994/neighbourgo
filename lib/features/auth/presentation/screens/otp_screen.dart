import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/providers/auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const OtpScreen({super.key, required this.verificationId, required this.phoneNumber});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otpCtrl = TextEditingController();
  Timer? _timer;
  int    _seconds = 60;
  bool   _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _seconds   = 60;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_seconds > 0) {
          _seconds--;
        } else {
          _canResend = true;
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() { _timer?.cancel(); _otpCtrl.dispose(); super.dispose(); }

  Future<void> _verify(String code) async {
    if (code.length != 6) return;
    final ok = await ref.read(phoneAuthProvider.notifier).verifyOtp(code);
    if (!mounted) return;
    if (ok) {
      // Check if profile is set up
      final user = ref.read(currentUserProvider).valueOrNull;
      if (user == null || !user.isProfileComplete) {
        context.go(AppRoutes.roleSelect);
      } else {
        context.go(AppRoutes.home);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state  = ref.watch(phoneAuthProvider);
    final theme  = Theme.of(context);
    final pinTheme = PinTheme(
      width: 52, height: 56,
      textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: AppRadius.button,
        border: Border.all(color: AppColors.border),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              const Text('📲', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 20),
              Text('Enter the 6-digit code', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Sent to ${widget.phoneNumber}',
                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 40),

              // ── PIN input ────────────────────────────────────────────────
              Pinput(
                controller:  _otpCtrl,
                length:      6,
                defaultPinTheme: pinTheme,
                focusedPinTheme: pinTheme.copyWith(
                  decoration: pinTheme.decoration?.copyWith(
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                ),
                errorPinTheme: pinTheme.copyWith(
                  decoration: pinTheme.decoration?.copyWith(
                    border: Border.all(color: AppColors.error),
                  ),
                ),
                onCompleted: _verify,
                hapticFeedbackType: HapticFeedbackType.mediumImpact,
              ),

              // ── Error ────────────────────────────────────────────────────
              if (state.error != null) ...[
                const SizedBox(height: 16),
                Text(state.error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
              ],

              const SizedBox(height: 32),

              // ── Resend ────────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Didn't receive the code?  ",
                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                  _canResend
                      ? TextButton(
                          onPressed: () async {
                            await ref.read(phoneAuthProvider.notifier).sendOtp(widget.phoneNumber);
                            _startTimer();
                          },
                          child: const Text('Resend'),
                        )
                      : Text(
                          'Resend in ${_seconds}s',
                          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textHint),
                        ),
                ],
              ),

              const Spacer(),
              AppButton(
                label: 'Verify',
                isLoading: state.isLoading,
                onPressed: () => _verify(_otpCtrl.text),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
