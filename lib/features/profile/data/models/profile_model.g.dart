// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ReviewModelImpl _$$ReviewModelImplFromJson(Map<String, dynamic> json) =>
    _$ReviewModelImpl(
      id: json['id'] as String,
      reviewerId: json['reviewerId'] as String,
      reviewerName: json['reviewerName'] as String,
      reviewerAvatarUrl: json['reviewerAvatarUrl'] as String?,
      reviewedUserId: json['reviewedUserId'] as String,
      taskId: json['taskId'] as String,
      taskCategory: json['taskCategory'] as String,
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'] as String?,
      skillEndorsements: (json['skillEndorsements'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      providerReply: json['providerReply'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$ReviewModelImplToJson(_$ReviewModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'reviewerId': instance.reviewerId,
      'reviewerName': instance.reviewerName,
      'reviewerAvatarUrl': instance.reviewerAvatarUrl,
      'reviewedUserId': instance.reviewedUserId,
      'taskId': instance.taskId,
      'taskCategory': instance.taskCategory,
      'rating': instance.rating,
      'comment': instance.comment,
      'skillEndorsements': instance.skillEndorsements,
      'providerReply': instance.providerReply,
      'createdAt': instance.createdAt.toIso8601String(),
    };
