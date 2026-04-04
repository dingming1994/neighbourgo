import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_view/photo_view.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/category_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../../reviews/presentation/widgets/rating_summary.dart';
import '../../../reviews/presentation/widgets/review_card.dart';
import '../../../chat/data/repositories/chat_repository.dart';
import '../../data/models/profile_model.dart';
import '../../data/repositories/profile_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────
final publicProfileProvider = StreamProvider.family<UserModel?, String>(
  (ref, uid) => ref.watch(profileRepositoryProvider).watchProfile(uid),
);

final userReviewsProvider = StreamProvider.family<List<ReviewModel>, String>(
  (ref, uid) =>
      ref.watch(profileRepositoryProvider).watchReviews(uid, limit: 10),
);

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
class PublicProfileScreen extends ConsumerWidget {
  final String userId;
  const PublicProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(publicProfileProvider(userId));
    final reviewsAsync = ref.watch(userReviewsProvider(userId));
    final me = ref.watch(currentUserProvider).valueOrNull;
    final isMyProfile = me?.uid == userId;

    return profileAsync.when(
      skipLoadingOnReload: true,
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        body: ErrorState(
          onRetry: () => ref.invalidate(publicProfileProvider(userId)),
        ),
      ),
      data: (user) {
        if (user == null) {
          return Scaffold(
            body: EmptyState(
              emoji: '👤',
              title: 'Profile no longer available',
              subtitle:
                  'This user may have removed their profile or the link is outdated.',
              action: ElevatedButton.icon(
                onPressed: () => context.go(AppRoutes.home),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.button,
                  ),
                ),
                icon: const Icon(Icons.home_outlined, size: 18),
                label: const Text('Go Home'),
              ),
            ),
          );
        }
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // ── Header (SliverAppBar with cover photo) ──────────────────
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                actions: [
                  if (isMyProfile)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => context.push(AppRoutes.editProfile),
                    ),
                  if (!isMyProfile)
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () => _showOptions(context, user),
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Cover / first photo
                      user.coverPhoto != null
                          ? CachedNetworkImage(
                              imageUrl: user.coverPhoto!.url, fit: BoxFit.cover)
                          : Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    Color(0xFF0D5C47)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                            ),
                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.5)
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Identity row ─────────────────────────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.12),
                                    blurRadius: 8)
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 38,
                              backgroundColor: AppColors.bgMint,
                              backgroundImage: user.avatarUrl != null
                                  ? CachedNetworkImageProvider(user.avatarUrl!)
                                  : null,
                              child: user.avatarUrl == null
                                  ? Text(
                                      user.displayName
                                              ?.substring(0, 1)
                                              .toUpperCase() ??
                                          '?',
                                      style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                        child: Text(
                                            user.displayName ?? 'Neighbour',
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineSmall)),
                                    if (user.isOnline) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                            color: AppColors.success,
                                            shape: BoxShape.circle),
                                      ),
                                    ],
                                  ],
                                ),
                                if (user.neighbourhood != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_outlined,
                                          size: 14, color: AppColors.textHint),
                                      const SizedBox(width: 2),
                                      Text(user.neighbourhood!,
                                          style: const TextStyle(
                                              fontSize: 13,
                                              color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ],
                                if (user.headline != null &&
                                    user.headline!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(user.headline!,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textSecondary,
                                          height: 1.4)),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Badges ────────────────────────────────────────────
                      if (user.badges.isNotEmpty)
                        _BadgeRow(badges: user.badges),

                      // ── Stats bar ─────────────────────────────────────────
                      if (user.stats != null) ...[
                        const SizedBox(height: 16),
                        _StatsBar(stats: user.stats!),
                      ],

                      // ── Rates & Availability ────────────────────────────
                      if (user.isProvider &&
                          (user.serviceRates.isNotEmpty ||
                              user.availableDays.isNotEmpty)) ...[
                        const SizedBox(height: 20),
                        _RatesAvailabilitySection(user: user),
                      ],

                      // ── Action buttons ────────────────────────────────────
                      if (!isMyProfile) ...[
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: AppButton(
                                label:
                                    'Hire ${user.displayName?.split(' ').first ?? "Them"}',
                                onPressed: () => context.push(
                                  AppRoutes.postTask,
                                  extra: {
                                    'directHireProviderId': userId,
                                    'directHireProviderName':
                                        user.displayName ?? 'Provider',
                                    'preSelectedCategory':
                                        user.serviceCategories.isNotEmpty
                                            ? user.serviceCategories.first
                                            : null,
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppButton(
                                label: 'Message',
                                isOutlined: true,
                                leading: const Icon(Icons.chat_bubble_outline,
                                    size: 18),
                                onPressed: () async {
                                  if (me == null) return;
                                  final chatRepo =
                                      ref.read(chatRepositoryProvider);
                                  final chatId =
                                      await chatRepo.createDirectChat(
                                    me.uid,
                                    userId,
                                    user.displayName ?? 'Neighbour',
                                  );
                                  if (context.mounted) {
                                    context.push(
                                      AppRoutes.chatThread
                                          .replaceFirst(':chatId', chatId),
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],

                      // ── Bio ───────────────────────────────────────────────
                      const SizedBox(height: 24),
                      _SectionHeader(title: 'About Me'),
                      const SizedBox(height: 8),
                      if (user.bio != null && user.bio!.isNotEmpty)
                        Text(user.bio!,
                            style: const TextStyle(
                                height: 1.6, color: AppColors.textPrimary))
                      else
                        const Text('This user hasn\'t added a bio yet.',
                            style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textHint,
                                fontStyle: FontStyle.italic)),

                      // ── Skill tags ────────────────────────────────────────
                      const SizedBox(height: 24),
                      _SectionHeader(title: 'Skills'),
                      const SizedBox(height: 10),
                      if (user.skillTags.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: user.skillTags
                              .map((t) => Chip(
                                  label: Text(t),
                                  backgroundColor: AppColors.bgMint))
                              .toList(),
                        )
                      else
                        const Text('No skills listed',
                            style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textHint,
                                fontStyle: FontStyle.italic)),

                      // ── Category Showcases ────────────────────────────────
                      if (user.categoryShowcases.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _SectionHeader(title: 'Services & Portfolio'),
                        const SizedBox(height: 12),
                        ...user.categoryShowcases.map(
                          (s) =>
                              _ShowcaseBlock(showcase: s, photos: user.photos),
                        ),
                      ],

                      // ── Photo gallery (remaining photos) ──────────────────
                      if (user.photos
                          .where((p) => p.categoryId == null)
                          .isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _SectionHeader(title: 'Photo Gallery'),
                        const SizedBox(height: 12),
                        _PhotoGrid(
                          photos: user.photos
                              .where((p) => p.categoryId == null)
                              .toList(),
                        ),
                      ],

                      // ── Reviews ───────────────────────────────────────────
                      const SizedBox(height: 24),
                      _SectionHeader(
                        title: 'Reviews',
                        trailing: user.stats != null
                            ? '${user.stats!.avgRating.toStringAsFixed(1)} ★  (${user.stats!.totalReviews})'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      reviewsAsync.when(
                        skipLoadingOnReload: true,
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => ErrorState(
                          onRetry: () =>
                              ref.invalidate(userReviewsProvider(userId)),
                        ),
                        data: (reviews) => reviews.isEmpty
                            ? const EmptyState(
                                emoji: '💬', title: 'No reviews yet')
                            : Column(
                                children: [
                                  RatingSummary(
                                    avgRating: user.stats?.avgRating ?? 0,
                                    totalReviews: user.stats?.totalReviews ?? 0,
                                    reviews: reviews,
                                  ),
                                  const SizedBox(height: 12),
                                  ...reviews.map((r) => ReviewCard(review: r)),
                                ],
                              ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showOptions(BuildContext context, UserModel user) {
    showModalBottomSheet(
        context: context,
        builder: (_) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.flag_outlined),
                  title: const Text('Report User'),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmReport(context, user);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.block),
                  title: const Text('Block User'),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmBlock(context, user);
                  },
                ),
              ],
            ));
  }

  void _confirmReport(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Report this user?'),
        content: Text(
            'Are you sure you want to report ${user.displayName ?? 'this user'}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Report submitted. We will review this.')),
              );
            },
            child:
                const Text('Report', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _confirmBlock(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Block this user?'),
        content:
            const Text('Block this user? You won\'t see their tasks or bids.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User blocked.')),
              );
            },
            child:
                const Text('Block', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;
  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          if (trailing != null)
            Text(trailing!,
                style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600)),
        ],
      );
}

