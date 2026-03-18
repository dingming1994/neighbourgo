import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../data/models/user_model.dart';
import '../../domain/providers/auth_provider.dart';
import '../../../../features/auth/data/repositories/auth_repository.dart';

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  UserRole? _selected;
  bool _loading = false;

  Future<void> _confirm() async {
    if (_selected == null) return;
    setState(() => _loading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.fetchCurrentUser();
      if (user != null) {
        await repo.createOrUpdateUser(user.copyWith(role: _selected!));
      }
      if (mounted) context.go(AppRoutes.profileSetup);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('How will you use NeighbourGo?')),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Text('Choose your role', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text('You can always do both later.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 32),

            _RoleCard(
              emoji: '📋',
              title: 'I need help',
              subtitle: 'Post tasks and hire trusted neighbours for cleaning, tutoring, errands & more.',
              selected: _selected == UserRole.poster,
              onTap: () => setState(() => _selected = UserRole.poster),
            ),
            const SizedBox(height: 16),
            _RoleCard(
              emoji: '💪',
              title: 'I want to earn',
              subtitle: 'Accept tasks in your neighbourhood and earn flexible income on your schedule.',
              selected: _selected == UserRole.provider,
              onTap: () => setState(() => _selected = UserRole.provider),
            ),
            const SizedBox(height: 16),
            _RoleCard(
              emoji: '🔄',
              title: 'Both — post & earn',
              subtitle: 'Get help when you need it, and earn when you have time.',
              selected: _selected == UserRole.both,
              onTap: () => setState(() => _selected = UserRole.both),
            ),

            const Spacer(),
            AppButton(
              label: 'Continue',
              isLoading: _loading,
              onPressed: _selected != null ? _confirm : null,
            ),
          ],
        ),
      ),
    ),
  );
}

class _RoleCard extends StatelessWidget {
  final String emoji, title, subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.emoji, required this.title, required this.subtitle,
    required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: selected ? AppColors.bgMint : AppColors.bgCard,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
              ],
            ),
          ),
          if (selected)
            const Icon(Icons.check_circle, color: AppColors.primary, size: 24),
        ],
      ),
    ),
  );
}
