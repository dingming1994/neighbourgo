import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/category_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../data/repositories/profile_repository.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _headlineCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _neighbourhoodCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();

  List<String> _selectedCategories = [];
  List<String> _skillTags = [];
  final Map<String, TextEditingController> _rateControllers = {};
  List<String> _availableDays = [];
  final _availableHoursCtrl = TextEditingController();
  File? _pickedAvatar;
  bool _isLoading = false;
  bool _initialized = false;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _headlineCtrl.dispose();
    _bioCtrl.dispose();
    _neighbourhoodCtrl.dispose();
    _tagCtrl.dispose();
    _availableHoursCtrl.dispose();
    for (final c in _rateControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _initFromUser(UserModel user) {
    if (_initialized) return;
    _initialized = true;
    _nameCtrl.text = user.displayName ?? '';
    _headlineCtrl.text = user.headline ?? '';
    _bioCtrl.text = user.bio ?? '';
    _neighbourhoodCtrl.text = user.neighbourhood ?? '';
    _selectedCategories = List.from(user.serviceCategories);
    _skillTags = List.from(user.skillTags);
    _availableDays = List.from(user.availableDays);
    _availableHoursCtrl.text = user.availableHours ?? '';
    // Init rate controllers for each existing service category
    for (final catId in user.serviceCategories) {
      final rateData = user.serviceRates[catId];
      final hourlyRate = rateData is Map ? (rateData['hourlyRate'] ?? '') : '';
      _rateControllers[catId] = TextEditingController(text: hourlyRate.toString());
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 85, maxWidth: 800);
    if (picked != null) {
      setState(() => _pickedAvatar = File(picked.path));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
      return;
    }
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(profileRepositoryProvider);
      String? avatarUrl = user.avatarUrl;

      if (_pickedAvatar != null) {
        avatarUrl = await repo.uploadAvatar(user.uid, _pickedAvatar!);
      }

      // Build serviceRates map from controllers — store hourlyRate as double
      final Map<String, dynamic> rates = {};
      for (final catId in _selectedCategories) {
        final ctrl = _rateControllers[catId];
        final rateText = ctrl?.text.trim() ?? '';
        if (rateText.isNotEmpty) {
          final parsed = double.tryParse(rateText);
          rates[catId] = {'hourlyRate': parsed ?? rateText};
        }
      }

      final updated = user.copyWith(
        displayName: _nameCtrl.text.trim(),
        headline: _headlineCtrl.text.trim().isEmpty
            ? null
            : _headlineCtrl.text.trim(),
        bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
        neighbourhood: _neighbourhoodCtrl.text.trim().isEmpty
            ? null
            : _neighbourhoodCtrl.text.trim(),
        serviceCategories: _selectedCategories,
        skillTags: _skillTags,
        avatarUrl: avatarUrl,
        serviceRates: rates,
        availableDays: _availableDays,
        availableHours: _availableHoursCtrl.text.trim().isEmpty
            ? null
            : _availableHoursCtrl.text.trim(),
      );
      await repo.updateProfile(updated);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        final message = e.toString().contains('PERMISSION_DENIED')
            ? 'Permission denied. Please sign in again.'
            : e.toString().contains('UNAVAILABLE')
                ? 'Network error. Please check your connection and try again.'
                : 'Failed to save profile. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addTag() {
    final tag = _tagCtrl.text.trim();
    if (tag.isEmpty) return;
    final formatted = tag.startsWith('#') ? tag : '#$tag';
    if (!_skillTags.contains(formatted)) {
      setState(() {
        _skillTags.add(formatted);
        _tagCtrl.clear();
      });
    }
  }

  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await ref.read(currentUserProvider.future);
    if (user != null && mounted) {
      setState(() {
        _user = user;
        _initFromUser(user);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.bgCard,
        elevation: 0,
        title: const Text('Edit Profile',
            style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        fontSize: 16)),
          ),
        ],
      ),
      body: _user == null
          ? const Center(child: CircularProgressIndicator())
          : Form(
            key: _formKey,
            autovalidateMode: _autovalidateMode,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Avatar ────────────────────────────────────────────
                _AvatarPicker(
                  existingUrl: _user!.avatarUrl,
                  pickedFile: _pickedAvatar,
                  onTap: _pickAvatar,
                ),
                const SizedBox(height: 24),

                // ── Basic Info ────────────────────────────────────────
                const _SectionHeader('Basic Info'),
                const SizedBox(height: 12),
                _Field(
                  controller: _nameCtrl,
                  label: 'Display Name',
                  hint: 'Your name',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                _Field(
                  controller: _headlineCtrl,
                  label: 'Headline',
                  hint: 'e.g. Trusted cleaner in Ang Mo Kio',
                  maxLength: 80,
                ),
                const SizedBox(height: 12),
                _Field(
                  controller: _bioCtrl,
                  label: 'About Me',
                  hint: 'Tell clients about yourself…',
                  maxLines: 4,
                  maxLength: 500,
                ),
                const SizedBox(height: 12),
                _Field(
                  controller: _neighbourhoodCtrl,
                  label: 'Neighbourhood',
                  hint: 'e.g. Ang Mo Kio, Tampines',
                ),
                const SizedBox(height: 24),

                // ── Service Categories ────────────────────────────────
                const _SectionHeader('Service Categories'),
                const SizedBox(height: 4),
                const Text(
                  'Select what services you offer',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppCategories.all.map((cat) {
                    final selected =
                        _selectedCategories.contains(cat.id);
                    return FilterChip(
                      label: Text('${cat.emoji} ${cat.label}'),
                      selected: selected,
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _selectedCategories.add(cat.id);
                          } else {
                            _selectedCategories.remove(cat.id);
                            // Dispose and remove stale controller to prevent memory leak
                            _rateControllers.remove(cat.id)?.dispose();
                          }
                        });
                      },
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      checkmarkColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: selected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        fontSize: 13,
                      ),
                      backgroundColor: AppColors.bgCard,
                      side: BorderSide(
                        color: selected
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // ── Skill Tags ────────────────────────────────────────
                const _SectionHeader('Skill Tags'),
                const SizedBox(height: 4),
                const Text(
                  'Add tags like #DogWalking, #Mandarin',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _tagCtrl,
                        decoration: InputDecoration(
                          hintText: 'Add a skill tag',
                          filled: true,
                          fillColor: AppColors.bgCard,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.border),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                        onSubmitted: (_) => _addTag(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _addTag,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Add'),
                      ),
                    ),
                  ],
                ),
                if (_skillTags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _skillTags
                        .map((tag) => Chip(
                              label: Text(tag,
                                  style: const TextStyle(fontSize: 13)),
                              backgroundColor:
                                  AppColors.accent.withValues(alpha: 0.12),
                              side: BorderSide(
                                  color:
                                      AppColors.accent.withValues(alpha: 0.3)),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () =>
                                  setState(() => _skillTags.remove(tag)),
                            ))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 24),

                // ── Rates ────────────────────────────────────────────
                if (_selectedCategories.isNotEmpty) ...[
                  const _SectionHeader('Rates'),
                  const SizedBox(height: 4),
                  const Text(
                    'Set your hourly rate per service category (S\$)',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  ..._selectedCategories.map((catId) {
                    final cat = AppCategories.getById(catId);
                    if (!_rateControllers.containsKey(catId)) {
                      _rateControllers[catId] = TextEditingController();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Text(cat?.emoji ?? '',
                              style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: Text(cat?.label ?? catId,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _rateControllers[catId],
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                              ],
                              decoration: InputDecoration(
                                prefixText: 'S\$ ',
                                hintText: '0',
                                suffixText: '/hr',
                                helperText: 'S\$1–S\$500',
                                helperStyle: const TextStyle(fontSize: 11),
                                filled: true,
                                fillColor: AppColors.bgCard,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: AppColors.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: AppColors.border),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 10),
                                isDense: true,
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return null; // optional
                                final n = double.tryParse(v.trim());
                                if (n == null) return 'Enter a number';
                                if (n < 1) return 'Min S\$1';
                                if (n > 500) return 'Max S\$500';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                ],

                // ── Availability ─────────────────────────────────────
                const _SectionHeader('Availability'),
                const SizedBox(height: 4),
                const Text(
                  'Select which days you are available',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                      .map((day) {
                    final selected = _availableDays.contains(day);
                    return FilterChip(
                      label: Text(day),
                      selected: selected,
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _availableDays.add(day);
                          } else {
                            _availableDays.remove(day);
                          }
                        });
                      },
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      checkmarkColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: selected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        fontSize: 13,
                      ),
                      backgroundColor: AppColors.bgCard,
                      side: BorderSide(
                        color: selected
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                _Field(
                  controller: _availableHoursCtrl,
                  label: 'Available Hours',
                  hint: 'e.g. 9am - 6pm',
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────
class _AvatarPicker extends StatelessWidget {
  final String? existingUrl;
  final File? pickedFile;
  final VoidCallback onTap;

  const _AvatarPicker(
      {required this.existingUrl,
      required this.pickedFile,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    Widget avatar;
    if (pickedFile != null) {
      avatar = CircleAvatar(
          radius: 50, backgroundImage: FileImage(pickedFile!));
    } else if (existingUrl != null && existingUrl!.isNotEmpty) {
      avatar = CircleAvatar(
        radius: 50,
        backgroundImage: CachedNetworkImageProvider(existingUrl!),
      );
    } else {
      avatar = CircleAvatar(
        radius: 50,
        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
        child: const Icon(Icons.person, size: 48, color: AppColors.primary),
      );
    }

    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          children: [
            avatar,
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.camera_alt,
                    color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary),
      );
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final int maxLines;
  final int? maxLength;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    this.hint,
    this.maxLines = 1,
    this.maxLength,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: AppColors.bgCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
    );
  }
}
