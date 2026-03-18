import 'package:freezed_annotation/freezed_annotation.dart';

part 'bid_model.freezed.dart';
part 'bid_model.g.dart';

enum BidStatus { pending, accepted, rejected }

@freezed
class BidModel with _$BidModel {
  const factory BidModel({
    required String  bidId,
    required String  taskId,
    required String  providerId,
    required String  providerName,
    String?          providerAvatar,
    required double  amount,
    String?          message,
    @Default(BidStatus.pending) BidStatus status,
    DateTime?        createdAt,
  }) = _BidModel;

  factory BidModel.fromJson(Map<String, dynamic> json) =>
      _$BidModelFromJson(json);
}
