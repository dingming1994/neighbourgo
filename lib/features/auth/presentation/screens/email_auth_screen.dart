import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

class EmailAuthScreen extends StatefulWidget {
  const EmailAuthScreen({super.key});

  @override
  State<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends State<EmailAuthScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey      = GlobalKey<FormState>();
  bool _isLoading     = false;
  String? _error;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isLoading = true; _error = null; });

    try {
      final repo = AuthRepository();
      // Sign out any stale session first
      await repo.signOut();

      // Try creating account first, fall back to sign in
      UserCredential cred;
      try {
        cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
          );
        } else {
          rethrow;
        }
      }

      final uid = cred.user!.uid;

      // Create user doc if it doesn't exist
      final existing = await repo.fetchCurrentUser();
      if (existing == null) {
        await repo.createOrUpdateUser(UserModel(
          uid: uid,
          phone: '',
          displayName: _emailCtrl.text.trim().split('@').first,
          email: _emailCtrl.text.trim(),
          role: UserRole.both,
        ));
      }

      if (mounted) {
        // Check if profile is complete
        final user = await repo.fetchCurrentUser();
        if (user == null || !user.isProfileComplete) {
          context.go(AppRoutes.roleSelect);
        } else {
          context.go(AppRoutes.home);
        }
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException: code=${e.code} message=${e.message}');
      setState(() {
        _error = switch (e.code) {
          'invalid-email'       => 'Invalid email address.',
          'wrong-password'      => 'Wrong password.',
          'weak-password'       => 'Password must be at least 6 characters.',
          'email-already-in-use' => 'Account exists. Check your password.',
          'too-many-requests'   => 'Too many attempts. Try again later.',
          _                     => '[${e.code}] ${e.message}',
        };
      });
    } catch (e, st) {
      debugPrint('Email auth error: $e\n$st');
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Email Login')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text('Sign in or create account',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'Enter your email and password. If you don\'t have an account, one will be created automatically.',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 32),

                // Email field
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    hintText: 'you@example.com',
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.textHint),
                    labelText: 'Email',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter your email';
                    if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password field
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outlined, color: AppColors.textHint),
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textHint,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter your password';
                    if (v.length < 6) return 'At least 6 characters';
                    return null;
                  },
                  onFieldSubmitted: (_) => _submit(),
                ),

                // Error message
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: AppRadius.button,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_error!,
                              style: const TextStyle(
                                  color: AppColors.error, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ],

                const Spacer(),

                AppButton(
                  label: 'Continue',
                  isLoading: _isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
