import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'service_listing_model.freezed.dart';
part 'service_listing_model.g.dart';

@freezed
class ServiceListingModel with _$ServiceListingModel {
  const factory ServiceListingModel({
    required String id,
    required String providerId,
    required String providerName,
    required String categoryId,
    required String title,
    required String description,
    @Default([]) List<String> photoUrls,
    double? hourlyRate,
    double? fixedRate,
    String? availability,
    String? neighbourhood,
    DateTime? createdAt,
    @Default(true) bool isActive,
  }) = _ServiceListingModel;

  factory ServiceListingModel.fromJson(Map<String, dynamic> json) =>
      _$ServiceListingModelFromJson(json);
}

extension ServiceListingModelExt on ServiceListingModel {
  String get rateDisplay {
    if (hourlyRate != null && fixedRate != null) {
      return 'S\$${hourlyRate!.toStringAsFixed(0)}/hr · S\$${fixedRate!.toStringAsFixed(0)} fixed';
    }
    if (hourlyRate != null) return 'S\$${hourlyRate!.toStringAsFixed(0)}/hr';
    if (fixedRate != null) return 'S\$${fixedRate!.toStringAsFixed(0)} fixed';
    return 'Contact for pricing';
  }

  static ServiceListingModel fromFirestore(DocumentSnapshot doc) {
    final data = Map<String, dynamic>.from(doc.data() as Map);
    for (final key in ['createdAt']) {
      if (data[key] is Timestamp) {
        data[key] = (data[key] as Timestamp).toDate().toIso8601String();
      }
    }
    return ServiceListingModel.fromJson({...data, 'id': doc.id});
  }
}