class _BadgeRow extends StatelessWidget {
  final List<VerificationBadge> badges;
  const _BadgeRow({required this.badges});

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 6,
        runSpacing: 6,
        children: badges
            .map((b) => Tooltip(
                  message: b.label,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.bgMint,
                      borderRadius: AppRadius.chip,
                      border:
                          Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(b.emoji, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text(b.label,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary)),
                    ]),
                  ),
                ))
            .toList(),
      );
}

class _StatsBar extends StatelessWidget {
  final ProviderStats stats;
  const _StatsBar({required this.stats});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
            color: AppColors.bgMint, borderRadius: AppRadius.card),
        child: Row(
          children: [
            _StatItem(
                value: stats.completedTasks.toString(), label: 'Tasks Done'),
            _divider(),
            _StatItem(
                value: stats.avgRating.toStringAsFixed(1), label: 'Avg Rating'),
            _divider(),
            _StatItem(value: '${stats.repeatHires}%', label: 'Repeat Hire'),
            _divider(),
            _StatItem(value: stats.avgResponseTime ?? 'N/A', label: 'Response'),
          ],
        ),
      );

  Widget _divider() => Container(
      height: 32,
      width: 1,
      color: AppColors.border,
      margin: const EdgeInsets.symmetric(horizontal: 12));
}

