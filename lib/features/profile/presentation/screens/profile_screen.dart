import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../data/repositories/profile_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────
extension _RoleLabel on UserRole {
  String get displayLabel {
    switch (this) {
      case UserRole.poster:   return 'Task Poster';
      case UserRole.provider: return 'Service Provider';
      case UserRole.both:     return 'Both';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final user      = userAsync.valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.bgCard,
        elevation: 0,
        title: const Text('Profile'),
        actions: [
          TextButton(
            onPressed: () => context.push(AppRoutes.editProfile),
            child: const Text('Edit', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (_) {
          if (user == null) {
            // currentUserProvider always synthesises a fallback, so this
            // path should be unreachable.  Show a safe placeholder anyway.
            return const Center(child: Text('Profile unavailable'));
          }
          return ListView(
            children: [
              // ── Avatar + name ──────────────────────────────────────────────
              _ProfileHeader(user: user),
              const Divider(height: 1),

              // ── Provider stats ─────────────────────────────────────────────
              if (user.stats != null &&
                  (user.role == UserRole.provider || user.role == UserRole.both))
                _ProviderStatsSection(stats: user.stats!),

              // ── My Role ───────────────────────────────────────────────────
              _RoleSection(user: user),
              const Divider(height: 1),

              // ── Quick links ────────────────────────────────────────────────
              _MenuItem(
                icon: Icons.person_outline,
                label: 'Edit Profile',
                onTap: () => context.push(AppRoutes.editProfile),
              ),
              _MenuItem(
                icon: Icons.verified_outlined,
                label: 'Verification Centre',
                onTap: () => context.push(AppRoutes.verificationCentre),
              ),
              _MenuItem(
                icon: Icons.photo_library_outlined,
                label: 'Photo Gallery',
                onTap: () => context.push(AppRoutes.photoGallery),
              ),
              const Divider(height: 1),
              _MenuItem(
                icon: Icons.logout,
                label: 'Sign Out',
                textColor: AppColors.error,
                iconColor: AppColors.error,
                onTap: () => ref.read(signOutProvider)(),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider Stats
// ─────────────────────────────────────────────────────────────────────────────
class _ProviderStatsSection extends StatelessWidget {
  final ProviderStats stats;
  const _ProviderStatsSection({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgCard,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatColumn(value: stats.completedTasks.toString(), label: 'Tasks Done'),
          _StatColumn(value: stats.avgRating.toStringAsFixed(1), label: 'Avg Rating'),
          _StatColumn(value: stats.totalReviews.toString(), label: 'Reviews'),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String value;
  final String label;
  const _StatColumn({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  final UserModel user;
  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgCard,
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.bgMint,
            backgroundImage: user.avatarUrl != null
                ? NetworkImage(user.avatarUrl!)
                : null,
            child: user.avatarUrl == null
                ? Text(
                    (user.displayName ?? 'N').substring(0, 1).toUpperCase(),
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.primary),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName ?? 'Neighbour',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                if (user.headline != null && user.headline!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(user.headline!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ],
                const SizedBox(height: 4),
                Text(user.phone, style: const TextStyle(fontSize: 13, color: AppColors.textHint)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// My Role section
// ─────────────────────────────────────────────────────────────────────────────
class _RoleSection extends ConsumerWidget {
  final UserModel user;
  const _RoleSection({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: AppColors.bgCard,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const Icon(Icons.badge_outlined, color: AppColors.textSecondary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('My Role', style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                const SizedBox(height: 2),
                Text(
                  user.role.displayLabel,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _showRoleBottomSheet(context, ref, user),
            child: const Text('Change Role', style: TextStyle(color: AppColors.primary, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  void _showRoleBottomSheet(BuildContext context, WidgetRef ref, UserModel user) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RolePickerSheet(currentUser: user),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Role picker bottom sheet
// ─────────────────────────────────────────────────────────────────────────────
class _RolePickerSheet extends ConsumerStatefulWidget {
  final UserModel currentUser;
  const _RolePickerSheet({required this.currentUser});

  @override
  ConsumerState<_RolePickerSheet> createState() => _RolePickerSheetState();
}

class _RolePickerSheetState extends ConsumerState<_RolePickerSheet> {
  late UserRole _selected;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentUser.role;
  }

  Future<void> _save() async {
    if (_selected == widget.currentUser.role) {
      Navigator.pop(context);
      return;
    }
    setState(() => _loading = true);
    try {
      final repo = ref.read(profileRepositoryProvider);
      await repo.updateProfile(widget.currentUser.copyWith(role: _selected));
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Role updated!')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
          ),
          Text('Change Role', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('You can always switch back later.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 24),

          _RoleCard(
            emoji: '📋',
            title: 'Task Poster',
            subtitle: 'Post tasks and hire trusted neighbours.',
            selected: _selected == UserRole.poster,
            onTap: () => setState(() => _selected = UserRole.poster),
          ),
          const SizedBox(height: 12),
          _RoleCard(
            emoji: '💪',
            title: 'Service Provider',
            subtitle: 'Accept tasks and earn flexible income.',
            selected: _selected == UserRole.provider,
            onTap: () => setState(() => _selected = UserRole.provider),
          ),
          const SizedBox(height: 12),
          _RoleCard(
            emoji: '🔄',
            title: 'Both — post & earn',
            subtitle: 'Get help when you need it, earn when you have time.',
            selected: _selected == UserRole.both,
            onTap: () => setState(() => _selected = UserRole.both),
          ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Role card (same style as RoleSelectionScreen)
// ─────────────────────────────────────────────────────────────────────────────
class _RoleCard extends StatelessWidget {
  final String emoji, title, subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(16),
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
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
              ],
            ),
          ),
          if (selected)
            const Icon(Icons.check_circle, color: AppColors.primary, size: 22),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Menu item row
// ─────────────────────────────────────────────────────────────────────────────
class _MenuItem extends StatelessWidget {
  final IconData   icon;
  final String     label;
  final VoidCallback onTap;
  final Color?     textColor;
  final Color?     iconColor;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    tileColor: AppColors.bgCard,
    leading: Icon(icon, color: iconColor ?? AppColors.textSecondary, size: 22),
    title: Text(label, style: TextStyle(fontSize: 15, color: textColor ?? AppColors.textPrimary)),
    trailing: textColor == null
        ? const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20)
        : null,
    onTap: onTap,
  );
}
