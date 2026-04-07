import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/category_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../../profile/data/models/profile_model.dart';
import '../../../profile/data/repositories/profile_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Skill endorsements per category
// ─────────────────────────────────────────────────────────────────────────────
const _categorySkills = <String, List<String>>{
  'cleaning':      ['Thorough', 'Punctual', 'Eco-friendly', 'Detail-oriented'],
  'tutoring':      ['Patient', 'Knowledgeable', 'Engaging', 'Well-prepared'],
  'pet_care':      ['Gentle', 'Reliable', 'Pet-friendly', 'Experienced'],
  'errands':       ['Fast', 'Accurate', 'Communicative', 'Flexible'],
  'queuing':       ['Patient', 'On-time', 'Reliable', 'Communicative'],
  'handyman':      ['Skilled', 'Clean work', 'Professional tools', 'Safe'],
  'moving':        ['Careful', 'Strong', 'Efficient', 'On-time'],
  'personal_care': ['Caring', 'Patient', 'Experienced', 'Trustworthy'],
  'admin':         ['Accurate', 'Fast', 'Tech-savvy', 'Detail-oriented'],
  'events':        ['Energetic', 'Organised', 'Friendly', 'Proactive'],
};

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
class SubmitReviewScreen extends ConsumerStatefulWidget {
  final String taskId;
  final String reviewedUserId;
  final String reviewedUserName;
  final String taskCategory;

  const SubmitReviewScreen({
    super.key,
    required this.taskId,
    required this.reviewedUserId,
    required this.reviewedUserName,
    required this.taskCategory,
  });

  @override
  ConsumerState<SubmitReviewScreen> createState() => _SubmitReviewScreenState();
}

class _SubmitReviewScreenState extends ConsumerState<SubmitReviewScreen> {
  double _rating = 0;
  final _commentController = TextEditingController();
  final _selectedSkills = <String>{};
  bool _isLoading = false;
  bool _isCheckingExisting = true;
  ReviewModel? _existingReview;

  List<String> get _availableSkills =>
      _categorySkills[widget.taskCategory] ?? ['Reliable', 'Punctual', 'Friendly', 'Professional'];

  @override
  void initState() {
    super.initState();
    _checkExistingReview();
  }

  Future<void> _checkExistingReview() async {
    final currentUser = ref.read(currentUserProvider).valueOrNull;
    if (currentUser == null) {
      setState(() => _isCheckingExisting = false);
      return;
    }

    try {
      final repo = ref.read(profileRepositoryProvider);
      final existing = await repo.fetchExistingReview(
        reviewedUserId: widget.reviewedUserId,
        taskId: widget.taskId,
        reviewerId: currentUser.uid,
      );
      if (mounted) {
        setState(() {
          _existingReview = existing;
          _isCheckingExisting = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isCheckingExisting = false);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    final currentUser = ref.read(currentUserProvider).valueOrNull;
    if (currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(profileRepositoryProvider);
      await repo.submitReview(
        reviewedUserId: widget.reviewedUserId,
        reviewerId: currentUser.uid,
        reviewerName: currentUser.displayName ?? 'Anonymous',
        reviewerAvatarUrl: currentUser.avatarUrl,
        taskId: widget.taskId,
        taskCategory: widget.taskCategory,
        rating: _rating,
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
        skillEndorsements: _selectedSkills.toList(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not submit review. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cat = AppCategories.getById(widget.taskCategory);

    if (_isCheckingExisting) {
      return Scaffold(
        appBar: AppBar(title: const Text('Leave a Review')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_existingReview != null) {
      return _ExistingReviewView(
        review: _existingReview!,
        reviewedUserName: widget.reviewedUserName,
        category: cat,
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Leave a Review')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Who you're reviewing ─────────────────────────────────────
            Text(
              'How was your experience with ${widget.reviewedUserName}?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (cat != null) ...[
              const SizedBox(height: 4),
              Text(
                '${cat.emoji} ${cat.label}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 24),

            // ── Star rating ──────────────────────────────────────────────
            Center(
              child: RatingBar.builder(
                initialRating: 0,
                minRating: 1,
                allowHalfRating: false,
                itemCount: 5,
                itemSize: 44,
                unratedColor: AppColors.border,
                itemBuilder: (_, __) => const Icon(
                  Icons.star_rounded,
                  color: AppColors.warning,
                ),
                onRatingUpdate: (r) => setState(() => _rating = r),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _ratingLabel(_rating),
                  style: TextStyle(
                    color: _rating > 0
                        ? AppColors.textPrimary
                        : AppColors.textHint,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── Comment ──────────────────────────────────────────────────
            Text('Comment (optional)',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 4,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: 'Share your experience...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // ── Skill endorsements ───────────────────────────────────────
            Text('Skill Endorsements (optional)',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableSkills.map((skill) {
                final selected = _selectedSkills.contains(skill);
                return AppChip(
                  label: skill,
                  selected: selected,
                  onTap: () => setState(() {
                    if (selected) {
                      _selectedSkills.remove(skill);
                    } else {
                      _selectedSkills.add(skill);
                    }
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // ── Submit ───────────────────────────────────────────────────
            AppButton(
              label: 'Submit Review',
              isLoading: _isLoading,
              onPressed: _rating > 0 ? _submit : null,
            ),
          ],
        ),
      ),
    );
  }

  String _ratingLabel(double rating) {
    if (rating <= 0) return 'Tap to rate';
    if (rating <= 1) return 'Poor';
    if (rating <= 2) return 'Fair';
    if (rating <= 3) return 'Good';
    if (rating <= 4) return 'Very Good';
    return 'Excellent';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Read-only view of an existing review
// ─────────────────────────────────────────────────────────────────────────────
class _ExistingReviewView extends StatelessWidget {
  final ReviewModel review;
  final String reviewedUserName;
  final ServiceCategory? category;

  const _ExistingReviewView({
    required this.review,
    required this.reviewedUserName,
    this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Review')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your review for $reviewedUserName',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (category != null) ...[
              const SizedBox(height: 4),
              Text(
                '${category!.emoji} ${category!.label}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 24),

            // ── Rating ───────────────────────────────────────────────────
            Center(
              child: RatingBarIndicator(
                rating: review.rating,
                itemCount: 5,
                itemSize: 44,
                unratedColor: AppColors.border,
                itemBuilder: (_, __) => const Icon(
                  Icons.star_rounded,
                  color: AppColors.warning,
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${review.rating.toStringAsFixed(0)} / 5',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── Comment ──────────────────────────────────────────────────
            if (review.comment != null && review.comment!.isNotEmpty) ...[
              Text('Your Comment',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: AppRadius.card,
                  border: Border.all(color: AppColors.divider),
                ),
                child: Text(
                  review.comment!,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ── Skill endorsements ───────────────────────────────────────
            if (review.skillEndorsements.isNotEmpty) ...[
              Text('Skill Endorsements',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: review.skillEndorsements
                    .map((skill) => Chip(
                          label: Text('👍 $skill',
                              style: const TextStyle(fontSize: 13)),
                          backgroundColor: AppColors.bgMint,
                        ))
                    .toList(),
              ),
              const SizedBox(height: 24),
            ],

            // ── Info banner ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bgMint,
                borderRadius: AppRadius.card,
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: AppColors.primary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'You have already submitted a review for this task.',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
