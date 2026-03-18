import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/category_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../data/models/user_model.dart';
import '../../../../features/profile/data/repositories/profile_repository.dart';
import '../../domain/providers/auth_provider.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _nameCtrl       = TextEditingController();
  final _headlineCtrl   = TextEditingController();
  final _bioCtrl        = TextEditingController();
  final _formKey        = GlobalKey<FormState>();
  File?  _avatarFile;
  String? _neighbourhood;
  bool   _loading       = false;
  int    _step          = 0; // 0=basic, 1=neighbourhood, 2=done

  static const _hoods = [
    'Ang Mo Kio', 'Bedok', 'Bishan', 'Bukit Merah', 'Bukit Timah',
    'Clementi', 'Geylang', 'Jurong East', 'Jurong West', 'Kallang',
    'Marine Parade', 'Pasir Ris', 'Punggol', 'Queenstown', 'Sembawang',
    'Sengkang', 'Serangoon', 'Tampines', 'Toa Payoh', 'Woodlands', 'Yishun',
    'Orchard / City', 'Novena', 'Hougang', 'Choa Chu Kang',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose(); _headlineCtrl.dispose(); _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final img = await ImagePicker().pickImage(
      source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 85,
    );
    if (img != null) setState(() => _avatarFile = File(img.path));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final profileRepo = ref.read(profileRepositoryProvider);
      final currentUser = ref.read(currentUserProvider).valueOrNull;
      if (currentUser == null) return;

      String? avatarUrl;
      if (_avatarFile != null) {
        avatarUrl = await profileRepo.uploadAvatar(currentUser.uid, _avatarFile!);
      }

      final updated = currentUser.copyWith(
        displayName:      _nameCtrl.text.trim(),
        headline:         _headlineCtrl.text.trim(),
        bio:              _bioCtrl.text.trim(),
        neighbourhood:    _neighbourhood,
        avatarUrl:        avatarUrl ?? currentUser.avatarUrl,
        isProfileComplete: true,
      );
      await profileRepo.updateProfile(updated);
      if (mounted) context.go(AppRoutes.home);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Up Profile'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_step + 1) / 2,
            backgroundColor: AppColors.divider,
            color: AppColors.primary,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Avatar picker ──────────────────────────────────────────
                Center(
                  child: GestureDetector(
                    onTap: _pickAvatar,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 52,
                          backgroundColor: AppColors.bgMint,
                          backgroundImage: _avatarFile != null ? FileImage(_avatarFile!) : null,
                          child: _avatarFile == null
                              ? const Text('👤', style: TextStyle(fontSize: 40))
                              : null,
                        ),
                        Positioned(
                          bottom: 0, right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // ── Name ────────────────────────────────────────────────────
                const Text('Display Name', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Wei Ming', prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
                ),
                const SizedBox(height: 20),

                // ── Headline ────────────────────────────────────────────────
                const Text('Headline', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('80 chars. e.g. "Dog lover & experienced walker in Bishan"',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textHint)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _headlineCtrl,
                  maxLength: 80,
                  decoration: const InputDecoration(hintText: 'A brief intro about yourself'),
                ),
                const SizedBox(height: 20),

                // ── Bio ──────────────────────────────────────────────────────
                const Text('About Me', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _bioCtrl,
                  maxLines: 4, maxLength: 500,
                  decoration: const InputDecoration(
                    hintText: 'Tell neighbours about yourself, your experience, working hours, languages…',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),

                // ── Neighbourhood ────────────────────────────────────────────
                const Text('Your Neighbourhood', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _neighbourhood,
                  decoration: const InputDecoration(
                    hintText: 'Select your area',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  items: _hoods.map((h) => DropdownMenuItem(value: h, child: Text(h))).toList(),
                  onChanged: (v) => setState(() => _neighbourhood = v),
                  validator: (v) => v == null ? 'Please select your neighbourhood' : null,
                ),

                const SizedBox(height: 36),
                AppButton(
                  label: 'Complete Setup',
                  isLoading: _loading,
                  onPressed: _save,
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () => context.go(AppRoutes.home),
                    child: const Text('Skip for now'),
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
