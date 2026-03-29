import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Enums
// ─────────────────────────────────────────────────────────────────────────────
enum UserRole { poster, provider, both }

enum VerificationBadge {
  phoneVerified,
  singpassVerified,
  idVerified,
  policeCleared,
  firstAidCertified,
  petSocietyMember,
  proProvider,
  repeatHireStar,
}

extension VerificationBadgeExt on VerificationBadge {
  String get label {
    switch (this) {
      case VerificationBadge.phoneVerified:      return 'Phone Verified';
      case VerificationBadge.singpassVerified:   return 'SingPass Verified';
      case VerificationBadge.idVerified:         return 'ID Verified';
      case VerificationBadge.policeCleared:      return 'Police Clearance';
      case VerificationBadge.firstAidCertified:  return 'First Aid Certified';
      case VerificationBadge.petSocietyMember:   return 'Pet Society Member';
      case VerificationBadge.proProvider:        return 'Pro Provider';
      case VerificationBadge.repeatHireStar:     return 'Repeat Hire Star';
    }
  }

  String get emoji {
    switch (this) {
      case VerificationBadge.phoneVerified:      return '📱';
      case VerificationBadge.singpassVerified:   return '🇸🇬';
      case VerificationBadge.idVerified:         return '🪪';
      case VerificationBadge.policeCleared:      return '🛡️';
      case VerificationBadge.firstAidCertified:  return '🩺';
      case VerificationBadge.petSocietyMember:   return '🐾';
      case VerificationBadge.proProvider:        return '⭐';
      case VerificationBadge.repeatHireStar:     return '🔄';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile Photo model
// ─────────────────────────────────────────────────────────────────────────────
@freezed
class ProfilePhoto with _$ProfilePhoto {
  const factory ProfilePhoto({
    required String id,
    required String url,
    String? caption,
    String? categoryId,           // which showcase album this belongs to
    @Default(false) bool isCover, // cover photo flag
    required DateTime uploadedAt,
  }) = _ProfilePhoto;

  factory ProfilePhoto.fromJson(Map<String, dynamic> json) =>
      _$ProfilePhotoFromJson(json);
}

// ─────────────────────────────────────────────────────────────────────────────
// Category Showcase Block
// ─────────────────────────────────────────────────────────────────────────────
@freezed
class CategoryShowcase with _$CategoryShowcase {
  const factory CategoryShowcase({
    required String categoryId,
    String? description,            // the "About Me" text for this category
    @Default([]) List<String> photoIds, // references into ProfilePhoto list
  }) = _CategoryShowcase;

  factory CategoryShowcase.fromJson(Map<String, dynamic> json) =>
      _$CategoryShowcaseFromJson(json);
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider Stats
// ─────────────────────────────────────────────────────────────────────────────
@freezed
class ProviderStats with _$ProviderStats {
  const factory ProviderStats({
    @Default(0)   int    completedTasks,
    @Default(0.0) double avgRating,
    @Default(0)   int    totalReviews,
    @Default(0)   int    repeatHires,        // times hired by same poster 2+
    String?             avgResponseTime,    // e.g. "< 1 hour"
    @Default(0.0) double earningsTotal,     // SGD (not shown publicly)
  }) = _ProviderStats;

  factory ProviderStats.fromJson(Map<String, dynamic> json) =>
      _$ProviderStatsFromJson(json);
}

// ─────────────────────────────────────────────────────────────────────────────
// Main User Model
// ─────────────────────────────────────────────────────────────────────────────
@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String uid,
    required String phone,

    // Basic info
    String? displayName,
    String? email,
    String? avatarUrl,
    String? headline,                         // 80-char tagline
    String? bio,                              // 500-char about me
    String? neighbourhood,                    // e.g. "Ang Mo Kio"

    // Role
    @Default(UserRole.poster) UserRole role,

    // Provider-specific
    @Default([]) List<String>         serviceCategories, // category IDs
    @Default([]) List<String>         skillTags,         // e.g. #DogWalking
    @Default([]) List<CategoryShowcase> categoryShowcases,

    // Media
    @Default([]) List<ProfilePhoto>   photos,
    String?                           introVideoUrl,

    // Trust & Verification
    @Default([]) List<VerificationBadge> badges,
    ProviderStats?                       stats,

    // Profile completeness (0–100)
    @Default(0) int completenessScore,

    // Meta
    DateTime?  createdAt,
    DateTime?  lastActiveAt,
    @Default(false) bool isOnline,
    @Default(false) bool isProfileComplete,
    @Default(false) bool isDeactivated,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}

// ─────────────────────────────────────────────────────────────────────────────
// Extension helpers
// ─────────────────────────────────────────────────────────────────────────────
extension UserModelExt on UserModel {
  bool get isProvider => role == UserRole.provider || role == UserRole.both;
  bool get isPoster   => role == UserRole.poster   || role == UserRole.both;
  bool get isSingPassVerified => badges.contains(VerificationBadge.singpassVerified);

  /// Deserialise from a Firestore DocumentSnapshot.
  static UserModel fromFirestore(DocumentSnapshot doc) {
    final data = Map<String, dynamic>.from(doc.data() as Map);
    // Convert Firestore Timestamps → ISO-8601 strings for json_serializable
    _convertTimestamp(data, 'createdAt');
    _convertTimestamp(data, 'lastActiveAt');
    // Convert nested ProfilePhoto timestamps
    if (data['photos'] is List) {
      data['photos'] = (data['photos'] as List).map((p) {
        if (p is Map<String, dynamic>) {
          final photo = Map<String, dynamic>.from(p);
          _convertTimestamp(photo, 'uploadedAt');
          return photo;
        }
        return p;
      }).toList();
    }
    return UserModel.fromJson({...data, 'uid': doc.id});
  }

  static void _convertTimestamp(Map<String, dynamic> map, String key) {
    if (map[key] is Timestamp) {
      map[key] = (map[key] as Timestamp).toDate().toIso8601String();
    }
  }

  ProfilePhoto? get coverPhoto {
    try { return photos.firstWhere((p) => p.isCover); }
    catch (_) { return photos.isNotEmpty ? photos.first : null; }
  }

  int get completeness {
    int score = 0;
    if (displayName != null && displayName!.isNotEmpty) score += 15;
    if (avatarUrl   != null)                             score += 15;
    if (headline    != null && headline!.isNotEmpty)     score += 10;
    if (bio         != null && bio!.isNotEmpty)          score += 10;
    if (neighbourhood != null)                           score += 5;
    if (photos.isNotEmpty)                               score += 15;
    if (serviceCategories.isNotEmpty)                    score += 10;
    if (skillTags.isNotEmpty)                            score += 5;
    if (categoryShowcases.isNotEmpty)                    score += 10;
    if (badges.contains(VerificationBadge.idVerified))   score += 5;
    return score.clamp(0, 100);
  }
}
