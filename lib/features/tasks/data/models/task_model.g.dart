// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GeoPoint2Impl _$$GeoPoint2ImplFromJson(Map<String, dynamic> json) =>
    _$GeoPoint2Impl(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );

Map<String, dynamic> _$$GeoPoint2ImplToJson(_$GeoPoint2Impl instance) =>
    <String, dynamic>{
      'lat': instance.lat,
      'lng': instance.lng,
    };

_$TaskModelImpl _$$TaskModelImplFromJson(Map<String, dynamic> json) =>
    _$TaskModelImpl(
      id: json['id'] as String,
      posterId: json['posterId'] as String,
      posterName: json['posterName'] as String?,
      posterAvatarUrl: json['posterAvatarUrl'] as String?,
      title: json['title'] as String,
      description: json['description'] as String,
      categoryId: json['categoryId'] as String,
      photoUrls: (json['photoUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      locationLabel: json['locationLabel'] as String,
      neighbourhood: json['neighbourhood'] as String?,
      location: json['location'] == null
          ? null
          : GeoPoint2.fromJson(json['location'] as Map<String, dynamic>),
      budgetMin: (json['budgetMin'] as num).toDouble(),
      budgetMax: (json['budgetMax'] as num?)?.toDouble(),
      currency: json['currency'] as String? ?? 'SGD',
      urgency: $enumDecode(_$TaskUrgencyEnumMap, json['urgency']),
      scheduledDate: json['scheduledDate'] == null
          ? null
          : DateTime.parse(json['scheduledDate'] as String),
      estimatedDurationMins: (json['estimatedDurationMins'] as num?)?.toInt(),
      status: $enumDecodeNullable(_$TaskStatusEnumMap, json['status']) ??
          TaskStatus.open,
      assignedProviderId: json['assignedProviderId'] as String?,
      assignedProviderName: json['assignedProviderName'] as String?,
      bidCount: (json['bidCount'] as num?)?.toInt() ?? 0,
      viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
      paymentIntentId: json['paymentIntentId'] as String?,
      isPaid: json['isPaid'] as bool? ?? false,
      isEscrowReleased: json['isEscrowReleased'] as bool? ?? false,
    );

Map<String, dynamic> _$$TaskModelImplToJson(_$TaskModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'posterId': instance.posterId,
      'posterName': instance.posterName,
      'posterAvatarUrl': instance.posterAvatarUrl,
      'title': instance.title,
      'description': instance.description,
      'categoryId': instance.categoryId,
      'photoUrls': instance.photoUrls,
      'tags': instance.tags,
      'locationLabel': instance.locationLabel,
      'neighbourhood': instance.neighbourhood,
      'location': instance.location,
      'budgetMin': instance.budgetMin,
      'budgetMax': instance.budgetMax,
      'currency': instance.currency,
      'urgency': _$TaskUrgencyEnumMap[instance.urgency]!,
      'scheduledDate': instance.scheduledDate?.toIso8601String(),
      'estimatedDurationMins': instance.estimatedDurationMins,
      'status': _$TaskStatusEnumMap[instance.status]!,
      'assignedProviderId': instance.assignedProviderId,
      'assignedProviderName': instance.assignedProviderName,
      'bidCount': instance.bidCount,
      'viewCount': instance.viewCount,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
      'expiresAt': instance.expiresAt?.toIso8601String(),
      'paymentIntentId': instance.paymentIntentId,
      'isPaid': instance.isPaid,
      'isEscrowReleased': instance.isEscrowReleased,
    };

const _$TaskUrgencyEnumMap = {
  TaskUrgency.flexible: 'flexible',
  TaskUrgency.today: 'today',
  TaskUrgency.asap: 'asap',
};

const _$TaskStatusEnumMap = {
  TaskStatus.open: 'open',
  TaskStatus.assigned: 'assigned',
  TaskStatus.inProgress: 'inProgress',
  TaskStatus.completed: 'completed',
  TaskStatus.cancelled: 'cancelled',
  TaskStatus.disputed: 'disputed',
};
