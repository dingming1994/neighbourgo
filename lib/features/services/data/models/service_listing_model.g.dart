// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_listing_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ServiceListingModelImpl _$$ServiceListingModelImplFromJson(
        Map<String, dynamic> json) =>
    _$ServiceListingModelImpl(
      id: json['id'] as String,
      providerId: json['providerId'] as String,
      providerName: json['providerName'] as String,
      categoryId: json['categoryId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      photoUrls: (json['photoUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble(),
      fixedRate: (json['fixedRate'] as num?)?.toDouble(),
      availability: json['availability'] as String?,
      neighbourhood: json['neighbourhood'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
    );

Map<String, dynamic> _$$ServiceListingModelImplToJson(
        _$ServiceListingModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'providerId': instance.providerId,
      'providerName': instance.providerName,
      'categoryId': instance.categoryId,
      'title': instance.title,
      'description': instance.description,
      'photoUrls': instance.photoUrls,
      'hourlyRate': instance.hourlyRate,
      'fixedRate': instance.fixedRate,
      'availability': instance.availability,
      'neighbourhood': instance.neighbourhood,
      'createdAt': instance.createdAt?.toIso8601String(),
      'isActive': instance.isActive,
    };
