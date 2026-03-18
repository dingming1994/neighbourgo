// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bid_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BidModelImpl _$$BidModelImplFromJson(Map<String, dynamic> json) =>
    _$BidModelImpl(
      bidId: json['bidId'] as String,
      taskId: json['taskId'] as String,
      providerId: json['providerId'] as String,
      providerName: json['providerName'] as String,
      providerAvatar: json['providerAvatar'] as String?,
      amount: (json['amount'] as num).toDouble(),
      message: json['message'] as String?,
      status: $enumDecodeNullable(_$BidStatusEnumMap, json['status']) ??
          BidStatus.pending,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$BidModelImplToJson(_$BidModelImpl instance) =>
    <String, dynamic>{
      'bidId': instance.bidId,
      'taskId': instance.taskId,
      'providerId': instance.providerId,
      'providerName': instance.providerName,
      'providerAvatar': instance.providerAvatar,
      'amount': instance.amount,
      'message': instance.message,
      'status': _$BidStatusEnumMap[instance.status]!,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

const _$BidStatusEnumMap = {
  BidStatus.pending: 'pending',
  BidStatus.accepted: 'accepted',
  BidStatus.rejected: 'rejected',
};
