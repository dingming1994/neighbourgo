import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/image_validator.dart';
import '../../../../core/constants/category_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../data/repositories/profile_repository.dart';

class PhotoGalleryScreen extends ConsumerStatefulWidget {
  const PhotoGalleryScreen({super.key});

  @override
  ConsumerState<PhotoGalleryScreen> createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends ConsumerState<PhotoGalleryScreen> {
  String? _selectedCategory; // null = general
  bool    _uploading = false;
  String? _deletingPhotoId;
  String? _settingCoverId;

  Future<void> _pickAndUpload() async {
    final imgs = await ImagePicker().pickMultiImage(
      maxWidth: 1024, maxHeight: 1024, imageQuality: 85, limit: 5,
    );
    if (imgs.isEmpty) return;

    // Validate images before upload
    final files = imgs.map((x) => File(x.path)).toList();
    final errors = ImageValidator.validateAll(files);
    if (errors.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errors.first), backgroundColor: AppColors.error),
        );
      }
      return;
    }

    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    // Check limit
    if (user.photos.length + imgs.length > AppConstants.maxProfilePhotos) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Max ${AppConstants.maxProfilePhotos} photos allowed. You can upload ${AppConstants.maxProfilePhotos - user.photos.length} more.')),
        );
      }
      return;
    }

    setState(() => _uploading = true);
    try {
      final repo   = ref.read(profileRepositoryProvider);
      final photos = <ProfilePhoto>[];
      for (final img in imgs) {
        final uploaded = await repo.uploadGalleryPhoto(
          uid:        user.uid,
          file:       File(img.path),
          categoryId: _selectedCategory,
          isCover:    user.photos.isEmpty && photos.isEmpty,
        );
        photos.add(uploaded);
      }
      for (final p in photos) {
        await repo.addGalleryPhoto(user.uid, p);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${photos.length} photo(s) uploaded!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _deletePhoto(UserModel user, ProfilePhoto photo) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Photo'),
        content: const Text('Remove this photo from your profile?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true),  child: const Text('Delete', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _deletingPhotoId = photo.id);
    try {
      await ref.read(profileRepositoryProvider).removeGalleryPhoto(user.uid, photo);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _deletingPhotoId = null);
    }
  }

  Future<void> _setCover(UserModel user, ProfilePhoto photo) async {
    setState(() => _settingCoverId = photo.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Setting cover photo...')),
      );
    }
    try {
      final updated = user.photos.map(
        (p) => p.copyWith(isCover: p.id == photo.id),
      ).toList();
      await ref.read(profileRepositoryProvider).updatePhotosArray(user.uid, updated);
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Cover photo updated!'), backgroundColor: AppColors.success),
          );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text('Failed to set cover: $e'), backgroundColor: AppColors.error),
          );
      }
    } finally {
      if (mounted) setState(() => _settingCoverId = null);
    }
  }

  void _openFullscreen(BuildContext context, List<ProfilePhoto> photos, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullscreenPhotoPage(photos: photos, initialIndex: index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Photo Gallery'),
        actions: [
          if (_uploading)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            IconButton(
              icon: const Icon(Icons.add_photo_alternate_outlined),
              tooltip: 'Add photos',
              onPressed: _pickAndUpload,
            ),
        ],
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Error: $e')),
        data:    (user) {
          if (user == null) return const SizedBox.shrink();

          return Column(
            children: [
              // ── Category filter chips ─────────────────────────────────────
              SizedBox(
                height: 48,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  scrollDirection: Axis.horizontal,
                  children: [
                    _CategoryChip(
                      label: 'All',
                      selected: _selectedCategory == null,
                      onTap: () => setState(() => _selectedCategory = null),
                    ),
                    const SizedBox(width: 8),
                    ...AppCategories.all.map((cat) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _CategoryChip(
                        label: '${cat.emoji} ${cat.label}',
                        selected: _selectedCategory == cat.id,
                        onTap: () => setState(() => _selectedCategory = cat.id),
                        color: cat.color,
                      ),
                    )),
                  ],
                ),
              ),
              const Divider(height: 1),

              // ── Photo count ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text('${user.photos.length}/${AppConstants.maxProfilePhotos} photos',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _pickAndUpload,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Photos'),
                    ),
                  ],
                ),
              ),

              // ── Grid ──────────────────────────────────────────────────────
              Expanded(
                child: () {
                  final filtered = _selectedCategory == null
                      ? user.photos
                      : user.photos.where((p) => p.categoryId == _selectedCategory).toList();

                  if (filtered.isEmpty) {
                    return const EmptyState(
                      emoji: '📸',
                      title: 'No photos yet',
                      subtitle: 'Tap + to add photos that show your personality and skills.',
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, crossAxisSpacing: 6, mainAxisSpacing: 6,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _PhotoTile(
                      photo: filtered[i],
                      isDeleting: _deletingPhotoId == filtered[i].id,
                      isSettingCover: _settingCoverId == filtered[i].id,
                      onDelete: () => _deletePhoto(user, filtered[i]),
                      onSetCover: () => _setCover(user, filtered[i]),
                      onTap: () => _openFullscreen(context, filtered, i),
                    ),
                  );
                }(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  const _CategoryChip({required this.label, required this.selected, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? c : AppColors.bgCard,
          borderRadius: AppRadius.chip,
          border: Border.all(color: selected ? c : AppColors.border),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
            color: selected ? Colors.white : AppColors.textSecondary)),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final ProfilePhoto photo;
  final bool isDeleting;
  final bool isSettingCover;
  final VoidCallback onDelete, onSetCover, onTap;

  const _PhotoTile({
    required this.photo,
    required this.onDelete,
    required this.onSetCover,
    required this.onTap,
    this.isDeleting = false,
    this.isSettingCover = false,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    onLongPress: (isDeleting || isSettingCover) ? null : () => _showMenu(context),
    child: Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: photo.url,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: AppColors.bgMint),
            errorWidget: (_, __, ___) => Container(
              color: AppColors.bgMint,
              child: const Icon(Icons.broken_image_outlined, color: AppColors.textHint),
            ),
          ),
        ),
        if (isDeleting || isSettingCover)
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            ),
          ),
        if (photo.isCover)
          Positioned(
            top: 4, left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4)),
              child: const Text('Cover', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
            ),
          ),
        // Caption overlay
        if (photo.caption != null && photo.caption!.isNotEmpty)
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
                color: Colors.black.withOpacity(0.5),
              ),
              child: Text(photo.caption!, style: const TextStyle(color: Colors.white, fontSize: 10),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
      ],
    ),
  );

  void _showMenu(BuildContext context) => showModalBottomSheet(
    context: context,
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!photo.isCover)
            ListTile(
              leading: const Icon(Icons.star_outline),
              title: const Text('Set as Cover Photo'),
              onTap: () { Navigator.pop(context); onSetCover(); },
            ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: AppColors.error),
            title: const Text('Delete Photo', style: TextStyle(color: AppColors.error)),
            onTap: () { Navigator.pop(context); onDelete(); },
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Fullscreen Photo Page with pinch-to-zoom
// ─────────────────────────────────────────────────────────────────────────────
class _FullscreenPhotoPage extends StatefulWidget {
  final List<ProfilePhoto> photos;
  final int initialIndex;

  const _FullscreenPhotoPage({required this.photos, required this.initialIndex});

  @override
  State<_FullscreenPhotoPage> createState() => _FullscreenPhotoPageState();
}

class _FullscreenPhotoPageState extends State<_FullscreenPhotoPage> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_currentIndex + 1} / ${widget.photos.length}',
            style: const TextStyle(color: Colors.white, fontSize: 16)),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.photos.length,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        itemBuilder: (_, i) => PhotoView(
          imageProvider: CachedNetworkImageProvider(widget.photos[i].url),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 3,
          backgroundDecoration: const BoxDecoration(color: Colors.black),
          loadingBuilder: (_, event) => Center(
            child: CircularProgressIndicator(
              value: event == null ? null
                  : event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? 1),
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

