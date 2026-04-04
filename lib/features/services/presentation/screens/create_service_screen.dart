import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/category_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../data/models/service_listing_model.dart';
import '../../data/repositories/service_listing_repository.dart';

class CreateServiceScreen extends ConsumerStatefulWidget {
  /// Pass an existing listing to enter **edit** mode.
  final ServiceListingModel? existingListing;

  const CreateServiceScreen({super.key, this.existingListing});

  @override
  ConsumerState<CreateServiceScreen> createState() =>
      _CreateServiceScreenState();
}

class _CreateServiceScreenState extends ConsumerState<CreateServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _categoryId;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _fixedRateController = TextEditingController();
  final _availabilityController = TextEditingController();
  final List<File> _photos = [];

  /// URLs of existing photos kept from the original listing (edit mode only).
  final List<String> _existingPhotoUrls = [];
  bool _isSubmitting = false;

  bool get _isEditing => widget.existingListing != null;

  @override
  void initState() {
    super.initState();
    final listing = widget.existingListing;
    if (listing != null) {
      _categoryId = listing.categoryId;
      _titleController.text = listing.title;
      _descriptionController.text = listing.description;
      if (listing.hourlyRate != null) {
        _hourlyRateController.text = listing.hourlyRate!.toStringAsFixed(0);
      }
      if (listing.fixedRate != null) {
        _fixedRateController.text = listing.fixedRate!.toStringAsFixed(0);
      }
      if (listing.availability != null) {
        _availabilityController.text = listing.availability!;
      }
      _existingPhotoUrls.addAll(listing.photoUrls);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _hourlyRateController.dispose();
    _fixedRateController.dispose();
    _availabilityController.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 80,
    );
    if (images.isNotEmpty) {
      setState(() {
        _photos.addAll(images.map((x) => File(x.path)));
        if (_photos.length > 6) _photos.removeRange(6, _photos.length);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = ref.read(currentUserProvider).valueOrNull;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Please sign in again before saving your service listing.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      final repo = ref.read(serviceListingRepositoryProvider);

      if (_isEditing) {
        // ── Edit existing listing ────────────────────────────────────────
        // Upload any new photos
        final newPhotoUrls = <String>[];
        if (_photos.isNotEmpty) {
          newPhotoUrls.addAll(
            await repo.uploadPhotos(widget.existingListing!.id, _photos),
          );
        }

        final allPhotoUrls = [..._existingPhotoUrls, ...newPhotoUrls];

        await repo.updateListing(widget.existingListing!.id, {
          'categoryId': _categoryId,
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'hourlyRate': _hourlyRateController.text.isNotEmpty
              ? double.tryParse(_hourlyRateController.text)
              : null,
          'fixedRate': _fixedRateController.text.isNotEmpty
              ? double.tryParse(_fixedRateController.text)
              : null,
          'availability': _availabilityController.text.trim().isNotEmpty
              ? _availabilityController.text.trim()
              : null,
          'photoUrls': allPhotoUrls,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Service listing updated!')),
          );
          context.pop();
        }
      } else {
        // ── Create new listing ───────────────────────────────────────────
        final listing = ServiceListingModel(
          id: '',
          providerId: user.uid,
          providerName: user.displayName ?? 'Provider',
          categoryId: _categoryId!,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          hourlyRate: _hourlyRateController.text.isNotEmpty
              ? double.tryParse(_hourlyRateController.text)
              : null,
          fixedRate: _fixedRateController.text.isNotEmpty
              ? double.tryParse(_fixedRateController.text)
              : null,
          availability: _availabilityController.text.trim().isNotEmpty
              ? _availabilityController.text.trim()
              : null,
          neighbourhood: user.neighbourhood,
        );

        await repo.createListing(listing, photos: _photos);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Service listing created!')),
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Could not update your service listing. Please try again.'
                  : 'Could not create your service listing. Please try again.',
            ),
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
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
          title: Text(
              _isEditing ? 'Edit Service Listing' : 'Create Service Listing')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // Category
            const Text('Category',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              value: _categoryId,
              decoration: const InputDecoration(hintText: 'Select a category'),
              items: AppCategories.all
                  .map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Text('${c.emoji} ${c.label}'),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _categoryId = v),
              validator: (v) => v == null ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.md),

            // Title
            const Text('Title',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                  hintText: 'e.g. Professional Deep Cleaning'),
              maxLength: 80,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.md),

            // Description
            const Text('Description',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                hintText:
                    'Describe your service, experience, what you offer...',
              ),
              maxLines: 4,
              maxLength: 500,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.md),

            // Photos
            const Text('Photos',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 90,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // Existing photos (edit mode) ─────────────────────────
                  ..._existingPhotoUrls.asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(e.value,
                                  width: 80, height: 80, fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: () => setState(
                                    () => _existingPhotoUrls.removeAt(e.key)),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(2),
                                  child: const Icon(Icons.close,
                                      size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                  // New local photos ────────────────────────────────────
                  ..._photos.asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(e.value,
                                  width: 80, height: 80, fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _photos.removeAt(e.key)),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(2),
                                  child: const Icon(Icons.close,
                                      size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                  if ((_existingPhotoUrls.length + _photos.length) < 6)
                    GestureDetector(
                      onTap: _pickPhotos,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.bgMint,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined,
                                color: AppColors.primary, size: 24),
                            SizedBox(height: 4),
                            Text('Add',
                                style: TextStyle(
                                    fontSize: 11, color: AppColors.primary)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Pricing
            const Text('Pricing',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _hourlyRateController,
                    decoration:
                        const InputDecoration(hintText: 'Hourly rate (S\$)'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TextFormField(
                    controller: _fixedRateController,
                    decoration:
                        const InputDecoration(hintText: 'Fixed rate (S\$)'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Availability
            const Text('Availability',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _availabilityController,
              decoration: const InputDecoration(
                hintText: 'e.g. Weekdays 9am-6pm, Weekends flexible',
              ),
              maxLength: 100,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Submit
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_isEditing ? 'Save Changes' : 'Publish Service'),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
