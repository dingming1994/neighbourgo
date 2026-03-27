import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Future<void> _devLogin(BuildContext context) async {
    try {
      // Use anonymous auth — works without any email/password setup
      final userCred = await FirebaseAuth.instance.signInAnonymously();
      final uid = userCred.user!.uid;
      final repo = AuthRepository();
      await repo.createOrUpdateUser(
        UserModel(
          uid: uid,
          phone: '+6500000000',
          displayName: 'Dev User',
          role: UserRole.both,
        ),
      );
      if (context.mounted) context.go(AppRoutes.home);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dev login failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Column(
        children: [
          // ── Hero banner ────────────────────────────────────────────────────
          Container(
            height: size.height * 0.52,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, Color(0xFF0D5C47)],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🏘️', style: TextStyle(fontSize: 64)),
                    const SizedBox(height: 20),
                    const Text(
                      'NeighbourGo',
                      style: TextStyle(
                        color: Colors.white, fontSize: 36,
                        fontWeight: FontWeight.w700, letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Singapore\'s community service platform. Get help or earn money in your neighbourhood.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85), fontSize: 16, height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Category pills
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: ['🧹 Cleaning', '📚 Tuition', '🐾 Pet Care',
                                 '🔧 Handyman', '🧍 Queuing', '🍱 Errands']
                          .map((t) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: AppRadius.chip,
                            ),
                            child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 13)),
                          )).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── CTA panel ──────────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                children: [
                  Text(
                    'Join 10,000+ neighbours across Singapore',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  AppButton(
                    label: 'Get Started with Phone',
                    leading: const Text('📱', style: TextStyle(fontSize: 18)),
                    onPressed: const bool.fromEnvironment('dart.vm.product') == false
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('📱 Phone auth not supported on simulator. Use "Dev Login" below.'),
                                duration: Duration(seconds: 3),
                              ),
                            );
                          }
                        : () => context.push(AppRoutes.phoneAuth),
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'Login with SingPass',
                    leading: const Text('🇸🇬', style: TextStyle(fontSize: 18)),
                    isOutlined: true,
                    onPressed: () {
                      // TODO: Integrate SingPass MyInfo OAuth
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('SingPass integration coming soon!')),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  // ── Dev bypass (simulator only) ──────────────────────────
                  if (const bool.fromEnvironment('dart.vm.product') == false)
                    TextButton.icon(
                      icon: const Icon(Icons.developer_mode, size: 16),
                      label: const Text('Dev Login (Simulator)', style: TextStyle(fontSize: 13)),
                      style: TextButton.styleFrom(foregroundColor: Colors.grey),
                      onPressed: () => _devLogin(context),
                    ),
                  const Spacer(),
                  Text(
                    'By continuing, you agree to our Terms of Service and Privacy Policy.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textHint),
                    textAlign: TextAlign.center,
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
