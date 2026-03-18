// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProfilePhotoImpl _$$ProfilePhotoImplFromJson(Map<String, dynamic> json) =>
    _$ProfilePhotoImpl(
      id: json['id'] as String,
      url: json['url'] as String,
      caption: json['caption'] as String?,
      categoryId: json['categoryId'] as String?,
      isCover: json['isCover'] as bool? ?? false,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
    );

Map<String, dynamic> _$$ProfilePhotoImplToJson(_$ProfilePhotoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'url': instance.url,
      'caption': instance.caption,
      'categoryId': instance.categoryId,
      'isCover': instance.isCover,
      'uploadedAt': instance.uploadedAt.toIso8601String(),
    };

_$CategoryShowcaseImpl _$$CategoryShowcaseImplFromJson(
        Map<String, dynamic> json) =>
    _$CategoryShowcaseImpl(
      categoryId: json['categoryId'] as String,
      description: json['description'] as String?,
      photoIds: (json['photoIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$CategoryShowcaseImplToJson(
        _$CategoryShowcaseImpl instance) =>
    <String, dynamic>{
      'categoryId': instance.categoryId,
      'description': instance.description,
      'photoIds': instance.photoIds,
    };

_$ProviderStatsImpl _$$ProviderStatsImplFromJson(Map<String, dynamic> json) =>
    _$ProviderStatsImpl(
      completedTasks: (json['completedTasks'] as num?)?.toInt() ?? 0,
      avgRating: (json['avgRating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: (json['totalReviews'] as num?)?.toInt() ?? 0,
      repeatHires: (json['repeatHires'] as num?)?.toInt() ?? 0,
      avgResponseTime: json['avgResponseTime'] as String?,
      earningsTotal: (json['earningsTotal'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$$ProviderStatsImplToJson(_$ProviderStatsImpl instance) =>
    <String, dynamic>{
      'completedTasks': instance.completedTasks,
      'avgRating': instance.avgRating,
      'totalReviews': instance.totalReviews,
      'repeatHires': instance.repeatHires,
      'avgResponseTime': instance.avgResponseTime,
      'earningsTotal': instance.earningsTotal,
    };

_$UserModelImpl _$$UserModelImplFromJson(Map<String, dynamic> json) =>
    _$UserModelImpl(
      uid: json['uid'] as String,
      phone: json['phone'] as String,
      displayName: json['displayName'] as String?,
      email: json['email'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      headline: json['headline'] as String?,
      bio: json['bio'] as String?,
      neighbourhood: json['neighbourhood'] as String?,
      role: $enumDecodeNullable(_$UserRoleEnumMap, json['role']) ??
          UserRole.poster,
      serviceCategories: (json['serviceCategories'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      skillTags: (json['skillTags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      categoryShowcases: (json['categoryShowcases'] as List<dynamic>?)
              ?.map((e) => CategoryShowcase.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      photos: (json['photos'] as List<dynamic>?)
              ?.map((e) => ProfilePhoto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      introVideoUrl: json['introVideoUrl'] as String?,
      badges: (json['badges'] as List<dynamic>?)
              ?.map((e) => $enumDecode(_$VerificationBadgeEnumMap, e))
              .toList() ??
          const [],
      stats: json['stats'] == null
          ? null
          : ProviderStats.fromJson(json['stats'] as Map<String, dynamic>),
      completenessScore: (json['completenessScore'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      lastActiveAt: json['lastActiveAt'] == null
          ? null
          : DateTime.parse(json['lastActiveAt'] as String),
      isOnline: json['isOnline'] as bool? ?? false,
      isProfileComplete: json['isProfileComplete'] as bool? ?? false,
      isDeactivated: json['isDeactivated'] as bool? ?? false,
    );

Map<String, dynamic> _$$UserModelImplToJson(_$UserModelImpl instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'phone': instance.phone,
      'displayName': instance.displayName,
      'email': instance.email,
      'avatarUrl': instance.avatarUrl,
      'headline': instance.headline,
      'bio': instance.bio,
      'neighbourhood': instance.neighbourhood,
      'role': _$UserRoleEnumMap[instance.role]!,
      'serviceCategories': instance.serviceCategories,
      'skillTags': instance.skillTags,
      'categoryShowcases': instance.categoryShowcases,
      'photos': instance.photos,
      'introVideoUrl': instance.introVideoUrl,
      'badges':
          instance.badges.map((e) => _$VerificationBadgeEnumMap[e]!).toList(),
      'stats': instance.stats,
      'completenessScore': instance.completenessScore,
      'createdAt': instance.createdAt?.toIso8601String(),
      'lastActiveAt': instance.lastActiveAt?.toIso8601String(),
      'isOnline': instance.isOnline,
      'isProfileComplete': instance.isProfileComplete,
      'isDeactivated': instance.isDeactivated,
    };

const _$UserRoleEnumMap = {
  UserRole.poster: 'poster',
  UserRole.provider: 'provider',
  UserRole.both: 'both',
};

const _$VerificationBadgeEnumMap = {
  VerificationBadge.phoneVerified: 'phoneVerified',
  VerificationBadge.singpassVerified: 'singpassVerified',
  VerificationBadge.idVerified: 'idVerified',
  VerificationBadge.policeCleared: 'policeCleared',
  VerificationBadge.firstAidCertified: 'firstAidCertified',
  VerificationBadge.petSocietyMember: 'petSocietyMember',
  VerificationBadge.proProvider: 'proProvider',
  VerificationBadge.repeatHireStar: 'repeatHireStar',
};