class _StatItem extends StatelessWidget {
  final String value, label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
        ]),
      );
}

class _ShowcaseBlock extends StatelessWidget {
  final CategoryShowcase showcase;
  final List<ProfilePhoto> photos;
  const _ShowcaseBlock({required this.showcase, required this.photos});

  @override
  Widget build(BuildContext context) {
    final cat = AppCategories.getById(showcase.categoryId);
    final blockPhotos =
        photos.where((p) => p.categoryId == showcase.categoryId).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: AppRadius.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: (cat?.color ?? AppColors.primary).withOpacity(0.08),
              borderRadius: BorderRadius.only(
                  topLeft: AppRadius.md, topRight: AppRadius.md),
            ),
            child: Row(
              children: [
                Text(cat?.emoji ?? '📁', style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Text(cat?.showcaseName ?? showcase.categoryId,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showcase.description != null &&
                    showcase.description!.isNotEmpty)
                  Text(showcase.description!,
                      style: const TextStyle(fontSize: 14, height: 1.5)),
                if (blockPhotos.isNotEmpty) ...[
                  if (showcase.description != null) const SizedBox(height: 12),
                  _PhotoGrid(photos: blockPhotos, compact: true),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  final List<ProfilePhoto> photos;
  final bool compact;
  const _PhotoGrid({required this.photos, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: photos.length,
      itemBuilder: (_, i) {
        final p = photos[i];
        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) =>
                  _FullscreenPhotoPage(photos: photos, initialIndex: i),
            ));
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                    imageUrl: p.url,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: AppColors.bgMint)),
              ),
              if (p.isCover)
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(4)),
                    child: const Text('Cover',
                        style: TextStyle(color: Colors.white, fontSize: 10)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _RatesAvailabilitySection extends StatelessWidget {
  final UserModel user;
  const _RatesAvailabilitySection({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Rates & Availability',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          if (user.serviceRates.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...user.serviceRates.entries.map((entry) {
              final cat = AppCategories.getById(entry.key);
              final rateData = entry.value;
              final hourlyRate =
                  rateData is Map ? rateData['hourlyRate'] : null;
              if (hourlyRate == null) return const SizedBox.shrink();
              // Handle both double and String values for backward compatibility
              final rateDisplay = hourlyRate is double
                  ? hourlyRate.toStringAsFixed(
                      hourlyRate.truncateToDouble() == hourlyRate ? 0 : 2)
                  : hourlyRate.toString();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(cat?.emoji ?? '',
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(cat?.label ?? entry.key,
                          style: const TextStyle(fontSize: 14)),
                    ),
                    Text('From S\$$rateDisplay/hr',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary)),
                  ],
                ),
              );
            }),
          ],
          if (user.availableDays.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: user.availableDays
                  .map((day) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.bgMint,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.primary.withOpacity(0.3)),
                        ),
                        child: Text(day,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primary)),
                      ))
                  .toList(),
            ),
          ],
          if (user.availableHours != null &&
              user.availableHours!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(user.availableHours!,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fullscreen Photo Viewer
// ─────────────────────────────────────────────────────────────────────────────
class _FullscreenPhotoPage extends StatefulWidget {
  final List<ProfilePhoto> photos;
  final int initialIndex;

  const _FullscreenPhotoPage(
      {required this.photos, required this.initialIndex});

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
              value: event == null
                  ? null
                  : event.cumulativeBytesLoaded /
                      (event.expectedTotalBytes ?? 1),
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
